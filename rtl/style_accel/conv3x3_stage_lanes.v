`timescale 1ns/1ps

// Streaming INT8 3x3 convolution stage.
//
// Owns reflect-pad -> 3x3 window -> time-multiplexed lane engine for one
// convolution layer. It accepts RAW_H x RAW_W raster input, produces one
// acc_flat (OC x int32) per output pixel, and applies downstream backpressure
// so no window is lost while the shared engine is busy.
module conv3x3_stage_lanes #(
    parameter integer RAW_W = 640,
    parameter integer RAW_H = 480,
    parameter integer IC = 8,
    parameter integer OC = 16,
    parameter integer LANES = 80,
    parameter integer STRIDE = 1,
    /* Width of the assembled weight window.  IC = MAX_IC today; the runtime-shape
     * step keeps IC <= MAX_IC and then only needs ceil(IC*9/32) words
     * (HANDOFF_ACCEL 9.21). */
    parameter integer MAX_IC = IC
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         in_valid,
    input  wire [8*IC-1:0]              in_pixel,
    output wire                         in_ready,
    output wire [$clog2(OC)+4-1:0]      w_addr,      /* {oc, 32-byte word slot} */
    input  wire [255:0]                 w_rdata,     /* 32 flat bytes of the filter */
    input  wire signed [8:0]            zp_in,
    output reg  signed [32*OC-1:0]      acc_flat,
    output wire                         out_valid,
    input  wire                         out_ready,
    output reg                          done
);

    localparam integer PW = RAW_W + 2;
    localparam integer OUT_W = (RAW_W + STRIDE - 1) / STRIDE;
    localparam integer OUT_H = (RAW_H + STRIDE - 1) / STRIDE;
    localparam integer OUT_COUNT = OUT_W * OUT_H;

    /* The weight BRAM holds 32 flat bytes of the current OC's filter per address,
     * so one filter costs ceil(IC*9/32) reads and the address is {oc, word}. */
    localparam integer WSTRIDE = (MAX_IC * 9 + 31) / 32;
    localparam [9:0]   TERMS_C  = IC * 9;   /* engine term count (IC fixed here) */

    localparam integer ST_IDLE  = 3'd0;
    localparam integer ST_WLOAD = 3'd1;
    localparam integer ST_START = 3'd2;
    localparam integer ST_WAIT  = 3'd3;
    localparam integer ST_EMIT  = 3'd4;

    reg [2:0] state;
    reg hold;
    reg [$clog2(OC)-1:0] oc_idx;
    reg [256*WSTRIDE-1:0] w_reg;   /* WSTRIDE x 32 bytes, flat */
    reg [3:0] w_j;                 /* word slot being fetched */
    reg [31:0] out_count;

    wire [IC-1:0] pad_valid_vec;
    wire [IC-1:0] pad_ready_vec;
    wire [IC-1:0] pad_done_vec;
    wire signed [7:0] pad_data [0:IC-1];
    wire [IC-1:0] lb_in_ready_vec;
    wire [IC-1:0] lb_valid;
    wire signed [7:0] win [0:IC*9-1];
    wire signed [8*IC*9-1:0] win_flat;

    reg  signed [8*IC*9-1:0] x_flat;
    wire signed [31:0] eng_acc;
    wire eng_busy;
    wire eng_done;

    genvar gc;
    genvar gi;

    // The whole stage advances only when every channel can accept. All IC
    // reflect-pad / line-buffer channels share the same control, so channel 0
    // is sufficient for the ready term.
    // pad.out_ready already carries the line-buffer backpressure, and the
    // line-buffer in_ready itself folds in hold. Gating with hold a second time
    // would let the line buffer eat a stalled pad pixel without the pad
    // advancing, so the source-side ready is just the pad capture ready.
    assign in_ready = pad_ready_vec[0];
    assign out_valid = (state == ST_EMIT);

    // One BRAM word holds one output channel's complete IC*9-byte filter.
    // Issue the next OC address while the current state is still active; the
    // synchronous BRAM returns that word during ST_WLOAD.
    /* The address is issued one cycle before the word is consumed (the BRAM read
     * is registered), so ST_WLOAD presents slot w_j+1 while latching word w_j. */
    assign w_addr = (state == ST_WLOAD) ? {oc_idx, (w_j + 4'd1)} :
                    (state == ST_IDLE)  ? {($clog2(OC)+4){1'b0}} :
                    ((state == ST_WAIT) && eng_done && (oc_idx != OC-1)) ?
                        {(oc_idx + 1'b1), 4'd0} : {($clog2(OC)+4){1'b0}};

    generate
        for (gc = 0; gc < IC; gc = gc + 1) begin: g_chan
            wire signed [7:0] w00, w01, w02;
            wire signed [7:0] w10, w11, w12;
            wire signed [7:0] w20, w21, w22;
            reflect_pad1_stream #(.WIDTH(RAW_W), .HEIGHT(RAW_H), .DW(8)) pad (
                .clk(clk), .rst_n(rst_n),
                .in_valid(in_valid), .in_data(in_pixel[8*gc +: 8]),
                .in_ready(pad_ready_vec[gc]),
                .out_valid(pad_valid_vec[gc]), .out_data(pad_data[gc]),
                .out_ready(lb_in_ready_vec[gc]),
                .done(pad_done_vec[gc])
            );
            line_buffer_3x3_bp #(.WIDTH(PW), .DW(8), .STRIDE(STRIDE)) lb (
                .clk(clk), .rst_n(rst_n),
                .in_valid(pad_valid_vec[gc]), .din(pad_data[gc]),
                .in_ready(lb_in_ready_vec[gc]),
                .out_valid(lb_valid[gc]), .out_ready(!hold),
                .w00(w00), .w01(w01), .w02(w02),
                .w10(w10), .w11(w11), .w12(w12),
                .w20(w20), .w21(w21), .w22(w22)
            );
            assign win[gc*9 + 0] = w00;
            assign win[gc*9 + 1] = w01;
            assign win[gc*9 + 2] = w02;
            assign win[gc*9 + 3] = w10;
            assign win[gc*9 + 4] = w11;
            assign win[gc*9 + 5] = w12;
            assign win[gc*9 + 6] = w20;
            assign win[gc*9 + 7] = w21;
            assign win[gc*9 + 8] = w22;
        end
    endgenerate

    generate
        for (gi = 0; gi < IC*9; gi = gi + 1) begin: g_winflat
            assign win_flat[8*gi +: 8] = win[gi];
        end
    endgenerate

    conv3x3_zp_lanes #(.MAX_IC(IC), .MAX_OC(OC), .LANES(LANES)) u_engine (
        .clk(clk), .rst_n(rst_n), .start(state == ST_START),
        .terms(TERMS_C),
        .oc_sel(oc_idx), .x_flat(x_flat), .zp_in(zp_in),
        .w_flat(w_reg[8*IC*9-1:0]),
        .busy(eng_busy), .done(eng_done), .acc_out(eng_acc)
    );

    // Once a window is latched, the line buffers are frozen (hold=1) while the
    // per-OC weight register file is reloaded and the OC loop runs.
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            hold <= 1'b0;
            oc_idx <= 0;
            w_reg <= {256*WSTRIDE{1'b0}};
            w_j   <= 4'd0;
            out_count <= 32'd0;
            x_flat <= {8*IC*9{1'b0}};
            acc_flat <= {32*OC{1'b0}};
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (lb_valid[0]) begin
                        x_flat <= win_flat;
                        hold <= 1'b1;
                        oc_idx <= 0;
                        w_j    <= 4'd0;
                        state <= ST_WLOAD;
                    end
                end
                /* One 32-byte weight word per cycle, address slot running one
                 * ahead.  WSTRIDE words cover the whole filter. */
                ST_WLOAD: begin
                    w_reg[256*w_j +: 256] <= w_rdata;
                    if (w_j == WSTRIDE - 1) begin
                        w_j   <= 4'd0;
                        state <= ST_START;
                    end else begin
                        w_j <= w_j + 4'd1;
                    end
                end
                ST_START: begin
                    state <= ST_WAIT;
                end
                ST_WAIT: begin
                    if (eng_done) begin
                        acc_flat[32*oc_idx +: 32] <= eng_acc;
                        if (oc_idx == OC-1)
                            state <= ST_EMIT;
                        else begin
                            oc_idx <= oc_idx + 1'b1;
                            w_j    <= 4'd0;
                            state <= ST_WLOAD;
                        end
                    end
                end
                ST_EMIT: begin
                    if (out_ready) begin
                        hold <= 1'b0;
                        out_count <= out_count + 32'd1;
                        if ((out_count + 32'd1) == OUT_COUNT)
                            done <= 1'b1;
                        state <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
