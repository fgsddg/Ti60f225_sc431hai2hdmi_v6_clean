//////////////////////////////////////////////////////////////////////////////
// video_scale_out.v -- scaler + clock crossing + 640x480 raster (genlocked)
//   the scaler marks the first pixel of every output frame (out_sof) and that
//   bit travels with the pixel through the FIFO, so the output raster can lock
//   its frame phase to the source.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module video_scale_out #(
    parameter SRC_W   = 1024, parameter SRC_H = 600,
    parameter DST_W   = 640,  parameter DST_H = 480,
    parameter BANKS   = 4, parameter ADDR_W = 11, parameter MAX_SUB = 3,
    parameter H_FP    = 16, parameter H_SYNC = 96, parameter H_BP = 88,
    parameter V_FP    = 10, parameter V_SYNC = 2,  parameter V_BP = 8,
    parameter V_DELAY = 0,
    parameter USE_BILINEAR = 0,
    parameter AA_FILTER = 0,
    parameter NEG_SYNC = 1,
    parameter FIFO_DEPTH = 2048
)(
    input               src_clk,
    input               src_rst_n,
    input               src_de,
    input               src_vs,
    input      [23:0]   src_rgb,
    input               out_clk,
    input               out_rst_n,
    output     [23:0]   out_rgb,
    output              out_de,
    output              out_hs,
    output              out_vs,
    output              out_frame_done,
    output     [15:0]   dbg_underflow,
    output     [15:0]   dbg_row_miss,
    output     [15:0]   dbg_sof_wait
);
    wire        sc_valid;
    wire        sc_sof;
    wire [23:0] sc_rgb;
    wire        fifo_full;

    generate
        if (USE_BILINEAR) begin : g_bilinear
            video_scaler_bilinear #(
                .SRC_W(SRC_W), .SRC_H(SRC_H), .DST_W(DST_W), .DST_H(DST_H),
                .BANKS(BANKS), .ADDR_W(ADDR_W), .AA_FILTER(AA_FILTER)
            ) u_scaler (
                .clk(src_clk), .rst_n(src_rst_n),
                .src_de(src_de), .src_vs(src_vs), .src_rgb(src_rgb),
                .out_valid(sc_valid), .out_rgb(sc_rgb), .out_ready(~fifo_full),
                .out_sof(sc_sof), .dbg_row_miss(dbg_row_miss)
            );
        end else begin : g_nearest
            video_scaler_top #(
                .SRC_W(SRC_W), .SRC_H(SRC_H), .DST_W(DST_W), .DST_H(DST_H),
                .BANKS(BANKS), .ADDR_W(ADDR_W), .MAX_SUB(MAX_SUB)
            ) u_scaler (
                .clk(src_clk), .rst_n(src_rst_n),
                .src_de(src_de), .src_vs(src_vs), .src_rgb(src_rgb),
                .out_valid(sc_valid), .out_rgb(sc_rgb), .out_ready(~fifo_full),
                .out_sof(sc_sof), .dbg_row_miss(dbg_row_miss)
            );
        end
    endgenerate

    wire        pix_req;
    wire        fifo_empty;
    wire [24:0] fifo_rgb;

    DC_FIFO #(
        .FIFO_MODE ("ShowAhead"),
        .DATA_WIDTH(25),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_fifo (
        .Reset  (~(src_rst_n & out_rst_n)),
        .WrClk  (src_clk),
        .WrEn   (sc_valid & ~fifo_full),
        .WrDNum (),
        .WrFull (fifo_full),
        .WrData ({sc_sof,sc_rgb}),
        .RdClk  (out_clk),
        .RdEn   (pix_req),
        .RdDNum (),
        .RdEmpty(fifo_empty),
        .DataVal(),
        .RdData (fifo_rgb)
    );

    video_out_timing #(
        .H_ACTIVE(DST_W), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_ACTIVE(DST_H), .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP),
        .V_DELAY(V_DELAY), .NEG_SYNC(NEG_SYNC)
    ) u_timing (
        .clk(out_clk), .rst_n(out_rst_n),
        .pix_valid(~fifo_empty), .pix_sof(fifo_rgb[24]), .pix_data(fifo_rgb[23:0]),
        .pix_req(pix_req),
        .rgb(out_rgb), .de(out_de), .hs(out_hs), .vs(out_vs),
        .frame_done(out_frame_done), .dbg_underflow(dbg_underflow),
        .dbg_sof_wait(dbg_sof_wait)
    );
endmodule