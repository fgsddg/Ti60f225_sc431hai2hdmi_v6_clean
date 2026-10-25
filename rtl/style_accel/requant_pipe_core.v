`timescale 1ns/1ps

// Pipelined requantization covering both post-InstanceNorm cases, selected by
// relu_en, so ONE instance serves the whole 19-pass sequence (the passes run one
// at a time; a second pipe would be dead area):
//
//   relu_en = 1 : y_q32 = max(0, acc*scale + bias)              <- conv + norm + relu
//   relu_en = 0 : y_q32 = acc*scale + bias + residual_q32       <- residual block
//   q_raw = (y_q32 * recip + 2^47) >>> 48
//   q_out = clamp(q_raw + zp, -128, 127)
//
// The relu path reproduces requant_relu_core bit for bit (including its 96-bit
// y truncation and the "q_high saturates" rule -- for y >= 0 the signed clamp is
// equivalent), and the residual path reproduces residual_add_requant_core.
// tb_requant_pipe_core checks both against those combinational cores and against
// the stored vector files.
//
// Latency: q_out reflects the inputs presented four cycles earlier.
module requant_pipe_core (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               relu_en,
    input  wire signed [31:0] acc,
    input  wire signed [63:0] norm_scale_q32,
    input  wire signed [63:0] norm_bias_q32,
    input  wire signed [63:0] residual_q32,
    input  wire        [63:0] q_scale_recip_q48,
    input  wire signed [7:0]  q_zero_point,
    output reg  signed [7:0]  q_out
);

    /* ---- stage 1: acc * norm_scale ---- */
    wire signed [95:0] affine_prod = $signed(acc) * $signed(norm_scale_q32);

    reg  signed [95:0] affine_prod_q;
    reg  signed [63:0] norm_bias_q;
    reg  signed [63:0] residual_q;
    reg                relu_q;

    /* ---- stage 2: + bias (+ residual), ReLU ---- */
    wire signed [99:0] aff_ext  = {{4{affine_prod_q[95]}}, affine_prod_q};
    wire signed [99:0] bias_ext = {{36{norm_bias_q[63]}}, norm_bias_q};
    wire signed [99:0] res_ext  = {{36{residual_q[63]}}, residual_q};
    wire signed [99:0] aff_sum  = aff_ext + bias_ext;
    wire        [95:0] y_relu   = (aff_sum < 0) ? 96'd0 : aff_sum[95:0];
    wire signed [99:0] y_q32    = relu_q ? {4'b0, y_relu} : (aff_sum + res_ext);

    reg  signed [99:0] y_q32_q;

    /* ---- stage 3: split the 100x64 multiply into two lanes ---- */
    wire signed [51:0]  y_hi = y_q32_q[99:48];
    wire        [47:0]  y_lo = y_q32_q[47:0];
    wire signed [127:0] p_hi = $signed(y_hi) * $signed({1'b0, q_scale_recip_q48});
    wire        [127:0] p_lo = {64'd0, y_lo} * {48'd0, q_scale_recip_q48};

    reg  signed [127:0] p_hi_q;
    reg  signed [127:0] p_lo_q;   /* >= 0 always, so signed is exact */

    /* ---- stage 4: reassemble, round, arithmetic shift, clamp ---- */
    wire signed [175:0] p_hi_ext  = {{48{p_hi_q[127]}}, p_hi_q};
    wire signed [175:0] p_lo_ext  = {{48{p_lo_q[127]}}, p_lo_q};
    wire signed [175:0] prod_full = (p_hi_ext <<< 48) + p_lo_ext;
    wire signed [175:0] rq_round  = prod_full + 176'sd140737488355328;  /* 1 << 47 */
    wire signed [127:0] q_raw     = rq_round >>> 48;
    wire signed [135:0] q_zp_ext  = {{128{q_zero_point[7]}}, q_zero_point};
    wire signed [135:0] q_shifted = $signed(q_raw) + q_zp_ext;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            affine_prod_q <= 96'sd0;
            norm_bias_q   <= 64'sd0;
            residual_q    <= 64'sd0;
            relu_q        <= 1'b1;
            y_q32_q       <= 100'sd0;
            p_hi_q        <= 128'sd0;
            p_lo_q        <= 128'sd0;
            q_out         <= 8'sd0;
        end else begin
            affine_prod_q <= affine_prod;
            norm_bias_q   <= norm_bias_q32;
            residual_q    <= residual_q32;
            relu_q        <= relu_en;
            y_q32_q       <= y_q32;
            p_hi_q        <= p_hi;
            p_lo_q        <= p_lo;

            if (q_shifted > 136'sd127)
                q_out <= 8'sd127;
            else if (q_shifted < -136'sd128)
                q_out <= -8'sd128;
            else
                q_out <= q_shifted[7:0];
        end
    end

endmodule
