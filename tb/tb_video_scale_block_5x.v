`timescale 1ns/1ps
module tb_video_scale_block_5x;
    reg clk = 0;
    reg rst_n = 0;
    reg in_de = 0;
    reg in_hs = 1;
    reg in_vs = 1;
    reg [23:0] in_rgb = 0;
    wire out_de, out_hs, out_vs;
    wire [23:0] out_rgb;

    integer sx, sy, ox, oy, errors, frames;
    integer chk_r, chk_g;
    reg [7:0] drive_r, drive_g;

    always #5 clk = ~clk;

    video_scale_block #(.SRC_W(640), .SRC_H(480), .STEP(5)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_de(in_de), .in_hs(in_hs), .in_vs(in_vs), .in_rgb(in_rgb),
        .out_de(out_de), .out_hs(out_hs), .out_vs(out_vs), .out_rgb(out_rgb)
    );

    always @(posedge clk) begin
        if (rst_n && out_de) begin
            chk_r = ox / 5;
            chk_g = oy / 5;
            if (out_rgb[7:0] !== chk_r[7:0] || out_rgb[15:8] !== chk_g[7:0]) begin
                if (errors < 10)
                    $display("BAD out x=%0d y=%0d rgb=%06x exp_r=%02x exp_g=%02x", ox, oy, out_rgb, chk_r, chk_g);
                errors = errors + 1;
            end
            ox = ox + 1;
            if (ox == 640) begin
                ox = 0;
                oy = oy + 1;
                if (oy == 480) begin
                    frames = frames + 1;
                    oy = 0;
                end
            end
        end
    end

    initial begin
        errors = 0; ox = 0; oy = 0; frames = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        in_vs = 0;
        repeat (3) @(posedge clk);
        in_vs = 1;
        for (sy = 0; sy < 480; sy = sy + 1) begin
            in_de = 1;
            for (sx = 0; sx < 640; sx = sx + 1) begin
                drive_r = sx / 5;
                drive_g = sy / 5;
                in_rgb = {8'd0, drive_g, drive_r};
                @(posedge clk);
            end
            in_de = 0;
            repeat (4) @(posedge clk);
        end
        repeat (20) @(posedge clk);

        if (frames != 1) begin
            $display("BAD frame count=%0d", frames);
            errors = errors + 1;
        end
        if (errors == 0)
            $display("PASS: video_scale_block 640x480 -> 128x96 5x5 sample/hold");
        else
            $display("FAIL: errors=%0d frames=%0d", errors, frames);
        $finish;
    end
endmodule
