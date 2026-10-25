//////////////////////////////////////////////////////////////////////////////
// video_scaler_top.v  --  streaming arbitrary-ratio video scaler (M1: nearest)
//
//   source : 1 pixel/clk, de/vs qualified, 24-bit RGB  (e.g. 1024x600 @49.5MHz)
//   target : 1 pixel/clk, valid/ready qualified, 24-bit RGB (e.g. 640x480)
//
//   sampling (centered, correct for both up/down scaling):
//       src = floor( (2*dst + 1) * SRC / (2*DST) )
//     which equals round( (dst + 0.5)*SRC/DST - 0.5 ) = nearest neighbour of
//     (dst+0.5)*SRC/DST - 0.5
//
//   architecture: BANKS line buffers + per-bank row-ready tags (streaming,
//   no full-frame buffering, no DDR access needed)
//
//   NOTE (M1): single clock domain, nearest neighbour only. Bilinear (M2) and
//   the 640x480 output timing / PLL / SDC (M3) are separate steps.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module video_scaler_top #(
    parameter SRC_W   = 1024,
    parameter SRC_H   = 600,
    parameter DST_W   = 640,
    parameter DST_H   = 480,
    parameter BANKS   = 4,          // power of two
    parameter ADDR_W  = 11,         // (1<<ADDR_W) >= SRC_W
    parameter MAX_SUB = 3           // >= ceil(SRC/DST) + 1
)(
    input               clk,
    input               rst_n,

    // ---- source stream (1 pixel/clk) ----
    input               src_de,
    input               src_vs,
    input      [23:0]   src_rgb,

    // ---- output stream ----
    output              out_valid,
    output     [23:0]   out_rgb,
    input               out_ready,

    // ---- status / debug ----
    output              out_sof,        // 1 on first pixel of a frame
    output reg [15:0]   dbg_row_miss    // output rows whose source row was overwritten
);

    localparam DEPTH   = (1<<ADDR_W);
    localparam BANK_AW = $clog2(BANKS);
    localparam XW      = $clog2(SRC_W);
    localparam YW      = $clog2(SRC_H);
    localparam DXW     = $clog2(DST_W);
    localparam DYW     = $clog2(DST_H);
    localparam AW      = BANK_AW + ADDR_W;
    localparam PAD     = ADDR_W - XW;          // >=0 required
    // phase init : src = floor((0.5*SRC)/DST)  (normalized, needed for ratio >= 2)
    localparam SX_INIT = (SRC_W/2)/DST_W;
    localparam AX_INIT = (SRC_W/2)%DST_W;
    localparam SY_INIT = (SRC_H/2)/DST_H;
    localparam AY_INIT = (SRC_H/2)%DST_H;

    //--------------------------------------------------------------------------
    // line buffers (infer block RAM)
    //--------------------------------------------------------------------------
    (* ramstyle = "block" *) reg [23:0] mem [0:BANKS*DEPTH-1];

    reg  [AW-1:0] waddr;
    reg  [23:0]   wdata;
    reg           we;
    always @(posedge clk) if (we) mem[waddr] <= wdata;

    reg  [AW-1:0] raddr;
    reg           re;
    reg  [23:0]   rdata;
    always @(posedge clk) if (re) rdata <= mem[raddr];

    //--------------------------------------------------------------------------
    // write side : store incoming rows, tag the bank that now holds which row
    //--------------------------------------------------------------------------
    reg  [XW-1:0]    wr_x;
    reg  [YW-1:0]    wr_row;
    reg  [BANKS-1:0] row_done;
    reg  [YW-1:0]    row_id [0:BANKS-1];
    wire [BANK_AW-1:0] wr_bank = wr_row[BANK_AW-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_x     <= {XW{1'b0}};
            wr_row   <= {YW{1'b0}};
            row_done <= {BANKS{1'b0}};
            we       <= 1'b0;
            waddr    <= {AW{1'b0}};
            wdata    <= 24'd0;
        end else if (src_vs) begin
            wr_x     <= {XW{1'b0}};
            wr_row   <= {YW{1'b0}};
            row_done <= {BANKS{1'b0}};
            we       <= 1'b0;
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
    // x phase : src_x = floor( (2*out_x+1)*SRC_W / (2*DST_W) )
    //   acc_x init = SRC_W/2 , then  use src_x ; acc_x += SRC_W ;
    //   while (acc_x >= DST_W) { acc_x -= DST_W ; src_x++ }
    //--------------------------------------------------------------------------
    reg  [DXW-1:0] out_x;
    reg  [XW-1:0]  src_x;
    reg  [15:0]    acc_x;

    wire [15:0] x_sum = acc_x + SRC_W;
    reg  [15:0] x_acc_n;
    reg  [XW:0] x_n;
    integer ix;
    always @(*) begin
        x_acc_n = x_sum;
        x_n     = src_x;
        for (ix = 0; ix < MAX_SUB; ix = ix + 1) begin
            if (x_acc_n >= DST_W) begin
                x_acc_n = x_acc_n - DST_W;
                x_n     = x_n + 1'b1;
            end
        end
    end

    //--------------------------------------------------------------------------
    // y phase : src_y = floor( (2*out_y+1)*SRC_H / (2*DST_H) )
    //--------------------------------------------------------------------------
    reg  [DYW-1:0] out_y;
    reg  [YW-1:0]  src_y;
    reg  [15:0]    acc_y;

    wire [15:0] y_sum = acc_y + SRC_H;
    reg  [15:0] y_acc_n;
    reg  [YW:0] y_n;
    integer iy;
    always @(*) begin
        y_acc_n = y_sum;
        y_n     = src_y;
        for (iy = 0; iy < MAX_SUB; iy = iy + 1) begin
            if (y_acc_n >= DST_H) begin
                y_acc_n = y_acc_n - DST_H;
                y_n     = y_n + 1'b1;
            end
        end
    end

    wire [BANK_AW-1:0] rd_bank    = src_y[BANK_AW-1:0];
    wire               row_ready  = row_done[rd_bank] && (row_id[rd_bank] == src_y);
    // row_missed : writer has already moved past this row and the bank was reused
    wire               row_missed = ~row_ready && (src_y < wr_row);

    //--------------------------------------------------------------------------
    // output skid buffer : holds one pixel until accepted
    //--------------------------------------------------------------------------
    reg        re_d;
    reg        valid_r;
    reg [23:0] px_r;

    always @(posedge clk) re_d <= re;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_r <= 1'b0;
            px_r    <= 24'd0;
        end else if (!valid_r || out_ready) begin
            valid_r <= re_d;
            if (re_d) px_r <= rdata;
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
            state        <= S_IDLE;
            out_x        <= {DXW{1'b0}};
            out_y        <= {DYW{1'b0}};
            src_x        <= {XW{1'b0}};
            src_y        <= {YW{1'b0}};
            acc_x        <= 16'd0;
            acc_y        <= 16'd0;
            re           <= 1'b0;
            raddr        <= {AW{1'b0}};
            dbg_row_miss <= 16'd0;
            vs_d         <= 1'b0;
        end else begin
            vs_d  <= src_vs;
            re    <= 1'b0;
            if (frame_start) begin
                // new frame : restart at destination (0,0)
                state   <= S_WAIT;
                out_x   <= {DXW{1'b0}};
                out_y   <= {DYW{1'b0}};
                src_x   <= {XW{1'b0}};
                src_y   <= SY_INIT[YW-1:0];
                acc_x   <= AX_INIT;
                acc_y   <= AY_INIT;
            end else begin
                case (state)
                //----------------------------------------------------------
                S_IDLE : state <= S_IDLE;   // wait for the next frame start
                //----------------------------------------------------------
                S_WAIT : begin
                    if (row_ready) begin
                        out_x <= {DXW{1'b0}};
                        src_x <= SX_INIT[XW-1:0];
                        acc_x <= AX_INIT;
                        state <= S_EMIT;
                    end else if (row_missed) begin
                        dbg_row_miss <= dbg_row_miss + 1'b1;   // row already overwritten
                        state        <= S_DRAIN;
                    end
                end
                //----------------------------------------------------------
                S_EMIT : begin
                    if (!valid_r || out_ready) begin
                        re    <= 1'b1;
                        raddr <= (rd_bank * DEPTH) + {{PAD{1'b0}}, src_x};

                        // advance horizontal phase
                        src_x <= x_n[XW-1:0];
                        acc_x <= x_acc_n;

                        if (out_x == DST_W-1) begin
                            state <= S_DRAIN;
                        end else begin
                            out_x <= out_x + 1'b1;
                        end
                    end
                end
                //----------------------------------------------------------
                S_DRAIN : begin
                    if (!valid_r) begin
                        // row finished -> advance vertical phase
                        src_y <= y_n[YW-1:0];
                        acc_y <= y_acc_n;
                        if (out_y == DST_H-1) begin
                            out_y <= {DYW{1'b0}};
                            state <= S_IDLE;
                        end else begin
                            out_y <= out_y + 1'b1;
                            state <= S_WAIT;
                        end
                    end
                end
                //----------------------------------------------------------
                default : state <= S_WAIT;
                endcase
            end
        end
    end

    // out_sof : first pixel of every frame
    reg frame_first_px;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) frame_first_px <= 1'b0;
        else if (state == S_WAIT && row_ready && (out_y == {DYW{1'b0}})) frame_first_px <= 1'b1;
        else if (out_valid && out_ready && frame_first_px)                  frame_first_px <= 1'b0;
    end
    assign out_sof = out_valid & frame_first_px;

endmodule