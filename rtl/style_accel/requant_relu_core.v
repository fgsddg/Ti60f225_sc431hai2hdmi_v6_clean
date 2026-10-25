`timescale 1ns/1ps

// Per-channel requantization after InstanceNorm affine + ReLU.
//
// Fixed-point contract:
//   y_q32 = max(0, acc * norm_scale_q32 + norm_bias_q32)
//   q_raw = round(y_q32 / q_scale_q32)
//   q_out = clamp(q_raw + q_zero_point, -128, 127)
//
// q_scale_q32 is a per-layer Q32.32 constant. The RTL divides by it with
// a Q48 reciprocal so the hot path is one fixed multiplier instead of a
// runtime divider:
//   q_raw = (y_q32 * q_scale_recip_q48 + 2^47) >> 48
module requant_relu_core (
    input  wire signed [31:0] acc,
    input  wire signed [63:0] norm_scale_q32,
    input  wire signed [63:0] norm_bias_q32,
    input  wire        [63:0] q_scale_recip_q48,
    input  wire signed [7:0]  q_zero_point,
    output reg  signed [7:0]  q_out
);

    wire signed [95:0] affine_prod = $signed(acc) * $signed(norm_scale_q32);
    wire signed [96:0] norm_bias_ext = {{33{norm_bias_q32[63]}}, norm_bias_q32};
    wire signed [96:0] affine_sum = $signed(affine_prod) + norm_bias_ext;
    wire        [95:0] y_q32 = (affine_sum < 0) ? 96'd0 : affine_sum[95:0];

    wire [159:0] rq_prod = y_q32 * {96'd0, q_scale_recip_q48};
    wire [159:0] rq_round = rq_prod + 160'd140737488355328; // 1 << 47
    wire [111:0] q_raw = rq_round >> 48;

    wire        q_high = |q_raw[111:8];
    wire [8:0] q_base = q_high ? 9'd256 : {1'b0, q_raw[7:0]};
    wire signed [10:0] q_base_ext = {2'b0, q_base};
    wire signed [10:0] q_zp_ext = {{3{q_zero_point[7]}}, q_zero_point};
    wire signed [10:0] q_shifted = q_base_ext + q_zp_ext;

    always @* begin
        if (q_high || (q_shifted > 11'sd127)) begin
            q_out = 8'sd127;
        end else if (q_shifted < -11'sd128) begin
            q_out = -8'sd128;
        end else begin
            q_out = q_shifted[7:0];
        end
    end

endmodule

`timescale 1ns/1ps

// Pipelined twin of requant_relu_core: identical fixed-point contract, but the
// work is split across four register stages so core_clk can actually close at
// 100 MHz.
//
//   y_q32 = max(0, acc * norm_scale_q32 + norm_bias_q32)
//   q_raw = (y_q32 * q_scale_recip_q48 + 2^47) >> 48
//   q_out = clamp(q_raw + q_zero_point, -128, 127)
//
// The combinational second multiply (96x64) is the long pole, so y_q32 is
// split into two 48-bit halves and multiplied by the reciprocal in two
// independent 48x64 lanes that run in parallel:
//
//   y_q32 * recip = (y_hi * 2^48 + y_lo) * recip
//                 = (y_hi * recip) * 2^48 + (y_lo * recip)
//
// That is bit-exact, just narrower per lane. requant_relu_core is kept as the
// combinational reference model for the stage testbenches.
//
// Latency: q_out reflects the inputs presented four cycles earlier.
module requant_relu_pipe_core (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [31:0] acc,
    input  wire signed [63:0] norm_scale_q32,
    input  wire signed [63:0] norm_bias_q32,
    input  wire        [63:0] q_scale_recip_q48,
    input  wire signed [7:0]  q_zero_point,
    output reg  signed [7:0]  q_out
);

    /* ---- stage 1: acc * norm_scale ---- */
    wire signed [95:0] affine_prod = $signed(acc) * $signed(norm_scale_q32);

    reg signed [95:0] affine_prod_q;
    reg signed [63:0] norm_bias_q;

    /* ---- stage 2: + bias, relu ---- */
    /* Keep the sign-extended bias as its own signed wire: folding the concat
     * straight into the `+` would make the whole expression unsigned and the
     * ReLU comparison would never fire. */
    wire signed [96:0] norm_bias_ext = {{33{norm_bias_q[63]}}, norm_bias_q};
    wire signed [96:0] affine_sum = $signed(affine_prod_q) + norm_bias_ext;
    wire        [95:0] y_q32 = (affine_sum < 0) ? 96'd0 : affine_sum[95:0];

    reg         [95:0] y_q32_q;

    /* ---- stage 3: split 96x64 multiply, two 48x64 lanes ---- */
    wire [47:0]   y_lo = y_q32_q[47:0];
    wire [47:0]   y_hi = y_q32_q[95:48];
    wire [111:0]  p_lo = {64'd0, y_lo} * {48'd0, q_scale_recip_q48};
    wire [111:0]  p_hi = {64'd0, y_hi} * {48'd0, q_scale_recip_q48};

    reg  [111:0]  p_lo_q;
    reg  [111:0]  p_hi_q;

    /* ---- stage 4: reassemble, round, shift, clamp ---- */
    wire [159:0] rq_full  = ({48'd0, p_hi_q} << 48) + {48'd0, p_lo_q};
    wire [159:0] rq_round = rq_full + 160'd140737488355328;   /* 1 << 47 */
    wire [111:0] q_raw    = rq_round >> 48;

    wire         q_high = |q_raw[111:8];
    wire [8:0]   q_base = q_high ? 9'd256 : {1'b0, q_raw[7:0]};
    wire signed [10:0] q_base_ext = {2'b0, q_base};
    wire signed [10:0] q_zp_ext   = {{3{q_zero_point[7]}}, q_zero_point};
    wire signed [10:0] q_shifted  = q_base_ext + q_zp_ext;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            affine_prod_q <= 96'sd0;
            norm_bias_q   <= 64'sd0;
            y_q32_q       <= 96'd0;
            p_lo_q        <= 112'd0;
            p_hi_q        <= 112'd0;
            q_out         <= 8'sd0;
        end else begin
            affine_prod_q <= affine_prod;
            norm_bias_q   <= norm_bias_q32;
            y_q32_q       <= y_q32;
            p_lo_q        <= p_lo;
            p_hi_q        <= p_hi;

            if (q_high || (q_shifted > 11'sd127))
                q_out <= 8'sd127;
            else if (q_shifted < -11'sd128)
                q_out <= -8'sd128;
            else
                q_out <= q_shifted[7:0];
        end
    end

endmodule
