`timescale 1ns/1ps

// Time-multiplexed INT8 3x3 convolution engine.
//
// One invocation computes one output channel from an IC-channel 3x3 window.
// Each cycle consumes up to LANES terms.  This is the synthesizable replacement
// for the fully unrolled conv3x3_zp_core used by the layer testbenches.
//
// The chunk sum (multiply + reduction) is registered before it is added to the
// accumulator.  Adding it combinationally put two more carry-chain levels on the
// same path as the row-select / zp-subtract / multiply chain and left core_clk
// 0.44 ns short of 100 MHz, so the chunk sum lands in `lane_sum_q` and the next
// cycle only does `acc + lane_sum_q`.  This costs one extra cycle per output
// channel and let `first_sum` (a second copy of the reduction tree) disappear.
//
// The reduction itself is a BALANCED adder tree, not a serial accumulation.
// `lane_sum = lane_sum + prod[i]` in a loop is ~LANES dependent adders deep; at
// the IC=16/OC=32/RAW=320x240 shape soc_top builds, that single chain became the
// worst path in the whole SoC once the residual-path logic was added:
//   u_engine/term_base[4] -> u_engine/lane_sum_q[0], 10.76 ns, 53-56 logic
//   levels, i.e. -0.788 ns of setup slack on a 10 ns clock
// and it was the ONLY violating path (the next worst had +0.141 ns).  See
// HANDOFF_ACCEL 9.19.  The tree is 4 levels deep at LANES=16 and 7 levels at
// LANES<=128, and it costs no extra cycles and no extra state.
//
// The tree is bit-identical to the serial chain: every product is exact, integer
// addition is associative, and every node is wide enough that no partial sum can
// overflow.  The per-term widths below are written out to match the serial
// version exactly -- a 9-bit (x - zp) and a 17-bit product -- so its truncation
// behaviour is preserved too.  tb_conv3x3_stage_lanes, the full stage suite and
// tb_style_accel_top_res0 all still reproduce their baseline mismatches.
/* Runtime-shape variant (HANDOFF_ACCEL 9.22 five / 9.23): the term count is now
 * an input (`terms` = IC*9) so ONE bitstream serves every pass in the 19-pass
 * envelope, while the x_flat/w_flat storage stays sized by MAX_IC.  TERMS_MAX is
 * MAX_IC*9, so the lane mask below is a runtime compare -- the extra term-mux
 * width that buys is the timing risk flagged in 9.23 section three. */
module conv3x3_zp_lanes #(
    parameter integer MAX_IC = 32,
    parameter integer MAX_OC = 32,
    parameter integer LANES  = 8
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           start,
    input  wire [9:0]                     terms,     /* runtime IC*9, <= MAX_IC*9 */
    input  wire [$clog2(MAX_OC)-1:0]      oc_sel,
    input  wire signed [8*MAX_IC*9-1:0]   x_flat,
    input  wire signed [8*MAX_IC*9-1:0]   w_flat,    /* current oc only */
    input  wire signed [8:0]              zp_in,
    output reg                            busy,
    output reg                            done,
    output reg  signed [31:0]             acc_out
);

    localparam integer TERMS_MAX = MAX_IC * 9;

    /* Balanced reduction: pad the lane count up to a power of two, then sum with
     * an implicit binary tree over one wire array -- leaf i sits at P+i, node n
     * is node[2n] + node[2n+1], and the root is node[1].  Every index below is a
     * constant once the generate loops elaborate, so this is plain combinational
     * logic, just shallow. */
    localparam integer LEAFS  = (LANES < 2) ? 1 : LANES;
    localparam integer LEVELS = $clog2(LEAFS);
    localparam integer P      = 1 << LEVELS;

    /* One term is (x - zp) * w with a 9-bit signed difference and an 8-bit signed
     * weight, exactly as the serial loop sized them, so a product is 17-bit
     * signed.  A node sums at most P of those, and P <= 128 keeps |node| < 2^22,
     * so TW bits can never overflow and the tree is exact. */
    localparam integer PW = 17;
    localparam integer TW = PW + LEVELS + 1;

    reg [31:0] term_base;
    reg signed [31:0] acc;
    reg signed [31:0] lane_sum_q;
    reg phase;                       /* 0 = feed chunks, 1 = final accumulate */

    wire [31:0] terms_left = terms - term_base;   /* kept for debug/parity */

    wire signed [PW-1:0] prod_lane [0:P-1];
    wire signed [TW-1:0] node      [0:2*P-1];

    genvar gv, gl;
    generate
        for (gv = 0; gv < P; gv = gv + 1) begin: g_lane
            if (gv < LANES) begin: g_real
                /* xv, wv and pv are their own signed wires on purpose.  Writing
                 * `cond ? (xv * wv) : 0` inline makes the ternary's type unsigned
                 * (the zero operand is a concatenation), that unsignedness leaks
                 * down into the multiply's context, and the 8-bit weight is then
                 * ZERO-extended instead of sign-extended: -3 * 1 silently became
                 * 253 * 1.  The serial version never tripped over this because it
                 * accumulated into a signed 32-bit reg.  Keep the product in a
                 * signed wire and only the bit pattern goes through the ternary. */
                wire signed [8:0]    xv = $signed(x_flat[8*(term_base + gv) +: 8]) - zp_in;
                wire signed [7:0]    wv = $signed(w_flat[8*(term_base + gv) +: 8]);
                wire signed [PW-1:0] pv = xv * wv;
                assign prod_lane[gv] = ((term_base + gv) < terms) ? pv : {PW{1'b0}};
            end else begin: g_pad
                assign prod_lane[gv] = {PW{1'b0}};
            end
        end

        for (gv = 0; gv < P; gv = gv + 1) begin: g_leaf
            assign node[P + gv] = prod_lane[gv];
        end

        for (gl = 0; gl < LEVELS; gl = gl + 1) begin: g_level
            for (gv = 0; gv < (P >> (gl + 1)); gv = gv + 1) begin: g_node
                assign node[(P >> (gl + 1)) + gv] =
                    node[2*((P >> (gl + 1)) + gv)] + node[2*((P >> (gl + 1)) + gv) + 1];
            end
        end
    endgenerate

    /* The tree root cannot overflow TW, so this sign extension is exact.
     * tree_root exists only so the sign bit is read from a plain vector: a
     * bit-select of an array element (node[1][TW-1]) is SystemVerilog, not
     * Verilog-2001, and the synthesis front end is the one tool we cannot run
     * here (see HANDOFF_ACCEL 9.19 section five). */
    wire signed [TW-1:0] tree_root = node[1];
    wire signed [31:0] lane_sum = {{(32-TW){tree_root[TW-1]}}, tree_root};

    always @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            term_base <= 32'd0;
            acc <= 32'sd0;
            acc_out <= 32'sd0;
            lane_sum_q <= 32'sd0;
            phase <= 1'b0;
        end else begin
            done <= 1'b0;
            if (!busy) begin
                if (start) begin
                    busy <= 1'b1;
                    term_base <= 32'd0;
                    acc <= 32'sd0;
                    lane_sum_q <= 32'sd0;
                    phase <= 1'b0;
                end
            end else if (!phase) begin
                /* lane_sum_q holds the previous chunk while lane_sum is the
                 * chunk selected by term_base; accumulate one, fetch the next. */
                lane_sum_q <= lane_sum;
                acc <= acc + lane_sum_q;
                if ((term_base + LANES) >= terms)
                    phase <= 1'b1;          /* last chunk fetched; finish next */
                else
                    term_base <= term_base + LANES;
            end else begin
                acc <= acc + lane_sum_q;
                acc_out <= acc + lane_sum_q;
                busy <= 1'b0;
                done <= 1'b1;
                phase <= 1'b0;
            end
        end
    end

endmodule
