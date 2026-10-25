`timescale 1ns/1ps
module tb_video_out_timing;
    localparam H_ACTIVE=16, H_FP=2, H_SYNC=4, H_BP=3;      // H_TOTAL = 25
    localparam V_ACTIVE=8,  V_FP=1, V_SYNC=1, V_BP=2;      // V_TOTAL = 12
    reg clk=0; always #5 clk=~clk;
    reg rst_n=0;
    reg        pix_valid = 1'b1;
    reg        pix_sof   = 1'b1;
    reg [23:0] pix_data  = 24'd0;
    wire       pix_req;
    wire [23:0] rgb; wire de, hs, vs; wire frame_done; wire [15:0] dbg_underflow, dbg_sof_wait;
    video_out_timing #(.H_ACTIVE(H_ACTIVE),.H_FP(H_FP),.H_SYNC(H_SYNC),.H_BP(H_BP),
                       .V_ACTIVE(V_ACTIVE),.V_FP(V_FP),.V_SYNC(V_SYNC),.V_BP(V_BP),
                       .NEG_SYNC(1)) dut (
        .clk(clk), .rst_n(rst_n), .pix_valid(pix_valid), .pix_sof(pix_sof),
        .pix_data(pix_data), .pix_req(pix_req),
        .rgb(rgb), .de(de), .hs(hs), .vs(vs), .frame_done(frame_done),
        .dbg_underflow(dbg_underflow), .dbg_sof_wait(dbg_sof_wait));
    integer exp_pix = 0, got_pix = 0, err_cnt = 0, fd_cnt = 0, src_cnt = 0;
    reg [23:0] exp_rgb;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin pix_data <= 24'd0; src_cnt <= 0; pix_sof <= 1'b1; end
        else if (pix_req) begin
            pix_data <= (src_cnt == H_ACTIVE*V_ACTIVE-1) ? 24'd0 : (pix_data + 1'b1);
            if (src_cnt == H_ACTIVE*V_ACTIVE-1) begin src_cnt <= 0; pix_sof <= 1'b1; end
            else begin src_cnt <= src_cnt + 1'b1; pix_sof <= 1'b0; end
        end
        else pix_sof <= 1'b0;
    end
    always @(posedge clk) if (rst_n) begin
        if (de) begin
            got_pix = got_pix + 1;
            exp_rgb = exp_pix[23:0];
            if (rgb !== exp_rgb) begin
                err_cnt = err_cnt + 1;
                if (err_cnt <= 5) $display("[%0t] MISMATCH got=%06h exp=%06h", $time, rgb, exp_rgb);
            end
            exp_pix = exp_pix + 1;
        end
        if (frame_done) begin fd_cnt = fd_cnt + 1; exp_pix = 0; end
    end
    initial begin
        rst_n = 0; repeat(4) @(posedge clk); rst_n = 1;
        wait (fd_cnt == 2);
        $display("--------------------------------------------------");
        $display("active pixels = %0d (expected %0d)", got_pix, 2*H_ACTIVE*V_ACTIVE);
        $display("frame_done    = %0d (expected 2)", fd_cnt);
        $display("underflow     = %0d", dbg_underflow);
        if (got_pix == 2*H_ACTIVE*V_ACTIVE && fd_cnt == 2 && err_cnt == 0 && dbg_underflow == 0)
            $display("RESULT: PASS");
        else begin $display("mismatches = %0d", err_cnt); $display("RESULT: FAIL"); end
        $finish;
    end
    initial begin #200_000; $display("RESULT: FAIL (timeout)"); $finish; end
endmodule