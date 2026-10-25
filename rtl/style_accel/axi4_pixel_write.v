/*
 * Channel-interleaved pixel stream -> AXI4 full-width writes.
 *
 * Pixels are packed into 16-byte W beats and accumulated in a bounded register
 * FIFO.  An AW is issued only after a complete burst has been buffered (or the
 * final partial burst is known to have its last input beat).  This keeps the
 * shared interconnect from holding a long write transaction open while the
 * compute datapath slowly trickles W beats; that failure mode previously wedged
 * the CPU and accelerator reads.  Each AW therefore represents a real
 * multi-beat AXI burst and receives exactly one BRESP.
 */
module axi4_pixel_write #(
    parameter integer ADDR_W    = 32,
    parameter integer DATA_W    = 128,
    parameter integer MAX_BURST = 8
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                start,
    input  wire [ADDR_W-1:0]   base_addr,
    input  wire [31:0]         total_bytes,
    input  wire [15:0]         pixel_bytes,
    output reg                 busy,
    output reg                 done,
    input  wire [255:0]        s_pixel,
    input  wire                s_valid,
    output wire                s_ready,
    output reg  [ADDR_W-1:0]   m_axi_awaddr,
    output reg  [7:0]          m_axi_awlen,
    output reg  [2:0]          m_axi_awsize,
    output reg  [1:0]          m_axi_awburst,
    output reg                 m_axi_awvalid,
    input  wire                m_axi_awready,
    output reg  [DATA_W-1:0]   m_axi_wdata,
    output reg  [(DATA_W/8)-1:0] m_axi_wstrb,
    output reg                 m_axi_wlast,
    output reg                 m_axi_wvalid,
    input  wire                m_axi_wready,
    input  wire [1:0]          m_axi_bresp,
    input  wire                m_axi_bvalid,
    output wire                m_axi_bready
);
    localparam integer ST_IDLE = 2'd0;
    localparam integer ST_RUN  = 2'd1;

    reg [1:0]   state;
    reg [31:0]  cur_addr;
    reg [31:0]  remaining_enq;
    reg [15:0]  pixel_bytes_r;
    reg         wide;
    reg         wide_remain;
    reg [127:0] wide_hi;
    reg [4:0]   pack_bytes;
    reg [127:0] pack_reg;
    reg [127:0] pack_next;
    reg         beat_valid;
    reg [127:0] beat_data;

    reg [DATA_W-1:0] wbuf [0:MAX_BURST-1];
    reg [31:0]       buf_count;
    reg              burst_active;
    reg [31:0]       burst_remaining;
    reg [31:0]       aw_beats_r;
    reg [31:0]       b_pending;
    reg              bresp_error;
    integer          bi;

    wire [31:0] bytes_to_4k = 32'd4096 - {20'd0, cur_addr[11:0]};
    wire [31:0] beats_fit   = bytes_to_4k >> 4;
    wire [31:0] burst_n     = (buf_count > beats_fit) ? beats_fit : buf_count;
    wire        tail_ready  = (remaining_enq == 0) && (buf_count != 0);
    wire        can_issue   = (state == ST_RUN) && !burst_active &&
                              (b_pending == 0) && !m_axi_awvalid &&
                              ((buf_count == MAX_BURST) || tail_ready) &&
                              (burst_n != 0);
    wire        enq_valid   = (state == ST_RUN) && beat_valid &&
                              (buf_count < MAX_BURST);
    wire        pop_valid   = (state == ST_RUN) && burst_active &&
                              m_axi_wvalid && m_axi_wready;

    /* A wide pixel can start with one FIFO slot free: its upper 128 bits are
     * parked in wide_hi/beat_valid and enqueued after the first half.  Requiring
     * two free slots deadlocks when a 4 KB split leaves buf_count == MAX_BURST-1. */
    assign s_ready = (state == ST_RUN) && !beat_valid &&
                     (buf_count < MAX_BURST);
    assign m_axi_bready = busy;

    always @* begin
        pack_next = pack_reg;
        case (pixel_bytes_r)
            16'd4: begin
                case (pack_bytes)
                    5'd0:  pack_next[31:0]   = s_pixel[31:0];
                    5'd4:  pack_next[63:32]  = s_pixel[31:0];
                    5'd8:  pack_next[95:64]  = s_pixel[31:0];
                    default: pack_next[127:96] = s_pixel[31:0];
                endcase
            end
            16'd8: begin
                if (pack_bytes == 5'd0) pack_next[63:0] = s_pixel[63:0];
                else                   pack_next[127:64] = s_pixel[63:0];
            end
            default: pack_next = s_pixel[127:0];
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            cur_addr <= {ADDR_W{1'b0}};
            remaining_enq <= 32'd0;
            pixel_bytes_r <= 16'd0;
            wide <= 1'b0;
            wide_remain <= 1'b0;
            wide_hi <= 128'd0;
            pack_bytes <= 5'd0;
            pack_reg <= 128'd0;
            beat_valid <= 1'b0;
            beat_data <= 128'd0;
            buf_count <= 32'd0;
            burst_active <= 1'b0;
            burst_remaining <= 32'd0;
            aw_beats_r <= 32'd0;
            b_pending <= 32'd0;
            bresp_error <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            m_axi_awaddr <= {ADDR_W{1'b0}};
            m_axi_awlen <= 8'd0;
            m_axi_awsize <= 3'd4;
            m_axi_awburst <= 2'b01;
            m_axi_awvalid <= 1'b0;
            m_axi_wdata <= {DATA_W{1'b0}};
            m_axi_wstrb <= {(DATA_W/8){1'b0}};
            m_axi_wlast <= 1'b0;
            m_axi_wvalid <= 1'b0;
        end else begin
            if (m_axi_bvalid && m_axi_bready) begin
                if (b_pending != 0) b_pending <= b_pending - 32'd1;
                if (m_axi_bresp != 2'b00) bresp_error <= 1'b1;
            end

            case (state)
            ST_IDLE: begin
                m_axi_awvalid <= 1'b0;
                m_axi_wvalid  <= 1'b0;
                m_axi_wlast   <= 1'b0;
                if (start) begin
                    cur_addr <= base_addr;
                    remaining_enq <= total_bytes >> 4;
                    pixel_bytes_r <= pixel_bytes;
                    wide <= (pixel_bytes == 16'd32);
                    wide_remain <= 1'b0;
                    wide_hi <= 128'd0;
                    pack_bytes <= 5'd0;
                    pack_reg <= 128'd0;
                    beat_valid <= 1'b0;
                    beat_data <= 128'd0;
                    buf_count <= 32'd0;
                    burst_active <= 1'b0;
                    burst_remaining <= 32'd0;
                    aw_beats_r <= 32'd0;
                    b_pending <= 32'd0;
                    bresp_error <= 1'b0;
                    busy <= 1'b1;
                    done <= 1'b0;
                    m_axi_awsize <= 3'd4;
                    m_axi_awburst <= 2'b01;
                    m_axi_awlen <= 8'd0;
                    state <= ST_RUN;
                end
            end

            ST_RUN: begin
                /* Build one 16-byte beat at a time from the pixel stream. */
                if (!beat_valid && s_valid && s_ready) begin
                    if (wide) begin
                        beat_data <= s_pixel[127:0];
                        wide_hi   <= s_pixel[255:128];
                        beat_valid <= 1'b1;
                        wide_remain <= 1'b1;
                    end else begin
                        pack_reg <= pack_next;
                        if ((pack_bytes + pixel_bytes_r) >= 16) begin
                            beat_data <= pack_next;
                            beat_valid <= 1'b1;
                            pack_bytes <= 5'd0;
                        end else begin
                            pack_bytes <= pack_bytes + pixel_bytes_r[4:0];
                        end
                    end
                end

                /* Fully buffered beats may be appended while a burst drains. */
                if (enq_valid) begin
                    beat_valid <= 1'b0;
                    remaining_enq <= remaining_enq - 32'd1;
                    if (wide_remain) begin
                        beat_data <= wide_hi;
                        wide_remain <= 1'b0;
                        beat_valid <= 1'b1;
                    end
                end

                /* Shift-register FIFO: one push and/or one pop per cycle. */
                if (enq_valid && pop_valid) begin
                    for (bi = 0; bi < MAX_BURST-1; bi = bi + 1)
                        wbuf[bi] <= wbuf[bi+1];
                    wbuf[buf_count - 1] <= beat_data;
                end else if (enq_valid) begin
                    wbuf[buf_count] <= beat_data;
                    buf_count <= buf_count + 32'd1;
                end else if (pop_valid) begin
                    for (bi = 0; bi < MAX_BURST-1; bi = bi + 1)
                        wbuf[bi] <= wbuf[bi+1];
                    buf_count <= buf_count - 32'd1;
                end

                /* Issue a full buffered burst, or a final known tail. */
                if (can_issue) begin
                    m_axi_awaddr <= cur_addr;
                    m_axi_awlen <= burst_n - 32'd1;
                    aw_beats_r <= burst_n;
                    m_axi_awvalid <= 1'b1;
                end
                if (m_axi_awvalid && m_axi_awready) begin
                    m_axi_awvalid <= 1'b0;
                    burst_remaining <= aw_beats_r;
                    burst_active <= 1'b1;
                end

                /* W beats are available immediately because the whole burst
                 * was buffered before AW was issued. */
                if (burst_active && !m_axi_wvalid && (burst_remaining != 0)) begin
                    m_axi_wdata <= wbuf[0];
                    m_axi_wstrb <= {(DATA_W/8){1'b1}};
                    m_axi_wlast <= (burst_remaining == 1);
                    m_axi_wvalid <= 1'b1;
                end
                if (m_axi_wvalid && m_axi_wready) begin
                    m_axi_wvalid <= 1'b0;
                    m_axi_wlast  <= 1'b0;
                    cur_addr <= cur_addr + 32'd16;
                    burst_remaining <= burst_remaining - 32'd1;
                    if (burst_remaining == 1) begin
                        burst_active <= 1'b0;
                        b_pending <= b_pending + 32'd1;
                    end
                end

                if ((remaining_enq == 0) && !beat_valid &&
                    (buf_count == 0) && !burst_active && !m_axi_awvalid &&
                    !m_axi_wvalid && (b_pending == 0)) begin
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
