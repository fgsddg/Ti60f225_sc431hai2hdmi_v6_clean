`timescale 1ns/1ps

// Sequential unsigned 64-bit restoring divider.
// quotient = numerator / denominator, remainder = numerator % denominator.
module div_u64 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [63:0] numerator,
    input  wire [63:0] denominator,
    output reg         done,
    output reg  [63:0] quotient,
    output reg  [63:0] remainder,
    output reg         divide_by_zero
);

    reg         busy;
    reg [127:0] sr;
    reg [63:0]  divisor;
    reg [63:0]  quot;
    reg [6:0]   count;

    wire [127:0] sr_shift = {sr[126:0], 1'b0};
    wire [63:0]  rem_shift = sr_shift[127:64];
    wire         rem_ge = (rem_shift >= divisor);
    wire [63:0]  rem_sub = rem_shift - divisor;
    wire [63:0]  quot_shift = {quot[62:0], 1'b0};
    wire [63:0]  quot_set = quot_shift | 64'd1;
    wire [127:0] sr_next = rem_ge ? {rem_sub, sr_shift[63:0]} : sr_shift;
    wire [63:0]  quot_next = rem_ge ? quot_set : quot_shift;

    always @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            sr <= 128'd0;
            divisor <= 64'd0;
            quot <= 64'd0;
            count <= 7'd0;
            quotient <= 64'd0;
            remainder <= 64'd0;
            divide_by_zero <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                if (denominator == 64'd0) begin
                    quotient <= 64'd0;
                    remainder <= 64'd0;
                    divide_by_zero <= 1'b1;
                    done <= 1'b1;
                end else begin
                    busy <= 1'b1;
                    sr <= {64'd0, numerator};
                    divisor <= denominator;
                    quot <= 64'd0;
                    count <= 7'd64;
                    divide_by_zero <= 1'b0;
                end
            end else if (busy) begin
                sr <= sr_next;
                quot <= quot_next;
                if (count == 7'd1) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    quotient <= quot_next;
                    remainder <= sr_next[127:64];
                end else begin
                    count <= count - 7'd1;
                end
            end
        end
    end

endmodule
