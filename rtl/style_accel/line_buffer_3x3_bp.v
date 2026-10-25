`timescale 1ns/1ps

module line_ram_sync #(
    parameter integer WIDTH = 640,
    parameter integer DW    = 8
) (
    input  wire                 clk,
    input  wire                 we,
    input  wire [$clog2(WIDTH)-1:0] waddr,
    input  wire signed [DW-1:0] wdata,
    input  wire                 re,
    input  wire [$clog2(WIDTH)-1:0] raddr,
    output reg  signed [DW-1:0] rdata
);

    (* ram_style = "block", syn_ram_style = "block" *) reg signed [DW-1:0] mem [0:WIDTH-1];

    always @(posedge clk)
        if (we)
            mem[waddr] <= wdata;

    always @(posedge clk)
        if (re)
            rdata <= mem[raddr];

endmodule

module line_buffer_3x3_bp #(
    parameter integer WIDTH = 640,
    parameter integer DW    = 8,
    parameter integer STRIDE = 1
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 in_valid,
    input  wire signed [DW-1:0] din,
    output wire                 in_ready,
    output wire                 out_valid,
    input  wire                 out_ready,
    output wire signed [DW-1:0] w00,
    output wire signed [DW-1:0] w01,
    output wire signed [DW-1:0] w02,
    output wire signed [DW-1:0] w10,
    output wire signed [DW-1:0] w11,
    output wire signed [DW-1:0] w12,
    output wire signed [DW-1:0] w20,
    output wire signed [DW-1:0] w21,
    output wire signed [DW-1:0] w22
);

    localparam integer AW = (WIDTH <= 1) ? 1 : $clog2(WIDTH);

    reg [AW-1:0] col;
    reg [31:0]   row;
    reg [1:0]    row_phase;
    reg [1:0]    top_sel_d1;
    reg [1:0]    mid_sel_d1;
    reg          d0_valid;
    reg          d1_valid;

    reg signed [DW-1:0] fifo_w00 [0:2];
    reg signed [DW-1:0] fifo_w01 [0:2];
    reg signed [DW-1:0] fifo_w02 [0:2];
    reg signed [DW-1:0] fifo_w10 [0:2];
    reg signed [DW-1:0] fifo_w11 [0:2];
    reg signed [DW-1:0] fifo_w12 [0:2];
    reg signed [DW-1:0] fifo_w20 [0:2];
    reg signed [DW-1:0] fifo_w21 [0:2];
    reg signed [DW-1:0] fifo_w22 [0:2];
    reg [1:0] fifo_wptr;
    reg [1:0] fifo_rptr;
    reg [2:0] fifo_count;

    reg signed [DW-1:0] top_hist [0:2];
    reg signed [DW-1:0] mid_hist [0:2];
    reg signed [DW-1:0] cur_hist [0:2];
    reg signed [DW-1:0] din_d1;

    wire signed [DW-1:0] rd0, rd1, rd2;
    wire signed [DW-1:0] top_rd = (top_sel_d1 == 2'd0) ? rd0 :
                                  (top_sel_d1 == 2'd1) ? rd1 : rd2;
    wire signed [DW-1:0] mid_rd = (mid_sel_d1 == 2'd0) ? rd0 :
                                  (mid_sel_d1 == 2'd1) ? rd1 : rd2;

    wire [1:0] top_sel  = (row_phase == 2'd0) ? 2'd1 :
                          (row_phase == 2'd1) ? 2'd2 : 2'd0;
    wire [1:0] mid_sel  = (row_phase == 2'd0) ? 2'd2 :
                          (row_phase == 2'd1) ? 2'd0 : 2'd1;

    wire signed [32:0] row_delta = $signed({1'b0, row}) - 33'sd2;
    wire signed [32:0] col_delta = $signed({1'b0, col}) - 33'sd2;

    wire [2:0] pending = fifo_count + (d0_valid ? 3'd1 : 3'd0) +
                         (d1_valid ? 3'd1 : 3'd0);
    assign in_ready = pending < 3'd3;
    assign out_valid = fifo_count != 3'd0;

    wire advance = in_valid && in_ready;
    wire flush   = !in_valid && (d0_valid || d1_valid);
    wire pipe    = advance || flush;
    wire push    = pipe && d1_valid;
    wire pop     = out_valid && out_ready;

    wire window_now = advance && (row >= 2) && (col >= 2) &&
                      ((row_delta % STRIDE) == 0) &&
                      ((col_delta % STRIDE) == 0);

    assign w00 = fifo_w00[fifo_rptr];
    assign w01 = fifo_w01[fifo_rptr];
    assign w02 = fifo_w02[fifo_rptr];
    assign w10 = fifo_w10[fifo_rptr];
    assign w11 = fifo_w11[fifo_rptr];
    assign w12 = fifo_w12[fifo_rptr];
    assign w20 = fifo_w20[fifo_rptr];
    assign w21 = fifo_w21[fifo_rptr];
    assign w22 = fifo_w22[fifo_rptr];

    line_ram_sync #(.WIDTH(WIDTH), .DW(DW)) bank0 (
        .clk(clk),
        .we(advance && (row_phase == 2'd0)), .waddr(col), .wdata(din),
        .re(advance), .raddr(col), .rdata(rd0)
    );
    line_ram_sync #(.WIDTH(WIDTH), .DW(DW)) bank1 (
        .clk(clk),
        .we(advance && (row_phase == 2'd1)), .waddr(col), .wdata(din),
        .re(advance), .raddr(col), .rdata(rd1)
    );
    line_ram_sync #(.WIDTH(WIDTH), .DW(DW)) bank2 (
        .clk(clk),
        .we(advance && (row_phase == 2'd2)), .waddr(col), .wdata(din),
        .re(advance), .raddr(col), .rdata(rd2)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            col         <= {AW{1'b0}};
            row         <= 32'd0;
            row_phase   <= 2'd0;
            top_sel_d1  <= 2'd1;
            mid_sel_d1  <= 2'd2;
            d0_valid    <= 1'b0;
            d1_valid    <= 1'b0;
            din_d1      <= {DW{1'b0}};
            top_hist[0] <= {DW{1'b0}};
            top_hist[1] <= {DW{1'b0}};
            top_hist[2] <= {DW{1'b0}};
            mid_hist[0] <= {DW{1'b0}};
            mid_hist[1] <= {DW{1'b0}};
            mid_hist[2] <= {DW{1'b0}};
            cur_hist[0] <= {DW{1'b0}};
            cur_hist[1] <= {DW{1'b0}};
            cur_hist[2] <= {DW{1'b0}};
            fifo_wptr   <= 2'd0;
            fifo_rptr   <= 2'd0;
            fifo_count  <= 3'd0;
        end else begin
            if (pipe) begin
                if (push) begin
                    fifo_w00[fifo_wptr] <= top_hist[2];
                    fifo_w01[fifo_wptr] <= top_hist[1];
                    fifo_w02[fifo_wptr] <= top_hist[0];
                    fifo_w10[fifo_wptr] <= mid_hist[2];
                    fifo_w11[fifo_wptr] <= mid_hist[1];
                    fifo_w12[fifo_wptr] <= mid_hist[0];
                    fifo_w20[fifo_wptr] <= cur_hist[2];
                    fifo_w21[fifo_wptr] <= cur_hist[1];
                    fifo_w22[fifo_wptr] <= cur_hist[0];
                    fifo_wptr <= (fifo_wptr == 2'd2) ? 2'd0 : (fifo_wptr + 2'd1);
                end
                d0_valid <= window_now;
                d1_valid <= d0_valid;

                top_hist[2] <= top_hist[1];
                top_hist[1] <= top_hist[0];
                top_hist[0] <= top_rd;
                mid_hist[2] <= mid_hist[1];
                mid_hist[1] <= mid_hist[0];
                mid_hist[0] <= mid_rd;
                cur_hist[2] <= cur_hist[1];
                cur_hist[1] <= cur_hist[0];
                cur_hist[0] <= din_d1;
            end
            if (advance) begin
                din_d1 <= din;
                top_sel_d1 <= top_sel;
                mid_sel_d1 <= mid_sel;
                if (col == WIDTH-1) begin
                    col       <= {AW{1'b0}};
                    row       <= row + 32'd1;
                    row_phase <= (row_phase == 2'd2) ? 2'd0 : (row_phase + 1'b1);
                end else begin
                    col <= col + 1'b1;
                end
            end
            if (pop)
                fifo_rptr <= (fifo_rptr == 2'd2) ? 2'd0 : (fifo_rptr + 2'd1);
            if (push && !pop)
                fifo_count <= fifo_count + 3'd1;
            else if (!push && pop)
                fifo_count <= fifo_count - 3'd1;
        end
    end

endmodule
