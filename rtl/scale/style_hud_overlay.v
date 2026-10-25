/*
 * Lower-centre style-intensity HUD.
 *
 * type 1: "强度调节：" + horizontal strength bar
 * type 2: "强度调节：开启"
 * type 3: "强度调节：关闭"
 *
 * The 16x16 Chinese glyphs come from style_hud_font.v.  The module has the
 * same one-register output latency as fps_overlay so video timing is unchanged.
 */
`timescale 1ns / 1ps

module style_hud_overlay #(
    parameter [11:0] BOX_X   = 12'd150,
    parameter [11:0] BOX_Y   = 12'd390,
    parameter [11:0] BOX_W   = 12'd340,
    parameter [11:0] BOX_H   = 12'd48,
    parameter [11:0] TEXT_X  = 12'd166,
    parameter [11:0] TEXT_Y  = 12'd404,
    parameter [11:0] BAR_X   = 12'd270,
    parameter [11:0] BAR_Y   = 12'd404,
    parameter [23:0] TEXT_COL= 24'hFFFFFF,
    parameter [23:0] BOX_COL = 24'h101820,
    parameter [23:0] BAR_COL = 24'h00C8FF,
    parameter [23:0] EDGE_COL= 24'hB0C8D8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire        hs_in,
    input  wire        vs_in,
    input  wire [23:0] rgb_in,
    input  wire        visible,
    input  wire [1:0]  hud_type,
    input  wire [7:0]  strength,
    output reg         de_out,
    output reg         hs_out,
    output reg         vs_out,
    output reg  [23:0] rgb_out
);

    localparam [11:0] LABEL_CELL = 12'd18;
    localparam [11:0] STATUS_X   = 12'd270;
    localparam [11:0] BAR_W      = 12'd134;
    localparam [11:0] BAR_H      = 12'd19;
    localparam [11:0] BAR_INNER_W= 12'd130;

    reg [11:0] x_cnt, y_cnt;
    reg        vs_d, de_d;
    reg        new_frame;
    wire       vs_fall = vs_d & ~vs_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt     <= 12'd0;
            y_cnt     <= 12'd0;
            vs_d      <= 1'b0;
            de_d      <= 1'b0;
            new_frame <= 1'b0;
        end else begin
            vs_d <= vs_in;
            de_d <= de_in;
            if (vs_fall)
                new_frame <= 1'b1;
            if (de_in) begin
                x_cnt <= x_cnt + 12'd1;
                if (new_frame) begin
                    y_cnt     <= 12'd0;
                    new_frame <= 1'b0;
                end
            end else begin
                x_cnt <= 12'd0;
                if (de_d)
                    y_cnt <= y_cnt + 12'd1;
            end
        end
    end

    wire hud_on = visible && (hud_type != 2'd0) && de_in;
    wire in_box = hud_on && (x_cnt >= BOX_X) && (x_cnt < BOX_X + BOX_W)
                         && (y_cnt >= BOX_Y) && (y_cnt < BOX_Y + BOX_H);

    /* "强度调节：" label: five 16x16 glyphs with two-pixel gaps. */
    wire in_label = hud_on && (x_cnt >= TEXT_X) &&
                    (x_cnt < TEXT_X + 5 * LABEL_CELL) &&
                    (y_cnt >= TEXT_Y) && (y_cnt < TEXT_Y + 12'd16);
    wire [11:0] label_x = x_cnt - TEXT_X;
    reg  [3:0]  label_idx;
    reg  [4:0]  label_col;
    always @* begin
        label_idx = 4'd0;
        label_col = 5'd0;
        if (label_x < 12'd18) begin
            label_idx = 4'd0;
            label_col = label_x[4:0];
        end else if (label_x < 12'd36) begin
            label_idx = 4'd1;
            label_col = label_x - 12'd18;
        end else if (label_x < 12'd54) begin
            label_idx = 4'd2;
            label_col = label_x - 12'd36;
        end else if (label_x < 12'd72) begin
            label_idx = 4'd3;
            label_col = label_x - 12'd54;
        end else begin
            label_idx = 4'd4;
            label_col = label_x - 12'd72;
        end
    end

    /* Status glyphs: 开启 for type 2, 关闭 for type 3. */
    wire in_status = hud_on && (hud_type != 2'd1) &&
                     (x_cnt >= STATUS_X) && (x_cnt < STATUS_X + 2 * LABEL_CELL) &&
                     (y_cnt >= TEXT_Y) && (y_cnt < TEXT_Y + 12'd16);
    wire [11:0] status_x = x_cnt - STATUS_X;
    wire [3:0] status_idx = (status_x < 12'd18)
                                ? ((hud_type == 2'd2) ? 4'd5 : 4'd7)
                                : ((hud_type == 2'd2) ? 4'd6 : 4'd8);
    wire [4:0] status_col = (status_x < 12'd18)
                                ? status_x[4:0]
                                : status_x - 12'd18;

    /* Strength bar: 134x19 outline, 130-pixel inner travel. */
    wire in_bar = hud_on && (hud_type == 2'd1) &&
                  (x_cnt >= BAR_X) && (x_cnt < BAR_X + BAR_W) &&
                  (y_cnt >= BAR_Y) && (y_cnt < BAR_Y + BAR_H);
    wire bar_edge = in_bar &&
                    ((x_cnt < BAR_X + 12'd2) || (x_cnt >= BAR_X + BAR_W - 12'd2) ||
                     (y_cnt < BAR_Y + 12'd2) || (y_cnt >= BAR_Y + BAR_H - 12'd2));
    wire [7:0] fill_width = (strength == 8'd255) ? BAR_INNER_W[7:0]
                                                  : {1'b0, strength[7:1]};
    wire bar_fill = in_bar && !bar_edge &&
                    ((x_cnt - (BAR_X + 12'd2)) < {4'd0, fill_width});

    wire [3:0] active_glyph_idx = in_label ? label_idx : status_idx;
    wire [4:0] active_glyph_col = in_label ? label_col : status_col;
    wire [3:0] glyph_row = y_cnt - TEXT_Y;
    wire [255:0] glyph_bits;
    wire [15:0] glyph_row_bits = glyph_bits[16 * (4'd15 - glyph_row[3:0]) +: 16];
    wire glyph_pixel = (in_label || in_status) &&
                       (active_glyph_col < 5'd16) &&
                       glyph_row_bits[4'd15 - active_glyph_col[3:0]];

    style_hud_glyph_rom u_glyph_rom (
        .idx (active_glyph_idx),
        .bits(glyph_bits)
    );

    wire draw_text = hud_on && glyph_pixel;
    wire draw_edge = hud_on && bar_edge;
    wire draw_fill = hud_on && bar_fill;
    wire draw_box  = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_out  <= 1'b0;
            hs_out  <= 1'b0;
            vs_out  <= 1'b0;
            rgb_out <= 24'd0;
        end else begin
            de_out <= de_in;
            hs_out <= hs_in;
            vs_out <= vs_in;
            if (draw_text)
                rgb_out <= TEXT_COL;
            else if (draw_edge)
                rgb_out <= EDGE_COL;
            else if (draw_fill)
                rgb_out <= BAR_COL;
            else
                rgb_out <= rgb_in;
        end
    end

endmodule