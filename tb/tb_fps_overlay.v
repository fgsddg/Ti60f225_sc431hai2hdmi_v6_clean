`timescale 1ns/1ps
module tb_fps_overlay;
    // raster: 160x64 active, H_TOTAL=184, V_TOTAL=80 -> 14720 clk per frame
    localparam H_ACTIVE=160, H_FP=4, H_SYNC=8, H_BP=12;
    localparam V_ACTIVE=64,  V_FP=2, V_SYNC=2, V_BP=12;
    localparam H_TOTAL=H_ACTIVE+H_FP+H_SYNC+H_BP;
    localparam V_TOTAL=V_ACTIVE+V_FP+V_SYNC+V_BP;
    localparam CLK_HZ = 736000;              // 736000 / 14720 = 50.0 fps
    localparam INCOL  = 24'h102030;          // {r_in,g_in,b_in}

    reg clk=0; always #5 clk=~clk;
    reg rst_n=0;
    reg proc_tick=0;
    reg proc_phase=0;

    reg [11:0] h_cnt=0, v_cnt=0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin h_cnt<=0; v_cnt<=0; end
        else if (h_cnt==H_TOTAL-1) begin
            h_cnt<=0;
            if (v_cnt==V_TOTAL-1) v_cnt<=0; else v_cnt<=v_cnt+1;
        end else h_cnt<=h_cnt+1;
    end

    wire de_in = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    wire hs_in = ~((h_cnt >= H_ACTIVE+H_FP) && (h_cnt < H_ACTIVE+H_FP+H_SYNC));
    wire vs_in = ~((v_cnt >= V_ACTIVE+V_FP) && (v_cnt < V_ACTIVE+V_FP+V_SYNC));

    // ---------------------------------------------------------------- DUT A
    wire da_de, da_hs, da_vs;
    wire [7:0] da_r,da_g,da_b;
    wire [15:0] da_fps;
    fps_overlay #(
        .CLK_HZ (CLK_HZ),
        .BOX_X (2), .BOX_Y (2), .PAD (1), .SCALE (1), .DRAW_BOX (1)
    ) dutA (
        .clk(clk), .rst_n(rst_n),
        .de_in(de_in), .hs_in(hs_in), .vs_in(vs_in), .frame_pulse(proc_tick), .show(1'b1),
        .r_in(8'h10), .g_in(8'h20), .b_in(8'h30),
        .de_out(da_de), .hs_out(da_hs), .vs_out(da_vs),
        .r_out(da_r), .g_out(da_g), .b_out(da_b),
        .fps_x10_dbg(da_fps)
    );

    // ---------------------------------------------------------------- DUT B
    wire db_de, db_hs, db_vs;
    wire [7:0] db_r,db_g,db_b;
    wire [15:0] db_fps;
    fps_overlay #(
        .CLK_HZ (CLK_HZ),
        .BOX_X (4), .BOX_Y (4), .PAD (3), .SCALE (2), .DRAW_BOX (1)
    ) dutB (
        .clk(clk), .rst_n(rst_n),
        .de_in(de_in), .hs_in(hs_in), .vs_in(vs_in), .frame_pulse(proc_tick), .show(1'b1),
        .r_in(8'h10), .g_in(8'h20), .b_in(8'h30),
        .de_out(db_de), .hs_out(db_hs), .vs_out(db_vs),
        .r_out(db_r), .g_out(db_g), .b_out(db_b),
        .fps_x10_dbg(db_fps)
    );

    reg [11:0] h_d=0, v_d=0;
    always @(posedge clk) begin h_d<=h_cnt; v_d<=v_cnt; end

    reg vs_d=0; integer frame_no=0;
    always @(posedge clk) begin
        vs_d <= vs_in;
        proc_tick <= 1'b0;
        if (vs_d & ~vs_in) begin
            frame_no = frame_no + 1;
            if (proc_phase) begin
                proc_tick  <= 1'b1;
                proc_phase <= 1'b0;
            end else begin
                proc_phase <= 1'b1;
            end
        end
    end

    reg [23:0] memA [0:V_ACTIVE*H_ACTIVE-1];
    reg [23:0] memB [0:V_ACTIVE*H_ACTIVE-1];
    integer dump_frame = 5;
    always @(posedge clk) if (frame_no==dump_frame) begin
        if (da_de) memA[v_d*H_ACTIVE + h_d] = {da_r,da_g,da_b};
        if (db_de) memB[v_d*H_ACTIVE + h_d] = {db_r,db_g,db_b};
    end

    integer x, y, errs, white, boxpix;
    integer bx0,bx1,by0,by1;
    reg [7:0] cc;
    reg [23:0] p;
    initial begin
        rst_n = 0; repeat(6) @(posedge clk); rst_n = 1;
        wait (frame_no >= 6);
        @(posedge clk);

        $display("--------------------------------------------------");
        $display("[A] fps_x10 = %0d (expect 250), SCALE=1", da_fps);
        $display("OSD dump (row 0..13, col 0..84)  #=text .=box ' '=passthrough");
        for (y=0; y<14; y=y+1) begin
            $write("y=%2d |", y);
            for (x=0; x<85; x=x+1) begin
                cc = memA[y*H_ACTIVE+x][7:0];
                if (memA[y*H_ACTIVE+x]==24'hFFFFFF) $write("#");
                else if (memA[y*H_ACTIVE+x]==24'h202020) $write(".");
                else if (memA[y*H_ACTIVE+x]==INCOL) $write(" ");
                else $write("?");
            end
            $write("|\n");
        end

        errs=0;
        if (da_fps !== 16'd250) begin $display("FAIL A fps"); errs=errs+1; end
        if (memA[2*H_ACTIVE+2] !== 24'h202020) begin $display("FAIL A box origin"); errs=errs+1; end
        if (memA[40*H_ACTIVE+140] !== INCOL) begin $display("FAIL A passthrough"); errs=errs+1; end
        white=0; boxpix=0;
        for (y=2;y<12;y=y+1) for (x=2;x<76;x=x+1) begin
            if (memA[y*H_ACTIVE+x]==24'hFFFFFF) white=white+1;
            if (memA[y*H_ACTIVE+x]==24'h202020) boxpix=boxpix+1;
        end
        $display("[A] white=%0d box=%0d", white, boxpix);
        if (white==0 || boxpix==0) begin $display("FAIL A text/box"); errs=errs+1; end

        // ---- DUT B geometry: box must be x 4..153, y 4..25 (150 x 22)
        bx0=9999; bx1=-1; by0=9999; by1=-1; white=0;
        for (y=0;y<V_ACTIVE;y=y+1) for (x=0;x<H_ACTIVE;x=x+1) begin
            p = memB[y*H_ACTIVE+x];
            if (p==24'h202020 || p==24'hFFFFFF) begin
                if (x<bx0) bx0=x; if (x>bx1) bx1=x;
                if (y<by0) by0=y; if (y>by1) by1=y;
            end
            if (p==24'hFFFFFF) white=white+1;
        end
        $display("[B] fps_x10 = %0d, SCALE=2 box = x[%0d..%0d] y[%0d..%0d], white=%0d",
                 db_fps, bx0,bx1,by0,by1, white);
        if (db_fps !== 16'd250)   begin $display("FAIL B fps"); errs=errs+1; end
        if (bx0!==4 || bx1!==153 || by0!==4 || by1!==25) begin $display("FAIL B geometry"); errs=errs+1; end
        if (white==0) begin $display("FAIL B text"); errs=errs+1; end

        if (errs==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)", errs);
        $finish;
    end
    initial begin #4_000_000; $display("RESULT: FAIL (timeout)"); $finish; end
endmodule
