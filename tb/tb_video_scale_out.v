//////////////////////////////////////////////////////////////////////////////
// tb_video_scale_out.v -- end-to-end TB (scaler + FIFO + genlocked raster)
//   scaled-down but rate-exact model of the real system:
//     source : 32x24 active, frame = 2560 src clocks : 1 vs + 768 act + 1791 idle
//     output : H_TOTAL 84 (20 act), V_TOTAL 50 (15 act) = 4200 clocks/frame
//     out_clk period = 25.6us/4200 = 6.0952ns  -> both frames = 25.6us
//     active : source 768*10ns = 7.68us ; output 15*84*6.0952ns = 7.68us
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_video_scale_out;
    parameter SRC_W = 32, SRC_H = 24, DST_W = 20, DST_H = 15;
    localparam ADDR_W = 6, BANKS = 4, MAX_SUB = 3;
    localparam H_FP = 1, H_SYNC = 3, H_BP = 60;         // 20+1+3+60 = 84
    localparam V_FP = 1, V_SYNC = 1, V_BP = 33;         // 15+1+1+33 = 50
    localparam SKIP = 3, LAST = 8;
    localparam SRC_FRAME = 2560;                        // src clocks per frame

    reg src_clk = 0;  always #5.0     src_clk = ~src_clk;      // 10.000 ns
    reg out_clk = 0;  always #3.0476  out_clk = ~out_clk;      //  6.0952 ns

    reg         rst_n = 0, src_de = 0, src_vs = 0;
    reg  [23:0] src_rgb = 0;
    wire [23:0] out_rgb; wire out_de, out_hs, out_vs, out_fd;
    wire [15:0] dbg_uf, dbg_rm;

    video_scale_out #(
        .SRC_W(SRC_W), .SRC_H(SRC_H), .DST_W(DST_W), .DST_H(DST_H),
        .BANKS(BANKS), .ADDR_W(ADDR_W), .MAX_SUB(MAX_SUB),
        .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP), .NEG_SYNC(1)
    ) dut (
        .src_clk(src_clk), .src_rst_n(rst_n),
        .src_de(src_de), .src_vs(src_vs), .src_rgb(src_rgb),
        .out_clk(out_clk), .out_rst_n(rst_n),
        .out_rgb(out_rgb), .out_de(out_de), .out_hs(out_hs), .out_vs(out_vs),
        .out_frame_done(out_fd), .dbg_underflow(dbg_uf), .dbg_row_miss(dbg_rm)
    );

    function [7:0] patc; input integer x; input integer y; input integer c;
        begin case (c) 0: patc = x[7:0]; 1: patc = y[7:0]; default: patc = (x[7:0] ^ y[7:0]); endcase end
    endfunction
    function integer sx_of; input integer d; begin sx_of = ((2*d+1)*SRC_W)/(2*DST_W); end endfunction
    function integer sy_of; input integer d; begin sy_of = ((2*d+1)*SRC_H)/(2*DST_H); end endfunction

    integer fd_cnt = 0, frame = 0, exp_dx = 0, exp_dy = 0, err_cnt = 0, checked = 0;
    integer uf0 = 0; reg checking = 0; reg [23:0] exp_rgb; reg fd_d;

    always @(posedge out_clk) if (rst_n) begin
        fd_d <= out_fd;
        if (out_fd & ~fd_d) begin
            fd_cnt = fd_cnt + 1; frame = frame + 1;
            exp_dx = 0; exp_dy = 0;
            if (fd_cnt == SKIP) begin checking = 1'b1; uf0 = dbg_uf; err_cnt = 0; checked = 0; end
        end
        if (out_de) begin
            if (checking) begin
                exp_rgb = {patc(sx_of(exp_dx),sy_of(exp_dy),0), patc(sx_of(exp_dx),sy_of(exp_dy),1), patc(sx_of(exp_dx),sy_of(exp_dy),2)};
                checked = checked + 1;
                if (out_rgb !== exp_rgb) begin
                    err_cnt = err_cnt + 1;
                    if (err_cnt <= 6) $display("[%0t] MISMATCH f%0d dst(%0d,%0d) got=%06h exp=%06h", $time, frame, exp_dx, exp_dy, out_rgb, exp_rgb);
                end
                if (exp_dx == DST_W-1) begin exp_dx = 0; if (exp_dy == DST_H-1) exp_dy = 0; else exp_dy = exp_dy + 1; end
                else exp_dx = exp_dx + 1;
            end
        end
    end

    integer x, y, k;
    initial begin
        rst_n = 0; repeat (5) @(posedge src_clk); rst_n = 1;
        k = 0;
        forever begin
            @(negedge src_clk); src_vs = 1; src_de = 0;   // frame start (1 clock)
            @(negedge src_clk); src_vs = 0;
            for (y = 0; y < SRC_H; y = y + 1)
                for (x = 0; x < SRC_W; x = x + 1) begin
                    @(negedge src_clk); src_de = 1; src_rgb = {patc(x,y,0),patc(x,y,1),patc(x,y,2)};
                end
            @(negedge src_clk); src_de = 0;
            for (k = 0; k < SRC_FRAME - 1 - SRC_W*SRC_H; k = k + 1) @(negedge src_clk);  // idle to keep frame exact
        end
    end

    initial begin
        wait (fd_cnt == LAST);
        repeat (20) @(posedge out_clk);
        $display("--------------------------------------------------");
        $display("frames      = %0d", fd_cnt);
        $display("checked px  = %0d (expected %0d)", checked, (LAST-SKIP)*DST_W*DST_H);
        $display("mismatches  = %0d", err_cnt);
        $display("underflow   = %0d (new since frame %0d)", dbg_uf - uf0, SKIP);
        $display("row misses  = %0d", dbg_rm);
        if (err_cnt == 0 && checked == (LAST-SKIP)*DST_W*DST_H && (dbg_uf - uf0) == 0 && dbg_rm == 0)
            $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
    initial begin #5_000_000; $display("RESULT: FAIL (timeout)"); $finish; end
endmodule