//////////////////////////////////////////////////////////////////////////////
// tb_video_scaler_top.v -- self checking testbench for video_scaler_top (M1)
//   small config : 64x48 -> 40x30  (ratio 1.6 x 1.6, non integer)
//   checks every output pixel against the centered-sampling reference
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_video_scaler_top;

    parameter SRC_W = 64, SRC_H = 48, DST_W = 40, DST_H = 30;
    localparam ADDR_W = 7, BANKS = 4, MAX_SUB = 3, FRAMES = 2;

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

    video_scaler_top #(
        .SRC_W(SRC_W), .SRC_H(SRC_H), .DST_W(DST_W), .DST_H(DST_H),
        .BANKS(BANKS), .ADDR_W(ADDR_W), .MAX_SUB(MAX_SUB)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .src_de(src_de), .src_vs(src_vs), .src_rgb(src_rgb),
        .out_valid(out_valid), .out_rgb(out_rgb), .out_ready(out_ready),
        .out_sof(out_sof), .dbg_row_miss(dbg_row_miss)
    );

    // ---------------- source pattern (unique per pixel) ----------------
    function [23:0] pat;
        input integer x;
        input integer y;
        begin
            pat = {x[7:0], y[7:0], (x[7:0] ^ y[7:0])};
        end
    endfunction

    // ---------------- reference model ----------------
    function integer sx_of; input integer d;
        begin sx_of = ((2*d + 1) * SRC_W) / (2*DST_W); end
    endfunction
    function integer sy_of; input integer d;
        begin sy_of = ((2*d + 1) * SRC_H) / (2*DST_H); end
    endfunction

    // ---------------- checker ----------------
    integer exp_dx = 0, exp_dy = 0, pix_cnt = 0, err_cnt = 0, sof_cnt = 0;
    reg [23:0] exp_rgb;
    reg        sof_d;

    always @(posedge clk) begin
        if (rst_n) begin
            sof_d <= out_sof;
            if (out_sof & ~sof_d) sof_cnt = sof_cnt + 1;

            if (out_valid & out_ready) begin
                exp_rgb = pat(sx_of(exp_dx), sy_of(exp_dy));
                if (out_rgb !== exp_rgb) begin
                    err_cnt = err_cnt + 1;
                    if (err_cnt <= 6)
                        $display("[%0t] MISMATCH dst(%0d,%0d) got=%06h exp=%06h (src %0d,%0d)",
                                 $time, exp_dx, exp_dy, out_rgb, exp_rgb,
                                 sx_of(exp_dx), sy_of(exp_dy));
                end
                pix_cnt = pix_cnt + 1;
                if (exp_dx == DST_W-1) begin
                    exp_dx = 0;
                    exp_dy = exp_dy + 1;
                    if (exp_dy == DST_H) exp_dy = 0;
                end else begin
                    exp_dx = exp_dx + 1;
                end
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
                    src_rgb = pat(x, y);
                end
                @(negedge clk);
                src_de  = 0;
                src_rgb = 0;
                repeat (2) @(negedge clk);
            end

            // wait until this frame has been fully emitted
            while (pix_cnt < (f+1)*DST_W*DST_H) @(posedge clk);
            repeat (5) @(posedge clk);
        end

        $display("--------------------------------------------------");
        $display("pixels      = %0d (expected %0d)", pix_cnt, FRAMES*DST_W*DST_H);
        $display("mismatches  = %0d", err_cnt);
        $display("sof pulses  = %0d (expected %0d)", sof_cnt, FRAMES);
        $display("row misses  = %0d", dbg_row_miss);
        if (err_cnt == 0 && pix_cnt == FRAMES*DST_W*DST_H &&
            sof_cnt == FRAMES && dbg_row_miss == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $finish;
    end

    // ---------------- watchdog ----------------
    initial begin
        #50_000_000;
        $display("RESULT: FAIL (timeout)");
        $finish;
    end

endmodule