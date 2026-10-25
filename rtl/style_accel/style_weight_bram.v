`timescale 1ns/1ps

/*
 * Weight cache for one accelerator pass.
 *
 * One address holds 32 BYTES of the current output channel's IC*9-byte filter,
 * flat packed: word j of channel oc holds bytes [32j, 32j+32) of that filter, so
 * the whole filter is contiguous in the byte stream and the term order stays
 * exactly the blob's (ic*9 + tap) order.  A runtime IC therefore only needs
 * ceil(IC*9/32) words and can take the low IC*9 bytes of the assembled window.
 *
 * The address is {oc, word}: 16 word slots per output channel, of which at most
 * ceil(32*9/32) = 9 are used.  Using a power-of-two slot count costs a little
 * depth (512 x 256b) and saves both a multiply in the address path and a lot of
 * block RAM: the old "one word per OC holds the whole filter" form spent ~58
 * RAM10 purely on word WIDTH, this form needs ceil(256/20) = 13 (HANDOFF 9.21).
 *
 * The loader writes a word in ST_WWRITE; the stage reads ceil(IC*9/32) words per
 * OC with a synchronous one-cycle read latency (matching the A2 stage FSM).
 */
module style_weight_bram #(
    parameter integer DATA_W = 256,      /* 32 bytes: a flat slice of the filter  */
    parameter integer ADDR_W = 9         /* {oc, word}: 16 word slots per channel */
) (
    input  wire                 clk,
    input  wire [DATA_W-1:0]    wdata,
    input  wire [ADDR_W-1:0]    waddr,
    input  wire                 we,
    input  wire [ADDR_W-1:0]    raddr,
    output reg  [DATA_W-1:0]    rdata
);

    (* ram_style = "block", syn_ram_style = "block" *) reg [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        rdata <= mem[raddr];
    end

endmodule
