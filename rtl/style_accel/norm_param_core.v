`timescale 1ns/1ps

// Fixed-point InstanceNorm parameter generation, Q32.32 variance path.
// Inputs are one channel's 64-bit conv statistics and layer constants.
// Outputs are Q32.32 affine parameters for y = acc*norm_scale + norm_bias.
//
// The whole derivation used to be one combinational cone: three 64x64
// multiplies in series from inv_n_q32 to isqrt_x, and two more from div_q to
// norm_bias (158 logic levels / 23.6 ns on Ti60, the last core_clk bottleneck).
// It is now spread over several cycles.  The downstream isqrt is already a
// ~33-cycle iterative unit, so the extra latency is free; `done` still pulses
// for exactly one cycle once every output is latched.
//
//   ST_IDLE -> ST_MEAN_MUL -> ST_MEAN_SQ -> ST_VAR_ACC -> ST_VAR_Y
//           -> ST_VAR_Y2 -> SQRT_START -> SQRT_WAIT -> DIV_START -> DIV_WAIT
//           -> ST_DIV_REG -> ST_NSCALE -> ST_NMUL -> ST_NBIAS (done)
//
// HANDOFF_ACCEL 9.50: the ten wide multiplies (68 DSP48 in the 9.49 PnR) are
// replaced by ONE shared 33x33 signed multiplier (4 DSP48) that is re-used
// across the five arithmetic states, one 32x32 partial product per cycle.  All
// of this is per-channel scalar work that runs ~288 times per frame, so the
// extra ~22 cycles per channel cost 0.001% of a frame.
//
// Bit-exactness is by construction, not by luck: every expression below is the
// SAME integer arithmetic as before, only re-associated, and every operand
// split is exact:
//     x = x_hi*2^32 + x_lo   (x_hi signed 32, x_lo unsigned 32, two's complement)
//     x*y = x_hi*y_hi*2^64 + (x_hi*y_lo + x_lo*y_hi)*2^32 + x_lo*y_lo
// with each sub-product < 2^64 (or < 2^63 for the signed halves), assembled by
// widened shifted adds exactly like the var_y split of HANDOFF_ACCEL 9.27 --
// whose four partial products are simply serialised here.
module norm_param_core (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               start,
    input  wire signed [63:0] sum_acc,
    input  wire        [63:0] sumsq_acc,
    input  wire        [31:0] inv_n_q32,
    input  wire signed [63:0] s2_q48,
    input  wire signed [63:0] sg_q32,
    input  wire signed [63:0] beta_q32,
    output reg                done,
    output reg  signed [63:0] mean_q32,
    output reg         [63:0] var_acc_q32,
    output reg         [63:0] var_y_q32,
    output reg         [31:0] sqrt_q16,
    output reg         [63:0] inv_std_q32,
    output reg  signed [63:0] norm_scale_q32,
    output reg  signed [63:0] norm_bias_q32
);

    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_MEAN_MUL   = 4'd1;
    localparam [3:0] ST_MEAN_SQ    = 4'd2;
    localparam [3:0] ST_VAR_ACC    = 4'd3;
    localparam [3:0] ST_VAR_Y      = 4'd4;
    localparam [3:0] ST_VAR_Y2     = 4'd13;  /* sum the registered partials */
    localparam [3:0] ST_SQRT_START = 4'd5;
    localparam [3:0] ST_SQRT_WAIT  = 4'd6;
    localparam [3:0] ST_DIV_START  = 4'd7;
    localparam [3:0] ST_DIV_WAIT   = 4'd8;
    localparam [3:0] ST_DIV_REG    = 4'd12;   /* register div_q before the mul */
    localparam [3:0] ST_NSCALE     = 4'd9;
    localparam [3:0] ST_NMUL       = 4'd10;
    localparam [3:0] ST_NBIAS      = 4'd11;

    reg [3:0] state;
    reg [2:0] mstep;                  /* sub-product index inside a state */
    reg signed [63:0] sum_q;
    reg [63:0] sumsq_q;
    reg        [31:0] inv_n_q;
    reg signed [63:0] s2_q;
    reg signed [63:0] sg_q;
    reg signed [63:0] beta_q;

    reg signed [63:0] mean_q;          /* mean held for the norm_bias stage    */
    reg signed [63:0] mean_q32_r;      /* (sum  * inv_n)[63:0]                 */
    reg        [63:0] sumsq_div_q32_r; /* (sumsq* inv_n)[63:0]                 */
    reg signed [63:0] mean_sq_q32_r;   /* (mean * mean)[95:32]                 */
    reg signed [63:0] norm_scale_r;    /* (sg   * div_q)[95:32]                */
    /* div_q is registered before the multiply: the signed 64x64 DSP cascade plus
     * its correction adder is ~9.6 ns on its own, and taking the divider's output
     * net (0.6 ns) out of that cycle is what buys the slack back (HANDOFF 9.23). */
    reg signed [63:0] div_q_r;
    reg signed [63:0] mean_nscale_r;   /* (mean * norm_scale)[95:32]           */

    reg signed [63:0] var_acc_q32_q;
    reg        [63:0] var_y_q32_q;
    reg        [63:0] isqrt_x_q;
    reg        [31:0] sqrt_q16_q;
    reg        [63:0] inv_std_q32_q;
    reg isqrt_start;
    reg div_start;

    wire isqrt_done;
    wire [31:0] isqrt_y;
    wire div_done;
    wire [63:0] div_q;
    wire [63:0] div_r;
    wire div_zero;

    /* ---- ONE shared 33x33 signed multiplier (4 DSP48) --------------------
     * 33 bits so an unsigned 32-bit operand (zero-extended) is positive: the
     * signed product then equals the unsigned one exactly. */
    reg  signed [32:0] mul_a, mul_b;
    wire signed [65:0] mul_p = mul_a * mul_b;

    /* registered partial products, one per operand pair */
    reg signed [63:0] mp_hi_q, mp_lo_q;      /* sum_hi*inv_n , sum_lo*inv_n   */
    reg signed [63:0] sp_hi_q, sp_lo_q;      /* sumsq_hi*inv_n, sumsq_lo*inv_n*/
    reg signed [63:0] ms_hi_q, ms_mid_q, ms_lo_q;   /* mean^2 parts           */
    reg signed [63:0] pa_q, pb_q, pc_q, pd_q;       /* s2*var_acc parts       */
    reg signed [63:0] ns_hh_q, ns_hl_q, ns_lh_q, ns_ll_q;  /* sg*div_q parts  */
    reg signed [63:0] nm_hh_q, nm_hl_q, nm_lh_q, nm_ll_q;  /* mean*nscale    */

    /* operand pair for the current (state, mstep); *_hi is sign-extended to 33
     * bits, *_lo zero-extended (it is an unsigned half of a two's-complement
     * 64-bit value). */
    always @* begin
        mul_a = 33'sd0;
        mul_b = 33'sd0;
        case (state)
        ST_MEAN_MUL: begin
            case (mstep)
            3'd0: begin mul_a = {sum_q[63],   sum_q[63:32]};   mul_b = {1'b0, inv_n_q};       end
            3'd1: begin mul_a = {1'b0,        sum_q[31:0]};    mul_b = {1'b0, inv_n_q};       end
            3'd2: begin mul_a = {1'b0,        sumsq_q[63:32]}; mul_b = {1'b0, inv_n_q};       end
            default: begin mul_a = {1'b0,     sumsq_q[31:0]};  mul_b = {1'b0, inv_n_q};       end
            endcase
        end
        ST_MEAN_SQ: begin
            case (mstep)
            3'd0: begin mul_a = {mean_q32_r[63], mean_q32_r[63:32]}; mul_b = {mean_q32_r[63], mean_q32_r[63:32]}; end
            3'd1: begin mul_a = {mean_q32_r[63], mean_q32_r[63:32]}; mul_b = {1'b0, mean_q32_r[31:0]};           end
            default: begin mul_a = {1'b0, mean_q32_r[31:0]};         mul_b = {1'b0, mean_q32_r[31:0]};           end
            endcase
        end
        ST_VAR_Y: begin
            case (mstep)
            3'd0: begin mul_a = {s2_q[63], s2_q[63:32]}; mul_b = {1'b0, var_acc_q32_q[63:32]}; end
            3'd1: begin mul_a = {s2_q[63], s2_q[63:32]}; mul_b = {1'b0, var_acc_q32_q[31:0]};  end
            3'd2: begin mul_a = {1'b0, s2_q[31:0]};      mul_b = {1'b0, var_acc_q32_q[63:32]}; end
            default: begin mul_a = {1'b0, s2_q[31:0]};   mul_b = {1'b0, var_acc_q32_q[31:0]};  end
            endcase
        end
        ST_NSCALE: begin
            case (mstep)
            3'd0: begin mul_a = {sg_q[63], sg_q[63:32]}; mul_b = {div_q_r[63], div_q_r[63:32]}; end
            3'd1: begin mul_a = {sg_q[63], sg_q[63:32]}; mul_b = {1'b0, div_q_r[31:0]};         end
            3'd2: begin mul_a = {1'b0, sg_q[31:0]};      mul_b = {div_q_r[63], div_q_r[63:32]}; end
            default: begin mul_a = {1'b0, sg_q[31:0]};   mul_b = {1'b0, div_q_r[31:0]};         end
            endcase
        end
        default: begin  /* ST_NMUL */
            case (mstep)
            3'd0: begin mul_a = {mean_q[63], mean_q[63:32]}; mul_b = {norm_scale_r[63], norm_scale_r[63:32]}; end
            3'd1: begin mul_a = {mean_q[63], mean_q[63:32]}; mul_b = {1'b0, norm_scale_r[31:0]};               end
            3'd2: begin mul_a = {1'b0, mean_q[31:0]};        mul_b = {norm_scale_r[63], norm_scale_r[63:32]};   end
            default: begin mul_a = {1'b0, mean_q[31:0]};     mul_b = {1'b0, norm_scale_r[31:0]};               end
            endcase
        end
        endcase
    end

    /* ---- assemblies: the original shifted adds, verbatim ------------------ */

    /* mean_q32 = sum * inv_n  (Q32.32); low 64 bits, exactly as before */
    wire signed [63:0] mean_low64 =
        mp_lo_q + {mp_hi_q[31:0], 32'd0};
    wire signed [63:0] sumsq_low64 =
        sp_lo_q + {sp_hi_q[31:0], 32'd0};

    /* mean_sq = mean^2, exact 128-bit, take [95:32].  The middle term is
     * 2*mean_hi*mean_lo, i.e. the registered product shifted left by one. */
    wire [127:0] mean_sq_sum =
        ({ {64{ms_hi_q[63]}},  ms_hi_q}  << 64) +
        (({ {64{ms_mid_q[63]}}, ms_mid_q} << 1) << 32) +
        {64'd0, ms_lo_q};
    wire signed [63:0] mean_sq_calc = mean_sq_sum[95:32];

    /* var_y = s2 * var_acc: identical to the 9.27 four-partial assembly */
    wire [127:0] var_y_sum =
        ({ {64{pa_q[63]}}, pa_q} << 64) +
        (({ {64{pb_q[63]}}, pb_q} + {64'd0, pc_q}) << 32) +
        {64'd0, pd_q};
    wire [63:0] var_y_q32_calc = var_y_sum[111:48];

    /* norm_scale = (sg * div_q) >> 32, exact 128-bit intermediate */
    wire [127:0] norm_scale_sum =
        ({ {64{ns_hh_q[63]}}, ns_hh_q} << 64) +
        (({ {64{ns_hl_q[63]}}, ns_hl_q} + {64'd0, ns_lh_q}) << 32) +
        {64'd0, ns_ll_q};
    wire signed [63:0] norm_scale_calc = norm_scale_sum[95:32];

    /* norm_bias helper: mean * norm_scale, [95:32] */
    wire [127:0] mean_nscale_sum =
        ({ {64{nm_hh_q[63]}}, nm_hh_q} << 64) +
        (({ {64{nm_hl_q[63]}}, nm_hl_q} + {64'd0, nm_lh_q}) << 32) +
        {64'd0, nm_ll_q};
    wire signed [63:0] mean_nscale_prod_calc = mean_nscale_sum[95:32];

    wire signed [63:0] var_acc_calc = sumsq_div_q32_r - mean_sq_q32_r;
    wire [63:0] var_acc_pos = (var_acc_calc < 0) ? 64'd0 : var_acc_calc;

    isqrt_u64 u_isqrt (
        .clk(clk), .rst_n(rst_n), .start(isqrt_start), .x(isqrt_x_q),
        .done(isqrt_done), .y(isqrt_y)
    );

    div_u64 u_div (
        .clk(clk), .rst_n(rst_n), .start(div_start),
        .numerator(64'h0001000000000000), // 1 << 48
        .denominator({32'd0, sqrt_q16_q}),
        .done(div_done), .quotient(div_q), .remainder(div_r),
        .divide_by_zero(div_zero)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            mstep <= 3'd0;
            done <= 1'b0;
            isqrt_start <= 1'b0;
            div_start <= 1'b0;
            sum_q <= 64'sd0;
            sumsq_q <= 64'd0;
            inv_n_q <= 32'd0;
            s2_q <= 64'sd0;
            sg_q <= 64'sd0;
            beta_q <= 64'sd0;
            mean_q <= 64'sd0;
            mean_q32_r <= 64'sd0;
            sumsq_div_q32_r <= 64'd0;
            mean_sq_q32_r <= 64'sd0;
            norm_scale_r <= 64'sd0;
            mean_nscale_r <= 64'sd0;
            div_q_r <= 64'sd0;
            mp_hi_q <= 64'sd0; mp_lo_q <= 64'sd0;
            sp_hi_q <= 64'sd0; sp_lo_q <= 64'sd0;
            ms_hi_q <= 64'sd0; ms_mid_q <= 64'sd0; ms_lo_q <= 64'sd0;
            pa_q <= 64'sd0; pb_q <= 64'sd0; pc_q <= 64'sd0; pd_q <= 64'sd0;
            ns_hh_q <= 64'sd0; ns_hl_q <= 64'sd0; ns_lh_q <= 64'sd0; ns_ll_q <= 64'sd0;
            nm_hh_q <= 64'sd0; nm_hl_q <= 64'sd0; nm_lh_q <= 64'sd0; nm_ll_q <= 64'sd0;
            var_acc_q32_q <= 64'd0;
            var_y_q32_q <= 64'd0;
            isqrt_x_q <= 64'd0;
            sqrt_q16_q <= 32'd0;
            inv_std_q32_q <= 64'd0;
            mean_q32 <= 64'sd0;
            var_acc_q32 <= 64'd0;
            var_y_q32 <= 64'd0;
            sqrt_q16 <= 32'd0;
            inv_std_q32 <= 64'd0;
            norm_scale_q32 <= 64'sd0;
            norm_bias_q32 <= 64'sd0;
        end else begin
            done <= 1'b0;
            isqrt_start <= 1'b0;
            div_start <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        sum_q <= sum_acc;
                        sumsq_q <= sumsq_acc;
                        inv_n_q <= inv_n_q32;
                        s2_q <= s2_q48;
                        sg_q <= sg_q32;
                        beta_q <= beta_q32;
                        mstep <= 3'd0;
                        state <= ST_MEAN_MUL;
                    end
                end
                /* mean_q32_r = (sum * inv_n)[63:0] and
                 * sumsq_div_q32_r = (sumsq * inv_n)[63:0]: two 64x32 products,
                 * two 32x32 partials each. */
                ST_MEAN_MUL: begin
                    case (mstep)
                    3'd0: begin mp_hi_q <= mul_p[63:0]; mstep <= 3'd1; end
                    3'd1: begin mp_lo_q <= mul_p[63:0]; mstep <= 3'd2; end
                    3'd2: begin sp_hi_q <= mul_p[63:0]; mstep <= 3'd3; end
                    3'd3: begin sp_lo_q <= mul_p[63:0]; mstep <= 3'd4; end
                    default: begin          /* assemble once every partial is registered */
                        mean_q32_r      <= mean_low64;
                        sumsq_div_q32_r <= sumsq_low64;
                        mstep <= 3'd0;
                        state <= ST_MEAN_SQ;
                    end
                    endcase
                end
                ST_MEAN_SQ: begin
                    case (mstep)
                    3'd0: begin ms_hi_q  <= mul_p[63:0]; mstep <= 3'd1; end
                    3'd1: begin ms_mid_q <= mul_p[63:0]; mstep <= 3'd2; end
                    3'd2: begin ms_lo_q <= mul_p[63:0]; mstep <= 3'd3; end
                    default: begin
                        mean_sq_q32_r <= mean_sq_calc;
                        mean_q        <= mean_q32_r;
                        mean_q32      <= mean_q32_r;
                        mstep <= 3'd0;
                        state <= ST_VAR_ACC;
                    end
                    endcase
                end
                ST_VAR_ACC: begin
                    var_acc_q32_q <= var_acc_pos;
                    var_acc_q32   <= var_acc_pos;
                    state <= ST_VAR_Y;
                end
                ST_VAR_Y: begin
                    case (mstep)
                    3'd0: begin pa_q <= mul_p[63:0]; mstep <= 3'd1; end
                    3'd1: begin pb_q <= mul_p[63:0]; mstep <= 3'd2; end
                    3'd2: begin pc_q <= mul_p[63:0]; mstep <= 3'd3; end
                    default: begin
                        pd_q  <= mul_p[63:0];
                        mstep <= 3'd0;
                        state <= ST_VAR_Y2;
                    end
                    endcase
                end
                ST_VAR_Y2: begin
                    /* the registered partials are summed in one 128-bit add */
                    var_y_q32_q <= var_y_q32_calc;
                    var_y_q32   <= var_y_q32_calc;
                    isqrt_x_q   <= var_y_q32_calc;
                    state <= ST_SQRT_START;
                end
                ST_SQRT_START: begin
                    isqrt_start <= 1'b1;
                    state <= ST_SQRT_WAIT;
                end
                ST_SQRT_WAIT: begin
                    if (isqrt_done) begin
                        sqrt_q16_q <= isqrt_y;
                        sqrt_q16   <= isqrt_y;
                        state <= ST_DIV_START;
                    end
                end
                ST_DIV_START: begin
                    div_start <= 1'b1;
                    state <= ST_DIV_WAIT;
                end
                ST_DIV_WAIT: begin
                    if (div_done) begin
                        inv_std_q32_q <= div_q;
                        inv_std_q32   <= div_q;
                        state <= ST_DIV_REG;
                    end
                end
                ST_DIV_REG: begin
                    div_q_r <= div_q;
                    state   <= ST_NSCALE;
                    mstep   <= 3'd0;
                end
                ST_NSCALE: begin
                    case (mstep)
                    3'd0: begin ns_hh_q <= mul_p[63:0]; mstep <= 3'd1; end
                    3'd1: begin ns_hl_q <= mul_p[63:0]; mstep <= 3'd2; end
                    3'd2: begin ns_lh_q <= mul_p[63:0]; mstep <= 3'd3; end
                    3'd3: begin ns_ll_q <= mul_p[63:0]; mstep <= 3'd4; end
                    default: begin
                        norm_scale_r   <= norm_scale_calc;
                        norm_scale_q32 <= norm_scale_calc;
                        mstep <= 3'd0;
                        state <= ST_NMUL;
                    end
                    endcase
                end
                ST_NMUL: begin
                    case (mstep)
                    3'd0: begin nm_hh_q <= mul_p[63:0]; mstep <= 3'd1; end
                    3'd1: begin nm_hl_q <= mul_p[63:0]; mstep <= 3'd2; end
                    3'd2: begin nm_lh_q <= mul_p[63:0]; mstep <= 3'd3; end
                    3'd3: begin nm_ll_q <= mul_p[63:0]; mstep <= 3'd4; end
                    default: begin
                        mean_nscale_r <= mean_nscale_prod_calc;
                        mstep <= 3'd0;
                        state <= ST_NBIAS;
                    end
                    endcase
                end
                ST_NBIAS: begin
                    norm_bias_q32 <= beta_q - mean_nscale_r;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
