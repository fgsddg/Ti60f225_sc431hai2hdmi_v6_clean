`timescale 1ns / 1ps

module tb_style_mix_3ch;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [23:0] original_rgb = 24'd0;
    reg [23:0] styled_rgb = 24'd0;
    reg [7:0] strength = 8'd0;
    reg in_de = 1'b0;
    reg in_hs = 1'b0;
    reg in_vs = 1'b0;

    wire [23:0] original_rgb_out;
    wire [23:0] styled_rgb_out;
    wire [23:0] mixed_rgb_out;
    wire out_de;
    wire out_hs;
    wire out_vs;

    integer orig;
    integer styled;
    integer a;
    integer errors = 0;
    integer checks = 0;

    style_mix_3ch dut (
        .clk(clk), .rst_n(rst_n),
        .original_rgb(original_rgb), .styled_rgb(styled_rgb),
        .strength(strength),
        .in_de(in_de), .in_hs(in_hs), .in_vs(in_vs),
        .original_rgb_out(original_rgb_out),
        .styled_rgb_out(styled_rgb_out),
        .mixed_rgb_out(mixed_rgb_out),
        .out_de(out_de), .out_hs(out_hs), .out_vs(out_vs)
    );

    always #5 clk = ~clk;

    function [7:0] expected_mix;
        input integer o;
        input integer s;
        input integer scale;
        integer delta;
        integer product;
        integer magnitude;
        integer rounded;
        begin
            delta = s - o;
            product = delta * scale;
            if (product < 0)
                magnitude = -product;
            else
                magnitude = product;
            rounded = (magnitude + 128) / 255;
            if (product < 0)
                expected_mix = o - rounded;
            else
                expected_mix = o + rounded;
        end
    endfunction

    task automatic check_pixel;
        input integer o;
        input integer s;
        input integer scale;
        reg [23:0] o_rgb;
        reg [23:0] s_rgb;
        reg [7:0] er;
        reg [7:0] eg;
        reg [7:0] eb;
        begin
            o_rgb = {o[7:0], (8'd255 - o[7:0]), (o[7:0] ^ 8'hA5)};
            s_rgb = {s[7:0], o[7:0], (s[7:0] ^ 8'h5A)};
            er = expected_mix(o, s, scale);
            eg = expected_mix(255 - o, o, scale);
            eb = expected_mix(o ^ 8'hA5, s ^ 8'h5A, scale);

            @(negedge clk);
            original_rgb = o_rgb;
            styled_rgb = s_rgb;
            strength = scale[7:0];
            in_de = 1'b1;
            in_hs = (checks & 1);
            in_vs = (checks & 2) != 0;
            @(posedge clk);
            @(posedge clk);
            #1;

            checks = checks + 1;
            if (original_rgb_out !== o_rgb) begin
                $display("FAIL original: o=%0d s=%0d a=%0d got=%h want=%h",
                         o, s, scale, original_rgb_out, o_rgb);
                errors = errors + 1;
            end
            if (styled_rgb_out !== s_rgb) begin
                $display("FAIL styled: o=%0d s=%0d a=%0d got=%h want=%h",
                         o, s, scale, styled_rgb_out, s_rgb);
                errors = errors + 1;
            end
            if (mixed_rgb_out !== {er, eg, eb}) begin
                $display("FAIL mix: o=%0d s=%0d a=%0d got=%h want=%h",
                         o, s, scale, mixed_rgb_out, {er, eg, eb});
                errors = errors + 1;
            end
            if (out_de !== 1'b1 || out_hs !== in_hs || out_vs !== in_vs) begin
                $display("FAIL timing: de=%b hs=%b vs=%b", out_de, out_hs, out_vs);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        /* Exhaustive per-channel correctness at the endpoints and useful
         * intermediate strengths. */
        for (a = 0; a <= 255; a = a + 1) begin
            if (a == 0 || a == 1 || a == 64 || a == 127 || a == 128 ||
                a == 192 || a == 254 || a == 255) begin
                for (orig = 0; orig <= 255; orig = orig + 1)
                    for (styled = 0; styled <= 255; styled = styled + 1)
                        check_pixel(orig, styled, a);
            end
        end

        @(negedge clk);
        in_de = 1'b0;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (out_de !== 1'b0) begin
            $display("FAIL de tail: got=%b", out_de);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS: tb_style_mix_3ch, %0d pixels checked", checks);
            $finish;
        end else begin
            $display("FAIL: tb_style_mix_3ch, %0d errors / %0d checks", errors, checks);
            $fatal(1);
        end
    end
endmodule