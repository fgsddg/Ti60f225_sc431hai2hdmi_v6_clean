`timescale 1ns/1ps

// Streaming per-channel InstanceNorm statistics accumulator.
// Uses 64-bit accumulators because a full 640x480 conv1 channel can exceed
// int32 for both sum and sumsq.
module stats_accum_core (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                valid,
    input  wire signed [31:0]  data,
    output reg  signed [63:0]  sum,
    output reg  signed [63:0]  sumsq,
    output reg  [31:0]         count
);

    wire signed [63:0] data64 = $signed(data);
    wire signed [63:0] sq = data64 * data64;

    always @(posedge clk) begin
        if (!rst_n) begin
            sum   <= 64'sd0;
            sumsq <= 64'sd0;
            count <= 32'd0;
        end else if (valid) begin
            sum   <= sum + data64;
            sumsq <= sumsq + sq;
            count <= count + 32'd1;
        end
    end

endmodule
