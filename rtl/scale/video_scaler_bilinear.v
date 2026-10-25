//////////////////////////////////////////////////////////////////////////////
// video_scaler_bilinear.v -- streaming arbitrary-ratio bilinear scaler (M2)
//
//   source : 1 pixel/clk, de/vs qualified, 24-bit RGB
//   target : 1 pixel/clk, valid/ready qualified, 24-bit RGB
//
//   sampling (centered, same as M1):
//       src_pos = (dst + 0.5) * SRC / DST - 0.5
//       x0 = floor(src_pos), fx = frac(src_pos)      (Q16)
//       x1 = min(x0+1, SRC_W-1)                      (edge replicate)
//
//   architecture (streaming, no full frame):
//     - ring of BANKS line buffers, each source row stored TWICE (memA/memB)
//       so the 2x2 neighbourhood can be read in one cycle:
//         memA : (y0,x0) and (y1,x0)
//         memB : (y0,x1) and (y1,x1)
//     - Q16.16 phase accumulators, centered start
//     - bilinear MAC, >>32, clamp to 255
//
//   NOTE: nearest-neighbour (M1) lives in video_scaler_top.v and is unchanged.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module video_scaler_bilinear #(
    parameter SRC_W  = 1024,
    parameter SRC_H  = 600,
    parameter DST_W  = 640,
    parameter DST_H  = 480,
    parameter BANKS  = 4,       // power of two
    parameter ADDR_W = 11       // (1<<ADDR_W) >= SRC_W
)(
    input               clk,
    input               rst_n,

    // ---- source stream ----
    input               src_de,
    input               src_vs,
    input      [23:0]   src_rgb,

    // ---- output stream ----
    output              out_valid,
    output     [23:0]   out_rgb,
    input               out_ready,

    // ---- status / debug ----
    output              out_sof,
    output reg [15:0]   dbg_row_miss
);

    localparam DEPTH   = (1<<ADDR_W);
    localparam BANK_AW = $clog2(BANKS);
    localparam XW      = $clog2(SRC_W);
    localparam YW      = $clog2(SRC_H);
    localparam DXW     = $clog2(DST_W);
    localparam DYW     = $clog2(DST_H);
    localparam AW      = BANK_AW + ADDR_W;
    localparam PAD     = ADDR_W - XW;

    // Q16 step and centered offset : off = (0.5*SRC/DST - 0.5) * 2^16
    localparam [31:0] STEP_X = (SRC_W << 16) / DST_W;
    localparam [31:0] STEP_Y = (SRC_H << 16) / DST_H;
    localparam signed [31:0] OFF_X = (SRC_W << 15) / DST_W - 32'sd32768;
    localparam signed [31:0] OFF_Y = (SRC_H << 15) / DST_H - 32'sd32768;

    //--------------------------------------------------------------------------
    // line buffers : two copies, each with 1 write + 2 read ports
    //--------------------------------------------------------------------------
    (* ramstyle = "block" *) reg [23:0] memA [0:BANKS*DEPTH-1];
    (* ramstyle = "block" *) reg [23:0] memB [0:BANKS*DEPTH-1];

    reg  [AW-1:0] waddr;
    reg  [23:0]   wdata;
    reg           we;

    reg  [AW-1:0] ra, ra1, rb, rb1;
    reg  [23:0]   da, da1, db, db1;

    always @(posedge clk) begin
        if (we) begin
            memA[waddr] <= wdata;
            memB[waddr] <= wdata;
        end
        da  <= memA[ra ];
        da1 <= memA[ra1];
        db  <= memB[rb ];
        db1 <= memB[rb1];
    end

    //--------------------------------------------------------------------------
    // write side
    //--------------------------------------------------------------------------
    reg  [XW-1:0]    wr_x;
    reg  [YW-1:0]    wr_row;
    reg  [BANKS-1:0] row_done;
    reg  [YW-1:0]    row_id [0:BANKS-1];
    wire [BANK_AW-1:0] wr_bank = wr_row[BANK_AW-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_x <= {XW{1'b0}}; wr_row <= {YW{1'b0}};
            row_done <= {BANKS{1'b0}};
            we <= 1'b0; waddr <= {AW{1'b0}}; wdata <= 24'd0;
        end else if (src_vs) begin
            wr_x <= {XW{1'b0}}; wr_row <= {YW{1'b0}};
            row_done <= {BANKS{1'b0}}; we <= 1'b0;
        end else begin
            we <= src_de;
            if (src_de) begin
                waddr <= (wr_bank * DEPTH) + {{PAD{1'b0}}, wr_x};
                wdata <= src_rgb;
                wr_x  <= (wr_x == SRC_W-1) ? {XW{1'b0}} : (wr_x + 1'b1);
                if (wr_x == SRC_W-1) begin
                    row_done[wr_bank] <= 1'b1;
                    row_id  [wr_bank] <= wr_row;
                    wr_row            <= wr_row + 1'b1;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // phases
    //--------------------------------------------------------------------------
    reg signed [31:0] pos_x, pos_y;
    reg  [DXW-1:0]    out_x;
    reg  [DYW-1:0]    out_y;

    wire [XW-1:0] x0 = pos_x[31:16];                  // integer part (>=0 in down-scale)
    wire [XW-1:0] x1 = (x0 == SRC_W-1) ? x0 : (x0 + 1'b1);
    wire [15:0]   fx = pos_x[15:0];

    wire [YW-1:0] y0 = pos_y[31:16];
    wire [YW-1:0] y1 = (y0 == SRC_H-1) ? y0 : (y0 + 1'b1);
    wire [15:0]   fy = pos_y[15:0];

    wire [BANK_AW-1:0] y0_bank = y0[BANK_AW-1:0];
    wire [BANK_AW-1:0] y1_bank = y1[BANK_AW-1:0];
    wire row0_ok  = row_done[y0_bank] && (row_id[y0_bank] == y0);
    wire row1_ok  = row_done[y1_bank] && (row_id[y1_bank] == y1);
    wire pair_ok  = row0_ok && row1_ok;
    wire pair_past = (y0 < wr_row) && (y1 < wr_row);
    wire pair_miss = ~pair_ok && pair_past;

    //--------------------------------------------------------------------------
    // bilinear MAC
    //--------------------------------------------------------------------------
    reg  [15:0] fx_d1, fy_d1;   // stage 1 : issued together with the addresses
    reg  [15:0] fx_d2, fy_d2;   // stage 2 : aligned with the RAM data
    reg         mac_v1, mac_v;  // v1 = issued, v2 = data valid (aligned with da..)

    wire [16:0] ifx = 17'd65536 - {1'b0, fx_d2};
    wire [16:0] ify = 17'd65536 - {1'b0, fy_d2};

    // horizontal first (Q16), then vertical (Q32 -> >>32)
    wire [25:0] r_top = da[23:16]*ifx + db[23:16]*fx_d2;
    wire [25:0] r_bot = da1[23:16]*ifx + db1[23:16]*fx_d2;
    wire [25:0] g_top = da[15:8]*ifx + db[15:8]*fx_d2;
    wire [25:0] g_bot = da1[15:8]*ifx + db1[15:8]*fx_d2;
    wire [25:0] b_top = da[7:0]*ifx + db[7:0]*fx_d2;
    wire [25:0] b_bot = da1[7:0]*ifx + db1[7:0]*fx_d2;

    wire [42:0] r_mac = r_top*ify + r_bot*fy_d2;
    wire [42:0] g_mac = g_top*ify + g_bot*fy_d2;
    wire [42:0] b_mac = b_top*ify + b_bot*fy_d2;

    wire [9:0] r_res = r_mac[41:32];
    wire [9:0] g_res = g_mac[41:32];
    wire [9:0] b_res = b_mac[41:32];

    wire [7:0] r_out = (r_res > 10'd255) ? 8'd255 : r_res[7:0];
    wire [7:0] g_out = (g_res > 10'd255) ? 8'd255 : g_res[7:0];
    wire [7:0] b_out = (b_res > 10'd255) ? 8'd255 : b_res[7:0];

    //--------------------------------------------------------------------------
    // output skid
    //--------------------------------------------------------------------------
    reg        valid_r;
    reg [23:0] px_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_r <= 1'b0; px_r <= 24'd0;
        end else if (!valid_r || out_ready) begin
            valid_r <= mac_v;
            if (mac_v) px_r <= {r_out, g_out, b_out};
        end
    end

    assign out_valid = valid_r;
    assign out_rgb   = px_r;

    //--------------------------------------------------------------------------
    // read / emit FSM
    //--------------------------------------------------------------------------
    localparam S_IDLE = 2'd0, S_WAIT = 2'd1, S_EMIT = 2'd2, S_DRAIN = 2'd3;
    reg [1:0] state;
    reg       vs_d;
    wire      frame_start = src_vs & ~vs_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            out_x <= {DXW{1'b0}}; out_y <= {DYW{1'b0}};
            pos_x <= 32'sd0; pos_y <= 32'sd0;
            ra <= {AW{1'b0}}; ra1 <= {AW{1'b0}};
            rb <= {AW{1'b0}}; rb1 <= {AW{1'b0}};
            fx_d1 <= 16'd0; fy_d1 <= 16'd0; fx_d2 <= 16'd0; fy_d2 <= 16'd0;
            mac_v1 <= 1'b0; mac_v <= 1'b0;
            dbg_row_miss <= 16'd0; vs_d <= 1'b0;
        end else begin
            vs_d <= src_vs;
            mac_v1 <= 1'b0;
            mac_v  <= mac_v1;
            fx_d2  <= fx_d1;
            fy_d2  <= fy_d1;
            if (frame_start) begin
                state <= S_WAIT;
                out_x <= {DXW{1'b0}}; out_y <= {DYW{1'b0}};
                pos_x <= OFF_X; pos_y <= OFF_Y;
            end else begin
                case (state)
                //--------------------------------------------------- wait rows
                S_WAIT : begin
                    if (pair_ok) begin
                        out_x <= {DXW{1'b0}};
                        pos_x <= OFF_X;
                        state <= S_EMIT;
                    end else if (pair_miss) begin
                        dbg_row_miss <= dbg_row_miss + 1'b1;
                        state        <= S_DRAIN;
                    end
                end
                //--------------------------------------------------- emit row
                S_EMIT : begin
                    if (!valid_r || out_ready) begin
                        // issue the 2x2 read addresses
                        ra  <= (y0_bank * DEPTH) + {{PAD{1'b0}}, x0};
                        rb  <= (y0_bank * DEPTH) + {{PAD{1'b0}}, x1};
                        ra1 <= (y1_bank * DEPTH) + {{PAD{1'b0}}, x0};
                        rb1 <= (y1_bank * DEPTH) + {{PAD{1'b0}}, x1};
                        fx_d1  <= fx;
                        fy_d1  <= fy;
                        mac_v1 <= 1'b1;
                        pos_x <= pos_x + STEP_X;

                        if (out_x == DST_W-1) state <= S_DRAIN;
                        else                  out_x <= out_x + 1'b1;
                    end
                end
                //--------------------------------------------------- row done
                S_DRAIN : begin
                    if (!valid_r && !mac_v && !mac_v1) begin
                        pos_y <= pos_y + STEP_Y;
                        if (out_y == DST_H-1) begin
                            out_y <= {DYW{1'b0}};
                            state <= S_IDLE;
                        end else begin
                            out_y <= out_y + 1'b1;
                            state <= S_WAIT;
                        end
                    end
                end
                default : state <= S_WAIT;
                endcase
            end
        end
    end

    //--------------------------------------------------------------------------
    // frame start flag
    //--------------------------------------------------------------------------
    reg frame_first_px;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) frame_first_px <= 1'b0;
        else if (state == S_WAIT && pair_ok && (out_y == {DYW{1'b0}})) frame_first_px <= 1'b1;
        else if (out_valid && out_ready && frame_first_px)             frame_first_px <= 1'b0;
    end
    assign out_sof = out_valid & frame_first_px;

endmodule