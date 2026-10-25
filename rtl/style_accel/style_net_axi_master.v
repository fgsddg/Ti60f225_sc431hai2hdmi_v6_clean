/*
 * Memory-facing half of one accelerator pass.
 *
 * Takes the 832-bit pass descriptor from style_accel_cmd_regs, decodes it and
 * runs one pass:
 *
 *     read input tensor from DDR  ->  dp_in_*  -> compute datapath
 *                                 ->  dp_out_* -> write result back to DDR
 *
 * The compute datapath (conv stage + InstanceNorm + requant + residual) is
 * instantiated above this module and connects through the dp_* stream ports, so
 * the DDR traffic and the arithmetic can be verified independently.
 *
 * Input and output base addresses in cfg are already absolute: the scheduler
 * adds model_base / arena_base before writing the registers.
 *
 * Pixel width follows the arena layout: pixel_bytes = align4(C).
 */
module style_net_axi_master #(
    parameter integer ADDR_W = 32,
    parameter integer DATA_W = 128,
    parameter integer CFG_W  = 832
) (
    input  wire                clk,
    input  wire                rst_n,

    /* pass command */
    input  wire                start,
    input  wire                abort,
    input  wire [CFG_W-1:0]    cfg,

    output reg                 busy,
    output reg                 done,
    output reg                 error,
    output reg  [31:0]         error_code,
    output reg  [63:0]         cycle_count,
    /* bring-up visibility: the three conditions the pass-complete test needs */
    output wire                dbg_rd_done,
    output wire                dbg_wr_done,
    output wire                dbg_has_output,
    /* bring-up: reader FSM + handshake (HANDOFF_ACCEL 9.13) */
    output wire [2:0]          dbg_rd_state,
    output wire                dbg_rd_m_valid,
    output wire                dbg_rd_read_done,

    /* decoded pass descriptor for the compute datapath */
    output wire [15:0]         cfg_op,
    output wire [15:0]         cfg_ic,
    output wire [15:0]         cfg_oc,
    output wire [15:0]         cfg_in_w,
    output wire [15:0]         cfg_in_h,
    output wire [15:0]         cfg_out_w,
    output wire [15:0]         cfg_out_h,
    output wire [15:0]         cfg_stride,
    output wire [15:0]         cfg_upsample,
    output wire [15:0]         cfg_pad_mode,
    output wire [15:0]         cfg_lanes,
    output wire [31:0]         cfg_flags,
    output wire [31:0]         cfg_weight_base,
    output wire [31:0]         cfg_w_scale_base,
    output wire [31:0]         cfg_bias_base,
    output wire [31:0]         cfg_gamma_base,
    output wire [31:0]         cfg_beta_base,
    output wire [31:0]         cfg_quant_in_base,
    output wire [31:0]         cfg_quant_mid_base,
    output wire [31:0]         cfg_quant_out_base,
    output wire [31:0]         cfg_stats_base,
    output wire [31:0]         cfg_residual_base,

    /* datapath input stream (from DDR) */
    output wire [255:0]        dp_in_pixel,
    output wire                dp_in_valid,
    input  wire                dp_in_ready,

    /* datapath residual stream (op = CONV_RESIDUAL compute passes) */
    output wire [255:0]        dp_res_pixel,
    output wire                dp_res_valid,
    input  wire                dp_res_ready,

    /* datapath output stream (to DDR) */
    input  wire [255:0]        dp_out_pixel,
    input  wire                dp_out_valid,
    output wire                dp_out_ready,

    /* datapath finished producing this pass */
    input  wire                dp_done,

    /* AXI4 master */
    output wire [ADDR_W-1:0]   m_axi_araddr,
    output wire [7:0]          m_axi_arlen,
    output wire [2:0]          m_axi_arsize,
    output wire [1:0]          m_axi_arburst,
    output wire                m_axi_arvalid,
    input  wire                m_axi_arready,
    input  wire [DATA_W-1:0]   m_axi_rdata,
    input  wire [1:0]          m_axi_rresp,
    input  wire                m_axi_rlast,
    input  wire                m_axi_rvalid,
    output wire                m_axi_rready,

    output wire [ADDR_W-1:0]   m_axi_awaddr,
    output wire [7:0]          m_axi_awlen,
    output wire [2:0]          m_axi_awsize,
    output wire [1:0]          m_axi_awburst,
    output wire                m_axi_awvalid,
    input  wire                m_axi_awready,
    output wire [DATA_W-1:0]   m_axi_wdata,
    output wire [DATA_W/8-1:0] m_axi_wstrb,
    output wire                m_axi_wlast,
    output wire                m_axi_wvalid,
    input  wire                m_axi_wready,
    input  wire [1:0]          m_axi_bresp,
    input  wire                m_axi_bvalid,
    output wire                m_axi_bready,

    /* Parameter-loader borrow of the read engine.  The top serialises the two
     * users with ldr_mode: while it is high the loader drives start/base/len
     * and consumes the pixel stream, and the pass-side reader interface is
     * masked.  Only one engine exists now, so the loader no longer owns a
     * second axi4_pixel_read (that reader cost 12 RAM10 + ~859 LUT). */
    input  wire                ldr_mode,
    input  wire                ldr_launch,
    input  wire [ADDR_W-1:0]   ldr_base,
    input  wire [31:0]         ldr_total,
    input  wire [15:0]         ldr_pixel_bytes,
    input  wire                ldr_ready,
    output wire [255:0]        ldr_pixel,
    output wire                ldr_valid,
    output wire                ldr_done
);

    localparam integer ST_IDLE  = 2'd0;
    localparam integer ST_RUN   = 2'd1;
    localparam integer ST_PRIME = 2'd2;

    reg [1:0] state;
    reg [1:0] prime_cnt;
    reg       launch;
    reg       armed;
    reg       aborted;

    /* ---- descriptor decode ---- */
    wire [31:0] c_op         = cfg[ 2*32 +: 32];
    wire [31:0] c_ic         = cfg[ 3*32 +: 32];
    wire [31:0] c_oc         = cfg[ 4*32 +: 32];
    wire [31:0] c_in_w       = cfg[ 5*32 +: 32];
    wire [31:0] c_in_h       = cfg[ 6*32 +: 32];
    wire [31:0] c_out_w      = cfg[ 7*32 +: 32];
    wire [31:0] c_out_h      = cfg[ 8*32 +: 32];
    wire [31:0] c_stride     = cfg[ 9*32 +: 32];
    wire [31:0] c_upsample   = cfg[10*32 +: 32];
    wire [31:0] c_pad_mode   = cfg[11*32 +: 32];
    wire [31:0] c_weight     = cfg[12*32 +: 32];
    wire [31:0] c_w_scale    = cfg[13*32 +: 32];
    wire [31:0] c_bias       = cfg[14*32 +: 32];
    wire [31:0] c_gamma      = cfg[15*32 +: 32];
    wire [31:0] c_beta       = cfg[16*32 +: 32];
    wire [31:0] c_qin        = cfg[17*32 +: 32];
    wire [31:0] c_qmid       = cfg[18*32 +: 32];
    wire [31:0] c_qout       = cfg[19*32 +: 32];
    wire [31:0] c_in_base    = cfg[20*32 +: 32];
    wire [31:0] c_out_base   = cfg[21*32 +: 32];
    wire [31:0] c_res_base   = cfg[22*32 +: 32];
    wire [31:0] c_stats      = cfg[23*32 +: 32];
    wire [31:0] c_lanes      = cfg[24*32 +: 32];
    wire [31:0] c_flags      = cfg[25*32 +: 32];

    assign cfg_op            = c_op[15:0];
    assign cfg_ic            = c_ic[15:0];
    assign cfg_oc            = c_oc[15:0];
    assign cfg_in_w          = c_in_w[15:0];
    assign cfg_in_h          = c_in_h[15:0];
    assign cfg_out_w         = c_out_w[15:0];
    assign cfg_out_h         = c_out_h[15:0];
    assign cfg_stride        = c_stride[15:0];
    assign cfg_upsample      = c_upsample[15:0];
    assign cfg_pad_mode      = c_pad_mode[15:0];
    assign cfg_lanes         = c_lanes[15:0];
    assign cfg_flags         = c_flags;
    assign cfg_weight_base   = c_weight;
    assign cfg_w_scale_base  = c_w_scale;
    assign cfg_bias_base     = c_bias;
    assign cfg_gamma_base    = c_gamma;
    assign cfg_beta_base     = c_beta;
    assign cfg_quant_in_base = c_qin;
    assign cfg_quant_mid_base= c_qmid;
    assign cfg_quant_out_base= c_qout;
    assign cfg_stats_base    = c_stats;
    assign cfg_residual_base = c_res_base;

    /* Pixel storage stride must stay one of the AXI pixel engine's
     * supported widths: 4, 8, 16 or 32 bytes.  Logical channel counts from
     * 17..32 are therefore padded to 32 bytes/pixel in DDR; the core still
     * computes only cfg_ic/cfg_oc channels and ignores the pad lanes.
     * Width detection is deliberately bitwise: Ti60 routing is already
     * above 95% XLR, so avoid a 16-bit magnitude comparator here. */
    function [15:0] align_pixel;
        input [15:0] c;
        reg   wide;
        begin
            wide = (|c[15:5]) | (c[4] & (|c[3:0]));
            align_pixel = wide ? 16'd32 : ((c + 16'd3) & 16'hFFFC);
        end
    endfunction

    /* RAW_PRODUCE writes int32 pixels (4 B/channel); RAW_CONSUME reads them.
     * The two directions are deliberately independent: p0' reads q_in as int8
     * but writes raw int32, while p1' reads raw int32 but writes q1 as int8. */
    wire raw_produce = c_flags[8];
    wire raw_consume = c_flags[9];
    wire [15:0] in_pixel_bytes  = raw_consume
                                  ? align_pixel(c_ic[15:0] * 16'd4)
                                  : align_pixel(c_ic[15:0]);
    wire [15:0] out_pixel_bytes = raw_produce
                                  ? align_pixel(c_oc[15:0] * 16'd4)
                                  : align_pixel(c_oc[15:0]);

    /* This first raw-int32 validation only fits the existing 32 B/pixel wide
     * transport.  16 or 24 int32 channels would silently be truncated to 32 B
     * by align_pixel(), so reject them before either engine is launched. */
    wire raw_width_bad = (raw_produce && (c_oc[15:0] > 16'd8)) ||
                         (raw_consume && (c_ic[15:0] > 16'd8));
    wire raw_mode_bad  = raw_produce && raw_consume;

    /* Byte counts feed the engines' beat counters at launch.  Compute w*h and
     * then area*pixel_bytes in two registered stages so that no multiply chain
     * sits between the cfg register and the AXI engines.  cfg is stable well
     * before start, so the two cycles of pipeline latency are free. */
    wire [31:0] in_area  = c_in_w[15:0] * c_in_h[15:0];
    wire [15:0] res_pixel_bytes = align_pixel(c_oc[15:0]);
    wire [31:0] out_area = c_out_w[15:0] * c_out_h[15:0];

    reg [31:0] in_area_q, out_area_q;
    reg [31:0] in_bytes, out_bytes;
    reg [31:0] res_bytes;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_area_q  <= 32'd0;
            out_area_q <= 32'd0;
            in_bytes   <= 32'd0;
            out_bytes  <= 32'd0;
            res_bytes  <= 32'd0;
        end else begin
            in_area_q  <= in_area;
            out_area_q <= out_area;
            in_bytes   <= in_area_q  * {16'd0, in_pixel_bytes};
            out_bytes  <= out_area_q * {16'd0, out_pixel_bytes};
            res_bytes  <= in_area_q  * {16'd0, res_pixel_bytes};
        end
    end

    /* ---- engines ---- */
    /* FLAG_COMPUTE (bit 1) decides whether this pass stores a result.
     * Statistics passes share out_point with their compute pass but do
     * not write DDR. */
    wire has_output = c_flags[1] || raw_produce;
    /* only a residual *compute* pass reads the second stream */
    wire has_residual = (c_op[15:0] == 16'd5) && c_flags[1];

    /* declare first: a reference before the declaration makes an implicit 1-bit
     * net, which truncates rd_dbg_state and upsets a strict compiler */
    wire rd_done_r;
    wire wr_done_r;
    wire [2:0] rd_dbg_state;
    wire       rd_dbg_m_valid;
    wire       rd_dbg_read_done;

    assign dbg_rd_done    = rd_done_r;
    assign dbg_wr_done    = wr_done_r;
    assign dbg_has_output = has_output;
    assign dbg_rd_state     = rd_dbg_state;
    assign dbg_rd_m_valid   = rd_dbg_m_valid;
    assign dbg_rd_read_done = rd_dbg_read_done;

    /* One reader, two owners.  ldr_mode is driven by the top's loader phase
     * and is stable for the whole borrow, so a combinational mux is enough:
     * axi4_pixel_read latches base/len on the start edge. */
    wire rd_start = ldr_mode ? ldr_launch : launch;
    wire wr_start = launch && has_output;

    wire [ADDR_W-1:0] in_araddr;
    wire [7:0]        in_arlen;
    wire [2:0]        in_arsize;
    wire [1:0]        in_arburst;
    wire              in_arvalid, in_arready;
    wire              in_rlast, in_rvalid, in_rready;
    wire [255:0]      rd_m_pixel;
    wire              rd_m_valid;
    wire              rd_m_ready;

    assign dp_in_pixel = rd_m_pixel;
    assign dp_in_valid = rd_m_valid && !ldr_mode;
    assign ldr_pixel   = rd_m_pixel;
    assign ldr_valid   = rd_m_valid && ldr_mode;
    assign ldr_done    = rd_done_r;
    assign rd_m_ready  = ldr_mode ? ldr_ready : dp_in_ready;

    /* Full-width long bursts are safe because axi4_pixel_read raises an AR
     * only when the whole burst fits in its FIFO.  Every beat is 16 bytes and
     * pixels are unpacked locally, which removes the historical narrow-burst
     * corruption while keeping the R channel fully drainable. */
    axi4_pixel_read #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .MAX_BURST(64)) u_rd (
        .clk(clk), .rst_n(rst_n),
        .start(rd_start),
        .base_addr(ldr_mode ? ldr_base : c_in_base[ADDR_W-1:0]),
        .total_bytes(ldr_mode ? ldr_total : in_bytes),
        .pixel_bytes(ldr_mode ? ldr_pixel_bytes : in_pixel_bytes),
        .busy(), .done(rd_done_r),
        .m_pixel(rd_m_pixel), .m_valid(rd_m_valid), .m_ready(rd_m_ready),
        .m_axi_araddr(in_araddr), .m_axi_arlen(in_arlen),
        .m_axi_arsize(in_arsize), .m_axi_arburst(in_arburst),
        .m_axi_arvalid(in_arvalid), .m_axi_arready(in_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(in_rlast), .m_axi_rvalid(in_rvalid),
        .m_axi_rready(in_rready),
        .dbg_state(rd_dbg_state), .dbg_m_valid(rd_dbg_m_valid),
        .dbg_read_done(rd_dbg_read_done)
    );

    /* ---- residual reader (op = CONV_RESIDUAL compute passes only) ----
     * Launched only when this pass actually consumes it: a residual stream that
     * nobody drains would hold an R beat on the shared port and block our own
     * writes (HANDOFF 9.14 section two). */
    wire [ADDR_W-1:0] res_araddr;
    wire [7:0]        res_arlen;
    wire [2:0]        res_arsize;
    wire [1:0]        res_arburst;
    wire              res_arvalid, res_arready;
    wire [1:0]        res_rresp;
    wire              res_rlast, res_rvalid, res_rready;
    wire              res_rd_done;

    /* The residual stream only needs one pixel per output pixel, so keep this
     * reader single-beat.  MAX_BURST 1 makes its FIFO registers instead of a
     * 256-bit block-RAM array; the main input reader carries the 64-beat burst
     * optimization. */
    axi4_pixel_read #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .MAX_BURST(1)) u_rd_res (
        .clk(clk), .rst_n(rst_n),
        /* only the pass's own launch may start the residual reader; a loader
         * borrow must never touch the shared AR/R path */
        .start(launch && has_residual),
        .base_addr(c_res_base[ADDR_W-1:0]),
        .total_bytes(res_bytes), .pixel_bytes(res_pixel_bytes),
        .busy(), .done(res_rd_done),
        .m_pixel(dp_res_pixel), .m_valid(dp_res_valid), .m_ready(dp_res_ready),
        .m_axi_araddr(res_araddr), .m_axi_arlen(res_arlen),
        .m_axi_arsize(res_arsize), .m_axi_arburst(res_arburst),
        .m_axi_arvalid(res_arvalid), .m_axi_arready(res_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(res_rresp),
        .m_axi_rlast(res_rlast), .m_axi_rvalid(res_rvalid),
        .m_axi_rready(res_rready),
        .dbg_state(), .dbg_m_valid(), .dbg_read_done()
    );

    /* ---- AR/R arbitration between the two readers ----
     * axi4_pixel_read keeps at most one burst outstanding and holds arvalid
     * until it is accepted, so a latched round-robin selection is enough: the
     * loser's arready is masked to 0 (its request stays asserted, unchanged) and
     * the R channel goes to whoever owns the burst until rlast.  Round robin,
     * not fixed priority, so neither stream can starve the other -- both advance
     * at one pixel per output pixel. */
    reg rd_sel_res;      /* mux selection, held for the whole burst */
    reg rd_inflight;
    reg rr_res;          /* round-robin: grant the residual next? */

    wire rd_last_beat = m_axi_rvalid && m_axi_rready && m_axi_rlast;
    wire rd_ar_fire   = m_axi_arvalid && m_axi_arready;

    /* The selection may only change when the currently selected reader is not
     * presenting an AR.  Flipping it mid-handshake would change araddr while
     * arvalid is high, and flipping it after an AR has been accepted would mask
     * the very beat that AR is waiting for -- that reader then sits in ST_R
     * forever and the pass hangs (it did, on the first attempt).  So freeze from
     * the AR handshake until rlast, then round-robin so neither stream starves. */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_sel_res  <= 1'b0;
            rd_inflight <= 1'b0;
            rr_res      <= 1'b0;
        end else if (rd_inflight) begin
            if (rd_last_beat) begin
                rd_inflight <= 1'b0;
                rr_res      <= ~rd_sel_res;     /* prefer the other stream next */
            end
        end else if (rd_ar_fire) begin
            rd_inflight <= 1'b1;
        end else if (!m_axi_arvalid) begin
            if (res_arvalid && (!in_arvalid || rr_res)) rd_sel_res <= 1'b1;
            else if (in_arvalid)                        rd_sel_res <= 1'b0;
        end
    end

    assign m_axi_araddr  = rd_sel_res ? res_araddr  : in_araddr;
    assign m_axi_arlen   = rd_sel_res ? res_arlen   : in_arlen;
    assign m_axi_arsize  = rd_sel_res ? res_arsize  : in_arsize;
    assign m_axi_arburst = rd_sel_res ? res_arburst : in_arburst;
    assign m_axi_arvalid = rd_sel_res ? res_arvalid : in_arvalid;
    assign m_axi_rready  = rd_sel_res ? res_rready : in_rready;

    assign in_arready  = rd_sel_res ? 1'b0 : m_axi_arready;
    assign res_arready = rd_sel_res ? m_axi_arready : 1'b0;
    assign in_rlast    = rd_sel_res ? 1'b0 : m_axi_rlast;
    assign res_rlast   = rd_sel_res ? m_axi_rlast : 1'b0;
    assign in_rvalid   = rd_sel_res ? 1'b0 : m_axi_rvalid;
    assign res_rvalid  = rd_sel_res ? m_axi_rvalid : 1'b0;
    assign res_rresp   = m_axi_rresp;

    axi4_pixel_write #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) u_wr (
        .clk(clk), .rst_n(rst_n),
        .start(wr_start), .base_addr(c_out_base[ADDR_W-1:0]),
        .total_bytes(out_bytes), .pixel_bytes(out_pixel_bytes),
        .busy(), .done(wr_done_r),
        .s_pixel(dp_out_pixel), .s_valid(dp_out_valid), .s_ready(dp_out_ready),
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize), .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );

    /* ---- pass sequencing ---- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= ST_IDLE;
            prime_cnt   <= 2'd0;
            launch      <= 1'b0;
            armed       <= 1'b0;
            aborted     <= 1'b0;
            busy        <= 1'b0;
            done        <= 1'b0;
            error       <= 1'b0;
            error_code  <= 32'd0;
            cycle_count <= 64'd0;
        end else begin
            case (state)
            ST_IDLE: begin
                launch <= 1'b0;
                if (start && (raw_width_bad || raw_mode_bad)) begin
                    /* Fail closed: accepting the pass would compute the wrong
                     * address stride and corrupt every pixel after the first. */
                    armed       <= 1'b0;
                    busy        <= 1'b0;
                    done        <= 1'b1;
                    error       <= 1'b1;
                    error_code  <= raw_mode_bad ? 32'd3 : 32'd2;
                    cycle_count <= 64'd0;
                    aborted     <= 1'b0;
                    launch      <= 1'b0;
                    prime_cnt   <= 2'd0;
                    state       <= ST_IDLE;
                end else if (start) begin
                    /* The engines keep done high until their next start, so
                     * mask the completion check for the launch cycle. */
                    armed       <= 1'b0;
                    done        <= 1'b0;
                    error       <= 1'b0;
                    error_code  <= 32'd0;
                    cycle_count <= 64'd0;
                    aborted     <= 1'b0;
                    busy        <= 1'b1;
                    launch      <= 1'b0;
                    prime_cnt   <= 2'd0;
                    state       <= ST_PRIME;
                end
            end

            ST_PRIME: begin
                /* in_bytes/out_bytes are registered out of cfg, so wait for
                 * that pipeline to settle before the engines latch the byte
                 * counts on the launch edge. */
                if (prime_cnt == 2'd1) begin
                    launch    <= 1'b1;
                    armed     <= 1'b0;
                    state     <= ST_RUN;
                end else begin
                    prime_cnt <= prime_cnt + 2'd1;
                end
            end

            ST_RUN: begin
                launch      <= 1'b0;
                cycle_count <= cycle_count + 64'd1;

                if (abort && !aborted) begin
                    aborted    <= 1'b1;
                    error      <= 1'b1;
                    error_code <= 32'd1;      /* aborted */
                end

                if (!armed) begin
                    armed <= 1'b1;
                end else if (rd_done_r && !ldr_mode &&
                             (res_rd_done || !has_residual)
                             && (wr_done_r || !has_output) && dp_done) begin
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


