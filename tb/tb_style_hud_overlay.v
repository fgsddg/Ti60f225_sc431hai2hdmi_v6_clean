`timescale 1ns / 1ps
module tb_style_hud_overlay;
    localparam H_ACTIVE = 640;
    localparam V_ACTIVE = 480;
    localparam H_TOTAL  = 800;
    localparam V_TOTAL  = 525;
    localparam [23:0] BG = 24'h112233;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst_n = 1'b0;
    reg [11:0] h_cnt = 0, v_cnt = 0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else if (h_cnt == H_TOTAL-1) begin
            h_cnt <= 0;
            if (v_cnt == V_TOTAL-1) v_cnt <= 0; else v_cnt <= v_cnt + 1;
        end else begin
            h_cnt <= h_cnt + 1;
        end
    end

    wire de_in = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    wire hs_in = ~((h_cnt >= H_ACTIVE) && (h_cnt < H_ACTIVE+40));
    wire vs_in = ~((v_cnt >= V_ACTIVE) && (v_cnt < V_ACTIVE+5));

    reg visible = 1'b1;
    reg [1:0] hud_type = 2'd1;
    reg [7:0] strength = 8'd128;

    wire de_out, hs_out, vs_out;
    wire [23:0] rgb_out;
    style_hud_overlay dut (
        .clk(clk), .rst_n(rst_n),
        .de_in(de_in), .hs_in(hs_in), .vs_in(vs_in), .rgb_in(BG),
        .visible(visible), .hud_type(hud_type), .strength(strength),
        .de_out(de_out), .hs_out(hs_out), .vs_out(vs_out), .rgb_out(rgb_out)
    );

    integer active_pixels = 0;
    integer text_pixels = 0;
    integer edge_pixels = 0;
    integer fill_pixels = 0;
    integer box_pixels = 0;
    integer bg_pixels = 0;
    integer errors = 0;

    always @(posedge clk) begin
        if (de_out) begin
            active_pixels = active_pixels + 1;
            if (rgb_out == 24'hFFFFFF)
                text_pixels = text_pixels + 1;
            if (rgb_out == 24'hB0C8D8)
                edge_pixels = edge_pixels + 1;
            if (rgb_out == 24'h00C8FF)
                fill_pixels = fill_pixels + 1;
            if (rgb_out == 24'h101820)
                box_pixels = box_pixels + 1;
            if (rgb_out == BG)
                bg_pixels = bg_pixels + 1;
        end
    end

    task check_frame;
        input [1:0] kind;
        input [7:0] value;
        begin
            @(posedge vs_in);
            active_pixels = 0;
            text_pixels = 0;
            edge_pixels = 0;
            fill_pixels = 0;
            box_pixels = 0;
            bg_pixels = 0;
            hud_type = kind;
            strength = value;
            @(posedge vs_in);
            #1;
            if (active_pixels != H_ACTIVE*V_ACTIVE) begin
                $display("FAIL type=%0d active=%0d", kind, active_pixels);
                errors = errors + 1;
            end
            if (text_pixels < 30) begin
                $display("FAIL type=%0d text_pixels=%0d", kind, text_pixels);
                errors = errors + 1;
            end
            if (kind == 2'd1) begin
                if (edge_pixels < 200 || fill_pixels < 900 || fill_pixels > 1000) begin
                    $display("FAIL type=1 edge=%0d fill=%0d", edge_pixels, fill_pixels);
                    errors = errors + 1;
                end
            end else if (fill_pixels != 0 || edge_pixels != 0) begin
                $display("FAIL type=%0d unexpected bar edge=%0d fill=%0d",
                         kind, edge_pixels, fill_pixels);
                errors = errors + 1;
            end
            if (box_pixels != 0 || bg_pixels != active_pixels - text_pixels - edge_pixels - fill_pixels) begin
                $display("FAIL type=%0d unexpected box=%0d bg=%0d", kind, box_pixels, bg_pixels);
                errors = errors + 1;
            end
            $display("type=%0d active=%0d text=%0d edge=%0d fill=%0d box=%0d bg=%0d",
                     kind, active_pixels, text_pixels, edge_pixels,
                     fill_pixels, box_pixels, bg_pixels);
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        check_frame(2'd1, 8'd128);
        check_frame(2'd2, 8'd128);
        check_frame(2'd3, 8'd128);
        if (errors == 0) begin
            $display("PASS: tb_style_hud_overlay");
            $finish;
        end else begin
            $display("FAIL: tb_style_hud_overlay errors=%0d", errors);
            $fatal(1);
        end
    end
endmodule