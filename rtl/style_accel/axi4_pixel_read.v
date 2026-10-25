/*
 * AXI4 full-width read -> channel-interleaved pixel stream.
 *
 * Every AR uses arsize=4 (16 bytes).  Each 128-bit R beat occupies exactly one
 * FIFO entry; 4/8/16 B pixels are unpacked directly, while a 32 B pixel is
 * assembled from two consecutive entries.  Keeping the FIFO 128 bits wide
 * halves its block-RAM footprint versus storing pre-combined 256-bit pixels.
 *
 * The FIFO is sized to MAX_BURST entries.  An AR is raised only when the whole
 * burst fits, so m_axi_rready never has to deassert with beats outstanding.
 */
module axi4_pixel_read #(
    parameter integer ADDR_W    = 32,
    parameter integer DATA_W    = 128,
    parameter integer MAX_BURST = 64
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                start,
    input  wire [ADDR_W-1:0]   base_addr,
    input  wire [31:0]         total_bytes,
    input  wire [15:0]         pixel_bytes,
    output reg                 busy,
    output reg                 done,
    output wire [255:0]        m_pixel,
    output wire                m_valid,
    input  wire                m_ready,
    output reg  [ADDR_W-1:0]   m_axi_araddr,
    output reg  [7:0]          m_axi_arlen,
    output reg  [2:0]          m_axi_arsize,
    output reg  [1:0]          m_axi_arburst,
    output reg                 m_axi_arvalid,
    input  wire                m_axi_arready,
    input  wire [DATA_W-1:0]   m_axi_rdata,
    input  wire [1:0]          m_axi_rresp,
    input  wire                m_axi_rlast,
    input  wire                m_axi_rvalid,
    output wire                m_axi_rready,
    output wire [2:0]          dbg_state,
    output wire                dbg_m_valid,
    output wire                dbg_read_done
);
    localparam integer ST_IDLE  = 3'd0;
    localparam integer ST_ISSUE = 3'd1;
    localparam integer ST_R     = 3'd2;
    localparam integer ST_DRAIN = 3'd3;
    localparam integer FW = (MAX_BURST <= 1) ? 1 : $clog2(MAX_BURST);
    localparam integer CW = FW + 1;

    reg [2:0]   state;
    reg [31:0]  cur_addr;
    reg [31:0]  beats_left;
    reg [15:0]  pixel_bytes_r;
    reg         wide;
    reg         wide_half;
    reg         read_done;
    reg [DATA_W-1:0] f_mem [0:MAX_BURST-1];
    reg [DATA_W-1:0] f_rd_data;
    reg              rd_valid;
    reg [FW-1:0] f_wr;
    reg [FW-1:0] f_rd;
    reg [CW-1:0] f_cnt;
    reg [255:0] o_pix;
    reg         o_valid;
    reg [1:0]   o_sub_idx;
    reg [2:0]   o_sub_count;

    wire [31:0] bytes_to_4k = 32'd4096 - {20'd0, cur_addr[11:0]};
    wire [31:0] beats_fit   = bytes_to_4k >> 4;
    wire [31:0] cap_this    = (beats_left > MAX_BURST) ? MAX_BURST : beats_left;
    wire [31:0] beats_this  = (cap_this > beats_fit) ? beats_fit : cap_this;
    wire [CW-1:0] room = MAX_BURST[CW-1:0] - f_cnt;
    wire [FW-1:0] f_rd_next = (f_rd == MAX_BURST-1) ? {FW{1'b0}} : (f_rd + 1'b1);
    wire beat = (state == ST_R) && m_axi_rvalid && m_axi_rready;
    wire push = beat;
    wire pop  = o_valid && m_ready;
    wire last_sub = ({1'b0, o_sub_idx} + 3'd1 >= o_sub_count);

    wire normal_pop  = !wide && rd_valid &&
                       (!o_valid || (pop && last_sub));
    wire wide_start  = wide && rd_valid && !o_valid && !wide_half;
    wire wide_finish = wide && rd_valid && !o_valid &&  wide_half;
    wire pop_entry   = normal_pop || wide_start || wide_finish;
    wire [FW-1:0] f_rd_look = pop_entry ? f_rd_next : f_rd;

    assign m_axi_rready = (state == ST_R) && (room != 0);
    assign m_valid      = o_valid;
    assign dbg_state     = state;
    assign dbg_m_valid   = o_valid;
    assign dbg_read_done = read_done;

    function [2:0] sub_count;
        input [15:0] pbytes;
        begin
            case (pbytes)
                16'd4:   sub_count = 3'd4;
                16'd8:   sub_count = 3'd2;
                default: sub_count = 3'd1;
            endcase
        end
    endfunction

    reg [255:0] m_pixel_r;
    always @* begin
        m_pixel_r = 256'd0;
        case (pixel_bytes_r)
            16'd4: begin
                case (o_sub_idx)
                    2'd0: m_pixel_r[31:0]  = o_pix[31:0];
                    2'd1: m_pixel_r[31:0]  = o_pix[63:32];
                    2'd2: m_pixel_r[31:0]  = o_pix[95:64];
                    default: m_pixel_r[31:0] = o_pix[127:96];
                endcase
            end
            16'd8: begin
                if (o_sub_idx[0])
                    m_pixel_r[63:0] = o_pix[127:64];
                else
                    m_pixel_r[63:0] = o_pix[63:0];
            end
            16'd16: m_pixel_r[127:0] = o_pix[127:0];
            default: m_pixel_r = o_pix;
        endcase
    end
    assign m_pixel = m_pixel_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            f_wr <= {FW{1'b0}}; f_rd <= {FW{1'b0}}; f_cnt <= {CW{1'b0}};
            f_rd_data <= {DATA_W{1'b0}};
            rd_valid <= 1'b0;
            o_pix <= 256'd0; o_valid <= 1'b0; o_sub_idx <= 2'd0; o_sub_count <= 3'd1;
            wide_half <= 1'b0;
        end else begin
            f_rd_data <= f_mem[f_rd_look];
            if (start && (state == ST_IDLE)) begin
                wide_half <= 1'b0;
                rd_valid  <= 1'b0;
            end
            if (push) begin
                f_mem[f_wr] <= m_axi_rdata;
                f_wr <= (f_wr == MAX_BURST-1) ? {FW{1'b0}} : (f_wr + 1'b1);
            end

            if (normal_pop) begin
                o_pix[127:0] <= f_rd_data;
                o_pix[255:128] <= 128'd0;
                o_valid <= 1'b1;
                o_sub_idx <= 2'd0;
                o_sub_count <= sub_count(pixel_bytes_r);
                f_rd <= (f_rd == MAX_BURST-1) ? {FW{1'b0}} : (f_rd + 1'b1);
            end else if (wide_start) begin
                o_pix[127:0] <= f_rd_data;
                o_pix[255:128] <= 128'd0;
                wide_half <= 1'b1;
                f_rd <= (f_rd == MAX_BURST-1) ? {FW{1'b0}} : (f_rd + 1'b1);
            end else if (wide_finish) begin
                o_pix[255:128] <= f_rd_data;
                o_valid <= 1'b1;
                o_sub_idx <= 2'd0;
                o_sub_count <= 3'd1;
                wide_half <= 1'b0;
                f_rd <= (f_rd == MAX_BURST-1) ? {FW{1'b0}} : (f_rd + 1'b1);
            end else if (pop) begin
                if (last_sub) o_valid <= 1'b0;
                else o_sub_idx <= o_sub_idx + 2'd1;
            end

            if (pop_entry)
                rd_valid <= (f_cnt > 1);
            else if (f_cnt != 0)
                rd_valid <= 1'b1;
            else
                rd_valid <= 1'b0;

            case ({push, pop_entry})
                2'b10: f_cnt <= f_cnt + 1'b1;
                2'b01: f_cnt <= f_cnt - 1'b1;
                default: f_cnt <= f_cnt;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE; cur_addr <= 32'd0; beats_left <= 32'd0;
            pixel_bytes_r <= 16'd0; wide <= 1'b0; read_done <= 1'b0;
            busy <= 1'b0; done <= 1'b0;
            m_axi_araddr <= {ADDR_W{1'b0}}; m_axi_arlen <= 8'd0;
            m_axi_arsize <= 3'd4; m_axi_arburst <= 2'b01; m_axi_arvalid <= 1'b0;
        end else begin
            case (state)
            ST_IDLE: begin
                m_axi_arvalid <= 1'b0;
                if (start) begin
                    cur_addr <= base_addr; pixel_bytes_r <= pixel_bytes;
                    wide <= (pixel_bytes == 16'd32);
                    read_done <= 1'b0; done <= 1'b0; busy <= 1'b1;
                    m_axi_arsize <= 3'd4; m_axi_arburst <= 2'b01;
                    beats_left <= total_bytes >> 4; state <= ST_ISSUE;
                end
            end
            ST_ISSUE: begin
                if ((beats_left != 0) && (room >= beats_this[CW-1:0])) begin
                    m_axi_araddr <= cur_addr;
                    m_axi_arlen <= (beats_this > 1) ? (beats_this - 1) : 8'd0;
                    m_axi_arvalid <= 1'b1; state <= ST_R;
                end else if (beats_left == 0) begin
                    read_done <= 1'b1; state <= ST_DRAIN;
                end
            end
            ST_R: begin
                if (m_axi_arvalid && m_axi_arready) m_axi_arvalid <= 1'b0;
                if (beat) begin
                    cur_addr <= cur_addr + 32'd16;
                    beats_left <= beats_left - 32'd1;
                    if (m_axi_rlast) begin
                        if (beats_left > 32'd1) state <= ST_ISSUE;
                        else begin read_done <= 1'b1; state <= ST_DRAIN; end
                    end
                end
            end
            ST_DRAIN: begin
                if (read_done && (f_cnt == 0) && !o_valid && !wide_half) begin
                    busy <= 1'b0; done <= 1'b1; state <= ST_IDLE;
                end
            end
            default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
