/*
 * Bit-exact p0/p1 raw-int32 scratch validation.
 *
 * Reference: normal stats p0 -> normal compute p1.
 * DUT:      RAW_PRODUCE p0 (stats + int32 write) -> RAW_CONSUME p1.
 *
 * Checks that both stats passes derive identical InstanceNorm parameters and
 * that every q1 byte matches.  Compile with Icarus -g2012 and the style_net_core
 * dependency set (conv3x3_zp_lanes, requant_pipe_core, norm_param_core,
 * div_u64, isqrt_u64).
 */`timescale 1ns/1ps
module tb_style_net_core_raw_p0p1;
    localparam integer W = 8;
    localparam integer H = 4;
    localparam integer IC = 3;
    localparam integer OC = 8;
    localparam integer MAX_IC = 24;
    localparam integer MAX_OC = 24;
    localparam integer LANES = 32;
    localparam integer COUNT = W * H;
    localparam integer NW = (IC*9 + 31)/32;

    reg clk, rst_n;
    reg start, is_stats, raw_produce, raw_consume, do_relu;
    wire busy, done;
    reg [255:0] in_pixel;
    reg in_valid;
    wire in_ready;
    wire [255:0] out_pixel;
    wire out_valid;
    reg out_ready;

    wire [$clog2(MAX_OC)+3:0] w_addr;
    reg [255:0] w_mem [0:MAX_OC*16-1];
    reg [255:0] w_rdata;
    reg signed [8:0] zp_in;
    reg [31:0] inv_n_q32;
    reg signed [63:0] s2_arr [0:OC-1];
    reg signed [63:0] sg_arr [0:OC-1];
    reg signed [63:0] beta_arr [0:OC-1];
    reg signed [63:0] p_s2,p_sg,p_beta;
    wire [$clog2(MAX_OC)-1:0] p_raddr;
    reg [63:0] q_recip;
    reg signed [7:0] q_zp;
    wire [64*MAX_OC-1:0] sum_flat,sumsq_flat;
    wire [31:0] count_out;
    reg [4:0] dbg_st_addr;
    wire signed [63:0] dbg_st_sum,dbg_st_sumsq;

    reg [255:0] raw_mem [0:COUNT-1];
    reg [63:0] ref_mem [0:COUNT-1];
    integer cap_mode; /* 0 none, 1 ref, 2 raw produce, 3 raw consume */
    integer cap_cnt, raw_cnt, sent, errors, i, w, k;
    reg [63:0] ref_scale [0:OC-1];
    reg [63:0] ref_bias  [0:OC-1];

    style_net_core #(
        .LANES(LANES), .MAX_IC(MAX_IC), .MAX_OC(MAX_OC), .MAX_UW(W)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .is_stats(is_stats),
        .raw_produce(raw_produce), .raw_consume(raw_consume), .do_relu(do_relu),
        .tanh_do(1'b0), .lut_we(1'b0), .lut_waddr(13'd0), .lut_wdata(24'd0),
        .busy(busy), .done(done),
        .shp_ic(IC), .shp_oc(OC), .shp_stride(1), .shp_up(1),
        .shp_in_w(W), .shp_in_h(H),
        .in_pixel(in_pixel), .in_valid(in_valid), .in_ready(in_ready),
        .out_pixel(out_pixel), .out_valid(out_valid), .out_ready(out_ready),
        .w_addr(w_addr), .w_rdata(w_rdata), .zp_in(zp_in), .inv_n_q32(inv_n_q32),
        .p_raddr(p_raddr), .p_s2(p_s2), .p_sg(p_sg), .p_beta(p_beta),
        .res_do(1'b0), .res_valid(1'b1), .res_pixel({8*MAX_OC{1'b0}}),
        .res_scale_q32(64'sd0), .res_zp(8'sd0), .res_ready(),
        .q_scale_recip_q48(q_recip), .q_zero_point(q_zp),
        .sum_flat(sum_flat), .sumsq_flat(sumsq_flat), .count_out(count_out),
        .dbg_st_addr(dbg_st_addr), .dbg_st_sum(dbg_st_sum), .dbg_st_sumsq(dbg_st_sumsq)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            w_rdata <= 256'd0;
            p_s2 <= 0; p_sg <= 0; p_beta <= 0;
        end else begin
            if (w_addr < MAX_OC*16) w_rdata <= w_mem[w_addr];
            p_s2 <= s2_arr[p_raddr];
            p_sg <= sg_arr[p_raddr];
            p_beta <= beta_arr[p_raddr];
        end
    end

    always @(posedge clk) begin
        if (rst_n && out_valid && out_ready) begin
            if (cap_mode == 1)
                ref_mem[cap_cnt] = out_pixel[8*OC-1:0];
            else if (cap_mode == 2)
                raw_mem[cap_cnt] = out_pixel;
            else if (cap_mode == 3) begin
                if (out_pixel[8*OC-1:0] !== ref_mem[cap_cnt]) begin
                    $display("FAIL q1 pixel=%0d got=%h exp=%h", cap_cnt,
                             out_pixel[8*OC-1:0], ref_mem[cap_cnt]);
                    errors = errors + 1;
                end
            end
            cap_cnt = cap_cnt + 1;
        end
    end

    task run_pass;
        input in_stats;
        input in_raw_prod;
        input in_raw_cons;
        input use_raw_input;
        integer id, guard;
        reg ready_before;
        begin
            is_stats=in_stats; raw_produce=in_raw_prod; raw_consume=in_raw_cons;
            cap_cnt=0; sent=0;
            @(negedge clk); start=1;
            @(negedge clk); start=0;
            id=0; in_valid=0;
            while (id < COUNT) begin
                @(negedge clk);
                ready_before = in_ready;
                if (!use_raw_input)
                    for (i=0;i<IC;i=i+1) in_pixel[8*i +:8] = (id*19 + i*7 + 3) & 255;
                else
                    in_pixel = raw_mem[id];
                in_valid=1;
                @(posedge clk);
                if (ready_before) id=id+1;
                sent=sent+1;
                if (sent > COUNT*1000) begin
                    $display("FAIL input stuck stats=%0d rp=%0d rc=%0d state=%0d", in_stats,in_raw_prod,in_raw_cons,dut.state);
                    $finish(1);
                end
            end
            @(negedge clk); in_valid=0;
            guard=0;
            while (!done && guard < 2000000) begin @(posedge clk); guard=guard+1; end
            if (!done) begin
                $display("FAIL timeout stats=%0d rp=%0d rc=%0d state=%0d", in_stats,in_raw_prod,in_raw_cons,dut.state);
                $finish(1);
            end
            @(posedge clk);
        end
    endtask

    initial begin
        clk=0; rst_n=0; start=0; is_stats=0; raw_produce=0; raw_consume=0; do_relu=1;
        in_pixel=0; in_valid=0; out_ready=1; cap_mode=0; cap_cnt=0; raw_cnt=0; sent=0; errors=0;
        zp_in=0; inv_n_q32=32'd134217728; q_recip=64'd4294967296; q_zp=0; dbg_st_addr=0;
        for (i=0;i<OC;i=i+1) begin
            s2_arr[i]=64'd281474976710656; sg_arr[i]=64'd0; beta_arr[i]=64'd0;
        end
        for (i=0;i<MAX_OC*16;i=i+1) w_mem[i]=256'd0;
        for (w=0;w<OC;w=w+1) begin
            for (k=0;k<32;k=k+1)
                w_mem[w*16][8*k +:8] = (w*37 + k*11 + 1) & 255;
        end
        repeat(4) @(posedge clk);
        @(negedge clk); rst_n=1;
        repeat(2) @(posedge clk);

        /* reference: normal stats + normal compute */
        cap_mode=0; run_pass(1,0,0,0);
        for (i=0;i<OC;i=i+1) begin
            ref_scale[i] = dut.norm_scale_ram[i];
            ref_bias[i]  = dut.norm_bias_ram[i];
        end
        cap_mode=1; run_pass(0,0,0,0);
        if (cap_cnt != COUNT) begin $display("FAIL ref cap=%0d",cap_cnt); errors=errors+1; end

        /* raw producer must accumulate exactly the same statistics while it
         * writes the unnormalised int32 convolution result. */
        cap_mode=2; run_pass(1,1,0,0);
        if (cap_cnt != COUNT) begin $display("FAIL raw cap=%0d",cap_cnt); errors=errors+1; end
        raw_cnt=cap_cnt;
        for (i=0;i<OC;i=i+1) begin
            if (dut.norm_scale_ram[i] !== ref_scale[i] ||
                dut.norm_bias_ram[i]  !== ref_bias[i]) begin
                $display("FAIL stats norm ch=%0d scale=%h/%h bias=%h/%h", i,
                         dut.norm_scale_ram[i], ref_scale[i],
                         dut.norm_bias_ram[i], ref_bias[i]);
                errors = errors + 1;
            end
        end

        /* raw consumer: read int32, skip conv, emit q1 and compare */
        cap_mode=3; run_pass(0,0,1,1);
        if (cap_cnt != COUNT) begin $display("FAIL raw consume cap=%0d",cap_cnt); errors=errors+1; end

        if (errors==0) $display("PASS raw_p0p1_bit_exact pixels=%0d", COUNT);
        else $display("FAIL raw_p0p1_bit_exact errors=%0d",errors);
        $finish;
    end

    initial begin
        #20000000;
        $display("FAIL watchdog raw_cnt=%0d cap=%0d state=%0d",raw_cnt,cap_cnt,dut.state);
        $finish(1);
    end
endmodule
