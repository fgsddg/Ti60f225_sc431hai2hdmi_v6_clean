`timescale 1ns/1ps
module tb_video_qin_writer_128x96;
    localparam [31:0] BASE = 32'h00001000;

    reg clk = 0;
    reg rst_n = 0;
    reg en = 1;
    reg vid_de = 0;
    reg vid_vs = 1;
    reg [23:0] vid_rgb = 0;
    wire [31:0] awaddr;
    wire [7:0] awlen;
    wire [2:0] awsize;
    wire [1:0] awburst, bresp;
    wire awvalid, awready;
    wire [127:0] wdata;
    wire [15:0] wstrb;
    wire wlast, wvalid, wready;
    wire bvalid, bready, busy, frame_done;
    wire [31:0] frame_count;

    reg [7:0] mem [0:524287];
    reg [31:0] aw_base;
    reg [7:0] aw_len;
    reg [7:0] w_beat;
    reg bvalid_r;
    reg [1:0] bresp_r;
    integer bid_count, b, errs;
    integer sx, sy, col, line;
    reg [7:0] drv_r, drv_g;

    always #5 clk = ~clk;

    assign awready = 1'b1;
    assign wready = 1'b1;
    assign bvalid = bvalid_r;
    assign bresp = bresp_r;

    video_qin_writer #(
        .QIN_ADDR(BASE), .SRC_W(640), .SRC_H(480), .DST_W(128), .DST_H(96)
    ) dut (
        .vid_clk(clk), .vid_rst_n(rst_n),
        .core_clk(clk), .core_rst_n(rst_n), .en(en),
        .vid_de(vid_de), .vid_vs(vid_vs), .vid_rgb(vid_rgb),
        .m_axi_awaddr(awaddr), .m_axi_awlen(awlen), .m_axi_awsize(awsize),
        .m_axi_awburst(awburst), .m_axi_awvalid(awvalid), .m_axi_awready(awready),
        .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast),
        .m_axi_wvalid(wvalid), .m_axi_wready(wready),
        .m_axi_bresp(bresp), .m_axi_bvalid(bvalid_r), .m_axi_bready(bready),
        .busy(busy), .frame_done(frame_done), .frame_count(frame_count)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            aw_base <= 0;
            aw_len <= 0;
            w_beat <= 0;
            bvalid_r <= 0;
            bresp_r <= 0;
            bid_count <= 0;
        end else begin
            if (awvalid && awready) begin
                aw_base <= awaddr;
                aw_len <= awlen;
                w_beat <= 0;
                if (awsize != 3'd4 || awburst != 2'b01) begin
                    $display("BAD awsize/burst %0d %0d", awsize, awburst);
                    errs = errs + 1;
                end
            end
            if (wvalid && wready) begin
                for (b = 0; b < 16; b = b + 1) begin
                    if (wstrb[b])
                        mem[(aw_base + w_beat*16 + b) & 32'h7FFFF] = wdata[b*8 +: 8];
                end
                if (wlast) begin
                    bvalid_r <= 1'b1;
                    bresp_r <= 2'b00;
                    if (w_beat != aw_len) begin
                        $display("BAD burst beat count=%0d len=%0d", w_beat, aw_len);
                        errs = errs + 1;
                    end
                end else begin
                    w_beat <= w_beat + 1;
                end
            end
            if (bvalid_r && bready) begin
                bvalid_r <= 1'b0;
                bid_count <= bid_count + 1;
            end
        end
    end

    initial begin
        errs = 0; bid_count = 0;
        repeat (8) @(posedge clk);
        rst_n = 1;
        repeat (8) @(posedge clk);
        vid_vs = 0;
        repeat (5) @(posedge clk);
        vid_vs = 1;
        repeat (5) @(posedge clk);

        for (sy = 0; sy < 480; sy = sy + 1) begin
            vid_de = 1;
            for (sx = 0; sx < 640; sx = sx + 1) begin
                drv_r = sx / 5;
                drv_g = sy / 5;
                vid_rgb = {drv_r, drv_g, 8'hA5};
                @(posedge clk);
            end
            vid_de = 0;
            repeat (4) @(posedge clk);
        end

        repeat (5000) @(posedge clk);
        if (frame_count != 1) begin
            $display("BAD frame_count=%0d", frame_count);
            errs = errs + 1;
        end
        for (line = 0; line < 96; line = line + 1) begin
            for (col = 0; col < 128; col = col + 1) begin
                if (mem[BASE + line*512 + col*4 + 0] !== ((col ^ 8'h80) & 8'hff) ||
                    mem[BASE + line*512 + col*4 + 1] !== ((line ^ 8'h80) & 8'hff) ||
                    mem[BASE + line*512 + col*4 + 2] !== (8'hA5 ^ 8'h80) ||
                    mem[BASE + line*512 + col*4 + 3] !== 8'h00) begin
                    if (errs < 10)
                        $display("BAD qin line=%0d col=%0d got=%02x %02x %02x %02x",
                                 line, col, mem[BASE+line*512+col*4],
                                 mem[BASE+line*512+col*4+1], mem[BASE+line*512+col*4+2],
                                 mem[BASE+line*512+col*4+3]);
                    errs = errs + 1;
                end
            end
        end
        $display("INFO bursts=%0d frame_count=%0d", bid_count, frame_count);
        if (errs == 0)
            $display("PASS: video_qin_writer 128x96, 512-byte lines, packed signed RGB");
        else
            $display("FAIL: errs=%0d", errs);
        $finish;
    end
endmodule
