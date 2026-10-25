//////////////////////////////////////////////////////////////////////////////
// fps_overlay.v -- real-time frame-rate on-screen display (OSD)
//
//   Measures the period between selected frame-completion pulses and paints
//   "FPS <xx.x>" into the corner of the active video.  The top level selects
//   camera-source frames in full-original mode and processed frames in
//   split/styled modes.  VSYNC is used only for raster coordinates / OSD
//   alignment, never as the FPS event.
//
//     measurement : fps_x10 = CLK_HZ*10 / period_clks
//                   one integer division per frame, done during the vertical
//                   blanking with a simple repeated-subtraction engine
//     rendering   : 8x8 bitmap font, 9 character cells, SCALE-x magnification,
//                   optional dark background box for legibility
//
//   CLK_HZ MUST match the pixel clock of the raster feeding de_in / vs_in.
//     1024x600 -> 640x480 build : vid_clk_dvi2 = 24.75 MHz (58.93 Hz)
//     1080p    -> 1024x600 build: vid_clk_dvi2 = 74.25 MHz (60.00 Hz)
//
//   de_in/hs_in/vs_in/rgb_in pass through one register stage, so the overlaid
//   stream stays perfectly aligned with the original timing.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module fps_overlay #(
    parameter CLK_HZ   = 24_750_000,   // pixel clock of de_in / vs_in
    parameter BOX_X    = 16,           // OSD box origin, active pixels
    parameter BOX_Y    = 16,
    parameter PAD      = 6,            // text padding inside the box, pixels
    parameter SCALE    = 2,            // font magnification (1, 2 or 4)
    parameter DRAW_BOX = 1,            // 1 = draw dark background box
    parameter TEXT_COL = 24'hFFFFFF,   // glyph colour
    parameter BOX_COL  = 24'h202020    // background colour
)(
    input               clk,
    input               rst_n,
    input               de_in,
    input               hs_in,
    input               vs_in,
    input               frame_pulse,      /* one clk pulse per measured frame */
    input               show,             /* 0 = keep timing, erase FPS text */
    input      [7:0]    r_in,
    input      [7:0]    g_in,
    input      [7:0]    b_in,
    output reg          de_out,
    output reg          hs_out,
    output reg          vs_out,
    output reg [7:0]    r_out,
    output reg [7:0]    g_out,
    output reg [7:0]    b_out,
    output     [15:0]   fps_x10_dbg
);

    // ---------------------------------------------------------------- layout
    localparam CW    = 8;                       // glyph cell, unscaled
    localparam CH    = 8;
    localparam NCH   = 9;                       // "FPS " + 3 int + '.' + 1 frac
    localparam SL2   = (SCALE == 4) ? 2 : (SCALE == 2) ? 1 : 0;   // log2(SCALE)
    localparam CWS   = CW << SL2;               // scaled cell width
    localparam CHS   = CH << SL2;
    localparam CW2   = SL2 + 3;                 // log2(CWS)
    localparam TEXTW = NCH * CWS;
    localparam TEXTH = CHS;
    localparam BOXW  = TEXTW + 2*PAD;
    localparam BOXH  = TEXTH + 2*PAD;

    localparam XW    = 12;                      // active pixel / line counter width
    localparam [XW-1:0] XMIN = BOX_X + PAD;     // text origin
    localparam [XW-1:0] YMIN = BOX_Y + PAD;

    // ------------------------------------------------- active-area coordinate
    reg  [XW-1:0] x_cnt, y_cnt;
    reg           vs_d, de_d;
    reg           new_frame;

    wire vs_fall = vs_d & ~vs_in;               // one pulse per frame

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt     <= {XW{1'b0}};
            y_cnt     <= {XW{1'b0}};
            vs_d      <= 1'b0;
            de_d      <= 1'b0;
            new_frame <= 1'b0;
        end else begin
            vs_d <= vs_in;
            de_d <= de_in;

            if (vs_fall) new_frame <= 1'b1;     // arm the next active line

            if (de_in) begin
                x_cnt <= x_cnt + 1'b1;
                if (new_frame) begin            // first line of the frame
                    y_cnt     <= {XW{1'b0}};
                    new_frame <= 1'b0;
                end
            end else begin
                x_cnt <= {XW{1'b0}};
                if (de_d) y_cnt <= y_cnt + 1'b1; // end of an active line
            end
        end
    end

    // ------------------------------------------------------ frame period meter
    localparam [31:0] NUM = CLK_HZ * 10;

    reg  [27:0] period_cnt;
    reg  [27:0] period_lat;
    reg         meas_req;
    reg         frame_d;

    // ------------------------------------------------------ fps = NUM / period
    reg         div_busy;
    reg  [31:0] div_acc;
    reg  [13:0] div_q;
    reg  [27:0] div_den;
    reg  [13:0] fps_x10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_cnt <= 28'd0;
            period_lat <= 28'd0;
            frame_d    <= 1'b0;
            meas_req   <= 1'b0;
        end else begin
            frame_d    <= frame_pulse;
            period_cnt <= period_cnt + 28'd1;
            if (frame_pulse && !frame_d) begin
                period_lat <= period_cnt;          // clocks in the last frame
                period_cnt <= 28'd0;
                meas_req   <= 1'b1;
            end else if (meas_req && div_busy) begin
                meas_req   <= 1'b0;                // consumed by the divider
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_busy <= 1'b0;
            div_acc  <= 32'd0;
            div_q    <= 14'd0;
            div_den  <= 28'd0;
            fps_x10  <= 14'd0;
        end else begin
            if (!div_busy) begin
                if (meas_req) begin
                    if (period_lat == 28'd0) begin
                        fps_x10 <= 14'd0;
                    end else begin
                        div_busy <= 1'b1;
                        div_acc  <= NUM;
                        div_q    <= 14'd0;
                        div_den  <= period_lat;
                    end
                end
            end else begin
                if ((div_acc >= {4'b0, div_den}) && (div_q < 14'd9999)) begin
                    div_acc <= div_acc - {4'b0, div_den};
                    div_q   <= div_q + 1'b1;
                end else begin
                    div_busy <= 1'b0;
                    fps_x10  <= div_q;
                end
            end
        end
    end

    assign fps_x10_dbg = {2'b0, fps_x10};

    // ------------------------------------------------------ number formatting
    wire [3:0] n_frac = fps_x10 % 10;
    wire [13:0] n_int = fps_x10 / 10;
    wire [3:0] n_one  = n_int % 10;
    wire [3:0] n_ten  = (n_int / 10) % 10;
    wire [3:0] n_hun  = (n_int / 100) % 10;

    wire [7:0] ch_h = (fps_x10 >= 14'd1000) ? (8'h30 + n_hun) : 8'h20;
    wire [7:0] ch_t = (fps_x10 >= 14'd100 ) ? (8'h30 + n_ten) : 8'h20;
    wire [7:0] ch_o = 8'h30 + n_one;
    wire [7:0] ch_f = 8'h30 + n_frac;

    function [7:0] get_char;
        input [3:0] idx;
        begin
            case (idx)
                4'd0:    get_char = 8'h46;   // 'F'
                4'd1:    get_char = 8'h50;   // 'P'
                4'd2:    get_char = 8'h53;   // 'S'
                4'd3:    get_char = 8'h20;   // ' '
                4'd4:    get_char = ch_h;
                4'd5:    get_char = ch_t;
                4'd6:    get_char = ch_o;
                4'd7:    get_char = 8'h2E;   // '.'
                4'd8:    get_char = ch_f;
                default: get_char = 8'h20;
            endcase
        end
    endfunction

    // 8x8 glyph, row0 (top) in bits [63:56], bit7 of a row = leftmost pixel
    function [63:0] glyph_bits;
        input [7:0] ch;
        begin
            case (ch)
                8'h30:   glyph_bits = 64'h3C666E7666663C00; // '0'
                8'h31:   glyph_bits = 64'h1838181818187E00; // '1'
                8'h32:   glyph_bits = 64'h3C66060C18307E00; // '2'
                8'h33:   glyph_bits = 64'h3C66061C06663C00; // '3'
                8'h34:   glyph_bits = 64'h0C1C3C6C7E0C0C00; // '4'
                8'h35:   glyph_bits = 64'h7E607C0606663C00; // '5'
                8'h36:   glyph_bits = 64'h1C30607C66663C00; // '6'
                8'h37:   glyph_bits = 64'h7E060C1830303000; // '7'
                8'h38:   glyph_bits = 64'h3C66663C66663C00; // '8'
                8'h39:   glyph_bits = 64'h3C66663E060C3800; // '9'
                8'h46:   glyph_bits = 64'h7E60607C60606000; // 'F'
                8'h50:   glyph_bits = 64'h7C66667C60606000; // 'P'
                8'h53:   glyph_bits = 64'h3C66603C06663C00; // 'S'
                8'h2E:   glyph_bits = 64'h0000000000181800; // '.'
                default: glyph_bits = 64'h0000000000000000; // ' '
            endcase
        end
    endfunction

    // ------------------------------------------------------------- pixel mux
    wire in_box  = de_in && (x_cnt >= BOX_X) && (x_cnt < BOX_X + BOXW)
                         && (y_cnt >= BOX_Y) && (y_cnt < BOX_Y + BOXH);
    wire in_text = in_box  && (x_cnt >= XMIN) && (x_cnt < XMIN + TEXTW)
                           && (y_cnt >= YMIN) && (y_cnt < YMIN + TEXTH);

    wire [XW-1:0] tlx = x_cnt - XMIN;
    wire [XW-1:0] tly = y_cnt - YMIN;

    wire [3:0] ch_idx = tlx[CW2+3 : CW2];        // 0 .. NCH-1
    wire [2:0] g_col  = tlx[SL2+2 : SL2];        // 0 .. 7
    wire [2:0] g_row  = tly[SL2+2 : SL2];        // 0 .. 7

    wire [7:0]  ch_now = get_char(ch_idx);
    wire [63:0] glyph  = glyph_bits(ch_now);
    wire [7:0]  grow   = glyph[8*(3'd7 - g_row) +: 8];
    wire        pon    = grow[3'd7 - g_col];

    wire px_text = in_text && pon;
    wire px_box  = in_box && ~px_text;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_out <= 1'b0;
            hs_out <= 1'b0;
            vs_out <= 1'b0;
            r_out  <= 8'd0;
            g_out  <= 8'd0;
            b_out  <= 8'd0;
        end else begin
            de_out <= de_in;
            hs_out <= hs_in;
            vs_out <= vs_in;
            if (de_in && show && px_text)
                {r_out, g_out, b_out} <= TEXT_COL;
            else if (de_in && show && px_box && DRAW_BOX)
                {r_out, g_out, b_out} <= BOX_COL;
            else
                {r_out, g_out, b_out} <= {r_in, g_in, b_in};
        end
    end

endmodule
