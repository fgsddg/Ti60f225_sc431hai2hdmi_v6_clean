/*
 * Accelerator data path for one pass: parameter load + DDR traffic + arithmetic.
 *
 *   start ?? [param loader] ?? [axi master + conv core] ?? done
 *
 * The InstanceNorm affine constants live in the model blob, so every pass first
 * replays them through style_param_loader (gamma_base, OC records of 32 bytes)
 * and then runs the data path.  The stats pass needs them too: its ST_NORM
 * phase derives the norm coefficients from the statistics.
 *
 * cfg addresses are absolute -- the RISC-V scheduler already folds in
 * model_base / arena_base.
 *
 * Scope: plain conv, stride 1 or 2, no residual, no upsample.
 */
module style_accel_top #(
    parameter integer ADDR_W = 32,
    parameter integer DATA_W = 128,
    parameter integer CFG_W  = 832,
    parameter integer IC     = 8,
    parameter integer OC     = 16,
    parameter integer RAW_W  = 640,
    parameter integer RAW_H  = 480,
    parameter integer STRIDE = 2,
    parameter integer LANES  = 80,
    parameter integer MAX_OC = 32,
    parameter integer MAX_IC = 32,
    parameter integer MAX_UW = 640
) (
    input  wire                        clk,
    input  wire                        rst_n,

    input  wire                        start,
    input  wire                        abort,
    input  wire [CFG_W-1:0]            cfg,

    output reg                         busy,
    output reg                         done,
    output wire                        error,
    output wire [31:0]                 error_code,
    output wire [63:0]                 cycle_count,

    /* Bring-up debug bundle, readable at APB offset 0x84. */
    output wire [31:0]                 dbg,
    /* Xbar-side read handshake (driven by the top-level xbar). */
    input  wire                        dbg_xbar_arready,
    input  wire                        dbg_xbar_rvalid,

    output wire [64*MAX_OC-1:0]        sum_flat,
    output wire [64*MAX_OC-1:0]        sumsq_flat,
    output wire [31:0]                 count_out,

    /* AXI4 master to the SoC DDR port (io_ddrMasters_0_*) */
    output wire [ADDR_W-1:0]           m_axi_araddr,
    output wire [7:0]                  m_axi_arlen,
    output wire [2:0]                  m_axi_arsize,
    output wire [1:0]                  m_axi_arburst,
    output wire                        m_axi_arvalid,
    input  wire                        m_axi_arready,
    input  wire [DATA_W-1:0]           m_axi_rdata,
    input  wire [1:0]                  m_axi_rresp,
    input  wire                        m_axi_rlast,
    input  wire                        m_axi_rvalid,
    output wire                        m_axi_rready,

    output wire [ADDR_W-1:0]           m_axi_awaddr,
    output wire [7:0]                  m_axi_awlen,
    output wire [2:0]                  m_axi_awsize,
    output wire [1:0]                  m_axi_awburst,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,
    output wire [DATA_W-1:0]           m_axi_wdata,
    output wire [DATA_W/8-1:0]         m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,
    input  wire [1:0]                  m_axi_bresp,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready
);

    localparam integer ST_IDLE = 2'd0;
    localparam integer ST_LOAD = 2'd1;
    localparam integer ST_RUN  = 2'd2;

    reg [1:0] state;
    reg       loader_start;
    reg       master_start;
    reg       loader_armed;
    reg       master_armed;

    wire        loader_busy;
    wire        loader_done;
    wire        loader_w_we;
    wire [$clog2(MAX_OC)+4-1:0] loader_w_waddr;   /* {oc, word} */
    wire [255:0] loader_w_wdata;
    wire [31:0] cfg_weight_base_w;
    wire [15:0] cfg_ic_w;
    wire [31:0] cfg_gamma_base_w;
    wire [31:0] cfg_qin_base_w;
    wire [31:0] cfg_qout_base_w;
wire [31:0] cfg_qmid_base_w;
    /* op=4 reuses the two norm address slots for the tanh head's tables
     * (gamma = LUT, beta = affine constants); the firmware already writes both
     * (HANDOFF_ACCEL 9.41). */
    wire [31:0] cfg_beta_base_w;
wire [15:0] cfg_op_w;
wire signed [63:0] res_scale_w;
wire signed [7:0]  res_zp_w;
    wire [15:0] cfg_oc_w;
    wire [15:0] cfg_in_w_w;
    wire [15:0] cfg_in_h_w;
    wire [15:0] cfg_stride_w;
    wire [15:0] cfg_upsample_w;

    wire        master_busy;
    wire        master_done;

    /* InstanceNorm parameters travel one channel at a time (see style_accel_core.v) */
    wire [4:0]           p_raddr;
    wire signed [63:0]   p_s2, p_sg, p_beta;
    wire [31:0]          inv_n_q32;
    wire        tanh_lut_we;
    wire [12:0] tanh_lut_waddr;
    wire [23:0] tanh_lut_wdata;
    wire signed [8:0]    zp_in_w;
    wire [63:0]          q_recip_w;
    wire signed [7:0]    q_zp_w;

    wire        is_stats      = cfg[25*32 + 0];
    wire        raw_produce   = cfg[25*32 + 8];
    wire        raw_consume   = cfg[25*32 + 9];
    wire        do_relu       = cfg[25*32 + 3];
    wire        do_tanh  = (cfg_op_w == 16'd4);

    /* {oc, word slot}: 16 slots per OC, so +4 address bits.  This drops the
     * weight cache from ~58 RAM10 to ~13 -- see HANDOFF_ACCEL 9.21. */
    localparam integer W_ADDR_W = (MAX_OC <= 1) ? 5 : ($clog2(MAX_OC) + 4);
    localparam integer W_DATA_W = 256;
    wire [$clog2(MAX_OC)+4-1:0] core_w_addr;
    wire [W_ADDR_W-1:0] weight_raddr;
    wire [W_DATA_W-1:0] weight_rdata;
    wire [255:0] core_w_rdata = weight_rdata;
    wire sel_loader = (state == ST_LOAD);
    wire [3:0] loader_state;      /* debug only, surfaced via dbg */

    /* loader <-> master read-engine handshake.  There is only one reader now;
     * sel_loader tells the master which owner drives it. */
    wire              ldr_launch;
    wire [ADDR_W-1:0] ldr_base;
    wire [31:0]       ldr_total;
    wire [15:0]       ldr_pixel_bytes;
    wire              ldr_ready;
    wire [255:0]      ldr_pixel;
    wire              ldr_valid;
    wire              ldr_done;

    /* master <-> core stream */
    wire [255:0] dp_in_pixel;
    wire         dp_in_valid;
    wire         dp_in_ready;
    wire [255:0] dp_res_pixel;
    wire         dp_res_valid;
    wire         dp_res_ready;
    wire [255:0] dp_out_pixel;
    wire         dp_out_valid;
    wire         dp_out_ready;
    wire         core_done;
    wire         mst_dbg_rd_done, mst_dbg_wr_done, mst_dbg_has_output;
    wire [2:0]   mst_dbg_rd_state;
    wire         mst_dbg_rd_m_valid, mst_dbg_rd_read_done;
    wire [2:0]   core_dbg_state;

    /* ---- AXI master + conv core (one pass) ---- */
    style_net_axi_master #(
        .ADDR_W(ADDR_W), .DATA_W(DATA_W), .CFG_W(CFG_W)
    ) u_master (
        .clk(clk), .rst_n(rst_n),
        .start(master_start), .abort(abort), .cfg(cfg),
        .busy(master_busy), .done(master_done), .error(error),
        .error_code(error_code), .cycle_count(cycle_count),
        .cfg_op(cfg_op_w), .cfg_ic(cfg_ic_w), .cfg_oc(cfg_oc_w),
        .cfg_in_w(cfg_in_w_w), .cfg_in_h(cfg_in_h_w), .cfg_out_w(), .cfg_out_h(),
        .cfg_stride(cfg_stride_w), .cfg_upsample(cfg_upsample_w), .cfg_pad_mode(), .cfg_lanes(),
        .cfg_flags(),
        .cfg_weight_base(cfg_weight_base_w), .cfg_w_scale_base(), .cfg_bias_base(),
        .cfg_gamma_base(cfg_gamma_base_w), .cfg_beta_base(cfg_beta_base_w),
        .cfg_quant_in_base(cfg_qin_base_w),
        .cfg_quant_mid_base(cfg_qmid_base_w), .cfg_quant_out_base(cfg_qout_base_w),
        .cfg_stats_base(),
        .dp_in_pixel(dp_in_pixel), .dp_in_valid(dp_in_valid),
        .dp_in_ready(dp_in_ready),
        .dp_res_pixel(dp_res_pixel), .dp_res_valid(dp_res_valid),
        .dp_res_ready(dp_res_ready),
        .dp_out_pixel(dp_out_pixel), .dp_out_valid(dp_out_valid),
        .dp_out_ready(dp_out_ready),
        .dp_done(core_done),
        .dbg_rd_done(mst_dbg_rd_done), .dbg_wr_done(mst_dbg_wr_done),
        .dbg_has_output(mst_dbg_has_output),
        .dbg_rd_state(mst_dbg_rd_state), .dbg_rd_m_valid(mst_dbg_rd_m_valid),
        .dbg_rd_read_done(mst_dbg_rd_read_done),
        .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize), .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .ldr_mode(sel_loader),
        .ldr_launch(ldr_launch), .ldr_base(ldr_base),
        .ldr_total(ldr_total), .ldr_pixel_bytes(ldr_pixel_bytes),
        .ldr_ready(ldr_ready), .ldr_pixel(ldr_pixel),
        .ldr_valid(ldr_valid), .ldr_done(ldr_done)
    );

    style_net_core #(
        .LANES(LANES), .MAX_IC(MAX_IC), .MAX_OC(MAX_OC), .MAX_UW(MAX_UW)
    ) u_core (
        /* runtime shape straight from the pass descriptor (HANDOFF 9.22 five) */
        .shp_ic(cfg_ic_w[5:0]), .shp_oc(cfg_oc_w[5:0]),
        .shp_stride(cfg_stride_w[1:0]), .shp_up(cfg_upsample_w[1:0]),
        .shp_in_w(cfg_in_w_w), .shp_in_h(cfg_in_h_w),
        .clk(clk), .rst_n(rst_n),
        .start(master_start), .is_stats(is_stats),
        .raw_produce(raw_produce), .raw_consume(raw_consume),
        .do_relu(do_relu),
        .tanh_do(do_tanh),
        .lut_we(tanh_lut_we), .lut_waddr(tanh_lut_waddr),
        .lut_wdata(tanh_lut_wdata),
        .busy(), .done(core_done), .dbg_state(core_dbg_state),
        .in_pixel(dp_in_pixel),
        .in_valid(dp_in_valid),
        .in_ready(dp_in_ready),
        .out_pixel(dp_out_pixel),
        .out_valid(dp_out_valid),
        .out_ready(dp_out_ready),
        .w_addr(core_w_addr), .w_rdata(core_w_rdata), .zp_in(zp_in_w),
        .inv_n_q32(inv_n_q32),
        .p_raddr(p_raddr), .p_s2(p_s2), .p_sg(p_sg), .p_beta(p_beta),
        /* op = CONV_RESIDUAL (5): the master launches its residual reader only
         * for such a pass, so res_valid belongs to that stream. */
        .res_do(cfg_op_w == 16'd5), .res_valid(dp_res_valid),
        .res_pixel(dp_res_pixel[8*MAX_OC-1:0]),
        .res_scale_q32(res_scale_w), .res_zp(res_zp_w), .res_ready(dp_res_ready),
        .q_scale_recip_q48(q_recip_w), .q_zero_point(q_zp_w),
        .sum_flat(sum_flat), .sumsq_flat(sumsq_flat), .count_out(count_out),
        /* the core's statistics read-back tap is a harness/debug port; the SoC
         * only needs the flat ports above wired to constants (see u_stats) */
        .dbg_st_addr(5'd0), .dbg_st_sum(), .dbg_st_sumsq()
    );

    /* ---- parameter loader ---- */
    style_param_loader #(
        .ADDR_W(ADDR_W), .DATA_W(DATA_W), .MAX_CH(MAX_OC),
        .MAX_IC(MAX_IC)
    ) u_loader (
        .clk(clk), .rst_n(rst_n),
        .start(loader_start),
        .base_addr(cfg_gamma_base_w),
        .channels(cfg_oc_w[7:0]),
        .quant_in_addr(cfg_qin_base_w),
        .quant_out_addr(cfg_qout_base_w),
        .do_residual(cfg_op_w == 16'd5), .res_quant_addr(cfg_qmid_base_w),
        .weight_addr(cfg_weight_base_w), .ic(cfg_ic_w[7:0]),
        .do_tanh(do_tanh), .head_param_addr(cfg_beta_base_w),
        .lut_waddr(tanh_lut_waddr), .lut_wdata(tanh_lut_wdata),
        .lut_we(tanh_lut_we),
        .w_waddr(loader_w_waddr), .w_wdata(loader_w_wdata),
        .w_we(loader_w_we),
        .dbg_state(loader_state),
        .zp_in(zp_in_w),
        .q_scale_recip_q48(q_recip_w),
        .q_zero_point(q_zp_w),
        .res_scale_q32(res_scale_w),
        .res_zp(res_zp_w),
        .busy(loader_busy), .done(loader_done),
        .pr_addr(p_raddr), .pr_s2(p_s2), .pr_sg(p_sg), .pr_beta(p_beta),
        .inv_n_q32(inv_n_q32),
        .ldr_launch(ldr_launch), .ldr_base(ldr_base),
        .ldr_total(ldr_total), .ldr_pixel_bytes(ldr_pixel_bytes),
        .ldr_ready(ldr_ready), .ldr_pixel(ldr_pixel),
        .ldr_valid(ldr_valid), .ldr_done(ldr_done)
    );

    /* ---- one-OC-per-word weight BRAM ---- */
    assign weight_raddr = core_w_addr;

    style_weight_bram #(
        .DATA_W(W_DATA_W), .ADDR_W(W_ADDR_W)
    ) u_weight_bram (
        .clk(clk),
        .wdata(loader_w_wdata), .waddr(loader_w_waddr),
        .we(loader_w_we),
        .raddr(weight_raddr), .rdata(weight_rdata)
    );

    /* ---- bring-up debug bundle (APB read offset 0x84) ----
     * Answers "where is it stuck?" with a register read, so the single JTAG
     * chain does not have to be shared with the RTL probe.
     *   [1:0] top state   [2] busy      [3] sel_loader  [4] loader_busy
     *   [5] loader_done   [9:6] loader state
     *   [10] ldr_ready  [11] ldr_valid  [12] ldr_launch  [13] ldr_mode
     *   [14] master arvalid  [15] master awvalid
     *   [31:29] reader FSM   [28] reader m_valid   [27] reader m_ready
     *   [26:25] progress heartbeat (output-pixel count LSBs: must change run to run)
     */
    assign dbg = {
        mst_dbg_rd_state,     /* [31:29] arena reader FSM: 0=IDLE 1=ISSUE 2=R 3=DRAIN */
        mst_dbg_rd_m_valid,   /* [28]    reader holds a pixel (m_valid) */
        dp_in_ready,          /* [27]    reader m_ready (consumer will take it) */
        {dbg_xbar_rvalid, dbg_xbar_arready}, /* [26:25] xbar AR ready / R valid */
        {1'b0, core_dbg_state}, /* [24:21] core FSM state (3-bit state, zero-extended) */
        mst_dbg_has_output,   /* [20] */
        mst_dbg_wr_done,      /* [19] */
        mst_dbg_rd_done,      /* [18]  pass completes when every one of these is set */
        2'd0,                 /* [17:16] overwritten by the cmd_regs stickies */
        m_axi_awvalid,
        m_axi_arvalid,
        ldr_ready,            /* [10] loader consumer is ready */
        ldr_valid,            /* [11] shared reader presents a loader pixel */
        ldr_launch,           /* [12] loader starts a borrow */
        sel_loader,           /* [13] ldr_mode == loader owns the reader */
        loader_state,
        loader_done,
        loader_busy,
        sel_loader,
        busy,
        state
    };

    /* ---- one read engine, directly on the top-level AXI master ----
     * The top FSM still serialises loader and pass; the master now muxes the
     * loader request into its own reader with ldr_mode (sel_loader), so the
     * whole loader-side AXI mux and its second read engine are gone. */

    /* ---- parameter load then pass ---- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            loader_start <= 1'b0;
            master_start <= 1'b0;
            loader_armed <= 1'b0;
            master_armed <= 1'b0;
            busy         <= 1'b0;
            done         <= 1'b0;
        end else begin
            loader_start <= 1'b0;
            master_start <= 1'b0;

            case (state)
            ST_IDLE: begin
                if (start) begin
                    busy         <= 1'b1;
                    done         <= 1'b0;
                    loader_start <= 1'b1;
                    loader_armed <= 1'b1;
                    master_armed <= 1'b0;
                    state        <= ST_LOAD;
                end
            end

            ST_LOAD: begin
                if (loader_armed && loader_busy)
                    loader_armed <= 1'b0;
                if (!loader_armed && loader_done) begin
                    master_start <= 1'b1;
                    master_armed <= 1'b1;
                    state        <= ST_RUN;
                end
            end

            ST_RUN: begin
                if (master_armed && master_busy)
                    master_armed <= 1'b0;
                if (!master_armed && master_done) begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= ST_IDLE;
                end
            end

            default: state <= ST_IDLE;
            endcase
        end
    end

endmodule





