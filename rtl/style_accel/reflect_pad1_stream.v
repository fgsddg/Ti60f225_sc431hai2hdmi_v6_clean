`timescale 1ns/1ps

// Streaming one-pixel reflect padding for raster-scan input.
// This matches torch.nn.ReflectionPad2d(1) / np.pad(mode="reflect"): the edge
// sample itself is not repeated. Example: [a,b,c] -> [b,a,b,c,b].
//
// The two row banks are packed into a single synchronous block RAM (bank0 at
// [0,WIDTH-1], bank1 at [WIDTH,2*WIDTH-1]). The previous revision read the
// banks combinationally (`row_mem[out_col-1]`), which Efinity lowered into
// ~10k FF + ~9k LUT of logic memory per channel; the emit path now issues the
// row addresses one beat ahead of the output so the read is a real BRAM port.
// The reflect border is folded into the read address, so no data-side mux is
// needed. Interface is unchanged.
module reflect_pad1_stream #(
    parameter integer WIDTH  = 640,
    parameter integer HEIGHT = 480,
    parameter integer DW     = 8
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 in_valid,
    input  wire signed [DW-1:0] in_data,
    output wire                 in_ready,
    output wire                 out_valid,
    output wire signed [DW-1:0] out_data,
    input  wire                 out_ready,
    output wire                 done
);

    localparam integer ST_CAP  = 2'd0;
    localparam integer ST_EMIT = 2'd1;
    localparam integer ST_DONE = 2'd2;

    localparam integer OUT_W = WIDTH + 2;
    localparam integer MEMN  = 2*WIDTH;
    localparam integer ABITS = (MEMN <= 1) ? 1 : $clog2(MEMN);

    reg [1:0]  state;
    reg [31:0] in_col;
    reg [31:0] in_row;
    reg [31:0] iss_col;      // columns issued so far in the current output row
    reg [1:0]  emit_phase;
    reg [1:0]  emit_count;
    reg        prev_sel;
    reg        cur_sel;
    reg        rd_valid;     // registered BRAM output holds one pending beat

    (* ram_style = "block", syn_ram_style = "block" *) reg signed [DW-1:0] mem [0:MEMN-1];
    reg signed [DW-1:0] rd_data;

    // Bank of the row that this output row reflects.
    wire phase_sel = (in_row == 1) ? ((emit_phase == 0) ? cur_sel :
                                      (emit_phase == 1) ? prev_sel : cur_sel) :
                     (in_row == HEIGHT-1) ? ((emit_phase == 0) ? cur_sel : prev_sel) :
                     cur_sel;

    // Interior column for the next output beat. The reflect borders reuse a
    // neighbouring interior sample, so the border case is only an address pick.
    wire [31:0] next_idx = (iss_col == 0)       ? 32'd1 :
                           (iss_col == OUT_W-1) ? (WIDTH-2) :
                           (iss_col - 32'd1);
    wire [ABITS-1:0] next_addr = phase_sel ? (next_idx[ABITS-1:0] + WIDTH)
                                           :  next_idx[ABITS-1:0];

    // Issue the next column unless the one-beat pipeline already holds a beat
    // the downstream has not accepted.
    wire issue    = (state == ST_EMIT) && (iss_col < OUT_W) &&
                    (!rd_valid || out_ready);
    wire row_done = (state == ST_EMIT) && rd_valid && out_ready &&
                    (iss_col == OUT_W);

    assign in_ready  = (state == ST_CAP);
    assign out_valid = rd_valid;
    assign out_data  = rd_data;
    assign done      = (state == ST_DONE);

    // Bank 0 holds rows captured while cur_sel==0, bank 1 the others.
    wire [ABITS-1:0] wr_addr = cur_sel ? (in_col[ABITS-1:0] + WIDTH)
                                       :  in_col[ABITS-1:0];

    always @(posedge clk)
        if ((state == ST_CAP) && in_valid && in_ready)
            mem[wr_addr] <= in_data;

    always @(posedge clk)
        if (issue)
            rd_data <= mem[next_addr];

    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= ST_CAP;
            in_col     <= 32'd0;
            in_row     <= 32'd0;
            iss_col    <= 32'd0;
            emit_phase <= 2'd0;
            emit_count <= 2'd0;
            prev_sel   <= 1'b1;
            cur_sel    <= 1'b0;
            rd_valid   <= 1'b0;
        end else begin
            // Hold the pending beat while the downstream stalls; only load a
            // new one when the previous beat was accepted (or the pipe is empty).
            rd_valid <= (rd_valid && !out_ready) || issue;

            if (issue)
                iss_col <= iss_col + 32'd1;

            case (state)
                ST_CAP: begin
                    if (in_valid && in_ready) begin
                        if (in_col == WIDTH-1) begin
                            in_col <= 32'd0;
                            if (in_row == 0) begin
                                // Need row 1 before we can emit the top reflect row.
                                prev_sel <= cur_sel;
                                cur_sel  <= ~cur_sel;
                                in_row   <= 32'd1;
                            end else begin
                                state      <= ST_EMIT;
                                iss_col    <= 32'd0;
                                rd_valid   <= 1'b0;
                                emit_phase <= 2'd0;
                                emit_count <= (in_row == 1) ? 2'd3 :
                                              (in_row == HEIGHT-1) ? 2'd2 : 2'd1;
                            end
                        end else begin
                            in_col <= in_col + 32'd1;
                        end
                    end
                end
                ST_EMIT: begin
                    if (row_done) begin
                        if (emit_phase == emit_count-1) begin
                            if (in_row == HEIGHT-1) begin
                                state <= ST_DONE;
                            end else begin
                                prev_sel <= cur_sel;
                                cur_sel  <= ~cur_sel;
                                in_row   <= in_row + 32'd1;
                                state    <= ST_CAP;
                            end
                        end else begin
                            emit_phase <= emit_phase + 2'd1;
                            iss_col    <= 32'd0;
                            rd_valid   <= 1'b0;
                        end
                    end
                end
                ST_DONE: begin
                    state <= ST_DONE;
                end
                default: state <= ST_CAP;
            endcase
        end
    end

endmodule

