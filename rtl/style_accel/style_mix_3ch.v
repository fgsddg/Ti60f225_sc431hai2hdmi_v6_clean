/*
 * Three-channel 8-bit style-intensity mixer.
 *
 *   mixed = original + (styled - original) * strength / 255
 *
 * strength is 0..255, so the endpoints are bit-exact original and styled.
 * The divide-by-255 is implemented without a divider:
 *
 *   floor(x / 255) = (x + 1 + (x >> 8)) >> 8        (x < 65536)
 *
 * The signed delta is rounded to nearest by adding 128 before the divide and
 * restoring its sign afterwards.  Three 18x18 DSP multiplies are inferred.
 * Output data and timing are delayed by two clocks relative to the inputs.
 */
`timescale 1ns / 1ps

module style_mix_3ch (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [23:0] original_rgb,
    input  wire [23:0] styled_rgb,
    input  wire [7:0]  strength,

    input  wire        in_de,
    input  wire        in_hs,
    input  wire        in_vs,

    output reg  [23:0] original_rgb_out,
    output reg  [23:0] styled_rgb_out,
    output reg  [23:0] mixed_rgb_out,
    output reg         out_de,
    output reg         out_hs,
    output reg         out_vs
);

    /* Round an 8x9 signed product by 255.  Product range is -65025..65025. */
    function signed [8:0] scale_255;
        input signed [17:0] product;
        reg [17:0] magnitude;
        reg [17:0] rounded;
        begin
            if (product[17])
                magnitude = -product;
            else
                magnitude = product;

            rounded = magnitude + 18'd128;
            rounded = rounded + 18'd1 + (rounded >> 8);
            rounded = rounded >> 8;

            if (product[17])
                scale_255 = -$signed({1'b0, rounded[7:0]});
            else
                scale_255 = $signed({1'b0, rounded[7:0]});
        end
    endfunction

    function [7:0] saturate_u8;
        input signed [9:0] value;
        begin
            if (value < 10'sd0)
                saturate_u8 = 8'd0;
            else if (value > 10'sd255)
                saturate_u8 = 8'd255;
            else
                saturate_u8 = value[7:0];
        end
    endfunction

    reg signed [8:0] diff_r;
    reg signed [8:0] diff_g;
    reg signed [8:0] diff_b;
    reg        [7:0] strength_r;
    reg        [23:0] original_r;
    reg        [23:0] styled_r;
    reg               de_r;
    reg               hs_r;
    reg               vs_r;

    wire signed [17:0] product_r =
        $signed({{9{diff_r[8]}}, diff_r}) *
        $signed({10'd0, strength_r});
    wire signed [17:0] product_g =
        $signed({{9{diff_g[8]}}, diff_g}) *
        $signed({10'd0, strength_r});
    wire signed [17:0] product_b =
        $signed({{9{diff_b[8]}}, diff_b}) *
        $signed({10'd0, strength_r});

    wire signed [8:0] delta_r = scale_255(product_r);
    wire signed [8:0] delta_g = scale_255(product_g);
    wire signed [8:0] delta_b = scale_255(product_b);

    wire signed [9:0] mixed_r =
        $signed({1'b0, original_r[23:16]}) + delta_r;
    wire signed [9:0] mixed_g =
        $signed({1'b0, original_r[15:8]}) + delta_g;
    wire signed [9:0] mixed_b =
        $signed({1'b0, original_r[7:0]}) + delta_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_r          <= 9'sd0;
            diff_g          <= 9'sd0;
            diff_b          <= 9'sd0;
            strength_r      <= 8'd0;
            original_r      <= 24'd0;
            styled_r        <= 24'd0;
            de_r            <= 1'b0;
            hs_r            <= 1'b0;
            vs_r            <= 1'b0;
            original_rgb_out <= 24'd0;
            styled_rgb_out   <= 24'd0;
            mixed_rgb_out    <= 24'd0;
            out_de           <= 1'b0;
            out_hs           <= 1'b0;
            out_vs           <= 1'b0;
        end else begin
            diff_r     <= $signed({1'b0, styled_rgb[23:16]}) -
                          $signed({1'b0, original_rgb[23:16]});
            diff_g     <= $signed({1'b0, styled_rgb[15:8]}) -
                          $signed({1'b0, original_rgb[15:8]});
            diff_b     <= $signed({1'b0, styled_rgb[7:0]}) -
                          $signed({1'b0, original_rgb[7:0]});
            strength_r <= strength;
            original_r <= original_rgb;
            styled_r   <= styled_rgb;
            de_r       <= in_de;
            hs_r       <= in_hs;
            vs_r       <= in_vs;

            original_rgb_out <= original_r;
            styled_rgb_out   <= styled_r;
            mixed_rgb_out    <= {saturate_u8(mixed_r),
                                 saturate_u8(mixed_g),
                                 saturate_u8(mixed_b)};
            out_de           <= de_r;
            out_hs           <= hs_r;
            out_vs           <= vs_r;
        end
    end

endmodule