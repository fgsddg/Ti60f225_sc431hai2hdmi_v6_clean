`timescale 1ns/1ps

// Sequential integer square root: floor(sqrt(x)) for a 64-bit unsigned x.
// Uses the restoring digit-by-digit algorithm and takes up to 32 iterations.
module isqrt_u64 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [63:0] x,
    output reg         done,
    output reg  [31:0] y
);

    reg        busy;
    reg [63:0] rem;
    reg [63:0] root;
    reg [63:0] step;

    wire [63:0] root_next = (rem >= (root + step)) ?
                            ((root >> 1) + step) : (root >> 1);
    wire [63:0] rem_next  = (rem >= (root + step)) ?
                            (rem - (root + step)) : rem;

    always @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            y    <= 32'd0;
            rem  <= 64'd0;
            root <= 64'd0;
            step <= 64'd0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                busy <= 1'b1;
                rem  <= x;
                root <= 64'd0;
                step <= 64'd1 << 62;
                y    <= 32'd0;
            end else if (busy) begin
                rem  <= rem_next;
                root <= root_next;

                if (step == 64'd1) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    y    <= root_next[31:0];
                end else begin
                    step <= step >> 2;
                end
            end
        end
    end

endmodule
