/*
 * Model parameter loader for one InstanceNorm layer.
 *
 * Reads the pre-derived 32-byte records that tools/gen_style_net_scheduler.py
 * writes into the model blob and unpacks them into the core's parameter ports:
 *
 *     +0   int64   s2_q48        -> s2_q48_flat[64*ch +: 64]
 *     +8   int64   sg_q32        -> sg_q32_flat[64*ch +: 64]
 *     +16  int64   beta_q32      -> beta_q32_flat[64*ch +: 64]
 *     +24  uint32  inv_n_q32     -> inv_n_q32
 *     +28  uint32  pad
 *
 * The records are 32 bytes wide, which is exactly the 256-bit pixel beat, so
 * axi4_pixel_read is reused unchanged with pixel_bytes = 32.
 *
 * op = CONV_TANH (4) has no InstanceNorm at all, so its two "norm" address
 * slots carry the output head's tables instead (HANDOFF_ACCEL 9.41):
 *
 *     base_addr       (cfg_gamma_base) -> the 24-bit Q8.16 tanh LUT, streamed
 *                       one little-endian u32 per 4-byte pixel into
 *                       lut_waddr/lut_wdata (entries 0..4096; entry 4096 is a
 *                       neighbour only, see style_net_core's LUT store)
 *     head_param_addr (cfg_beta_base)  -> the head's per-channel affine
 *                       constants {i64 scale_q32, i64 bias_q32}, unpacked into
 *                       the norm parameter store (nothing else uses it on such
 *                       a pass) so the core reads them over p_s2 / p_sg
 *
 * do_tanh = 0 skips the two head phases, leaving every existing pass
 * bit-identical; the quant records are read in both cases.
 *
 * The parameter store is a BLOCK RAM (style_param_store, 32 x 256b = 13 RAM10)
 * and not the three distributed flop arrays it used to be.  "distributed" was
 * the right call when RAM10 sat at 250/256, but the arrays cost ~4096 flops
 * plus two 32:1 read muxes (~1.3k LUT) and the XLR array is now the binding
 * constraint (HANDOFF_ACCEL 9.43).  The read is still a single registered read
 * (the RAM's own output register), so the core's nrm_settle timing and every
 * bit of behaviour are unchanged -- only the storage moves.
 */
module style_param_loader #(
    parameter integer ADDR_W  = 32,
    parameter integer DATA_W  = 128,
    parameter integer MAX_CH  = 32,
    parameter integer MAX_IC  = 32
) (
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    start,
    input  wire [ADDR_W-1:0]       base_addr,
    input  wire [7:0]              channels,
    input  wire [ADDR_W-1:0]       quant_in_addr,
    input  wire [ADDR_W-1:0]       quant_out_addr,
    /* residual branch (op = CONV_RESIDUAL): a 16-byte record carrying
     * { u64 scale_q32, i8 zero_point } that dequantises the residual tensor */
    input  wire                    do_residual,
    input  wire [ADDR_W-1:0]       res_quant_addr,
    input  wire [ADDR_W-1:0]       weight_addr,
    input  wire [7:0]              ic,
    /* op = CONV_TANH: load the tanh output head (see the header comment) */
    input  wire                    do_tanh,
    input  wire [ADDR_W-1:0]       head_param_addr,
    output reg  [12:0]             lut_waddr,   /* 4096 selects the neighbour entry */
    output reg  [23:0]             lut_wdata,
    output reg                     lut_we,
    output reg                     busy,
    output reg                     done,

    /* input quantisation point (quant_in_addr) */
    output reg  signed [8:0]       zp_in,
    /* output quantisation point (quant_out_addr) */
    output reg  [63:0]             q_scale_recip_q48,
    output reg  signed [7:0]       q_zero_point,
    output reg  signed [63:0]      res_scale_q32,
    output reg  signed [7:0]       res_zp,

    /* InstanceNorm parameters, addressed one channel at a time.  They used to
     * be three 64*MAX_CH flat busses held in flops (6144 FFs at MAX_CH=32, plus
     * the core's read mux); a RAM plus a registered read port is what makes the
     * IC=16/OC=32 instantiation fit the Ti60 (HANDOFF_ACCEL 9.14 section nine). */
    input  wire [$clog2(MAX_CH)-1:0] pr_addr,
    output wire signed [63:0]      pr_s2,
    output wire signed [63:0]      pr_sg,
    output wire signed [63:0]      pr_beta,
    output reg  [31:0]             inv_n_q32,

    /* Current-layer weight BRAM write port.  One word is 32 flat bytes of one
     * OC's IC*9-byte filter, addressed {oc, word} (word j = bytes 32j..32j+31).
     * Lanes a partial word never wrote stay zero. */
    output reg  [$clog2(MAX_CH)+4-1:0] w_waddr,   /* {oc, word slot} */
    output reg  [255:0]            w_wdata,       /* 32 flat bytes of the filter */
    output reg                     w_we,

    /* Bring-up visibility: the FSM state is surfaced through the APB debug
     * register 0x84 in style_accel_top, so a stuck pass can be located with a
     * plain register read instead of competing for the single JTAG chain. */
    output wire [3:0]              dbg_state,

    /* 2026-10-15: the reader itself now lives in style_net_axi_master and is borrowed
     * by this loader; the top's loader mode serializes them exactly like the old
     * sel_loader mux did.  The loader only presents a request and takes the stream. */
    output wire                  ldr_launch,
    output wire [ADDR_W-1:0]     ldr_base,
    output wire [31:0]           ldr_total,
    output wire [15:0]           ldr_pixel_bytes,
    output wire                  ldr_ready,
    input  wire [255:0]          ldr_pixel,
    input  wire                  ldr_valid,
    input  wire                  ldr_done
);

    localparam integer ST_IDLE   = 4'd0;
    localparam integer ST_WLOAD  = 4'd1;
    localparam integer ST_WPACK  = 4'd2;
    localparam integer ST_WWRITE = 4'd3;
    localparam integer ST_WDRAIN = 4'd4;
    localparam integer ST_NORM   = 4'd5;
    localparam integer ST_NWAIT  = 4'd6;
    localparam integer ST_QIN    = 4'd7;
    localparam integer ST_IWAIT  = 4'd8;
    localparam integer ST_QOUT   = 4'd9;
    localparam integer ST_OWAIT  = 4'd10;
    localparam integer ST_QRES   = 4'd11;
    localparam integer ST_RWAIT  = 4'd12;
    localparam integer ST_TLUT   = 4'd13;   /* stream the tanh LUT        */
    localparam integer ST_LWAIT  = 4'd14;   /* drain it, then head params */
    localparam integer ST_THD    = 4'd15;   /* tanh head affine constants */

    /* op=4 head sizes, from sw/generated/style_net_pass_table.h:
     * STYLE_NET_TANH_LUT_BYTES 16400 (4100 u32 entries, 4098 live + 2 pad) and
     * STYLE_NET_HEAD_PARAM_CHANNELS 3 records of 16 bytes. */
    localparam [31:0] TANH_LUT_BYTES  = 32'd16400;
    localparam [31:0] TANH_LUT_PIXELS = 32'd4100;
    localparam [12:0] TANH_LUT_LAST   = 13'd4096;

    /* Parameter store: one 32-byte record per output channel, in a block RAM.
     * Layout matches the blob record exactly, so the read slices below are the
     * same slices the distributed arrays used: +0 s2_q48, +8 sg_q32,
     * +16 beta_q32, +24 inv_n_q32.  An op=4 pass stores the tanh head's
     * {scale_q32, bias_q32} in the +0/+8 fields instead. */
    reg          prm_we;
    reg  [$clog2(MAX_CH)-1:0] prm_waddr;
    reg  [255:0] prm_wdata;
    wire [255:0] prm_rdata;

    style_param_store #(.MAX_CH(MAX_CH)) u_prm (
        .clk(clk), .we(prm_we), .waddr(prm_waddr), .wdata(prm_wdata),
        .raddr(pr_addr), .rdata(prm_rdata)
    );

    assign pr_s2   = $signed(prm_rdata[63:0]);
    assign pr_sg   = $signed(prm_rdata[127:64]);
    assign pr_beta = $signed(prm_rdata[191:128]);

    reg [3:0]  state;
    reg        launch;
    reg [7:0]  ch;
    reg [12:0] lut_idx;      /* tanh LUT entry counter (0..4099)  */
    reg [7:0]  hp_ch;        /* tanh head record counter          */
    reg [ADDR_W-1:0] rd_base;
    reg [31:0] rd_total;
    reg [15:0] rd_pixel_bytes;
    reg [31:0] beats_left;
    reg [15:0] w_pack_cnt;
    reg [15:0] w_word_idx;
    reg [31:0] w_bytes_left;
    reg [255:0] w_word;
    reg [3:0]   w_woff;      /* word slot of the write in flight */
    reg         w_last;      /* the write in flight ends this OC   */
    reg [127:0] w_beat;
    reg [4:0]   w_beat_bytes_left;
    reg [4:0]   w_beat_byte_idx;

    /* Aliases: stream and phase-done now come from the borrowed reader. */
    wire [255:0] rd_pixel = ldr_pixel;
    wire         rd_valid = ldr_valid;
    wire         rd_done  = ldr_done;

    wire [31:0] w_ic_bytes = {24'd0, ic} * 32'd9;
    wire [31:0] w_total_bytes = {24'd0, channels} * w_ic_bytes;
    wire [31:0] w_total_padded = (w_total_bytes + 32'd15) & ~32'd15;

    /* Weight reads are consumed one byte per beat and assembled into one
     * MAX_IC*9-byte word per OC.  The other phases use their existing
     * record widths.
     *
     * m_ready must ALSO cover the four "waiting for rd_done" states: the
     * reader raises done only once m_valid has been drained, so if it is
     * still holding a beat when the loader stops consuming, both sides wait
     * forever.  Draining that leftover beat in the wait states is harmless --
     * the phase is already finished.
     *
     * The packing states deliberately stay at 0: they are still consuming
     * the beat latched in ST_WLOAD, and asserting m_ready there would let
     * the reader run ahead and drop beats.
     */
    wire rd_ready_w = (state == ST_WLOAD)  || (state == ST_NORM) ||
                      (state == ST_QIN)    || (state == ST_QOUT) ||
                      (state == ST_WDRAIN) || (state == ST_NWAIT) ||
                      (state == ST_IWAIT)  || (state == ST_OWAIT) ||
                      (state == ST_QRES)   || (state == ST_RWAIT) ||
                      (state == ST_TLUT)   || (state == ST_LWAIT) ||
                      (state == ST_THD);

    /* Borrowed-reader request (same signals the local reader used to take). */
    assign ldr_launch      = launch;
    assign ldr_base        = rd_base;
    assign ldr_total       = rd_total;
    assign ldr_pixel_bytes = rd_pixel_bytes;
    assign ldr_ready       = rd_ready_w;

    integer n;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            launch       <= 1'b0;
            busy         <= 1'b0;
            done         <= 1'b0;
            ch           <= 8'd0;
            beats_left   <= 32'd0;
            rd_base      <= {ADDR_W{1'b0}};
            rd_total     <= 32'd0;
            rd_pixel_bytes <= 16'd32;
            zp_in        <= 9'sd0;
            q_scale_recip_q48 <= 64'd0;
            q_zero_point <= 8'sd0;
            res_scale_q32 <= 64'sd0;
            res_zp        <= 8'sd0;
            inv_n_q32    <= 32'd0;
            lut_idx      <= 13'd0;
            hp_ch        <= 8'd0;
            lut_waddr    <= 13'd0;
            lut_wdata    <= 24'd0;
            lut_we       <= 1'b0;
            w_waddr      <= { ($clog2(MAX_CH)+4){1'b0} };
            w_wdata      <= 256'd0;
            w_we         <= 1'b0;
            w_woff       <= 4'd0;
            w_last       <= 1'b0;
            w_pack_cnt   <= 16'd0;
            w_word_idx   <= 16'd0;
            w_bytes_left <= 32'd0;
            w_word       <= 256'd0;
            w_beat       <= 128'd0;
            w_beat_bytes_left <= 5'd0;
            w_beat_byte_idx   <= 5'd0;
            prm_we       <= 1'b0;
            prm_waddr    <= { $clog2(MAX_CH){1'b0} };
            prm_wdata    <= 256'd0;
        end else begin
            launch <= 1'b0;
            w_we   <= 1'b0;
            lut_we <= 1'b0;
            prm_we <= 1'b0;

            /* The parameter store's own output register IS the one-cycle read
             * the core samples (nrm_settle); nothing to do here. */

            case (state)
            ST_IDLE: begin
                if (start) begin
                    busy           <= 1'b1;
                    done           <= 1'b0;
                    ch             <= 8'd0;
                    rd_base        <= weight_addr;
                    rd_total       <= w_total_padded;
                    rd_pixel_bytes <= 16'd16;
                    w_pack_cnt     <= 16'd0;
                    w_word_idx     <= 16'd0;
                    w_woff         <= 4'd0;
                    w_last         <= 1'b0;
                    w_bytes_left   <= w_total_bytes;
                    w_word         <= 256'd0;
                    w_beat         <= 128'd0;
                    w_beat_bytes_left <= 5'd0;
                    w_beat_byte_idx   <= 5'd0;
                    launch         <= 1'b1;
                    state          <= ST_WLOAD;
                end
            end

            /* Latch one 16-byte AXI pixel, then unpack it one byte at a time. */
            ST_WLOAD: begin
                if (rd_valid) begin
                    w_beat <= rd_pixel[127:0];
                    w_beat_bytes_left <= (w_bytes_left >= 32'd16) ? 5'd16 :
                                                                  w_bytes_left[4:0];
                    w_beat_byte_idx <= 5'd0;
                    state <= ST_WPACK;
                end
            end

            /* Assemble one OC's IC*9 bytes, then write one BRAM word. */
            /* Flat packing: byte b of this OC lands in word b[8:5], lane b[4:0], so
             * the filter stays byte-contiguous in the blob's own (ic*9+tap) order
             * and the BRAM address is just the concatenation {oc, word}.  A word is
             * written as soon as its 32nd byte lands, plus once more (possibly
             * partial) at the end of the OC.  w_word is cleared after each write so
             * the lanes a partial word never wrote stay 0 instead of holding the
             * previous word's bytes. */
            ST_WPACK: begin
                w_word[8*w_pack_cnt[4:0] +: 8] <= w_beat[8*w_beat_byte_idx +: 8];
                w_bytes_left       <= w_bytes_left - 32'd1;
                w_beat_bytes_left  <= w_beat_bytes_left - 5'd1;
                w_woff             <= w_pack_cnt[8:5];
                if (w_pack_cnt == w_ic_bytes - 32'd1) begin
                    w_pack_cnt <= 16'd0;
                    w_last     <= 1'b1;
                    state      <= ST_WWRITE;
                end else if (w_pack_cnt[4:0] == 5'd31) begin
                    w_pack_cnt <= w_pack_cnt + 16'd1;
                    w_last     <= 1'b0;
                    state      <= ST_WWRITE;
                end else begin
                    w_pack_cnt <= w_pack_cnt + 16'd1;
                    if (w_beat_bytes_left == 5'd1) begin
                        state <= ST_WLOAD;
                    end else begin
                        w_beat_byte_idx <= w_beat_byte_idx + 5'd1;
                    end
                end
            end

            ST_WWRITE: begin
                w_waddr <= {w_word_idx[$clog2(MAX_CH)-1:0], w_woff};
                w_wdata <= w_word;
                w_word  <= 256'd0;
                w_we    <= 1'b1;
                if (w_last) begin
                    w_word_idx <= w_word_idx + 16'd1;
                    w_last     <= 1'b0;
                    if (w_bytes_left == 32'd0)
                        state <= ST_WDRAIN;
                    else if (w_beat_bytes_left == 5'd0)
                        state <= ST_WLOAD;
                    else begin
                        w_beat_byte_idx <= w_beat_byte_idx + 5'd1;
                        state <= ST_WPACK;
                    end
                end else if (w_beat_bytes_left == 5'd0)
                    state <= ST_WLOAD;
                else begin
                    w_beat_byte_idx <= w_beat_byte_idx + 5'd1;
                    state <= ST_WPACK;
                end
            end

            ST_WDRAIN: begin
                if (rd_done) begin
                    rd_base <= base_addr;
                    launch  <= 1'b1;
                    if (do_tanh) begin
                        /* base_addr is the tanh LUT, not norm records */
                        rd_total       <= TANH_LUT_BYTES;
                        rd_pixel_bytes <= 16'd4;
                        beats_left     <= TANH_LUT_PIXELS;
                        lut_idx        <= 13'd0;
                        state          <= ST_TLUT;
                    end else begin
                        rd_total       <= {19'd0, channels, 5'b0};
                        rd_pixel_bytes <= 16'd32;
                        beats_left     <= {24'd0, channels};
                        state          <= ST_NORM;
                    end
                end
            end

            /* one 32-byte record per output channel */
            ST_NORM: begin
                if (rd_valid) begin
                    prm_we    <= 1'b1;
                    prm_waddr <= ch[$clog2(MAX_CH)-1:0];
                    prm_wdata <= rd_pixel;          /* stored verbatim */
                    inv_n_q32                  <= rd_pixel[223:192];
                    ch         <= ch + 8'd1;
                    beats_left <= beats_left - 32'd1;
                    if (beats_left == 32'd1) begin
                        state <= ST_NWAIT;   /* let the reader return to IDLE */
                    end
                end
            end

            ST_NWAIT: begin
                if (rd_done) begin
                    rd_base        <= quant_in_addr;
                    rd_total       <= 32'd16;
                    rd_pixel_bytes <= 16'd16;
                    beats_left     <= 32'd1;
                    launch         <= 1'b1;
                    state          <= ST_QIN;
                end
            end

            /* quant_in record: +0 f32 scale, +4 i32 zero_point */
            ST_QIN: begin
                if (rd_valid) begin
                    zp_in <= {{1{rd_pixel[39]}}, rd_pixel[39:32]};
                    state <= ST_IWAIT;
                end
            end

            ST_IWAIT: begin
                if (rd_done) begin
                    rd_base  <= quant_out_addr;
                    launch   <= 1'b1;
                    state    <= ST_QOUT;
                end
            end

            /* quant_out record: +4 i32 zero_point, +8 u64 recip_q48 */
            ST_QOUT: begin
                if (rd_valid) begin
                    q_zero_point      <= rd_pixel[39:32];
                    q_scale_recip_q48 <= rd_pixel[127:64];
                    state             <= ST_OWAIT;
                end
            end

            ST_OWAIT: begin
                if (rd_done) begin
                    if (do_residual) begin
                        rd_base <= res_quant_addr;
                        launch  <= 1'b1;
                        state   <= ST_QRES;
                    end else begin
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= ST_IDLE;
                    end
                end
            end

            /* residual dequant record: +0 u64 scale_q32, +8 i8 zero_point */
            ST_QRES: begin
                if (rd_valid) begin
                    res_scale_q32 <= rd_pixel[63:0];
                    res_zp        <= rd_pixel[71:64];
                    state         <= ST_RWAIT;
                end
            end

            ST_RWAIT: begin
                if (rd_done) begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= ST_IDLE;
                end
            end

            /* op=4: one 4-byte pixel per LUT entry, so the whole table streams
             * in with a single write port.  Entry 4096 goes to the core's
             * neighbour register (it is only ever read as the upper
             * interpolation endpoint); 4097..4099 are the generator's pad
             * entries and are dropped. */
            ST_TLUT: begin
                if (rd_valid) begin
                    if (lut_idx <= TANH_LUT_LAST) begin
                        lut_we    <= 1'b1;
                        lut_waddr <= lut_idx;
                        lut_wdata <= rd_pixel[23:0];
                    end
                    lut_idx    <= lut_idx + 13'd1;
                    beats_left <= beats_left - 32'd1;
                    if (beats_left == 32'd1)
                        state <= ST_LWAIT;
                end
            end

            ST_LWAIT: begin
                if (rd_done) begin
                    rd_base        <= head_param_addr;
                    rd_total       <= {27'd0, channels, 4'b0}; /* channels x 16 B */
                    rd_pixel_bytes <= 16'd16;
                    beats_left     <= {24'd0, channels};
                    hp_ch          <= 8'd0;
                    launch         <= 1'b1;
                    state          <= ST_THD;
                end
            end

            /* one 16-byte record per output channel: +0 i64 scale_q32,
             * +8 i64 bias_q32.  They land in the norm parameter store, which
             * an op=4 pass does not otherwise use, so the core reads them
             * through the existing p_s2 / p_sg port. */
            ST_THD: begin
                if (rd_valid) begin
                    /* the head's {scale_q32, bias_q32} go in the s2 / sg fields
                     * so the core keeps reading them over p_s2 / p_sg */
                    prm_we    <= 1'b1;
                    prm_waddr <= hp_ch[$clog2(MAX_CH)-1:0];
                    prm_wdata <= {128'd0, rd_pixel[127:64], rd_pixel[63:0]};
                    hp_ch      <= hp_ch + 8'd1;
                    beats_left <= beats_left - 32'd1;
                    if (beats_left == 32'd1)
                        /* An op=4 pass still needs the quant records: the stage
                         * de-zero-points its INPUT with zp_in, so skipping the
                         * ST_QIN phase leaves zp_in at its reset value 0 and
                         * shifts every accumulator by -128*sum(w) -- which is
                         * exactly what the board did when pass 18 ran standalone
                         * (HANDOFF_ACCEL 9.45).  Join the normal chain at
                         * ST_NWAIT, which sets up the quant_in read; the
                         * quant_out record it then fetches is unused by the tanh
                         * head, and ST_OWAIT ends the pass as usual. */
                        state <= ST_NWAIT;
                end
            end

            default: state <= ST_IDLE;
            endcase
        end
    end

assign dbg_state = state;

endmodule


/* ==========================================================================
 * style_param_store -- the InstanceNorm parameter store, 32 x 256 bits
 * (one 32-byte blob record per output channel) = 13 RAM10 (HANDOFF_ACCEL 9.43).
 *
 * Keep this the plain write + registered read pair: any qualification of the
 * read data (a mux, a comparison) makes Efinity fall back to "logic memory" and
 * cost thousands of flops instead of 13 block RAMs (HANDOFF_ACCEL 9.42).
 * ========================================================================== */
module style_param_store #(
    parameter integer MAX_CH = 32
) (
    input  wire                       clk,
    input  wire                       we,
    input  wire [$clog2(MAX_CH)-1:0]  waddr,
    input  wire [255:0]               wdata,
    input  wire [$clog2(MAX_CH)-1:0]  raddr,
    output reg  [255:0]               rdata
);

    (* ram_style = "block", syn_ram_style = "block" *) reg [255:0] mem [0:MAX_CH-1];

    always @(posedge clk)
        if (we)
            mem[waddr] <= wdata;

    always @(posedge clk)
        rdata <= mem[raddr];

endmodule
