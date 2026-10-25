//////////////////////////////////////////////////////////////////////////////
// tb_video_scaler_bilinear.v -- self checking TB for video_scaler_bilinear
//   small config : 64x40 -> 40x32 (ratio 1.6 x 1.25, same as 1024x600 -> 640x480)
//   reference    : real arithmetic bilinear with centered sampling,
//                  tolerance +/-2 LSB (DUT uses Q16 fixed point)
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_video_scaler_bilinear;

    parameter SRC_W = 64, SRC_H = 40, DST_W = 40, DST_H = 32;   // ratio 1.6 x 1.25 (deployment ratio)
    localparam ADDR_W = 7, BANKS = 4, FRAMES = 1;

    reg clk = 0;
    always #5 clk = ~clk;

    reg         rst_n  = 0;
    reg         src_de = 0;
    reg         src_vs = 0;
    reg  [23:0] src_rgb = 0;

    wire        out_valid;
    wire [23:0] out_rgb;
    wire        out_ready = 1'b1;
    wire        out_sof;
    wire [15:0] dbg_row_miss;

    video_scaler_bilinear #(
        .SRC_W(SRC_W), .SRC_H(SRC_H), .DST_W(DST_W), .DST_H(DST_H),
        .BANKS(BANKS), .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .src_de(src_de), .src_vs(src_vs), .src_rgb(src_rgb),
        .out_valid(out_valid), .out_rgb(out_rgb), .out_ready(out_ready),
        .out_sof(out_sof), .dbg_row_miss(dbg_row_miss)
    );

    // ---------------- source pattern : smooth, no wrap ----------------
    function [7:0] patc;
        input integer x;
        input integer y;
        input integer c;
        begin
            case (c)
                0: patc = x[7:0];               // R = x
                1: patc = y[7:0];               // G = y
                default: patc = (x + y) >> 1;   // B = (x+y)/2
            endcase
        end
    endfunction

    // ---------------- checker ----------------
    integer exp_dx = 0, exp_dy = 0, pix_cnt = 0, err_cnt = 0, sof_cnt = 0;
    integer max_err = 0, e0, e1, e2;
    reg [7:0] got0, got1, got2, exp0, exp1, exp2;
    integer x0, x1, y0, y1;
    real    px, py, fx, fy, v0, v1, v2;
    reg     sof_d;

    task automatic calc_exp;
        input integer dx;
        input integer dy;
        begin
            px = (dx + 0.5) * SRC_W / DST_W - 0.5;
            py = (dy + 0.5) * SRC_H / DST_H - 0.5;
            if (px < 0.0) px = 0.0;
            if (py < 0.0) py = 0.0;
            x0 = $rtoi($floor(px)); fx = px - x0;
            y0 = $rtoi($floor(py)); fy = py - y0;
            if (x0 > SRC_W-1) begin x0 = SRC_W-1; fx = 0.0; end
            if (y0 > SRC_H-1) begin y0 = SRC_H-1; fy = 0.0; end
            x1 = (x0 == SRC_W-1) ? x0 : x0 + 1;
            y1 = (y0 == SRC_H-1) ? y0 : y0 + 1;

            v0 = (1.0-fx)*(1.0-fy)*patc(x0,y0,0) + fx*(1.0-fy)*patc(x1,y0,0)
               + (1.0-fx)*fy      *patc(x0,y1,0) + fx*fy      *patc(x1,y1,0);
            v1 = (1.0-fx)*(1.0-fy)*patc(x0,y0,1) + fx*(1.0-fy)*patc(x1,y0,1)
               + (1.0-fx)*fy      *patc(x0,y1,1) + fx*fy      *patc(x1,y1,1);
            v2 = (1.0-fx)*(1.0-fy)*patc(x0,y0,2) + fx*(1.0-fy)*patc(x1,y0,2)
               + (1.0-fx)*fy      *patc(x0,y1,2) + fx*fy      *patc(x1,y1,2);
            exp0 = $rtoi(v0 + 0.5);
            exp1 = $rtoi(v1 + 0.5);
            exp2 = $rtoi(v2 + 0.5);
        end
    endtask

    always @(posedge clk) begin
        if (rst_n) begin
            sof_d <= out_sof;
            if (out_sof & ~sof_d) sof_cnt = sof_cnt + 1;

            if (out_valid & out_ready) begin
                calc_exp(exp_dx, exp_dy);
                got0 = out_rgb[23:16];
                got1 = out_rgb[15:8];
                got2 = out_rgb[7:0];
                e0 = (got0 > exp0) ? (got0 - exp0) : (exp0 - got0);
                e1 = (got1 > exp1) ? (got1 - exp1) : (exp1 - got1);
                e2 = (got2 > exp2) ? (got2 - exp2) : (exp2 - got2);
                if (e0 > max_err) max_err = e0;
                if (e1 > max_err) max_err = e1;
                if (e2 > max_err) max_err = e2;
                if (e0 > 2 || e1 > 2 || e2 > 2) begin
                    err_cnt = err_cnt + 1;
                    if (err_cnt <= 6)
                        $display("[%0t] MISMATCH dst(%0d,%0d) got=%02h%02h%02h exp=%02h%02h%02h (x0=%0d fx=%f y0=%0d fy=%f)",
                                 $time, exp_dx, exp_dy, got0,got1,got2, exp0,exp1,exp2, x0, fx, y0, fy);
                end
                pix_cnt = pix_cnt + 1;
                if (exp_dx == DST_W-1) begin
                    exp_dx = 0; exp_dy = exp_dy + 1;
                    if (exp_dy == DST_H) exp_dy = 0;
                end else exp_dx = exp_dx + 1;
            end
        end
    end

    // ---------------- stimulus ----------------
    integer f, x, y;
    initial begin
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (3) @(posedge clk);

        for (f = 0; f < FRAMES; f = f + 1) begin
            @(negedge clk); src_vs = 1;
            @(negedge clk); src_vs = 0; src_de = 0;
            for (y = 0; y < SRC_H; y = y + 1) begin
                for (x = 0; x < SRC_W; x = x + 1) begin
                    @(negedge clk);
                    src_de  = 1;
                    src_rgb = {patc(x,y,0), patc(x,y,1), patc(x,y,2)};
                end
                @(negedge clk); src_de = 0; src_rgb = 0;
                repeat (2) @(negedge clk);
            end
            while (pix_cnt < (f+1)*DST_W*DST_H) @(posedge clk);
            repeat (5) @(posedge clk);
        end

        $display("--------------------------------------------------");
        $display("pixels      = %0d (expected %0d)", pix_cnt, FRAMES*DST_W*DST_H);
        $display("mismatches  = %0d (tolerance +/-2 LSB)", err_cnt);
        $display("max error   = %0d LSB", max_err);
        $display("sof pulses  = %0d (expected %0d)", sof_cnt, FRAMES);
        $display("row misses  = %0d", dbg_row_miss);
        if (err_cnt == 0 && pix_cnt == FRAMES*DST_W*DST_H && sof_cnt == FRAMES && dbg_row_miss == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $finish;
    end

    initial begin
        #50_000_000;
        $display("RESULT: FAIL (timeout)");
        $finish;
    end

endmodule
