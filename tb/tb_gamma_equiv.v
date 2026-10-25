//======================================================================
// tb_gamma_equiv : gamma_correction 新实现 (BRAM 直查) vs 旧实现 (寄存器堆)
//   逐周期对拍, 要求 o_red/o_green/o_blue/o_valid/o_hs/o_vs 完全一致。
//   旧实现需要先用 1024 拍把 ROM 搬进寄存器堆, 所以前 1100 拍 (i_valid=0,
//   消隐期) 只做预热, 不比较。
//======================================================================
`timescale 1ns/1ps

module tb_gamma_equiv;

	reg	clk = 0, rstn = 0;
	reg	i_valid = 0, i_hs = 0, i_vs = 0;
	reg	[7:0] i_r = 0, i_g = 0, i_b = 0;

	wire [7:0] n_r, n_g, n_b, f_r, f_g, f_b;
	wire n_valid, n_hs, n_vs, f_valid, f_hs, f_vs;

	integer errors = 0, cyc = 0, checks = 0;
	integer k;
	reg [31:0] lfsr = 32'h1234_5678;

	always #5 clk = ~clk;			// 100 MHz

	gamma_correction #(.DATA_WIDTH(8), .GAMMA_CURVE("./rtl/gamma_conrrection/2P2.mem")) dut_new
	(
		.i_pclk(clk), .i_rstn(rstn),
		.i_valid(i_valid), .i_hs(i_hs), .i_vs(i_vs),
		.i_red(i_r), .i_green(i_g), .i_blue(i_b),
		.o_red(n_r), .o_green(n_g), .o_blue(n_b),
		.o_valid(n_valid), .o_hs(n_hs), .o_vs(n_vs)
	);

	gamma_correction_ref #(.DATA_WIDTH(8), .GAMMA_CURVE("./rtl/gamma_conrrection/2P2.mem")) dut_ref
	(
		.i_pclk(clk), .i_rstn(rstn),
		.i_valid(i_valid), .i_hs(i_hs), .i_vs(i_vs),
		.i_red(i_r), .i_green(i_g), .i_blue(i_b),
		.o_red(f_r), .o_green(f_g), .o_blue(f_b),
		.o_valid(f_valid), .o_hs(f_hs), .o_vs(f_vs)
	);

	function [7:0] rnd;
		input d;
		begin
			lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
			rnd  = lfsr[7:0];
		end
	endfunction

	// 统计一次比较
	task compare;
		begin
			if ( (n_r !== f_r) || (n_g !== f_g) || (n_b !== f_b) ||
			     (n_valid !== f_valid) || (n_hs !== f_hs) || (n_vs !== f_vs) )
			begin
				errors = errors + 1;
				if (errors <= 10)
					$display("MISMATCH @cyc %0d : new r/g/b=%02x/%02x/%02x v/hs/vs=%b%b%b  ref=%02x/%02x/%02x %b%b%b",
						cyc, n_r, n_g, n_b, n_valid, n_hs, n_vs, f_r, f_g, f_b, f_valid, f_hs, f_vs);
			end
			checks = checks + 1;
		end
	endtask

	// 一拍 (输入在 negedge 更新, 输出在 posedge 采样)
	task step;
		input v, hs, vs, en;
		begin
			@(negedge clk);
			i_valid = v; i_hs = hs; i_vs = vs;
			if (en) begin i_r = rnd(0); i_g = rnd(0); i_b = rnd(0); end
			@(posedge clk);
			#1;
			cyc = cyc + 1;
			if (checks_en) compare;
		end
	endtask

	reg checks_en = 0;

	initial begin
		// reset
		rstn = 0;
		repeat (4) begin @(negedge clk); i_valid=0; i_hs=0; i_vs=0; end
		@(negedge clk); rstn = 1;

		// 预热: 1100 拍消隐 (旧实现靠这段时间把 ROM 搬进寄存器堆)
		for (k = 0; k < 1100; k = k + 1)
			step(1'b0, 1'b0, 1'b0, 1'b0);

		checks_en = 1;

		// 3 帧: 每帧 20 行 x 40 像素有效 + 随机消隐
		for (k = 0; k < 3; k = k + 1) begin
			integer row, col, n;
			for (row = 0; row < 20; row = row + 1) begin
				for (col = 0; col < 40; col = col + 1)
					step(1'b1, 1'b0, 1'b0, 1'b1);
				for (n = 0; n < 12; n = n + 1)		// 行消隐
					step(1'b0, 1'b1, 1'b0, 1'b0);
			end
			for (n = 0; n < 40; n = n + 1)			// 场消隐
				step(1'b0, 1'b0, 1'b1, 1'b0);
		end

		$display("gamma equivalence: checks=%0d errors=%0d", checks, errors);
		if (errors == 0) $display("RESULT: PASS");
		else             $display("RESULT: FAIL");
		$finish;
	end

endmodule