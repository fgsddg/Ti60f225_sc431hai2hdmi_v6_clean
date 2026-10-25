/*
 * style_net_axi_master regression for the p0/p1 raw-int32 validation.
 *
 * Covers the original 24-byte wide path, RAW_PRODUCE (int8 -> eight int32
 * lanes), RAW_CONSUME (eight int32 lanes -> int8), 4 KB boundary crossings,
 * stats-only and residual passes, and fail-closed checks for unsupported raw
 * widths or simultaneous RAW_PRODUCE/RAW_CONSUME.
 *//*
 * Test for style_net_axi_master.
 *
 * A behavioural AXI memory slave plus a loopback "datapath" that feeds the
 * read stream straight into the write stream, so one pass is a DDR -> DDR copy
 * of in_w*in_h pixels.  Runs the same pass twice back to back to exercise the
 * launch/completion masking (the engines hold done high until their next
 * start).
 */
`timescale 1ns/1ps

module tb_style_net_axi_master_raw;

    localparam integer AW = 32;
    localparam integer DW = 128;
    localparam integer MEM_BYTES = 16384;

    reg clk;
    reg rst_n;

    reg              start;
    reg              abort;
    reg  [831:0]     cfg;
    wire             busy, done, error;
    wire [31:0]      error_code;
    wire [63:0]      cycle_count;

    wire [255:0]     dp_in_pixel;
    wire             dp_in_valid;
    wire             dp_in_ready;
    wire [255:0]     dp_out_pixel;
    wire             dp_out_valid;
    wire             dp_out_ready;
    wire             dp_done;

    wire [AW-1:0]    araddr;
    wire [7:0]       arlen;
    wire [2:0]       arsize;
    wire [1:0]       arburst;
    wire             arvalid, arready;
    wire [DW-1:0]    rdata;
    wire [1:0]       rresp;
    wire             rlast, rvalid, rready;

    wire [AW-1:0]    awaddr;
    wire [7:0]       awlen;
    wire [2:0]       awsize;
    wire [1:0]       awburst;
    wire             awvalid, awready;
    wire [DW-1:0]    wdata;
    wire [DW/8-1:0]  wstrb;
    wire             wlast, wvalid, wready;
    wire [1:0]       bresp;
    wire             bvalid, bready;

    reg [7:0] mem [0:MEM_BYTES-1];

    integer errors;
    integer k;
    integer pass;
    integer qc;

    localparam integer IN_BASE  = 128;
    localparam integer OUT_BASE = 1024;
    localparam integer NPIX     = 8 * 2;
    localparam integer RES_BASE = 2048;
    localparam integer RAW_IN_BASE  = 32'h0000_0FD0; /* crosses the 4 KB boundary */
    localparam integer RAW_OUT_BASE = 32'h0000_2FD0; /* crosses the 4 KB boundary */

    /* residual stream: accept every pixel and record it, so a residual pass can
     * be checked byte for byte against the memory model */
    wire [255:0]     dp_res_pixel;
    wire             dp_res_valid;
    wire             dp_res_ready = 1'b1;
    reg  [7:0]       res_seen [0:NPIX*32-1];
    integer          res_count;
    integer          rk;

    always @(posedge clk) begin
        if (rst_n && dp_res_valid && dp_res_ready) begin
            for (rk = 0; rk < 32; rk = rk + 1)
                res_seen[res_count*32 + rk] <= dp_res_pixel[rk*8 +: 8];
            res_count = res_count + 1;
        end
    end

    /* loopback datapath: normal passes copy 8-bit pixels.  RAW_PRODUCE expands
     * each input byte to a signed int32 lane; RAW_CONSUME keeps one int8 lane
     * per output pixel.  Both directions still produce/consume NPIX pixels. */
    wire is_compute    = cfg[25*32 + 1];
    wire is_raw_produce = cfg[25*32 + 8];
    wire is_raw_consume = cfg[25*32 + 9];
    wire needs_output   = is_compute || is_raw_produce;

    reg [255:0] dp_out_pixel_r;
    always @* begin
        dp_out_pixel_r = dp_in_pixel;
        if (is_raw_produce) begin
            dp_out_pixel_r = 256'd0;
            for (qc = 0; qc < 8; qc = qc + 1)
                dp_out_pixel_r[32*qc +: 32] =
                    {{24{dp_in_pixel[8*qc + 7]}}, dp_in_pixel[8*qc +: 8]};
        end else if (is_raw_consume) begin
            dp_out_pixel_r = 256'd0;
            for (qc = 0; qc < 8; qc = qc + 1)
                dp_out_pixel_r[8*qc +: 8] = dp_in_pixel[32*qc +: 8];
        end
    end
    assign dp_out_pixel = dp_out_pixel_r;
    assign dp_out_valid = needs_output ? dp_in_valid : 1'b0;
    assign dp_in_ready  = needs_output ? dp_out_ready : 1'b1;

    reg [31:0] out_count;
    reg [31:0] in_count;
    assign dp_done = needs_output ? (out_count >= NPIX) : (in_count >= NPIX);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_count <= 32'd0;
            in_count  <= 32'd0;
        end else if (start) begin
            out_count <= 32'd0;
            in_count  <= 32'd0;
        end else begin
            if (dp_out_valid && dp_out_ready) out_count <= out_count + 32'd1;
            if (dp_in_valid && dp_in_ready)   in_count  <= in_count + 32'd1;
        end
    end

    style_net_axi_master #(.ADDR_W(AW), .DATA_W(DW)) dut (
        .clk(clk), .rst_n(rst_n),
        .start(start), .abort(abort), .cfg(cfg),
        .busy(busy), .done(done), .error(error),
        .error_code(error_code), .cycle_count(cycle_count),
        .cfg_op(), .cfg_ic(), .cfg_oc(),
        .cfg_in_w(), .cfg_in_h(), .cfg_out_w(), .cfg_out_h(),
        .cfg_stride(), .cfg_upsample(), .cfg_pad_mode(), .cfg_lanes(),
        .cfg_flags(), .cfg_weight_base(), .cfg_w_scale_base(),
        .cfg_bias_base(), .cfg_gamma_base(), .cfg_beta_base(),
        .cfg_quant_in_base(), .cfg_quant_mid_base(), .cfg_quant_out_base(),
        .cfg_stats_base(),
        .dp_in_pixel(dp_in_pixel), .dp_in_valid(dp_in_valid),
        .dp_in_ready(dp_in_ready),
        .dp_out_pixel(dp_out_pixel), .dp_out_valid(dp_out_valid),
        .dp_out_ready(dp_out_ready), .dp_done(dp_done),
        .dp_res_pixel(dp_res_pixel), .dp_res_valid(dp_res_valid),
        .dp_res_ready(dp_res_ready),
        .m_axi_araddr(araddr), .m_axi_arlen(arlen), .m_axi_arsize(arsize),
        .m_axi_arburst(arburst), .m_axi_arvalid(arvalid),
        .m_axi_arready(arready),
        .m_axi_rdata(rdata), .m_axi_rresp(rresp), .m_axi_rlast(rlast),
        .m_axi_rvalid(rvalid), .m_axi_rready(rready),
        .m_axi_awaddr(awaddr), .m_axi_awlen(awlen), .m_axi_awsize(awsize),
        .m_axi_awburst(awburst), .m_axi_awvalid(awvalid),
        .m_axi_awready(awready),
        .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast),
        .m_axi_wvalid(wvalid), .m_axi_wready(wready),
        .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
        /* this TB exercises the pass path only: the loader never borrows */
        .ldr_mode(1'b0), .ldr_launch(1'b0), .ldr_base({AW{1'b0}}),
        .ldr_total(32'd0), .ldr_pixel_bytes(16'd0), .ldr_ready(1'b0),
        .ldr_pixel(), .ldr_valid(), .ldr_done()
    );

    always #5 clk = ~clk;


    /* ---------------- AXI read slave ---------------- */
    reg          ar_active;
    reg [AW-1:0] ar_addr;
    reg [7:0]    ar_len;
    reg [2:0]    ar_size;
    reg [7:0]    ar_cnt;
    reg          r_valid_r;
    reg [DW-1:0] r_data_r;
    reg          r_last_r;

    assign arready = !ar_active && !r_valid_r;
    assign rvalid  = r_valid_r;
    assign rdata   = r_data_r;
    assign rlast   = r_last_r;
    assign rresp   = 2'b00;

    function [DW-1:0] make_beat;
        input [AW-1:0] a;
        input [2:0]    sz;
        integer i;
        integer nb;
        integer ln;
        begin
            make_beat = {DW{1'b0}};
            nb = 1 << sz;
            ln = a[3:0];
            for (i = 0; i < nb; i = i + 1)
                make_beat[(ln + i)*8 +: 8] = mem[a + i];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ar_active <= 1'b0;
            r_valid_r <= 1'b0;
            ar_cnt    <= 8'd0;
        end else begin
            if (arready && arvalid) begin
                ar_addr   <= araddr;
                ar_len    <= arlen;
                ar_size   <= arsize;
                ar_cnt    <= 8'd0;
                ar_active <= 1'b1;
            end
            if (ar_active && !r_valid_r) begin
                r_data_r  <= make_beat(ar_addr, ar_size);
                r_last_r  <= (ar_cnt == ar_len);
                r_valid_r <= 1'b1;
            end
            if (r_valid_r && rready) begin
                r_valid_r <= 1'b0;
                if (ar_cnt == ar_len) ar_active <= 1'b0;
                else begin
                    ar_addr <= ar_addr + (1 << ar_size);
                    ar_cnt  <= ar_cnt + 8'd1;
                end
            end
        end
    end

    /* ---------------- AXI write slave ---------------- */
    reg          aw_active;
    reg [AW-1:0] aw_addr;
    reg [7:0]    aw_len;
    reg [2:0]    aw_size;
    reg          b_valid_r;

    assign awready = !aw_active && !b_valid_r;
    assign wready  = aw_active && !b_valid_r;
    assign bvalid  = b_valid_r;
    assign bresp   = 2'b00;

    integer b;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_active <= 1'b0;
            b_valid_r <= 1'b0;
        end else begin
            if (awready && awvalid) begin
                aw_addr   <= awaddr;
                aw_len    <= awlen;
                aw_size   <= awsize;
                aw_active <= 1'b1;
            end
            if (wready && wvalid) begin
                for (b = 0; b < DW/8; b = b + 1)
                    if (wstrb[b])
                        mem[{aw_addr[AW-1:4], 4'b0} + b] <= wdata[b*8 +: 8];
                aw_addr <= aw_addr + (1 << aw_size);
                if (wlast) begin
                    aw_active <= 1'b0;
                    b_valid_r <= 1'b1;
                end
            end
            if (b_valid_r && bready)
                b_valid_r <= 1'b0;
        end
    end

    /* ---------------- config helper ---------------- */
    task set_field;
        input integer idx;
        input [31:0]  v;
        begin
            cfg[idx*32 +: 32] = v;
        end
    endtask

    integer wait_cyc;
    task run_pass;
        begin
            /* Hold start across a real rising edge: assigning between the
             * previous posedge and the next negedge is racy in this TB. */
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;
            wait_cyc = 0;
            while (!done) begin
                @(posedge clk);
                wait_cyc = wait_cyc + 1;
                if (wait_cyc % 2000 == 0)
                    $display("[t=%0t] in=%0d out=%0d res=%0d inrdy=%b inv=%b outv=%b outrdy=%b dpdone=%b busy=%b err=%b",
                             $time, in_count, out_count, res_count, dp_in_ready,
                             dp_in_valid, dp_out_valid, dp_out_ready, dp_done,
                             busy, error);
            end
            @(posedge clk);
        end
    endtask

    /* ---------------- test ---------------- */
    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        abort = 1'b0;
        cfg = 832'd0;
        errors = 0;

        for (k = 0; k < MEM_BYTES; k = k + 1) mem[k] = 8'h00;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        /* descriptor: IC=OC=24, 8x2 -> 8x2, stride 1; storage is padded to 32 B/pixel */
        set_field(1, 32'd0);               /* stage_id  */
        set_field(2, 32'd1);               /* op = conv */
        set_field(3, 32'd24);              /* ic        */
        set_field(4, 32'd24);              /* oc        */
        set_field(5, 32'd8);               /* in_w      */
        set_field(6, 32'd2);               /* in_h      */
        set_field(7, 32'd8);               /* out_w     */
        set_field(8, 32'd2);               /* out_h     */
        set_field(9, 32'd1);               /* stride    */
        set_field(10, 32'd1);              /* upsample  */
        set_field(11, 32'd1);              /* pad       */
        set_field(20, IN_BASE);            /* input base  */
        set_field(21, OUT_BASE);           /* output base */
        set_field(25, 32'h0000_0002);      /* FLAG_COMPUTE -> writes */

        for (pass = 0; pass < 2; pass = pass + 1) begin
            /* input pattern */
            for (k = 0; k < NPIX*32; k = k + 1)
                mem[IN_BASE + k] = (8'h30 + pass * 8'h40 + k * 5) & 8'hff;
            /* clear destination */
            for (k = 0; k < NPIX*32; k = k + 1)
                mem[OUT_BASE + k] = 8'h00;

            out_count = 0;
            run_pass;

            for (k = 0; k < NPIX*32; k = k + 1) begin
                if (mem[OUT_BASE + k] !== mem[IN_BASE + k]) begin
                    $display("FAIL: pass %0d byte %0d got=%02x exp=%02x",
                             pass, k, mem[OUT_BASE+k], mem[IN_BASE+k]);
                    errors = errors + 1;
                end
            end

            if (error) begin
                $display("FAIL: pass %0d asserted error 0x%08x", pass, error_code);
                errors = errors + 1;
            end

            $display("pass %0d done, cycles=%0d", pass, cycle_count);
        end

        /* ---- RAW_PRODUCE: int8 stream -> eight little-endian int32 lanes.
         * The bases are 16-byte aligned but deliberately cross 4 KB. ---- */
        set_field(2, 32'd1);
        set_field(3, 32'd8);
        set_field(4, 32'd8);
        set_field(20, RAW_IN_BASE);
        set_field(21, RAW_OUT_BASE);
        set_field(25, 32'h0000_0100);          /* RAW_PRODUCE */
        for (k = 0; k < NPIX*8; k = k + 1)
            mem[RAW_IN_BASE + k] = (8'h70 + k*23) & 8'hff;
        for (k = 0; k < NPIX*32; k = k + 1)
            mem[RAW_OUT_BASE + k] = 8'h00;
        out_count = 0;
        run_pass;
        if (error || error_code != 0) begin
            $display("FAIL: raw produce error=%b code=%0d", error, error_code);
            errors = errors + 1;
        end
        for (k = 0; k < NPIX*32; k = k + 1) begin
            integer pix;
            integer chn;
            integer byt;
            reg [7:0] src;
            reg [7:0] exp;
            pix = k / 32;
            chn = (k % 32) / 4;
            byt = k % 4;
            src = mem[RAW_IN_BASE + pix*8 + chn];
            exp = (byt == 0) ? src : {8{src[7]}};
            if (mem[RAW_OUT_BASE + k] !== exp) begin
                $display("FAIL: raw produce byte %0d got=%02x exp=%02x", k,
                         mem[RAW_OUT_BASE+k], exp);
                errors = errors + 1;
            end
        end
        $display("raw produce done, cycles=%0d", cycle_count);

        /* ---- RAW_CONSUME: eight int32 lanes -> int8 pixel. ---- */
        set_field(2, 32'd1);
        set_field(3, 32'd8);
        set_field(4, 32'd8);
        set_field(20, RAW_IN_BASE);
        set_field(21, RAW_OUT_BASE);
        set_field(25, 32'h0000_0202);          /* COMPUTE | RAW_CONSUME */
        for (k = 0; k < NPIX*32; k = k + 1)
            mem[RAW_IN_BASE + k] = (8'h11 + k*13) & 8'hff;
        for (k = 0; k < NPIX*8; k = k + 1)
            mem[RAW_OUT_BASE + k] = 8'h00;
        out_count = 0;
        run_pass;
        if (error || error_code != 0) begin
            $display("FAIL: raw consume error=%b code=%0d", error, error_code);
            errors = errors + 1;
        end
        for (k = 0; k < NPIX*8; k = k + 1) begin
            integer pix;
            integer chn;
            reg [7:0] exp;
            pix = k / 8;
            chn = k % 8;
            exp = mem[RAW_IN_BASE + pix*32 + chn*4];
            if (mem[RAW_OUT_BASE + k] !== exp) begin
                $display("FAIL: raw consume byte %0d got=%02x exp=%02x", k,
                         mem[RAW_OUT_BASE+k], exp);
                errors = errors + 1;
            end
        end
        $display("raw consume done, cycles=%0d", cycle_count);

        /* ---- fail closed before launch on unsupported raw widths/modes ---- */
        set_field(4, 32'd16);
        set_field(25, 32'h0000_0100);
        #1;
        run_pass;
        if (!error || error_code != 2) begin
            $display("FAIL: raw width guard error=%b code=%0d", error, error_code);
            errors = errors + 1;
        end
        set_field(3, 32'd16);
        set_field(4, 32'd8);
        set_field(25, 32'h0000_0202);          /* COMPUTE | RAW_CONSUME */
        run_pass;
        if (!error || error_code != 2) begin
            $display("FAIL: raw consume width guard error=%b code=%0d", error, error_code);
            errors = errors + 1;
        end
        set_field(25, 32'h0000_0300);
        run_pass;
        if (!error || error_code != 3) begin
            $display("FAIL: raw mode guard error=%b code=%0d", error, error_code);
            errors = errors + 1;
        end
        set_field(3, 32'd24);
        set_field(4, 32'd24);
        set_field(25, 32'h0000_0002);

        /* ---- statistics-only pass: must read but not write ---- */
        for (k = 0; k < NPIX*32; k = k + 1)
            mem[IN_BASE + k] = (8'h77 + k * 3) & 8'hff;
        for (k = 0; k < NPIX*32; k = k + 1)
            mem[OUT_BASE + k] = 8'h00;
        set_field(25, 32'h0000_0005);   /* STATS | NORM, no COMPUTE */
        run_pass;
        for (k = 0; k < NPIX*32; k = k + 1) begin
            if (mem[OUT_BASE + k] !== 8'h00) begin
                $display("FAIL: stats pass wrote mem[%0d]=%02x", k, mem[OUT_BASE+k]);
                errors = errors + 1;
            end
        end
        $display("stats pass done, cycles=%0d (no write)", cycle_count);

        /* ---- residual pass (op = 5, FLAG_COMPUTE): the second stream must be
         * read in step with the first ---- */
        set_field(2, 32'd5);                   /* op = conv + residual */
        set_field(22, RES_BASE);               /* residual base */
        set_field(25, 32'h0000_0002);          /* FLAG_COMPUTE */
        for (k = 0; k < NPIX*32; k = k + 1)
            mem[RES_BASE + k] = (8'h90 + k * 7) & 8'hff;
        res_count = 0;
        for (k = 0; k < NPIX*32; k = k + 1) res_seen[k] = 8'h00;
        run_pass;
        if (res_count !== NPIX) begin
            $display("FAIL: residual stream delivered %0d pixels, expected %0d",
                     res_count, 16*8);
            errors = errors + 1;
        end
        for (k = 0; k < NPIX*32; k = k + 1) begin
            if (res_seen[k] !== mem[RES_BASE + k]) begin
                $display("FAIL: residual byte %0d got=%02x exp=%02x",
                         k, res_seen[k], mem[RES_BASE+k]);
                errors = errors + 1;
            end
        end
        $display("residual pass done, pixels=%0d cycles=%0d", res_count, cycle_count);

        if (errors == 0) $display("PASS: style_net_axi_master_raw");
        else             $display("FAIL: style_net_axi_master_raw (%0d errors)", errors);
        $finish;
    end

    initial begin
        #2000000;
        $display("FAIL: watchdog timeout in=%0d out=%0d res=%0d busy=%b done=%b err=%b code=%0d dp_in_valid=%b dp_out_valid=%b dp_in_ready=%b dp_out_ready=%b", in_count, out_count, res_count, busy, done, error, error_code, dp_in_valid, dp_out_valid, dp_in_ready, dp_out_ready);
        $finish;
    end

endmodule
