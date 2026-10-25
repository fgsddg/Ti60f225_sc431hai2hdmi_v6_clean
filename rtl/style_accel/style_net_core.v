/*
 * Per-layer streaming core: conv stage + InstanceNorm + requant.
 *
 * Statistics and requantisation are serialised over output channels.  This
 * keeps one 32x32 stats multiplier and one requant multiplier instead of OC
 * copies of each, which is required to fit the Ti60 DSP budget.
 */
module style_net_core #(
    parameter integer LANES   = 80,
    parameter integer MAX_IC  = 32,
    parameter integer MAX_OC  = 32,
    parameter integer MAX_UW  = 640
) (
    input  wire                        clk,
    input  wire                        rst_n,

    input  wire                        start,
    input  wire                        is_stats,
    /* p0/p1 raw-int32 validation modes. */
    input  wire                        raw_produce,
    input  wire                        raw_consume,
    input  wire                        do_relu,
    /* op = CONV_TANH (4): the requant tail is replaced by the Q8.16 tanh output
     * head.  tanh_do = 0 leaves the whole requant path bit-identical.  The LUT
     * arrives over the write port below (streamed by the parameter loader); the
     * per-channel affine constants arrive on p_s2/p_sg, which the loader fills
     * from the head's records on such a pass (HANDOFF_ACCEL 9.41). */
    input  wire                        tanh_do,
    input  wire                        lut_we,
    input  wire [12:0]                 lut_waddr,
    input  wire [23:0]                 lut_wdata,
    output reg                         busy,
    output wire [2:0]                  dbg_state,   /* bring-up: core FSM state */
    output reg                         done,

    /* runtime shape (from cfg; from the pass descriptor, stable per pass) */
    input  wire [5:0]                  shp_ic,
    input  wire [5:0]                  shp_oc,
    input  wire [1:0]                  shp_stride,
    input  wire [1:0]                  shp_up,
    input  wire [15:0]                 shp_in_w,
    input  wire [15:0]                 shp_in_h,

    input  wire [255:0]                in_pixel,
    input  wire                        in_valid,
    output wire                        in_ready,

    output reg  [255:0]                out_pixel,
    output wire                        out_valid,
    input  wire                        out_ready,

    output wire [$clog2(MAX_OC)+4-1:0] w_addr,     /* {oc, word} into the weight BRAM */
    input  wire [255:0]                w_rdata,    /* 32 flat bytes of the filter */
    input  wire signed [8:0]           zp_in,
    input  wire [31:0]                 inv_n_q32,
    /* InstanceNorm parameters come from the loader a channel at a time: send the
     * channel and sample the registered data one cycle later (see nrm_settle). */
    output wire [$clog2(MAX_OC)-1:0]   p_raddr,
    input  wire signed [63:0]          p_s2,
    input  wire signed [63:0]          p_sg,
    input  wire signed [63:0]          p_beta,
    /* Residual branch (op = CONV_RESIDUAL).  The second DDR stream carries the
     * block-input tensor, and res_q32 = (res_pixel - res_zp) * res_scale_q32 is
     * added to y_q32 before the output requant.  res_do = 0 leaves the relu path
     * bit-identical to requant_relu_pipe_core. */
    input  wire                        res_do,
    input  wire                        res_valid,
    input  wire [8*MAX_OC-1:0]         res_pixel,
    input  wire signed [63:0]          res_scale_q32,
    input  wire signed [7:0]           res_zp,
    output wire                        res_ready,
    input  wire [63:0]                 q_scale_recip_q48,
    input  wire signed [7:0]           q_zero_point,

    /* sum_flat/sumsq_flat are historical: they used to expose the per-channel
     * statistics arrays, which are now a block RAM (u_stats, see
     * stats_channel_store).  The ports stay because the harnesses and the SoC
     * template list them; they read 0.  Read a channel back through the
     * dbg_st_* tap below (HANDOFF_ACCEL 10.2). */
    output wire [64*MAX_OC-1:0]        sum_flat,
    output wire [64*MAX_OC-1:0]        sumsq_flat,
    output wire [31:0]                 count_out,

    /* Bring-up/harness read-back of one statistics channel at a time.  The
     * address is only sampled while no FSM owns the RAM (see st_raddr), so a
     * harness can read the sums out after the stats pass has finished. */
    input  wire [4:0]                  dbg_st_addr,
    output wire signed [63:0]          dbg_st_sum,
    output wire signed [63:0]          dbg_st_sumsq
);

    localparam integer ST_IDLE   = 3'd0;
    localparam integer ST_CLEAR  = 3'd1;
    localparam integer ST_STATS  = 3'd2;
    localparam integer ST_NORM   = 3'd3;
    localparam integer ST_COMPUTE= 3'd4;
    localparam integer ST_RESET  = 3'd5;
    localparam integer ST_SCLR   = 3'd6;   /* zero the statistics RAM (stats pass) */
    localparam integer ST_RAW    = 3'd7;   /* raw-int32 consume: no conv stage */

    reg [2:0] state;
    integer   ch;
    reg [5:0] st_sc;        /* statistics walk cursor: 0 .. shp_oc, 0 on entry */
    reg       nrm_settle;   /* one cycle for the loader's norm-parameter read */
    reg [3:0] clear_cnt;
    reg       next_is_stats;
    reg       stage_rst;
    reg       stage_done_seen;
    reg       raw_active;
    reg       raw_preload;
    reg       raw_busy;
    reg       raw_finish_pending;
    reg [255:0] raw_pixel_r;
    reg [31:0] raw_pix_count;
    reg [31:0] raw_total_r;

    wire stage_rst_n = rst_n && !stage_rst;

    /* ---- conv stage ---- */
    wire signed [32*MAX_OC-1:0] acc_flat;
    wire [$clog2(MAX_OC)-1:0] oc_ev_idx;
    wire signed [31:0]        oc_ev_acc;
    wire                      oc_ev_valid;
    wire                    stage_valid;
    wire                    stage_done;
    wire                    acc_ready;
    wire                    stage_in_ready;

    /* The pass sequencer owns the statistics RAM for the first few cycles of a
     * stats pass.  Do not let the stage get far enough ahead to publish OC events
     * before ST_STATS can consume them.  Both directions are gated: merely
     * masking in_ready would still let the stage consume in_valid internally. */
    wire input_window_open = (state == ST_STATS) || (state == ST_COMPUTE);
    wire stage_in_valid = in_valid && input_window_open && !raw_consume;
    assign in_ready = raw_consume ? raw_input_open
                                  : (stage_in_ready && input_window_open);

    /* Shared-bank stage: one channel-interleaved line-buffer set for all IC
     * channels (HANDOFF_ACCEL 9.22); same port contract as the per-channel
     * conv3x3_stage_lanes it replaces. */
    conv3x3_stage_wide #(
        .MAX_UW(MAX_UW), .MAX_IC(MAX_IC), .MAX_OC(MAX_OC), .LANES(LANES)
    ) u_stage (
        .shp_in_w(shp_in_w), .shp_in_h(shp_in_h),
        .shp_up(shp_up), .shp_stride(shp_stride),
        .shp_ic(shp_ic), .shp_oc(shp_oc),
        .clk(clk), .rst_n(stage_rst_n),
        .in_valid(stage_in_valid), .in_pixel(in_pixel[8*MAX_IC-1:0]),
        .in_ready(stage_in_ready),
        .w_addr(w_addr), .w_rdata(w_rdata),
        .zp_in(zp_in),
        .acc_flat(acc_flat),
        .oc_ev_idx(oc_ev_idx), .oc_ev_acc(oc_ev_acc),
        .oc_ev_valid(oc_ev_valid),
        .out_valid(stage_valid), .out_ready(acc_ready),
        .done(stage_done)
    );

    /* ---- streamed statistics ----
     * Each OC event is accumulated into the same 32 x 64-bit statistics RAM as
     * soon as that channel leaves the conv engine.  This overlaps the read +
     * write of channel N with the engine's work on channel N+1, instead of
     * waiting for the whole pixel and then scanning all OCs one per cycle.
     *
     * `st_ev_pend` is the one-deep read/write pipeline.  An event presents its
     * channel address to the RAM; the following cycle commits read-data + acc
     * back to that same address.  The conv engine cannot publish two events in
     * consecutive cycles, so one pending entry is sufficient. */
    reg        [31:0] count_r [0:MAX_OC-1];
    reg [4:0]  st_ev_idx;
    reg signed [31:0] st_ev_acc;
    reg        st_ev_pend;
    reg        st_last_seen;
    reg [4:0] proc_ch;
    /* which output channel's parameters we want from the loader.  On an op=4
     * pass the norm store holds the tanh head's affine constants instead, and
     * they are needed channel-by-channel as the output walk runs. */
    assign p_raddr = tanh_do ? proc_ch : ch[4:0];
    reg       proc_active;
    reg       acc_ready_r;
    reg       out_valid_r;
    wire raw_input_open = (state == ST_RAW) && !raw_busy &&
                          !out_valid_r && !raw_finish_pending;
    reg       rq_busy;      /* holds the compute slot from latch to output take */

    wire signed [63:0] stats_sq = st_ev_acc * st_ev_acc;

    wire signed [63:0] st_rsum;     /* u_stats read data for `st_raddr` */
    wire signed [63:0] st_rsumsq;

    wire [4:0] st_waddr = (state == ST_SCLR) ? st_sc[4:0] : st_ev_idx;
    wire       st_we    = (state == ST_SCLR) ||
                          ((state == ST_STATS) && st_ev_pend);
    wire signed [63:0] st_wsum   = (state == ST_SCLR) ? 64'sd0 :
                                                       (st_rsum + st_ev_acc);
    wire signed [63:0] st_wsumsq = (state == ST_SCLR) ? 64'sd0 :
                                                       (st_rsumsq + stats_sq);

    /* The event address is presented in the event cycle; its data arrives in
     * the next cycle, which is exactly when st_ev_pend commits it.  ST_NORM and
     * the debug tap keep their original sequential/read-back addressing. */
    wire [4:0] st_norm_raddr = (ch == (shp_oc - 6'd1)) ? 5'd0 : (ch[4:0] + 5'd1);
    wire [4:0] st_raddr = (state == ST_NORM) ? st_norm_raddr :
                          (state == ST_SCLR) ? st_sc[4:0] :
                          ((state == ST_STATS) && oc_ev_valid) ? oc_ev_idx :
                          dbg_st_addr;

    stats_channel_store #(.MAX_CH(MAX_OC)) u_stats (
        .clk(clk),
        .we(st_we), .waddr(st_waddr),
        .wdata_sum(st_wsum), .wdata_sumsq(st_wsumsq),
        .raddr(st_raddr),
        .rdata_sum(st_rsum), .rdata_sumsq(st_rsumsq)
    );

    assign sum_flat    = {64*MAX_OC{1'b0}};
    assign sumsq_flat  = {64*MAX_OC{1'b0}};
    assign dbg_st_sum   = st_rsum;
    assign dbg_st_sumsq = st_rsumsq;

    assign count_out = count_r[0];
    assign acc_ready = acc_ready_r;
    assign out_valid = out_valid_r;

    /* ---- InstanceNorm parameter derivation ---- */
    reg         np_start;
    wire        np_done;
    wire signed [63:0] np_scale;
    wire signed [63:0] np_bias;

    /* norm_scale/norm_bias live in a RAM, not one 64-bit register per output
     * channel.  At OC=32 the two arrays are 4096 flops plus roughly 1.4k LUT of
     * 32:1 read mux, a large part of why the IC=16/OC=32 instantiation did not
     * fit the Ti60 (HANDOFF_ACCEL 9.14 section nine).  A registered read costs
     * nothing here: the write (ST_NORM) and the read (ST_COMPUTE) both walk the
     * channels sequentially, so the read address is issued one cycle ahead and
     * the data lines up with proc_ch. */
    (* ram_style = "distributed", syn_ram_style = "logic" *)   /* small: keep it out of the 256 BRAMs */
    reg signed [63:0] norm_scale_ram [0:MAX_OC-1];
    (* ram_style = "distributed", syn_ram_style = "logic" *)
    reg signed [63:0] norm_bias_ram  [0:MAX_OC-1];
    reg        [4:0]  nrm_waddr;
    reg signed [63:0] nrm_wdata_s, nrm_wdata_b;
    reg               nrm_we;
    /* Read-ahead address for the compute-pass reads.  The RAM read is the one and
     * only pipeline stage (`nrm_scale_r <= ram[nrm_raddr]`), so the address must
     * be combinational in proc_ch: the data registered at the end of cycle T is
     * then ram[proc_ch(T)].
     *
     * Registering this address as well (the original 0ca679f form) added a second
     * pipeline stage, so the value registered at cycle T was ram[proc_ch(T)-1]:
     * every output channel except the first used the *previous* channel's
     * InstanceNorm scale/bias.  Simulation missed it because tb_style_net_core
     * printed mismatch/max_diff but only gated on the emitted-pixel count. */
    /* Normal relu compute streams each completed OC directly into requant.
     * The event address selects the norm RAM in the event cycle; nrm_scale_r is
     * then valid in the following cycle, when oc_feed_pend offers the same OC to
     * requant.  Tanh and residual passes retain the original serial walk. */
    wire compute_stream = !tanh_do && !res_do && !raw_consume;
    wire raw_context = raw_consume && (state == ST_RAW) && raw_active;
    wire [4:0] nrm_raddr = raw_context
                           ? (raw_preload
                              ? proc_ch
                              : ((proc_ch == (shp_oc - 6'd1)) ? 5'd0 : (proc_ch + 5'd1)))
                           : ((compute_stream && (state == ST_COMPUTE) && oc_ev_valid)
                              ? oc_ev_idx :
                              (proc_active
                               ? ((proc_ch == (shp_oc - 6'd1)) ? 5'd0 : (proc_ch + 5'd1))
                               : 5'd0));
    reg signed [63:0] nrm_scale_r, nrm_bias_r;

    always @(posedge clk) begin
        if (nrm_we) begin
            norm_scale_ram[nrm_waddr] <= nrm_wdata_s;
            norm_bias_ram [nrm_waddr] <= nrm_wdata_b;
        end
        nrm_scale_r <= norm_scale_ram[nrm_raddr];
        nrm_bias_r  <= norm_bias_ram [nrm_raddr];
    end

    reg signed [63:0] np_sum;
    reg signed [63:0] np_sumsq;

    norm_param_core u_norm (
        .clk(clk), .rst_n(rst_n), .start(np_start),
        .sum_acc(np_sum), .sumsq_acc(np_sumsq), .inv_n_q32(inv_n_q32),
        .s2_q48(p_s2),
        .sg_q32(p_sg),
        .beta_q32(p_beta),
        .done(np_done),
        .mean_q32(), .var_acc_q32(), .var_y_q32(), .sqrt_q16(),
        .inv_std_q32(), .norm_scale_q32(np_scale), .norm_bias_q32(np_bias)
    );

    /* ---- one shared requant unit, serviced one OC per cycle ----
     * requant_pipe_core covers the relu case and the residual case via relu_en,
     * so the whole 19-pass sequence needs exactly ONE instance (the passes run
     * one at a time).  requant_relu_core / residual_add_requant_core stay as the
     * combinational reference models for the testbenches. */
    /* The residual pixel for the output being requantised is latched when the
     * core accepts that output, then indexed by proc_ch as the channels drain. */
    reg  [8*MAX_OC-1:0]    res_pix_r;
    reg        oc_feed_pend;
    reg [4:0]  oc_feed_idx;
    reg signed [31:0] oc_feed_acc;
    reg        tanh_ev_pend;
    reg [4:0]  tanh_ev_idx;
    wire [4:0] rq_operand_ch = compute_stream ? oc_feed_idx : proc_ch;
    wire signed [7:0]  rq_res_byte = res_pix_r[8*rq_operand_ch +: 8];
    wire signed [8:0]  rq_res_ctr  = rq_res_byte - res_zp;
    wire signed [63:0] rq_res_q32  = rq_res_ctr * res_scale_q32;

    wire signed [7:0] rq_out;
    /* Register the proc_ch-selected inputs before the 32x64 multiply.  This
     * splits the 24:1 acc/scale/bias/residual muxes from the long carry chain
     * without changing any arithmetic.  All four operands advance together. */
    reg signed [31:0] rq_acc_r;
    reg signed [63:0] rq_scale_r, rq_bias_r, rq_res_q32_r;

    requant_pipe_core u_rq (
        .clk(clk), .rst_n(rst_n),
        .relu_en(~res_do),
        .acc(rq_acc_r),
        .norm_scale_q32(rq_scale_r),
        .norm_bias_q32(rq_bias_r),
        .residual_q32(rq_res_q32_r),
        .q_scale_recip_q48(q_scale_recip_q48),
        .q_zero_point(q_zero_point),
        .q_out(rq_out)
    );

    /* One input register plus the four internal requant stages: the channel
     * index offered five cycles ago is the one whose result is on rq_out now. */
    reg [4:0] rq_pch_d1, rq_pch_d2, rq_pch_d3, rq_pch_d4, rq_pch_d5;
    reg       rq_pv_d1,  rq_pv_d2,  rq_pv_d3,  rq_pv_d4,  rq_pv_d5;
    wire      rq_feed = ((state == ST_COMPUTE) && !tanh_do &&
                         (compute_stream ? oc_feed_pend : proc_active)) ||
                        (raw_context && !raw_preload);

    assign dbg_state = state;

always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rq_acc_r <= 32'sd0; rq_scale_r <= 64'sd0;
            rq_bias_r <= 64'sd0; rq_res_q32_r <= 64'sd0;
            rq_pch_d1 <= 5'd0; rq_pch_d2 <= 5'd0; rq_pch_d3 <= 5'd0;
            rq_pch_d4 <= 5'd0; rq_pch_d5 <= 5'd0;
            rq_pv_d1  <= 1'b0; rq_pv_d2  <= 1'b0; rq_pv_d3  <= 1'b0;
            rq_pv_d4  <= 1'b0; rq_pv_d5  <= 1'b0;
        end else begin
            rq_acc_r     <= raw_consume ? raw_pixel_r[32*proc_ch +: 32]
                                        : (compute_stream ? oc_feed_acc
                                                          : acc_flat[32*proc_ch +: 32]);
            rq_scale_r   <= nrm_scale_r;
            rq_bias_r    <= nrm_bias_r;
            rq_res_q32_r <= (raw_consume || compute_stream) ? 64'sd0 : rq_res_q32;
            rq_pch_d1 <= rq_operand_ch; rq_pv_d1 <= rq_feed;
            rq_pch_d2 <= rq_pch_d1;   rq_pv_d2 <= rq_pv_d1;
            rq_pch_d3 <= rq_pch_d2;   rq_pv_d3 <= rq_pv_d2;
            rq_pch_d4 <= rq_pch_d3;   rq_pv_d4 <= rq_pv_d3;
            rq_pch_d5 <= rq_pch_d4;   rq_pv_d5 <= rq_pv_d4;
        end
    end

    /* Accept of an output pixel in the compute pass: the residual branch needs
     * that pixel present before the channel walk starts, so res_ready is the
     * same condition.  With res_do = 0 the term short-circuits and the relu path
     * keeps its old timing exactly. */
    assign res_ready = (state == ST_COMPUTE) && !proc_active && !rq_busy
                       && !out_valid_r && !acc_ready_r && stage_valid
                       && (res_valid || !res_do);

    /* ---- tanh output head (op = 4) ----------------------------------------
     * The table is 4098 live Q8.16 entries; only 0..4096 are reachable (lut_addr
     * is at most 4096 and lut_frac is zero whenever it is), and 4096 is only
     * ever read as the *upper* interpolation endpoint, so it lives in a
     * neighbour register instead of a 9th RAM10-deep block.
     *
     * One output channel takes four cycles, which keeps the 32x64 affine
     * multiply (tanh_y_core) and the 25x17 interpolate multiply
     * (tanh_interp_core) in separate cycles:
     *
     *   P0  p_raddr selects the channel; the loader's registered read settles
     *   P1  tanh_y_core -> th_a_reg / th_fx_r, table address A
     *   P2  th_lut_q (== table[A])  -> th_lut0_r
     *   P3  th_lut_q (== table[A+1]) + th_lut0_r + th_fx_r -> th_q, emit
     */
    wire [23:0] th_lut_q;
    reg  [2:0]  th_phase;
    reg  [12:0] th_a_reg;
    reg  [15:0] th_fx_r;
    reg  [23:0] th_lut0_r;
    wire [12:0] th_lut_addr;
    wire [15:0] th_y_frac;
    wire signed [7:0] th_q;

    /* the y stage output is valid in P2 (prod_r / bias_r landed at the end of
     * P1), so that is where the read of A comes from; A+1 reads in P3 / P4 */
    wire [12:0] th_rd_addr = (th_phase == 3'd2) ? th_lut_addr
                                                : (th_a_reg + 13'd1);

    /* Block-RAM store.  It is the plain single-read template of
     * style_weight_bram ON PURPOSE: Efinity maps a memory into LOGIC instead of
     * RAM10 the moment the read port is not a bare registered read
     * ("MEM|SYN-0657 ... because read port is not synchronous"), and a 4096x24
     * array in fabric is ~100k logic blocks -- the first Phase D PnR blew up to
     * 4x the device on exactly that (HANDOFF_ACCEL 9.42).  So this module holds
     * nothing but the array; entry 4096 -- never an interpolation BASE (its
     * fraction is necessarily zero), only the upper endpoint of the last cell --
     * lives in the flop below, and its select is registered so it still travels
     * with the address it was computed for. */
    reg  [23:0] th_hi;
    reg         th_hi_sel;

    /* the ONLY block that drives th_hi / th_hi_sel: a second driver anywhere
     * (even just the reset in the pass sequencer) is a VDB-1000 "constantly
     * driven from multiple places" that only Efinity reports (HANDOFF 9.42). */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            th_hi     <= 24'd0;
            th_hi_sel <= 1'b0;
        end else begin
            if (lut_we && (lut_waddr == 13'd4096))
                th_hi <= lut_wdata;
            th_hi_sel <= (th_rd_addr == 13'd4096);
        end
    end

    wire [23:0] th_lut_mem_q;

    tanh_lut_store u_lut (
        .clk(clk),
        .we(lut_we && (lut_waddr != 13'd4096)),
        .waddr(lut_waddr[11:0]), .wdata(lut_wdata),
        .raddr(th_rd_addr[11:0]), .rdata(th_lut_mem_q)
    );

    assign th_lut_q = th_hi_sel ? th_hi : th_lut_mem_q;

    tanh_y_pipe_core u_ty (
        .clk(clk),
        .acc(acc_flat[32*proc_ch +: 32]),
        .scale_q32(p_s2), .bias_q32(p_sg),
        .lut_addr(th_lut_addr), .lut_frac(th_y_frac)
    );

    tanh_interp_core u_ti (
        .lut_val(th_lut0_r), .lut_next(th_lut_q), .lut_frac(th_fx_r),
        .q_out(th_q)
    );

    /* ---- pass sequencer ---- */
    integer n;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            np_start <= 1'b0;
            ch <= 0;
            clear_cnt <= 4'd0;
            next_is_stats <= 1'b0;
            stage_rst <= 1'b0;
            nrm_settle <= 1'b0;
            proc_active <= 1'b0;
            proc_ch <= 5'd0;
            acc_ready_r <= 1'b0;
            out_valid_r <= 1'b0;
            rq_busy <= 1'b0;
            st_ev_idx <= 5'd0;
            st_ev_acc <= 32'sd0;
            st_ev_pend <= 1'b0;
            st_last_seen <= 1'b0;
            oc_feed_pend <= 1'b0;
            oc_feed_idx <= 5'd0;
            oc_feed_acc <= 32'sd0;
            tanh_ev_pend <= 1'b0;
            tanh_ev_idx <= 5'd0;
            stage_done_seen <= 1'b0;
            raw_active <= 1'b0;
            raw_preload <= 1'b0;
            raw_busy <= 1'b0;
            raw_finish_pending <= 1'b0;
            raw_pixel_r <= 256'd0;
            raw_pix_count <= 32'd0;
            raw_total_r <= 32'd0;
            out_pixel <= 256'd0;
            np_sum <= 64'sd0;
            np_sumsq <= 64'sd0;
            th_phase <= 3'd0;
            th_a_reg <= 13'd0;
            th_fx_r  <= 16'd0;
            th_lut0_r <= 24'd0;
            st_sc <= 6'd0;
            for (n = 0; n < MAX_OC; n = n + 1)
                count_r[n] <= 32'd0;
        end else begin
            np_start <= 1'b0;
            acc_ready_r <= 1'b0;
            nrm_we <= 1'b0;   /* one-cycle write pulse into the norm RAM */
            if (stage_done)
                stage_done_seen <= 1'b1;
            if (acc_ready_r && !stage_valid)
                acc_ready_r <= 1'b0;

            case (state)
            ST_IDLE: begin
                if (start) begin
                    done <= 1'b0;
                    busy <= 1'b1;
                    next_is_stats <= is_stats;
                    clear_cnt <= 4'd0;
                    nrm_settle <= 1'b0;
                    ch <= 0;
                    proc_active <= 1'b0;
                    out_valid_r <= 1'b0;
                    st_ev_pend <= 1'b0;
                    st_last_seen <= 1'b0;
                    oc_feed_pend <= 1'b0;
                    tanh_ev_pend <= 1'b0;
                    stage_done_seen <= 1'b0;
                    raw_active <= 1'b0;
                    raw_preload <= 1'b0;
                    raw_busy <= 1'b0;
                    raw_finish_pending <= 1'b0;
                    raw_pix_count <= 32'd0;
                    raw_total_r <= {16'd0, shp_in_w} * {16'd0, shp_in_h};
                    if (is_stats)
                        for (n = 0; n < MAX_OC; n = n + 1)
                            count_r[n] <= 32'd0;   /* the sums are zeroed in ST_SCLR */
                    state <= ST_CLEAR;
                end
            end

            ST_CLEAR: begin
                clear_cnt <= clear_cnt + 4'd1;
                if (clear_cnt == 4'd7) begin
                    if (next_is_stats) begin
                        state <= ST_SCLR;
                    end else if (raw_consume) begin
                        proc_ch <= 5'd0;
                        raw_active <= 1'b0;
                        raw_preload <= 1'b0;
                        state <= ST_RAW;
                    end else begin
                        state <= ST_COMPUTE;
                    end
                end
            end

            /* Zero the statistics RAM.  A flop array was reset in parallel; a
             * RAM has to be written, so the stats pass pays 32 cycles once
             * (the stage sits in its segment reset for this whole state, so no
             * producer can see it). */
            ST_SCLR: begin
                if (st_sc == (MAX_OC - 1)) begin
                    st_sc <= 6'd0;            /* st_raddr := 0 for the entry */
                    state <= ST_STATS;
                end else begin
                    st_sc <= st_sc + 6'd1;
                end
            end

            ST_STATS: begin
                /* Latch this pixel's next completed channel.  If the previous
                 * event is already pending, its RAM write happens in this same
                 * cycle while the new event takes its place. */
                if (oc_ev_valid) begin
                    st_ev_pend <= 1'b1;
                    st_ev_idx  <= oc_ev_idx;
                    st_ev_acc  <= oc_ev_acc;
                    if (raw_produce) begin
                        out_pixel[32*oc_ev_idx +: 32] <= oc_ev_acc;
                        if (oc_ev_idx == (shp_oc - 6'd1))
                            out_valid_r <= 1'b1;
                    end
                    if (oc_ev_idx == (shp_oc - 6'd1))
                        st_last_seen <= 1'b1;
                end else begin
                    st_ev_pend <= 1'b0;
                end

                /* The pending channel's registered read data is valid now. */
                if (st_ev_pend)
                    count_r[st_ev_idx] <= count_r[st_ev_idx] + 32'd1;

                /* All OC events for this pixel have arrived and the stage is
                 * holding the completed pixel in ST_EMIT.  The final RAM write
                 * above is on the same edge, so it is safe to release the stage
                 * now: the next pixel's first event is many cycles away. */
                if (raw_produce) begin
                    /* The raw pixel is complete when the writer accepts it.
                     * Only then may the stage advance to the next pixel. */
                    if (out_valid_r && out_ready) begin
                        out_valid_r <= 1'b0;
                        acc_ready_r <= 1'b1;
                        st_last_seen <= 1'b0;
                    end
                end else if (stage_valid && st_last_seen) begin
                    acc_ready_r <= 1'b1;
                    st_last_seen <= 1'b0;
                end

                if (stage_done_seen && !st_ev_pend && !out_valid_r) begin
                    stage_done_seen <= 1'b0;
                    ch         <= 0;
                    nrm_settle <= 1'b1;   /* u_stats' read of channel 0 settles */
                    state      <= ST_NORM;
                end
            end

            ST_NORM: begin
                if (nrm_settle) begin
                    /* the loader's registered read for the new ch, and u_stats'
                     * read of the same channel, are both valid now */
                    nrm_settle <= 1'b0;
                    np_sum     <= st_rsum;
                    np_sumsq   <= st_rsumsq;
                    np_start   <= 1'b1;
                end else if (np_done) begin
                    nrm_we      <= 1'b1;
                    nrm_waddr   <= ch[4:0];
                    nrm_wdata_s <= np_scale;
                    nrm_wdata_b <= np_bias;
                    if (ch == (shp_oc - 6'd1)) begin
                        clear_cnt <= 4'd0;
                        state <= ST_RESET;
                    end else begin
                        ch <= ch + 1;
                        nrm_settle <= 1'b1;   /* sums and params settle */
                    end
                end
            end

            ST_RAW: begin
                /* One 256-bit input beat is one complete raw-int32 pixel.
                 * Preload channel-0 norm data first, then stream one requant
                 * channel per cycle. */
                if (!raw_active && raw_input_open) begin
                    if (in_valid && in_ready) begin
                        raw_pixel_r   <= in_pixel;
                        raw_active    <= 1'b1;
                        raw_preload   <= 1'b1;
                        raw_busy      <= 1'b1;
                        proc_ch       <= 5'd0;
                        raw_pix_count <= raw_pix_count + 32'd1;
                    end
                end else if (raw_active) begin
                    if (raw_preload) begin
                        raw_preload <= 1'b0;
                    end else if (proc_ch == (shp_oc - 6'd1)) begin
                        raw_active <= 1'b0;
                    end else begin
                        proc_ch <= proc_ch + 5'd1;
                    end
                end

                if (rq_pv_d5)
                    out_pixel[8*rq_pch_d5 +: 8] <= rq_out;

                if (rq_pv_d5 && (rq_pch_d5 == (shp_oc - 6'd1)))
                    out_valid_r <= 1'b1;

                if (out_valid_r && out_ready) begin
                    out_valid_r <= 1'b0;
                    raw_busy <= 1'b0;
                    if (raw_pix_count == raw_total_r)
                        raw_finish_pending <= 1'b1;
                end

                if (raw_finish_pending) begin
                    clear_cnt <= 4'd0;
                    state <= ST_RESET;
                end
            end

            ST_COMPUTE: begin
                if (compute_stream) begin
                    /* Non-residual relu passes stream OC results directly into
                     * requant.  The event selects the norm parameter one cycle
                     * before oc_feed_pend offers acc + the matching scale/bias. */
                    if (oc_ev_valid) begin
                        oc_feed_pend <= 1'b1;
                        oc_feed_idx  <= oc_ev_idx;
                        oc_feed_acc  <= oc_ev_acc;
                    end else begin
                        oc_feed_pend <= 1'b0;
                    end
                end else if (tanh_do) begin
                    /* The tanh head is also OC-streamed.  Its five phases fit
                     * inside the interval between consecutive OC completions,
                     * so channel N is interpolated while the engine computes
                     * channel N+1.  One event buffer covers clock-domain slack. */
                    if (oc_ev_valid) begin
                        if (!proc_active && !tanh_ev_pend) begin
                            proc_active <= 1'b1;
                            proc_ch     <= oc_ev_idx;
                            th_phase    <= 3'd0;
                        end else begin
                            tanh_ev_pend <= 1'b1;
                            tanh_ev_idx  <= oc_ev_idx;
                        end
                    end else if (!proc_active && tanh_ev_pend) begin
                        proc_active  <= 1'b1;
                        proc_ch      <= tanh_ev_idx;
                        th_phase     <= 3'd0;
                        tanh_ev_pend <= 1'b0;
                    end else if (proc_active) begin
                        /* four phases after launch, see the head note */
                        case (th_phase)
                        3'd0: th_phase <= 3'd1;   /* p_raddr settles; multiply issued  */
                        3'd1: th_phase <= 3'd2;   /* prod_r / bias_r now hold         */
                        3'd2: begin               /* y / clip / extract valid, addr=A  */
                            th_a_reg <= th_lut_addr;
                            th_fx_r  <= th_y_frac;
                            th_phase <= 3'd3;
                        end
                        3'd3: begin               /* dout = table[A] -> lut0          */
                            th_lut0_r <= th_lut_q;
                            th_phase  <= 3'd4;
                        end
                        default: begin            /* dout = table[A+1] -> emit        */
                            out_pixel[8*proc_ch +: 8] <= th_q;
                            th_phase <= 3'd0;
                            if (proc_ch == (shp_oc - 6'd1)) begin
                                proc_active <= 1'b0;
                                out_valid_r <= 1'b1;
                            end else begin
                                proc_active <= 1'b0;
                            end
                        end
                        endcase
                    end
                end else if (!proc_active && !rq_busy && !out_valid_r && !acc_ready_r) begin
                    /* Residual passes keep the original whole-pixel walk: the
                     * residual pixel is accepted together with the completed
                     * conv pixel, then indexed as channels drain. */
                    if (stage_valid && (res_valid || !res_do)) begin
                        proc_active <= 1'b1;
                        rq_busy     <= 1'b1;
                        proc_ch     <= 5'd0;
                        res_pix_r   <= res_pixel;
                    end
                end else if (proc_active) begin
                    if (proc_ch == (shp_oc - 6'd1))
                        proc_active <= 1'b0;      /* last channel offered; drain */
                    else
                        proc_ch <= proc_ch + 5'd1;
                end

                /* Collect requant results as they leave the five-stage pipe. */
                if (rq_pv_d5)
                    out_pixel[8*rq_pch_d5 +: 8] <= rq_out;

                if (rq_pv_d5 && (rq_pch_d5 == (shp_oc - 6'd1)))
                    out_valid_r <= 1'b1;

                if (out_valid_r && out_ready) begin
                    out_valid_r <= 1'b0;
                    acc_ready_r <= 1'b1;
                    rq_busy     <= 1'b0;
                end
                if (stage_done_seen && !proc_active && !out_valid_r && !acc_ready_r) begin
                    stage_done_seen <= 1'b0;
                    clear_cnt <= 4'd0;
                    state <= ST_RESET;
                end
            end

            ST_RESET: begin
                stage_rst <= 1'b1;
                clear_cnt <= clear_cnt + 4'd1;
                if (clear_cnt == 4'd7) begin
                    stage_rst <= 1'b0;
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end
            end

            default: state <= ST_IDLE;
            endcase
        end
    end

endmodule


module tanh_y_core (
    input  wire signed [31:0] acc,
    input  wire signed [63:0] scale_q32,
    input  wire signed [63:0] bias_q32,
    output wire        [12:0] lut_addr,
    output wire        [15:0] lut_frac
);

    wire signed [95:0] prod = $signed(acc) * $signed(scale_q32);
    wire signed [96:0] prod_ext = {prod[95], prod};
    wire signed [96:0] bias_ext = {{33{bias_q32[63]}}, bias_q32};
    wire signed [96:0] y_full = prod_ext + bias_ext;

    wire signed [96:0] y_lo = -97'sd34359738368; // -8 * 2^32
    wire signed [96:0] y_hi =  97'sd34359738368; // +8 * 2^32
    wire signed [96:0] y_clip = (y_full < y_lo) ? y_lo :
                                (y_full > y_hi) ? y_hi : y_full;
    wire signed [96:0] y_off = y_clip + 97'sd34359738368;

    /* y_off is in [0, 2^36], so lut_addr is at most 4096 and lut_frac is zero
     * whenever it is: the head only ever needs table entries 0..4096, and entry
     * 4096 only as an interpolate neighbour (see style_net_core's LUT store). */
    assign lut_addr = y_off[36:24];
    assign lut_frac = y_off[23:8];

endmodule

/* Same arithmetic as tanh_y_core, but the 32x64 product and the bias are
 * registered first, so style_net_core gets two short paths instead of one
 * 11.7 ns / 69-level one: the first Phase D route put the whole
 * multiply -> +bias -> clip -> +2^35 -> extract chain between proc_ch and the
 * LUT RAM's address input (slack -0.796 ns).  Bit-identical to tanh_y_core when
 * its inputs are held, which is what the core's phase walk does (HANDOFF 9.44).
 *
 *   P1: prod_r <= acc*scale_q32, bias_r <= bias_q32
 *   P2: prod_r/bias_r -> y_full -> clip -> y_off -> lut_addr / lut_frac
 */
module tanh_y_pipe_core (
    input  wire                clk,
    input  wire signed [31:0]  acc,
    input  wire signed [63:0]  scale_q32,
    input  wire signed [63:0]  bias_q32,
    output wire        [12:0]  lut_addr,
    output wire        [15:0]  lut_frac
);

    reg signed [95:0] prod_r;
    reg signed [63:0] bias_r;

    always @(posedge clk) begin
        prod_r <= $signed(acc) * $signed(scale_q32);
        bias_r <= bias_q32;
    end

    wire signed [96:0] prod_ext = {prod_r[95], prod_r};
    wire signed [96:0] bias_ext = {{33{bias_r[63]}}, bias_r};
    wire signed [96:0] y_full   = prod_ext + bias_ext;

    wire signed [96:0] y_lo = -97'sd34359738368; // -8 * 2^32
    wire signed [96:0] y_hi =  97'sd34359738368; // +8 * 2^32
    wire signed [96:0] y_clip = (y_full < y_lo) ? y_lo :
                                (y_full > y_hi) ? y_hi : y_full;
    wire signed [96:0] y_off = y_clip + 97'sd34359738368;

    assign lut_addr = y_off[36:24];
    assign lut_frac = y_off[23:8];

endmodule

module tanh_interp_core (
    input  wire        [23:0] lut_val,
    input  wire        [23:0] lut_next,
    input  wire        [15:0] lut_frac,
    output reg  signed [7:0]  q_out
);

    wire signed [24:0] lut0 = {1'b0, lut_val};
    wire signed [24:0] lut1 = {1'b0, lut_next};
    wire signed [24:0] lut_diff = lut1 - lut0;
    wire signed [40:0] lut_delta = lut_diff * $signed({1'b0, lut_frac});
    wire signed [24:0] z_q16 = lut0 + (lut_delta >>> 16);
    wire signed [24:0] z_round = z_q16 + 25'sd32768;
    wire signed [24:0] q_raw = z_round >>> 16;
    wire signed [25:0] q_int = q_raw - 26'sd128;

    always @* begin
        if (q_int < -26'sd128)
            q_out = -8'sd128;
        else if (q_int > 26'sd127)
            q_out = 8'sd127;
        else
            q_out = q_int[7:0];
    end

endmodule

/* ==========================================================================
 * tanh_lut_store -- the op=4 output head's Q8.16 table (HANDOFF_ACCEL 9.41).
 *
 * 4096 x 24 bits = 8 x 2 RAM10 blocks, plus ONE 24-bit neighbour register for
 * entry 4096.  lut_addr reaches 4096 (y_off <= 2^36) but its interpolation
 * fraction is necessarily zero exactly there, so a 4096-deep store is enough
 * as long as entry 4096 is available as the upper endpoint of the last cell;
 * a 4098-deep array would be an odd depth and Efinity would round it up to
 * 8192 (16 x 2 = 32 RAM10 instead of 16).
 *
 * Lives here, not in its own file, for the reason spelled out below.
 * ========================================================================== */
module tanh_lut_store (
    input  wire        clk,
    input  wire        we,
    input  wire [11:0] waddr,
    input  wire [23:0] wdata,
    input  wire [11:0] raddr,
    output reg  [23:0] rdata
);

    /* Keep this the plain write + registered read pair: any qualification of the
     * read data (a mux, a comparison) makes Efinity fall back to logic memory
     * and cost ~100k logic blocks (HANDOFF_ACCEL 9.42). */
    (* ram_style = "block", syn_ram_style = "block" *) reg [23:0] mem [0:4095];

    always @(posedge clk)
        if (we)
            mem[waddr] <= wdata;

    always @(posedge clk)
        rdata <= mem[raddr];

endmodule


/* Per-output-channel statistics storage (the InstanceNorm sum and sum-of-
 * squares accumulators).
 *
 * These used to be two 32 x 64-bit register arrays = 4096 flops.  Neither array
 * is ever read in parallel: the accumulate walk (ST_STATS) and the norm walk
 * (ST_NORM) both touch ONE channel per cycle, so a block RAM's single
 * registered read port serves both, at 4 RAM10 blocks for the pair.
 *
 * Keep this exactly the write-port + bare registered read pair: qualifying the
 * read data (a mux, a compare, an address slice) makes Efinity fall back to
 * logic memory and cost tens of thousands of logic blocks (HANDOFF_ACCEL 6.39,
 * 9.42).  stats_channel_store must not appear in the synthesis report's
 * MEM|SYN-0657 list.
 */
module stats_channel_store #(
    parameter integer MAX_CH = 32
) (
    input  wire                       clk,
    input  wire                       we,
    input  wire [$clog2(MAX_CH)-1:0]  waddr,
    input  wire signed [63:0]         wdata_sum,
    input  wire signed [63:0]         wdata_sumsq,
    input  wire [$clog2(MAX_CH)-1:0]  raddr,
    output reg  signed [63:0]         rdata_sum,
    output reg  signed [63:0]         rdata_sumsq
);

    (* ram_style = "block", syn_ram_style = "block" *)
    reg signed [63:0] mem_sum   [0:MAX_CH-1];
    (* ram_style = "block", syn_ram_style = "block" *)
    reg signed [63:0] mem_sumsq [0:MAX_CH-1];

    always @(posedge clk) begin
        if (we) begin
            mem_sum  [waddr] <= wdata_sum;
            mem_sumsq[waddr] <= wdata_sumsq;
        end
    end

    always @(posedge clk) begin
        rdata_sum   <= mem_sum  [raddr];
        rdata_sumsq <= mem_sumsq[raddr];
    end

endmodule


/* The shared-bank 3x3 stage used above lives in THIS file on purpose:
 * the regression flows find modules either by explicit file list or by
 * `vlog -y rtl` (which looks for <module>.v), and Efinity drops hand-added
 * design_file entries from soc/soc.xml (HANDOFF_ACCEL 6.20).  Keeping it in
 * a file that every flow already lists avoids all three problems; the same
 * reason requant_relu_pipe_core lives inside requant_relu_core.v.
 */


/* ==========================================================================
 * conv3x3_stage_wide -- shared-bank 3x3 conv AND nearest-x2 upsample stage
 * with a RUNTIME shape (HANDOFF_ACCEL 9.22 five, 9.24, 9.25).
 *
 * Port contract: conv3x3_stage_lanes plus six runtime shape inputs, so ONE
 * bitstream serves the whole 19-pass envelope (IC/OC 3..32, in 160x120 ..
 * 640x480, stride {1,2}, upsample {1,2}).
 *
 *  1. The banks hold the OUTPUT-resolution image.  UPSAMPLE=1 writes one bank
 *     cell per input word; UPSAMPLE=2 replicates each input word into a 2x2
 *     block (2 rows x 2 columns), so the read side stays the same reflect-pad
 *     address clamp, only over (up*in_w) x (up*in_h) coordinates.  One bank
 *     word is all MAX_IC channels of one pixel, so the IC per-channel
 *     pad + line-buffer + window-FIFO chains the old stage built are gone.
 *
 *  2. Reflect padding is read-address clamping, no pad RAM.  With
 *     ry = oy*stride, the window rows/cols are
 *         rA = (ry == 0)      ? 1            : ry - 1
 *         rC = (ry >= Hup-1)  ? Hup - 2      : ry + 1
 *     and px = ox*stride + j (j = 0,1,2) the same on the columns -- exactly
 *     what the layer testbenches compute for their reference.
 *
 *  3. FOUR row banks, fixed.  At UPSAMPLE=2 the writer commits a 2-row group
 *     atomically, so a 3-bank ring would let the group clobber row ry-1 that
 *     the reader still needs: three banks either corrupt the window or (with
 *     the safe bound) deadlock on odd rows.  With four banks the group
 *     clobbers rows wr_row-4 .. wr_row+UPSAMPLE-3, all strictly below ry-1,
 *     and "wr_row <= ry+1" is SAFE and LIVE.  Bank arithmetic is mod 4, i.e.
 *     plain 2-bit wrap.
 *
 *  4. Window assembly: a bank word now holds 16 channels (128 bits).  Layers
 *     with IC <= 16 read one word per tap; a 32-channel layer stores its second
 *     half at column + H_OFF and reads it in the next cycle (9 -> 18 window
 *     cycles).  Both halves scatter into the same x_flat[8*(ic*9 + tap)]
 *     layout, so the weight blob, the ABI, w_reg and every weight model stay
 *     untouched.  The widest 32-channel layer is pass 7's 160x120 -> 320x240
 *     upsample, so the second half starts at H_OFF=320.
 *
 *  5. The weight fetch walks ceil(IC*9/32) 32-byte words per oc (runtime) and
 *     the engine gets the runtime term count IC*9, so a wide MAX_IC does not
 *     cost fetch cycles for narrow layers.
 * ========================================================================== */
module conv3x3_stage_wide #(
    parameter integer MAX_UW = 640,   /* bank columns = max upsampled width  */
    parameter integer MAX_IC = 32,    /* channels storable per bank word    */
    parameter integer MAX_OC = 32,
    parameter integer LANES  = 16
) (
    input  wire                          clk,
    input  wire                          rst_n,
    /* runtime shape (from cfg; must be stable before and during a pass) */
    input  wire [15:0]                   shp_in_w,
    input  wire [15:0]                   shp_in_h,
    input  wire [1:0]                    shp_up,      /* 1 or 2 */
    input  wire [1:0]                    shp_stride,  /* 1 or 2 */
    input  wire [5:0]                    shp_ic,      /* 3..32 */
    input  wire [5:0]                    shp_oc,      /* 3..32 */
    input  wire                          in_valid,
    input  wire [8*MAX_IC-1:0]           in_pixel,
    output wire                          in_ready,
    output wire [$clog2(MAX_OC)+3:0]     w_addr,     /* {oc, 32-byte word slot} */
    input  wire [255:0]                  w_rdata,
    input  wire signed [8:0]             zp_in,
    output reg  [32*MAX_OC-1:0]          acc_flat,
    /* One event per completed output channel.  style_net_core consumes these
     * while the engine is still working on the following channels, removing the
     * old full-OC scan after every pixel. */
    output reg  [$clog2(MAX_OC)-1:0]     oc_ev_idx,
    output reg  signed [31:0]            oc_ev_acc,
    output reg                           oc_ev_valid,
    output wire                          out_valid,
    input  wire                          out_ready,
    output reg                           done
);

    localparam integer ICW  = (MAX_IC > 16) ? 16 : MAX_IC; /* channels/word */
    localparam integer WW   = 8*ICW;
    /* Envelope: the widest 32-channel layer is the x2 upsample (160 input ->
     * 320 output columns); wider layers have IC <= 16.  Put the second half at
     * H_OFF=320, so the bank array always needs 640 columns.  With the
     * 512 main + 128 tail split that is 4*7 + 7 = 35 RAM10, vs 52 before. */
    localparam integer W32_MAX   = 320;
    localparam integer BANK_COLS = (MAX_UW > (2*W32_MAX)) ? MAX_UW : (2*W32_MAX);
    localparam integer H_OFF     = W32_MAX;
    localparam [15:0]  H_OFF16   = H_OFF;
    /* HANDOFF_ACCEL 9.35 -- RAM10 geometry: an EFX_RAM10 is 512 deep x 20 wide,
     * so a 320-column 128-bit row costs ceil(320/512)*ceil(128/20)=7 blocks per
     * bank; four banks therefore need 28 instead of 52.  For BANK_COLS > 512
     * keep the 512 main + tail split (4*7 + 7 = 35 at 640).  The row-reuse
     * distance stays 4, so "wr_row <= ry+1" is unchanged. */
    localparam integer MAIN = (BANK_COLS > 512) ? 512 : BANK_COLS;
    localparam integer TAIL = BANK_COLS - MAIN;
    localparam integer TBUF = (TAIL < 1) ? 1 : 4*TAIL;
    localparam integer WSTRIDE_MAX = (MAX_IC * 9 + 31) / 32;
    localparam integer OCW  = (MAX_OC <= 1) ? 1 : $clog2(MAX_OC);

    /* ---- runtime geometry ---- */
    wire [15:0] uw    = shp_in_w * shp_up;                       /* up * in_w */
    wire [15:0] uh    = shp_in_h * shp_up;                       /* up * in_h */
    wire [15:0] out_w = (shp_stride == 2'd2) ? ((uw + 16'd1) >> 1) : uw;
    wire [15:0] out_h = (shp_stride == 2'd2) ? ((uh + 16'd1) >> 1) : uh;
    wire [31:0] out_total = out_w * out_h;
    /* Registered copy of the frame size: the 16x16 product is stable for the
     * whole pass, so pay it once instead of leaving it on the emit compare. */
    reg  [31:0] out_total_r;
    wire [9:0]  terms_r  = {4'b0, shp_ic} * 10'd9;               /* IC*9      */
    wire [4:0]  wstrd_r  = (({4'b0, shp_ic} * 10'd9) + 10'd31) >> 5;
    wire [2:0]  gu       = {1'b0, shp_up} * {1'b0, shp_up};      /* cells/word */

    localparam integer ST_PIX   = 3'd0;   /* build the window (9 bank reads) */
    localparam integer ST_WLOAD = 3'd1;   /* initial oc0 weight fetch only   */
    localparam integer ST_START = 3'd2;
    localparam integer ST_WAIT  = 3'd3;   /* engine runs; next oc prefetches */
    localparam integer ST_EMIT  = 3'd4;   /* hand the window to the consumer */

    reg  [2:0]  state;
    reg  [1:0]  wi, wj;             /* window row / column index          */
    reg  [1:0]  bsel;               /* bank of the word read last cycle   */
    reg  [1:0]  wi_q, wj_q;         /* ... and its window indices         */
    reg         rh, rh_q;           /* current / latched channel half     */
    reg         vld_q;              /* a window word has just landed      */
    reg  [3:0]  w_j;
    reg  [OCW-1:0] oc_idx;
    reg  [31:0] out_count;
    reg  [15:0] rd_ox, rd_oy;
    reg  [1:0]  bmid;               /* bank of bank row rd_oy*stride      */

    reg  [8*MAX_IC*9-1:0]      x_flat;
    /* In-place streamed weight prefetch.  With LANES=32 the engine consumes
     * exactly one 256-bit weight word per cycle, so word j can be overwritten
     * with the next OC's word j in the same cycle the engine uses the old one.
     * This hides ST_WLOAD without a second 2304-bit register bank. */
    reg  [256*WSTRIDE_MAX-1:0] w_reg;
    reg  [3:0]                 pf_j;
    reg                        pf_active, pf_done;
    reg                        eng_done_seen;
    reg signed [31:0]          eng_acc_r;
    reg                        w_valid0;

    integer ic;
    genvar  gi;

    /* ---------------- input side ---------------- */
    /* in_pixel arrives 8*MAX_IC wide; mask off the bytes above IC so the
     * banks hold clean data (the engine ignores them by the terms mask). */
    wire [8*MAX_IC-1:0] ic_mask_full;
    wire                two_halves = (shp_ic > 6'd16);

    reg  [15:0]   wr_row;    /* base bank row of the group = up * input row */
    reg  [15:0]   wr_col;    /* base bank col = up * input col              */
    reg  [3:0]    wr_step;   /* 0 .. gu*nhalves-1 inside the current group  */
    reg  [1:0]    wr_bank;   /* bank of the group's first row (mod 4)       */
    reg  [8*MAX_IC-1:0] wr_data_r;

    wire          wr_accept = in_valid && in_ready;
    wire          wr_go     = wr_accept || (wr_step != 4'd0);
    wire [8*MAX_IC-1:0] wr_data_full = in_pixel & ic_mask_full;
    wire [8*MAX_IC-1:0] wr_pix_cur   = (wr_step == 4'd0) ? wr_data_full : wr_data_r;
    wire [3:0]    wr_steps  = {1'b0, gu} * (two_halves ? 4'd2 : 4'd1);
    wire          wr_half   = two_halves && (wr_step >= {1'b0, gu});
    wire [3:0]    wr_cell_step = wr_half ? (wr_step - {1'b0, gu}) : wr_step;

    wire [WW-1:0] wr_data_lo = wr_pix_cur[WW-1:0];
    wire [WW-1:0] wr_data_hi;
    wire [WW-1:0] wr_data_sel = wr_half ? wr_data_hi : wr_data_lo;

    generate
        if (MAX_IC > 16) begin : g_wr_hi
            assign wr_data_hi = {{(WW - 8*(MAX_IC-16)){1'b0}},
                                 wr_pix_cur[8*MAX_IC-1:WW]};
        end else begin : g_wr_no_hi
            assign wr_data_hi = {WW{1'b0}};
        end
    endgenerate

    /* wr_cell_step/up selects the row copy, wr_cell_step%up the column copy */
    wire [1:0]    wr_row_off  = (shp_up == 2'd2) ? {1'b0, wr_cell_step[1]} : 2'd0;
    wire [1:0]    wr_col_off  = (shp_up == 2'd2) ? {1'b0, wr_cell_step[0]} : 2'd0;
    wire [15:0]   wr_cell_col = wr_col + {14'd0, wr_col_off};
    wire [15:0]   wr_cell_col_h = wr_cell_col + (wr_half ? H_OFF16 : 16'd0);
    wire [1:0]    wr_cell_bank = wr_bank + wr_row_off;   /* mod 4 */
    wire          wr_in_tail  = (wr_cell_col_h >= MAIN);
    wire [15:0]   wr_tail_a   = (wr_cell_bank * TAIL) + (wr_cell_col_h - MAIN);
    wire          wr_last_col = ((wr_col + {14'd0, shp_up}) >= uw);

    wire [15:0] ry        = rd_oy * shp_stride;
    wire [15:0] need_hi   = (ry >= (uh - 16'd1)) ? (uh - 16'd2) : (ry + 16'd1);
    wire        rows_ready = (wr_row > need_hi);

    /* Four banks are reused every 4 rows, so the writer must never pass the
     * last row the reader's window still needs (see the header note), and it
     * must stop at the bottom of the frame. */
    assign      in_ready = (wr_step == 4'd0) && (wr_row <= (ry + 16'd1)) &&
                           (wr_row < uh);

    reg [WW-1:0] bk0 [0:MAIN-1];
    reg [WW-1:0] bk1 [0:MAIN-1];
    reg [WW-1:0] bk2 [0:MAIN-1];
    reg [WW-1:0] bk3 [0:MAIN-1];
    reg [WW-1:0] bt  [0:TBUF-1];      /* tail columns, 4 rows deep */

    generate
        for (gi = 0; gi < MAX_IC; gi = gi + 1)
            assign ic_mask_full[8*gi +: 8] = (gi < shp_ic) ? 8'hFF : 8'h00;
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_row    <= 16'd0;
            wr_col    <= 16'd0;
            wr_step   <= 4'd0;
            wr_bank   <= 2'd0;
            wr_data_r <= {8*MAX_IC{1'b0}};
        end else if (wr_go) begin
            if (wr_accept)
                wr_data_r <= wr_data_full;
            if (wr_in_tail) begin
                bt[wr_tail_a] <= wr_data_sel;
            end else begin
                case (wr_cell_bank)
                    2'd0:    bk0[wr_cell_col_h] <= wr_data_sel;
                    2'd1:    bk1[wr_cell_col_h] <= wr_data_sel;
                    2'd2:    bk2[wr_cell_col_h] <= wr_data_sel;
                    default: bk3[wr_cell_col_h] <= wr_data_sel;
                endcase
            end
            if (wr_step == (wr_steps - 4'd1)) begin
                wr_step <= 4'd0;
                if (wr_last_col) begin
                    wr_col  <= 16'd0;
                    wr_row  <= wr_row + {14'd0, shp_up};
                    wr_bank <= wr_bank + shp_up;          /* mod 4 */
                end else begin
                    wr_col <= wr_col + {14'd0, shp_up};
                end
            end else begin
                wr_step <= wr_step + 4'd1;
            end
        end
    end

    /* ---------------- window addressing ---------------- */
    wire [15:0] px_j  = (rd_ox * shp_stride) + {15'd0, wj};
    wire [15:0] rd_a  = (px_j == 16'd0)         ? 16'd1 :
                        (px_j == (uw + 16'd1))  ? (uw - 16'd2) :
                                                  (px_j - 16'd1);
    wire [1:0]  b_plus1  = bmid + 2'd1;      /* mod 4 */
    wire [1:0]  b_minus1 = bmid - 2'd1;      /* mod 4 */
    wire [1:0]  bank_want = (wi == 2'd0)  ? ((ry == 16'd0)       ? b_plus1  : b_minus1) :
                            (wi == 2'd1)  ? bmid :
                                            ((ry >= (uh-16'd1)) ? b_minus1 : b_plus1);

    /* all four banks read the same column; the row's bank picks the word.
     * Columns >= MAIN come from the tail memory instead (its address already
     * carries the row slot, so the row mux is not consulted there). */
    reg [WW-1:0] d0, d1, d2, d3;
    reg [WW-1:0] d_tail;
    reg          tail_q;
    wire [15:0]  rd_col    = rd_a + (rh ? H_OFF16 : 16'd0);
    wire [15:0]  rd_a_m    = (rd_col >= MAIN) ? 16'd0 : rd_col;
    wire [15:0]  rd_tail_a = (rd_col >= MAIN) ? ((bank_want * TAIL) + (rd_col - MAIN))
                                              : 16'd0;
    always @(posedge clk) begin
        d0 <= bk0[rd_a_m];
        d1 <= bk1[rd_a_m];
        d2 <= bk2[rd_a_m];
        d3 <= bk3[rd_a_m];
        d_tail <= bt[rd_tail_a];
        tail_q <= (rd_col >= MAIN);
    end

    wire [WW-1:0] d_sel = tail_q ? d_tail :
                          (bsel == 2'd0) ? d0 : (bsel == 2'd1) ? d1 :
                          (bsel == 2'd2) ? d2 : d3;

    /* ---------------- weight fetch + engine ---------------- */
    wire signed [31:0] eng_acc;
    wire               eng_busy, eng_done;

    wire [OCW-1:0] oc_next = (oc_idx == (shp_oc - 6'd1)) ? {OCW{1'b0}} :
                                                              (oc_idx + 1'b1);
    wire [OCW-1:0] oc_next2 = (oc_next == (shp_oc - 6'd1)) ? {OCW{1'b0}} :
                                                               (oc_next + 1'b1);
    wire oc_complete = (eng_done || eng_done_seen) &&
                       (pf_done || (pf_active && (pf_j == (wstrd_r - 5'd1))));
    /* When the next OC's weights are already fully prefetched, start it in the
     * same cycle the current OC completes.  The one-cycle ST_START fallback is
     * retained for the case where the final prefetch word is still in flight. */
    wire direct_start = (state == ST_WAIT) && oc_complete && pf_done &&
                        (oc_idx != (shp_oc - 6'd1));

    assign w_addr = (state == ST_WLOAD) ? {oc_idx, (w_j + 4'd1)} :
                    (state == ST_START) ? {oc_next, 4'd0} :
                    direct_start ? {oc_next2, 4'd0} :
                    ((state == ST_WAIT) && pf_active &&
                     (pf_j != (wstrd_r - 5'd1))) ?
                        {oc_next, (pf_j + 4'd1)} :
                        {($clog2(MAX_OC)+4){1'b0}};

    conv3x3_zp_lanes #(.MAX_IC(MAX_IC), .MAX_OC(MAX_OC), .LANES(LANES)) u_engine (
        .clk(clk), .rst_n(rst_n), .start((state == ST_START) || direct_start),
        .terms(terms_r), .oc_sel(oc_idx), .x_flat(x_flat), .zp_in(zp_in),
        .w_flat(w_reg[8*MAX_IC*9-1:0]),
        .busy(eng_busy), .done(eng_done), .acc_out(eng_acc)
    );

    assign out_valid = (state == ST_EMIT);

    always @(posedge clk) begin
        if (!rst_n) begin
            state    <= ST_PIX;
            wi <= 2'd0; wj <= 2'd0; bsel <= 2'd0; wi_q <= 2'd0; wj_q <= 2'd0;
            rh <= 1'b0; rh_q <= 1'b0; vld_q <= 1'b0;
            w_j <= 4'd0; oc_idx <= {OCW{1'b0}};
            out_count <= 32'd0; rd_ox <= 16'd0; rd_oy <= 16'd0; bmid <= 2'd0;
            x_flat <= {8*MAX_IC*9{1'b0}};
            w_reg <= {256*WSTRIDE_MAX{1'b0}};
            pf_j <= 4'd0; pf_active <= 1'b0; pf_done <= 1'b0;
            eng_done_seen <= 1'b0; eng_acc_r <= 32'sd0; w_valid0 <= 1'b0;
            out_total_r <= 32'd0;
            acc_flat <= {32*MAX_OC{1'b0}}; done <= 1'b0;
            oc_ev_idx <= {($clog2(MAX_OC)){1'b0}};
            oc_ev_acc <= 32'sd0;
            oc_ev_valid <= 1'b0;
        end else begin
            done <= 1'b0;
            oc_ev_valid <= 1'b0;
            out_total_r <= out_total;
            wi_q <= wi; wj_q <= wj; rh_q <= rh;
            vld_q <= (state == ST_PIX) && rows_ready;
            bsel  <= bank_want;

            /* a window word lands one cycle after its address was presented;
             * rh_q says whether it is the low (channels 0..15) or high half */
            if (vld_q) begin
                if (!rh_q) begin
                    for (ic = 0; ic < ICW; ic = ic + 1)
                        if (ic < shp_ic)
                            x_flat[8*(ic*9 + (wi_q*3 + wj_q)) +: 8] <= d_sel[8*ic +: 8];
                end else begin
                    for (ic = 0; ic < ICW; ic = ic + 1)
                        if ((ic + 16) < shp_ic)
                            x_flat[8*((ic+16)*9 + (wi_q*3 + wj_q)) +: 8] <= d_sel[8*ic +: 8];
                end
            end

            case (state)
                ST_PIX: begin
                    if (rows_ready) begin
                        if (two_halves && !rh) begin
                            rh <= 1'b1;          /* high half of this tap */
                        end else begin
                            rh <= 1'b0;
                            if (wj == 2'd2) begin
                                wj <= 2'd0;
                                if (wi == 2'd2) begin
                                    wi <= 2'd0;
                                    w_j <= 4'd0;
                                    state <= w_valid0 ? ST_START : ST_WLOAD;
                                end else wi <= wi + 2'd1;
                            end else wj <= wj + 2'd1;
                        end
                    end
                end

                ST_WLOAD: begin
                    w_reg[256*w_j +: 256] <= w_rdata;
                    if (w_j == (wstrd_r - 5'd1)) begin
                        w_j      <= 4'd0;
                        w_valid0 <= 1'b1;
                        state    <= ST_START;
                    end else w_j <= w_j + 4'd1;
                end

                ST_START: begin
                    pf_j          <= 4'd0;
                    pf_done       <= 1'b0;
                    pf_active     <= 1'b1;
                    eng_done_seen <= 1'b0;
                    state         <= ST_WAIT;
                end

                ST_WAIT: begin
                    /* The first next-OC word was addressed in ST_START; its
                     * data lands here one cycle later.  Store it into the
                     * inactive bank while the engine works on the active one. */
                    if (pf_active) begin
                        /* The engine samples word pf_j before this edge, so the
                         * overwrite with next OC's word pf_j is not visible to
                         * the arithmetic being computed this cycle. */
                        w_reg[256*pf_j +: 256] <= w_rdata;
                        if (pf_j == (wstrd_r - 5'd1)) begin
                            pf_active <= 1'b0;
                            pf_done   <= 1'b1;
                        end else begin
                            pf_j <= pf_j + 4'd1;
                        end
                    end

                    /* done is a one-cycle pulse.  Latch both completion events
                     * so engine and prefetch may finish in either order. */
                    if (eng_done) begin
                        eng_acc_r     <= eng_acc;
                        eng_done_seen <= 1'b1;
                    end

                    if (oc_complete) begin
                        acc_flat[32*oc_idx +: 32] <= eng_done ? eng_acc : eng_acc_r;
                        oc_ev_idx   <= oc_idx;
                        oc_ev_acc   <= eng_done ? eng_acc : eng_acc_r;
                        oc_ev_valid <= 1'b1;
                        eng_done_seen <= 1'b0;
                        pf_done       <= 1'b0;
                        if (oc_idx == (shp_oc - 6'd1)) state <= ST_EMIT;
                        else begin
                            oc_idx <= oc_next;
                            w_j    <= 4'd0;
                            if (direct_start) begin
                                /* Consume the just-finished prefetch, then
                                 * immediately begin prefetching OC+2.  oc_next2
                                 * was presented on w_addr in this cycle. */
                                pf_j          <= 4'd0;
                                pf_active     <= 1'b1;
                                pf_done       <= 1'b0;
                                state         <= ST_WAIT;
                            end else begin
                                state <= ST_START;
                            end
                        end
                    end
                end

                ST_EMIT: begin
                    if (out_ready) begin
                        out_count <= out_count + 32'd1;
                        if (rd_ox == (out_w - 16'd1)) begin
                            rd_ox <= 16'd0;
                            rd_oy <= rd_oy + 16'd1;
                            bmid  <= bmid + shp_stride;      /* mod 4 */
                        end else rd_ox <= rd_ox + 16'd1;

                        wi <= 2'd0; wj <= 2'd0; rh <= 1'b0;
                        oc_idx <= {OCW{1'b0}};
                        if ((out_count + 32'd1) == out_total_r) done <= 1'b1;
                        state <= ST_PIX;
                    end
                end

                default: state <= ST_PIX;
            endcase
        end
    end

endmodule
