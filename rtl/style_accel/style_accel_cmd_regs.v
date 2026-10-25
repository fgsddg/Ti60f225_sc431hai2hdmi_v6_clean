/*
 * RISC-V-visible command registers for the style-transfer accelerator.
 *
 * This block is deliberately independent of the convolution data path.  The
 * first integration revision uses RISC-V software scheduling: firmware writes
 * one pass descriptor, pulses start, and waits for done/error.
 */

module style_accel_cmd_regs #(
    parameter [31:0] ABI_VERSION = 32'h0001_0001,
    parameter [31:0] PASS_COUNT = 32'd19
) (
    input  wire                    axi_slave_clk,
    input  wire                    axi_slave_rst,

    input  wire                    axi_slave_we,
    input  wire [31:0]             axi_slave_waddr,
    input  wire [31:0]             axi_slave_wdata,
    input  wire                    axi_slave_re,
    input  wire [31:0]             axi_slave_raddr,
    output reg  [31:0]             axi_slave_rdata,
    output reg                     axi_slave_rvalid,

    input  wire                    busy,
    input  wire                    done,
    input  wire                    error,
    input  wire [31:0]             error_code,
    input  wire [63:0]             cycle_count,

    input  wire [31:0]             dbg,
    input  wire                    ddr_rst,   /* io_ddrMasters_n_reset, sticky-latched */
    input  wire                    key0_raw,  /* KEY0, GPIOL_07, active-low */
    input  wire                    key1_raw,  /* KEY1, GPIOR_22, active-low */
    input  wire                    key2_raw,  /* KEY2, GPIOR_21, active-low */
    input  wire                    key3_raw,  /* KEY3, GPIOL_03, active-low */

    /* Video-stream mailbox.  The q_in writer publishes a monotonically
     * increasing count only after the final q_in line has received its AXI
     * write response.  The display bank is double-buffered in the q_out
     * reader and latched at video VS. */
    input  wire [31:0]             video_frame_count,
    output reg                     video_display_bank,
    input  wire [31:0]             qout_diag_count,
    input  wire [31:0]             video_diag2,

    output wire [831:0]            cfg,
    output reg                     start_pulse,
    output reg                     abort_pulse,

    /* Level interrupt: asserted while IRQ_EN is set and a DONE/ERROR
     * sticky flag is pending.  Software clears it by writing CTRL_CLEAR. */
    output wire                    irq,
    output wire [1:0]              display_mode,
    output wire [7:0]              style_strength,
    output wire                    hud_visible,
    output wire [1:0]              hud_type
);


    /* pass descriptor fields (Verilog-2001: no struct) */
    reg [31:0] cfg_pass_id;
    reg [31:0] cfg_stage_id;
    reg [31:0] cfg_op;
    reg [31:0] cfg_ic;
    reg [31:0] cfg_oc;
    reg [31:0] cfg_in_w;
    reg [31:0] cfg_in_h;
    reg [31:0] cfg_out_w;
    reg [31:0] cfg_out_h;
    reg [31:0] cfg_stride;
    reg [31:0] cfg_upsample;
    reg [31:0] cfg_pad_mode;
    reg [31:0] cfg_weight_base;
    reg [31:0] cfg_w_scale_base;
    reg [31:0] cfg_bias_base;
    reg [31:0] cfg_gamma_base;
    reg [31:0] cfg_beta_base;
    reg [31:0] cfg_quant_in_base;
    reg [31:0] cfg_quant_mid_base;
    reg [31:0] cfg_quant_out_base;
    reg [31:0] cfg_input_base;
    reg [31:0] cfg_output_base;
    reg [31:0] cfg_residual_base;
    reg [31:0] cfg_stats_base;
    reg [31:0] cfg_lanes;
    reg [31:0] cfg_flags;

    localparam [31:0] CTRL_START = 32'h0000_0001;
    localparam [31:0] CTRL_IRQ_EN = 32'h0000_0002;
    localparam [31:0] CTRL_CLEAR = 32'h0000_0004;
    localparam [31:0] CTRL_ABORT = 32'h0000_0008;
    /* Self-test: writing CTRL[4] sets the DONE sticky flag without a
     * running datapath, so the IRQ chain can be brought up (L4). */
    localparam [31:0] CTRL_FORCE_DONE = 32'h0000_0010;

    reg        axi_slave_re_r;
    reg        done_sticky;
    reg        done_d;          /* edge detect: done/error are levels, not pulses */
    reg        error_d;
    reg        irq_en;
    reg        error_sticky;
    reg        started;        /* a START was written at least once */
    reg        ddr_rst_seen;   /* io_ddrMasters_n_reset has been high at least once */
    reg        ddr_rst_late;   /* io_ddrMasters_n_reset went high after a START */
    reg  [1:0] display_mode_reg;
    reg  [7:0] style_strength_reg;
    reg  [28:0] hud_hold_count;
    reg  [1:0]  hud_type_reg;
    wire       axi_slave_re_pulse;

    /* KEY0..KEY3 conditioner (100 MHz core clock, 10 ms debounce).
     * All keys are active-low with weak pull-ups. Falling-edge events latch
     * until software reads 0x98 (KEY0) or 0x9C (KEY1/KEY2/KEY3). */
    localparam [19:0] KEY_DEBOUNCE_CYCLES = 20'd999_999;
    reg  [3:0]  key_meta;
    reg  [3:0]  key_sync;
    reg  [3:0]  key_stable;
    reg  [3:0]  key_stable_d;
    reg  [19:0] key_filter_count [0:3];
    reg  [3:0]  key_event;
    wire        key0_event_clear;
    wire        key123_event_clear;
    integer     ki;

    assign key0_event_clear = axi_slave_re_pulse &&
                              (axi_slave_raddr[7:2] == 6'h26);
    assign key123_event_clear = axi_slave_re_pulse &&
                                (axi_slave_raddr[7:2] == 6'h27);

    always @(posedge axi_slave_clk or posedge axi_slave_rst) begin
        if (axi_slave_rst) begin
            key_meta     <= 4'b1111;
            key_sync     <= 4'b1111;
            key_stable   <= 4'b1111;
            key_stable_d <= 4'b1111;
            key_event    <= 4'b0000;
            for (ki = 0; ki < 4; ki = ki + 1)
                key_filter_count[ki] <= 20'd0;
        end else begin
            key_meta     <= {key3_raw, key2_raw, key1_raw, key0_raw};
            key_sync     <= key_meta;
            key_stable_d <= key_stable;

            for (ki = 0; ki < 4; ki = ki + 1) begin
                if (key_sync[ki] != key_stable[ki]) begin
                    if (key_filter_count[ki] == KEY_DEBOUNCE_CYCLES) begin
                        key_stable[ki]       <= key_sync[ki];
                        key_filter_count[ki] <= 20'd0;
                    end else begin
                        key_filter_count[ki] <= key_filter_count[ki] + 20'd1;
                    end
                end else begin
                    key_filter_count[ki] <= 20'd0;
                end

                if (key_stable_d[ki] && !key_stable[ki]) begin
                    key_event[ki] <= 1'b1;
                end else if ((ki == 0 && key0_event_clear) ||
                             (ki != 0 && key123_event_clear)) begin
                    key_event[ki] <= 1'b0;
                end
            end
        end
    end

    assign axi_slave_re_pulse = ~axi_slave_re_r && axi_slave_re;

    /* CTRL[4] write -> one-shot DONE, used by the interrupt bring-up. */
    wire force_done;
    assign force_done = axi_slave_we &&
                        (axi_slave_waddr[7:2] == 6'h00) &&
                        axi_slave_wdata[4];

    always @(posedge axi_slave_clk or posedge axi_slave_rst) begin
        if (axi_slave_rst) begin
            cfg_pass_id         <= 32'd0;
            cfg_stage_id        <= 32'd0;
            cfg_op              <= 32'd0;
            cfg_ic              <= 32'd0;
            cfg_oc              <= 32'd0;
            cfg_in_w            <= 32'd0;
            cfg_in_h            <= 32'd0;
            cfg_out_w           <= 32'd0;
            cfg_out_h           <= 32'd0;
            cfg_stride          <= 32'd0;
            cfg_upsample        <= 32'd0;
            cfg_pad_mode        <= 32'd0;
            cfg_weight_base     <= 32'd0;
            cfg_w_scale_base    <= 32'd0;
            cfg_bias_base       <= 32'd0;
            cfg_gamma_base      <= 32'd0;
            cfg_beta_base       <= 32'd0;
            cfg_quant_in_base   <= 32'd0;
            cfg_quant_mid_base  <= 32'd0;
            cfg_quant_out_base  <= 32'd0;
            cfg_input_base      <= 32'd0;
            cfg_output_base     <= 32'd0;
            cfg_residual_base   <= 32'd0;
            cfg_stats_base      <= 32'd0;
            cfg_lanes           <= 32'd80;
            cfg_flags           <= 32'd0;
            start_pulse         <= 1'b0;
            abort_pulse         <= 1'b0;
            done_sticky         <= 1'b0;
            started             <= 1'b0;
            ddr_rst_seen        <= 1'b0;
            ddr_rst_late        <= 1'b0;
            error_sticky        <= 1'b0;
            done_d              <= 1'b0;
            error_d             <= 1'b0;
            irq_en              <= 1'b0;
            video_display_bank  <= 1'b0;
            axi_slave_re_r      <= 1'b0;
            axi_slave_rvalid    <= 1'b0;
            axi_slave_rdata     <= 32'd0;
            display_mode_reg    <= 2'd0;
            style_strength_reg  <= 8'd0;
            hud_hold_count      <= 29'd0;
            hud_type_reg        <= 2'd0;
        end else begin
            start_pulse      <= 1'b0;
            abort_pulse      <= 1'b0;
            axi_slave_re_r   <= axi_slave_re;
            axi_slave_rvalid <= axi_slave_re_pulse;

            /* Latch the completion EVENT, not the level: style_accel_top holds
             * done/error high until the next START, so re-latching every cycle
             * would re-arm the sticky one cycle after software writes CTRL_CLEAR
             * and the PLIC level interrupt would storm -- the CPU would never
             * leave the claim/service/release loop in style_net_irq_handler. */
            if ((done && !done_d) || force_done) begin
                done_sticky <= 1'b1;
            end
            if (error && !error_d) begin
                error_sticky <= 1'b1;
            end
            done_d  <= done;
            error_d <= error;

            if (ddr_rst) begin
                ddr_rst_seen <= 1'b1;
                if (started) ddr_rst_late <= 1'b1;
            end

            if (hud_hold_count != 29'd0)
                hud_hold_count <= hud_hold_count - 29'd1;

            if (axi_slave_we) begin
                case (axi_slave_waddr[7:2])
                    6'h00: begin
                        start_pulse <= axi_slave_wdata[0];
                        abort_pulse <= axi_slave_wdata[3];
                        irq_en      <= axi_slave_wdata[1];
                        if (axi_slave_wdata[0]) begin
                            started      <= 1'b1;
                            ddr_rst_late <= 1'b0;   /* measure since THIS start */
                        end
                        if (axi_slave_wdata[2]) begin
                            done_sticky  <= 1'b0;
                            error_sticky <= 1'b0;
                        end
                    end
                    6'h03: cfg_pass_id        <= axi_slave_wdata;
                    6'h04: cfg_stage_id       <= axi_slave_wdata;
                    6'h05: cfg_op             <= axi_slave_wdata;
                    6'h06: cfg_ic             <= axi_slave_wdata;
                    6'h07: cfg_oc             <= axi_slave_wdata;
                    6'h08: cfg_in_w           <= axi_slave_wdata;
                    6'h09: cfg_in_h           <= axi_slave_wdata;
                    6'h0a: cfg_out_w          <= axi_slave_wdata;
                    6'h0b: cfg_out_h          <= axi_slave_wdata;
                    6'h0c: cfg_stride         <= axi_slave_wdata;
                    6'h0d: cfg_upsample       <= axi_slave_wdata;
                    6'h0e: cfg_pad_mode       <= axi_slave_wdata;
                    6'h0f: cfg_weight_base    <= axi_slave_wdata;
                    6'h10: cfg_w_scale_base   <= axi_slave_wdata;
                    6'h11: cfg_bias_base      <= axi_slave_wdata;
                    6'h12: cfg_gamma_base     <= axi_slave_wdata;
                    6'h13: cfg_beta_base      <= axi_slave_wdata;
                    6'h14: cfg_quant_in_base  <= axi_slave_wdata;
                    6'h15: cfg_quant_mid_base <= axi_slave_wdata;
                    6'h16: cfg_quant_out_base <= axi_slave_wdata;
                    6'h17: cfg_input_base     <= axi_slave_wdata;
                    6'h18: cfg_output_base    <= axi_slave_wdata;
                    6'h19: cfg_residual_base  <= axi_slave_wdata;
                    6'h1a: cfg_stats_base     <= axi_slave_wdata;
                    6'h1b: cfg_lanes          <= axi_slave_wdata;
                    6'h1c: cfg_flags          <= axi_slave_wdata;
                    6'h23: video_display_bank <= axi_slave_wdata[0];
                    6'h28: display_mode_reg    <= axi_slave_wdata[1:0];
                    6'h29: style_strength_reg  <= axi_slave_wdata[7:0];
                    6'h2A: begin
                        if (axi_slave_wdata[1:0] != 2'd0) begin
                            hud_type_reg   <= axi_slave_wdata[1:0];
                            hud_hold_count <= 29'd349_999_999;
                        end
                    end
                    default: begin
                    end
                endcase
            end

            if (axi_slave_re_pulse) begin
                case (axi_slave_raddr[7:2])
                    6'h01: axi_slave_rdata <= {29'd0, error_sticky, done_sticky, busy};
                    6'h02: axi_slave_rdata <= error_sticky ? error_code : 32'd0;
                    6'h03: axi_slave_rdata <= cfg_pass_id;
                    6'h1d: axi_slave_rdata <= cycle_count[31:0];
                    6'h1e: axi_slave_rdata <= cycle_count[63:32];
                    6'h1f: axi_slave_rdata <= PASS_COUNT;
                    6'h20: axi_slave_rdata <= ABI_VERSION;
                    /* bring-up debug bundle; [16]=ddr_rst ever seen, [17]=ddr_rst after START */
                    6'h21: axi_slave_rdata <= {dbg[31:18], ddr_rst_late, ddr_rst_seen, dbg[15:0]};
                    6'h22: axi_slave_rdata <= video_frame_count;
                    6'h23: axi_slave_rdata <= {31'd0, video_display_bank};
                    6'h24: axi_slave_rdata <= qout_diag_count;
                    6'h25: axi_slave_rdata <= video_diag2;
                    6'h26: axi_slave_rdata <= {30'd0, key_stable[0], key_event[0]};
                    6'h27: axi_slave_rdata <= {26'd0, key_stable[3], key_event[3],
                                                     key_stable[2], key_event[2],
                                                     key_stable[1], key_event[1]};
                    6'h28: axi_slave_rdata <= {30'd0, display_mode_reg};
                    6'h29: axi_slave_rdata <= {24'd0, style_strength_reg};
                    6'h2A: axi_slave_rdata <= {29'd0, hud_hold_count != 29'd0, hud_type_reg};
                    default: axi_slave_rdata <= 32'd0;
                endcase
            end
        end
    end

    assign cfg = {
        cfg_flags,
        cfg_lanes,
        cfg_stats_base,
        cfg_residual_base,
        cfg_output_base,
        cfg_input_base,
        cfg_quant_out_base,
        cfg_quant_mid_base,
        cfg_quant_in_base,
        cfg_beta_base,
        cfg_gamma_base,
        cfg_bias_base,
        cfg_w_scale_base,
        cfg_weight_base,
        cfg_pad_mode,
        cfg_upsample,
        cfg_stride,
        cfg_out_h,
        cfg_out_w,
        cfg_in_h,
        cfg_in_w,
        cfg_oc,
        cfg_ic,
        cfg_op,
        cfg_stage_id,
        cfg_pass_id
    };

    assign irq = irq_en && (done_sticky || error_sticky);
    assign display_mode = display_mode_reg;
    assign style_strength = style_strength_reg;
    assign hud_visible = (hud_hold_count != 29'd0);
    assign hud_type = hud_type_reg;

endmodule

