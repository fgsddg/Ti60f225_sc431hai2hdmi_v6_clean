/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2018 Efinix Inc. All rights reserved.
//
// Gamma correction (curve lookup)
//
// 2026-10-14 rewrite:
//   原实现把 1024x10 的 gamma ROM 按像素顺序搬进一个 1024x10 的寄存器堆
//   (r_gamma_2P), 再用它做 R/G/B 三路组合查找 -> 综合成 ~8.2k FF + ~19.5k LUT,
//   占顶层 63% 的逻辑 (见 outflow/ti60f225_oob_top.res.csv)。
//   现改为每个通道一个只读 ROM 直接查找, 由 Efinity 推断成 BRAM:
//   约 6 块 RAM10 换掉 ~25k XLR。
//   逐周期行为与旧实现完全一致 (延迟 1 拍, 数据与 hs/vs/valid 同相),
//   见 tb/tb_gamma_equiv.v (旧实现逐周期对拍)。
//
// 时序: 地址来自当前输入像素 -> ROM 输出寄存 (1 拍) -> 用已寄存的 valid 组合
//       选通输出。数据与 o_valid/o_hs/o_vs 都是 1 拍延迟, 与旧实现相同。
//
/////////////////////////////////////////////////////////////////////////////

(* syn_ram_style = "block_ram" *)
module gamma_rom_1024x10
(
	input				clk,
	input	[9:0]		addr,
	output	reg	[9:0]	dout
);
	parameter	INIT_FILE	= "ram_init_file.mem";

	(* syn_ram_style = "block_ram" *) reg [9:0] mem [0:1023];

	initial
	begin
		if (INIT_FILE != "")
			$readmemh(INIT_FILE, mem);
	end

	always @(posedge clk)
		dout <= mem[addr];
endmodule


module gamma_correction
#(
	parameter	DATA_WIDTH	= 10,
	parameter 	GAMMA_CURVE	= "2P2.mem"
)
(
	input						i_pclk,
	input						i_rstn,

	input 						i_valid,
	input 						i_hs,
	input 						i_vs,
	input 	[DATA_WIDTH-1:0]	i_red,
	input 	[DATA_WIDTH-1:0]	i_green,
	input 	[DATA_WIDTH-1:0]	i_blue,

	output	wire[DATA_WIDTH-1:0]	o_red,
	output	wire[DATA_WIDTH-1:0]	o_green,
	output	wire[DATA_WIDTH-1:0]	o_blue,
	output	reg					o_valid,
	output  reg  				o_hs,
	output 	reg 				o_vs
);

	wire	[9:0]	w_addr_r, w_addr_g, w_addr_b;
	wire	[9:0]	w_gamma_r, w_gamma_g, w_gamma_b;

	//------------------------------------------------------------------
	// 查表地址: DATA_WIDTH=10 时直接用像素值; =8 时 {像素, 高2位} 形成
	// 1024 项的插值表 (与旧实现一致)
	//------------------------------------------------------------------
	generate
	if (DATA_WIDTH == 10)
	begin : g_addr_full
		assign w_addr_r = i_red;
		assign w_addr_g = i_green;
		assign w_addr_b = i_blue;
	end
	else
	begin : g_addr_interp
		assign w_addr_r = {i_red,   i_red[7:6]};
		assign w_addr_g = {i_green, i_green[7:6]};
		assign w_addr_b = {i_blue,  i_blue[7:6]};
	end
	endgenerate

	//------------------------------------------------------------------
	// 每通道一个只读 ROM (BRAM)
	//------------------------------------------------------------------
	gamma_rom_1024x10 #(.INIT_FILE(GAMMA_CURVE)) u_rom_r
	(
		.clk(i_pclk), .addr(w_addr_r), .dout(w_gamma_r)
	);

	gamma_rom_1024x10 #(.INIT_FILE(GAMMA_CURVE)) u_rom_g
	(
		.clk(i_pclk), .addr(w_addr_g), .dout(w_gamma_g)
	);

	gamma_rom_1024x10 #(.INIT_FILE(GAMMA_CURVE)) u_rom_b
	(
		.clk(i_pclk), .addr(w_addr_b), .dout(w_gamma_b)
	);

	//------------------------------------------------------------------
	// 输出: 用已寄存的 o_valid 选通 (与旧实现同相)
	//------------------------------------------------------------------
	generate
	if (DATA_WIDTH == 10)
	begin : g_out_full
		assign o_red	= o_valid ? w_gamma_r        : {DATA_WIDTH{1'b0}};
		assign o_green	= o_valid ? w_gamma_g        : {DATA_WIDTH{1'b0}};
		assign o_blue	= o_valid ? w_gamma_b        : {DATA_WIDTH{1'b0}};
	end
	else
	begin : g_out_interp
		assign o_red	= o_valid ? w_gamma_r[9:2]   : {DATA_WIDTH{1'b0}};
		assign o_green	= o_valid ? w_gamma_g[9:2]   : {DATA_WIDTH{1'b0}};
		assign o_blue	= o_valid ? w_gamma_b[9:2]   : {DATA_WIDTH{1'b0}};
	end
	endgenerate

	always @(posedge i_pclk)
	begin
		if (~i_rstn)
		begin
			o_valid	<= 1'b0;
			o_hs	<= 1'b0;
			o_vs	<= 1'b0;
		end
		else
		begin
			o_valid	<= i_valid;
			o_hs	<= i_hs;
			o_vs	<= i_vs;
		end
	end

endmodule