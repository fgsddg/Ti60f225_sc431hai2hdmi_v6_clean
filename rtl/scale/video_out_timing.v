//////////////////////////////////////////////////////////////////////////////
// video_out_timing.v -- 640x480 raster, self-synchronising genlock
//   after each frame the raster waits for the FIRST pixel of the next frame
//   (pix_sof=1, carried in-band with the pixel) and pops/discards stale pixels,
//   so the frame phase is locked to the source without any flush.
//   840 x 500 @24.75MHz ; active 480*840 = 403200 clk = source active
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module video_out_timing #(
    parameter H_ACTIVE = 640, parameter H_FP = 16, parameter H_SYNC = 96, parameter H_BP = 88,
    parameter V_ACTIVE = 480, parameter V_FP = 10, parameter V_SYNC = 2, parameter V_BP = 8,
    parameter V_DELAY = 0,
    parameter NEG_SYNC = 1
)(
    input               clk,
    input               rst_n,
    input               pix_valid,
    input               pix_sof,
    input      [23:0]   pix_data,
    output              pix_req,
    output reg [23:0]   rgb,
    output reg          de,
    output reg          hs,
    output reg          vs,
    output reg          frame_done,
    output reg [15:0]   dbg_underflow,
    output reg [15:0]   dbg_sof_wait
);
    localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam V_TOTAL = V_DELAY + V_ACTIVE + V_FP + V_SYNC + V_BP;
    localparam HW = $clog2(H_TOTAL);
    localparam VW = $clog2(V_TOTAL);

    reg [HW-1:0] h_cnt;
    reg [VW-1:0] v_cnt;
    reg          run;

    wire h_active = (h_cnt < H_ACTIVE);
    wire v_active = (v_cnt >= V_DELAY) && (v_cnt < V_DELAY + V_ACTIVE);
    wire active   = h_active & v_active;
    wire starting = ~run & pix_valid & pix_sof;      // found the frame's first pixel

    wire hs_i = (h_cnt >= H_ACTIVE + H_FP) && (h_cnt < H_ACTIVE + H_FP + H_SYNC);
    wire vs_i = (v_cnt >= V_DELAY + V_ACTIVE + V_FP) && (v_cnt < V_DELAY + V_ACTIVE + V_FP + V_SYNC);

    // While hunting, discard stale pixels.  With a pre-roll delay, keep the
    // SOF pixel in the FIFO so it becomes the first active pixel after V_DELAY.
    wire hunt_req = ~run & pix_valid & (~pix_sof | (V_DELAY == 0));
    assign pix_req = run ? (active & pix_valid) : hunt_req;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin h_cnt <= {HW{1'b0}}; v_cnt <= {VW{1'b0}}; run <= 1'b0; end
        else if (!run) begin
            if (starting) begin
                h_cnt <= {{(HW-1){1'b0}}, 1'b1};      // the sof pixel is h=0
                v_cnt <= {VW{1'b0}};
                run   <= 1'b1;
            end
        end else begin
            if (h_cnt == H_TOTAL-1) begin
                h_cnt <= {HW{1'b0}};
                if (v_cnt == V_TOTAL-1) begin v_cnt <= {VW{1'b0}}; run <= 1'b0; end
                else v_cnt <= v_cnt + 1'b1;
            end else h_cnt <= h_cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb <= 24'd0; de <= 1'b0; hs <= 1'b0; vs <= 1'b0;
            frame_done <= 1'b0; dbg_underflow <= 16'd0; dbg_sof_wait <= 16'd0;
        end else begin
            de <= active & (run | starting);
            if (active & (run | starting) & pix_valid) rgb <= pix_data;
            else                                       rgb <= 24'd0;
            hs <= NEG_SYNC ? ~hs_i : hs_i;
            vs <= NEG_SYNC ? ~vs_i : vs_i;
            frame_done <= run && (h_cnt == H_TOTAL-1) && (v_cnt == V_TOTAL-1);
            if (active & (run | starting) & ~pix_valid) dbg_underflow <= dbg_underflow + 1'b1;
            if (!run && pix_valid && !pix_sof)          dbg_sof_wait <= dbg_sof_wait + 1'b1;
        end
    end
endmodule