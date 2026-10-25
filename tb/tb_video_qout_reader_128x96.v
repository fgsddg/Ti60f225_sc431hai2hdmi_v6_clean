`timescale 1ns/1ps
module tb_video_qout_reader_128x96;
    localparam [31:0] BASE0 = 32'h00010000;
    localparam [31:0] BASE1 = 32'h00020000;

    reg clk = 0;
    reg rst_n = 0;
    reg en = 1;
    reg bank_sel = 0;
    reg vid_de = 0;
    reg vid_hs = 1;
    reg vid_vs = 1;
    wire [31:0] araddr;
    wire [7:0] arlen;
    wire [2:0] arsize;
    wire [1:0] arburst;
    wire arvalid, arready;
    reg [127:0] rdata;
    wire rlast, rvalid, rready;
    wire [23:0] out_rgb;
    wire busy;
    wire [31:0] diag_count;

    reg [7:0] mem [0:262143];
    reg [31:0] rd_base;
    reg [7:0] rd_len;
    reg [7:0] rd_beat;
    reg [1:0] rd_delay;
    reg rvalid_r;
    integer k, line, col, errs, ox, oy, frames;
    integer chk_r, chk_g;
    reg vid_de_d;

    always #5 clk = ~clk;
    assign arready = 1'b1;
    assign rvalid = rvalid_r;
    assign rlast = rvalid_r && (rd_beat == rd_len);

    always @* begin
        rdata = 128'd0;
        for (k = 0; k < 16; k = k + 1)
            rdata[k*8 +: 8] = mem[(rd_base + rd_beat*16 + k) & 32'h3FFFF];
    end

    video_qout_reader #(
        .BASE_ADDR(BASE0), .BASE_ADDR_ALT(BASE1),
        .SRC_W(640), .SRC_H(480), .DST_W(128), .DST_H(96)
    ) dut (
        .core_clk(clk), .core_rst_n(rst_n),
        .vid_clk(clk), .vid_rst_n(rst_n), .en(en), .bank_sel(bank_sel),
        .vid_de(vid_de), .vid_hs(vid_hs), .vid_vs(vid_vs),
        .m_axi_araddr(araddr), .m_axi_arlen(arlen), .m_axi_arsize(arsize),
        .m_axi_arburst(arburst), .m_axi_arvalid(arvalid), .m_axi_arready(arready),
        .m_axi_rdata(rdata), .m_axi_rlast(rlast), .m_axi_rvalid(rvalid_r),
        .m_axi_rready(rready), .out_rgb(out_rgb), .busy(busy),
        .diag_count(diag_count)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_base <= 0; rd_len <= 0; rd_beat <= 0; rd_delay <= 0; rvalid_r <= 0;
        end else begin
            if (arvalid && arready) begin
                rd_base <= araddr;
                rd_len <= arlen;
                rd_beat <= 0;
                rd_delay <= 2;
                if (arsize != 3'd4 || arburst != 2'b01) begin
                    $display("BAD araddr=%08x size=%0d burst=%0d", araddr, arsize, arburst);
                    errs = errs + 1;
                end
            end else if (rd_delay != 0) begin
                rd_delay <= rd_delay - 1;
                if (rd_delay == 1) rvalid_r <= 1;
            end
            if (rvalid_r && rready) begin
                if (rd_beat == rd_len)
                    rvalid_r <= 0;
                else
                    rd_beat <= rd_beat + 1;
            end
        end
    end

    always @(posedge clk) begin
        vid_de_d <= vid_de;
        if (rst_n && vid_de_d) begin
            chk_r = ox / 5;
            chk_g = oy / 5;
            if (out_rgb[23:16] !== chk_r[7:0] || out_rgb[15:8] !== chk_g[7:0] ||
                out_rgb[7:0] !== 8'hA5) begin
                if (errs < 10)
                    $display("BAD out x=%0d y=%0d rgb=%06x exp=%02x%02x%02x",
                             ox, oy, out_rgb, chk_r, chk_g, 8'hA5);
                errs = errs + 1;
            end
            ox = ox + 1;
            if (ox == 640) begin
                ox = 0;
                oy = oy + 1;
                if (oy == 480) begin
                    frames = frames + 1;
                    oy = 0;
                end
            end
        end
    end

    task hsync_pulse;
        begin
            vid_hs = 0;
            repeat (4) @(posedge clk);
            vid_hs = 1;
            repeat (250) @(posedge clk);
        end
    endtask

    initial begin
        errs = 0; ox = 0; oy = 0; frames = 0;
        for (line = 0; line < 96; line = line + 1) begin
            for (col = 0; col < 128; col = col + 1) begin
                mem[BASE0 + line*512 + col*4 + 0] = col ^ 8'h80;
                mem[BASE0 + line*512 + col*4 + 1] = line ^ 8'h80;
                mem[BASE0 + line*512 + col*4 + 2] = 8'hA5 ^ 8'h80;
                mem[BASE0 + line*512 + col*4 + 3] = 8'h00;
            end
        end
        repeat (8) @(posedge clk);
        rst_n = 1;
        repeat (8) @(posedge clk);
        vid_vs = 0;
        repeat (5) @(posedge clk);
        vid_vs = 1;
        repeat (10) @(posedge clk);
        repeat (3) hsync_pulse();

        for (line = 0; line < 480; line = line + 1) begin
            vid_de = 1;
            for (col = 0; col < 640; col = col + 1)
                @(posedge clk);
            vid_de = 0;
            hsync_pulse();
        end
        repeat (200) @(posedge clk);

        if (frames != 1) begin
            $display("BAD frames=%0d", frames);
            errs = errs + 1;
        end
        $display("INFO frames=%0d diag=%08x", frames, diag_count);
        if (diag_count[15:0] != 0) begin
            $display("BAD request drops=%0d", diag_count[15:0]);
            errs = errs + 1;
        end
        if (errs == 0)
            $display("PASS: video_qout_reader 128x96, 512-byte lines, 5x display timing");
        else
            $display("FAIL: errs=%0d", errs);
        $finish;
    end
endmodule
