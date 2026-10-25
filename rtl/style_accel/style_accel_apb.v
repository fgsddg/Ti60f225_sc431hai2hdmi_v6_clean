/*
 * APB3 adapter for style_accel_cmd_regs.
 *
 * The TinyML SoC maps IO_APB_SLAVE_0_INPUT at 0xf8100000.  This adapter
 * presents the command registers at that 64 KiB region for RISC-V firmware.
 */

module style_accel_apb #(
    parameter [31:0] ABI_VERSION = 32'h0001_0001,
    parameter [31:0] PASS_COUNT = 32'd19
) (
    input  wire                    clk,
    input  wire                    resetn,

    input  wire [11:0]             PADDR,
    input  wire                    PSEL,
    input  wire                    PENABLE,
    output wire                    PREADY,
    input  wire                    PWRITE,
    input  wire [31:0]             PWDATA,
    output wire [31:0]             PRDATA,
    output wire                    PSLVERROR,

    input  wire                    busy,
    input  wire                    done,
    input  wire                    error,
    input  wire [31:0]             error_code,
    input  wire [63:0]             cycle_count,

    input  wire [31:0]             dbg,

    /* style_accel_ddr_reset from the SoC (io_ddrMasters_n_reset).  Latched as a
     * sticky bit inside the command block, which is only reset by ddr_rstn and
     * therefore survives the SoC's DDR-domain reset.  Read back via 0x84. */
    input  wire                    ddr_rst,
    input  wire                    key0,
    input  wire                    key1,
    input  wire                    key2,
    input  wire                    key3,

    output wire [831:0]            cfg,
    output wire                    start_pulse,
    output wire                    abort_pulse,
    output wire                    irq,
    output wire [1:0]              display_mode,
    output wire [7:0]              style_strength,
    output wire                    hud_visible,
    output wire [1:0]              hud_type,

    input  wire [31:0]             video_frame_count,
    output wire                    video_display_bank,
    input  wire [31:0]             qout_diag_count,
    input  wire [31:0]             video_diag2
);

    reg         read_issued;
    reg         write_issued;
    reg         cmd_we;
    reg         cmd_re;
    reg  [31:0] cmd_waddr;
    reg  [31:0] cmd_wdata;
    reg  [31:0] cmd_raddr;
    wire [31:0] cmd_rdata;
    wire        cmd_rvalid;
    wire        access;

    assign access     = PSEL && PENABLE;
    assign PREADY     = access && ((PWRITE && write_issued) || (!PWRITE && cmd_rvalid));
    assign PRDATA     = cmd_rdata;
    assign PSLVERROR  = 1'b0;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            cmd_we       <= 1'b0;
            cmd_re       <= 1'b0;
            cmd_waddr    <= 32'd0;
            cmd_wdata    <= 32'd0;
            cmd_raddr    <= 32'd0;
            read_issued  <= 1'b0;
            write_issued <= 1'b0;
        end else begin
            cmd_we <= 1'b0;
            cmd_re <= 1'b0;

            if (!PSEL) begin
                read_issued <= 1'b0;
                write_issued <= 1'b0;
            end else if (PSEL && !PENABLE) begin
                cmd_waddr <= {20'd0, PADDR};
                cmd_wdata <= PWDATA;
                cmd_raddr <= {20'd0, PADDR};
                read_issued <= 1'b0;
                write_issued <= 1'b0;
            end else if (access) begin
                if (PWRITE && !write_issued) begin
                    cmd_we <= 1'b1;
                    write_issued <= 1'b1;
                end else if (!read_issued) begin
                    cmd_re <= 1'b1;
                    read_issued <= 1'b1;
                end
            end
        end
    end

    style_accel_cmd_regs #(
        .ABI_VERSION(ABI_VERSION),
        .PASS_COUNT(PASS_COUNT)
    ) u_cmd_regs (
        .axi_slave_clk(clk),
        .axi_slave_rst(!resetn),
        .axi_slave_we(cmd_we),
        .axi_slave_waddr(cmd_waddr),
        .axi_slave_wdata(cmd_wdata),
        .axi_slave_re(cmd_re),
        .axi_slave_raddr(cmd_raddr),
        .axi_slave_rdata(cmd_rdata),
        .axi_slave_rvalid(cmd_rvalid),
        .busy(busy),
        .done(done),
        .error(error),
        .error_code(error_code),
        .cycle_count(cycle_count),
        .dbg(dbg),
        .ddr_rst(ddr_rst),
        .key0_raw(key0),
        .key1_raw(key1),
        .key2_raw(key2),
        .key3_raw(key3),
        .cfg(cfg),
        .start_pulse(start_pulse),
        .abort_pulse(abort_pulse),
        .irq(irq),
        .display_mode(display_mode),
        .style_strength(style_strength),
        .hud_visible(hud_visible),
        .hud_type(hud_type),
        .video_frame_count(video_frame_count),
        .video_display_bank(video_display_bank),
        .qout_diag_count(qout_diag_count),
        .video_diag2(video_diag2)
    );

endmodule
