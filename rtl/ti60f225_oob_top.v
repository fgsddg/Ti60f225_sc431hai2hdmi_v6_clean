
/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2021 Efinix Inc. All rights reserved.
//
// Description:
// Example top file for ti60f225 dev kit OOB design
//
// Language:  Verilog 2001
//Ti60f225_sc431hai2hdmi_v6：
//使用了最新版本的framebuffer_v3;
// ------------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////////
//`define SOFT_TAP 1
`include "ddr3_controller/ddr3_parameter.vh"
// `include "define.v"

module ti60f225_oob_top #(

	parameter                       RANK_RATIO         = 1,       // # of unique CS outputs per rank
	parameter                       ASYN_AXI_CLK       = `ASYN_AXI_CLK, 
	parameter                       RANKS              = `RANKS,
	parameter                       CK_WIDTH           = `CK_WIDTH,       // # of CK/CK# outputs to memory   
	parameter                       CKE_WIDTH          = `CKE_WIDTH,       // # of cke outputs
	parameter                       CS_WIDTH           = `CS_WIDTH,       // # of unique CS outputs
	parameter                       BANK_WIDTH         = `BANK_WIDTH,       // # of bank bits
	parameter                       ROW_WIDTH          = `ROW_WIDTH,       // DRAM address bus width
	parameter                       COL_WIDTH          = `COL_WIDTH,      // column address width
	parameter                       DM_WIDTH           = `DM_WIDTH,       // # of DM (data mask)
	parameter                       DQS_WIDTH          = `DQS_WIDTH,       // # of DQS (strobe)
	parameter                       DQ_WIDTH           = `DQ_WIDTH,      // # of DQ (data)
	parameter                       ODT_WIDTH          = `ODT_WIDTH,
	parameter                       DQ_CNT_WIDTH       = `DQ_CNT_WIDTH,       // = ceil(log2(DQ_WIDTH))
	parameter                       DQS_CNT_WIDTH      = `DQS_CNT_WIDTH,       // = ceil(log2(DQS_WIDTH))  
	parameter                       DRAM_WIDTH         = `DRAM_WIDTH,       // # of DQ per DQS   
	parameter                       DATA_WIDTH         = `DATA_WIDTH,
	parameter                       ADDR_WIDTH         = `ADDR_WIDTH,    
	parameter                       AXI_ID_WIDTH       = `AXI_ID_WIDTH,
	parameter                       AXI_ADDR_WIDTH     = `AXI_ADDR_WIDTH,
	parameter                       AXI_DATA_WIDTH     = `AXI_DATA_WIDTH
)
(

  (* syn_peri_port = 0 *) input jtag_inst1_CAPTURE,
  (* syn_peri_port = 0 *) input jtag_inst1_DRCK,
  (* syn_peri_port = 0 *) input jtag_inst1_RESET,
  (* syn_peri_port = 0 *) input jtag_inst1_RUNTEST,
  (* syn_peri_port = 0 *) input jtag_inst1_SEL,
  (* syn_peri_port = 0 *) input jtag_inst1_SHIFT,
  (* syn_peri_port = 0 *) input jtag_inst1_TCK,
  (* syn_peri_port = 0 *) input jtag_inst1_TDI,
  (* syn_peri_port = 0 *) input jtag_inst1_TMS,
  (* syn_peri_port = 0 *) input jtag_inst1_UPDATE,
  (* syn_peri_port = 0 *) output jtag_inst1_TDO,
    (* syn_peri_port = 0 *) input  wire system_uart_0_io_rxd,
    (* syn_peri_port = 0 *) output wire system_uart_0_io_txd,

    // Dedicated configuration Flash, user-mode SPI access
    input  wire system_spi_0_io_data_0_IN,
    input  wire system_spi_0_io_data_1_IN,
    output wire system_spi_0_io_ss,
    output wire system_spi_0_io_sclk_write,
    output wire system_spi_0_io_data_0_OUT,
    output wire system_spi_0_io_data_0_OE,
    output wire system_spi_0_io_data_1_OUT,
    output wire system_spi_0_io_data_1_OE,

   //Clocks 
	input	wire	key1,
	input	wire	key2,
	input	wire	key3,
	input	wire	key0,
    input	wire	i_mipi_rx_pclk,
    input wire  vid_clk_dvi2,
    input wire  hdmi_scale_clk,
    input wire  hdmi_tx_slow_clk,
    input wire CLK_5M,
    input  wire CLK_25M,
	output  wire    pll_inst1_RSTN,
	input	wire	i_pll_locked,
	input 	wire  	pll_locked,
	output  wire    pll_inst4_RSTN,
	input   wire    pll_inst4_LOCKED,
	output  wire  	USER_PLL_RSTN,
    output 	wire 	DDR3_PLL_RSTN,
	input 	wire  	user_pll_locked,
    //CSI Interface
    input	 wire		io_cam_sda_IN,
    output wire   io_cam_sda_OUT,
    output wire		io_cam_sda_OE,

    output io_cam_scl_OUT,
    input io_cam_scl_IN,
    output io_cam_scl_OE,

    output	wire		o_cam_rst_p,
    
    input	wire		i_cam_ck_LP_P_IN,
    input	wire		i_cam_ck_LP_N_IN,
    output	wire		o_cam_ck_HS_TERM,
    output	wire		o_cam_ck_HS_ENA,
    input	wire		i_cam_ck_CLKOUT,
    
    input	wire	[7:0]			cam_d0_HS_IN,
    input	  wire		      cam_d0_LP_P_IN,
    input	  wire		      cam_d0_LP_N_IN,
    output	wire		      cam_d0_HS_TERM,
    output	wire		      cam_d0_HS_ENA,
    output	wire		      cam_d0_RST,
    output	wire		      cam_d0_FIFO_RD,
    input	  wire		      cam_d0_FIFO_EMPTY,
    
    input 	wire	[7:0]			cam_d1_HS_IN,
    input	  wire		        cam_d1_LP_P_IN,
    input	  wire		        cam_d1_LP_N_IN,
    output	wire		        cam_d1_HS_TERM,
    output	wire		        cam_d1_HS_ENA,
    output	wire		        cam_d1_RST,
    output	wire		        cam_d1_FIFO_RD,
    input	  wire		        cam_d1_FIFO_EMPTY,
    
    input 	wire	[7:0]			cam_d2_HS_IN,
    input	  wire		        cam_d2_LP_P_IN,
    input	  wire		        cam_d2_LP_N_IN,
    output	wire		        cam_d2_HS_TERM,
    output	wire		        cam_d2_HS_ENA,
    output	wire		        cam_d2_RST,
    output	wire		        cam_d2_FIFO_RD,
    input	  wire		        cam_d2_FIFO_EMPTY,  
   
    input 	wire	[7:0]			cam_d3_HS_IN,
    input	  wire		        cam_d3_LP_P_IN,
    input	  wire		        cam_d3_LP_N_IN,
    output	wire		        cam_d3_HS_TERM,
    output	wire		        cam_d3_HS_ENA,
    output	wire		        cam_d3_RST,
    output	wire		        cam_d3_FIFO_RD,
    input	  wire		        cam_d3_FIFO_EMPTY,

	
	input 					tx_cal_clk_90edge,
  	input 					rx_cal_clk,
  	input 					tx_cal_clk,
	input                              core_clk,     // CORE CLK @ 100MHz
	input                              sdram_clk,    // SDRAM CK @ 400MHz
	// PLL status flags  
	output [2:0]                       pll_shift,  
	output [4:0]                       pll_shift_sel,
	output                             pll_shift_ena,  
	// memory interface ports
	output                             ddr_ck_hi,
	output                             ddr_ck_lo,
	output                             ddr_reset_n,
	output [CKE_WIDTH-1:0]             ddr_cke,     
	output [ROW_WIDTH-1:0]             ddr_addr,
	output [BANK_WIDTH-1:0]            ddr_ba,
	output                             ddr_cas_n,
 
	output [CS_WIDTH*RANK_RATIO-1:0]   ddr_cs_n,
	output                             ddr_ras_n,
	output                             ddr_we_n,
	
	input  [DQS_WIDTH-1:0]             ddr_dqs_in_hi,
	input  [DQS_WIDTH-1:0]             ddr_dqs_in_lo,
	input  [DQ_WIDTH-1:0]              ddr_dq_in_hi,
	input  [DQ_WIDTH-1:0]              ddr_dq_in_lo,
	
	output [DQS_WIDTH-1:0]             ddr_dqs_oe,
	output [DQS_WIDTH-1:0]             ddr_dqs_oe_n,
	output [DQ_WIDTH-1:0]              ddr_dq_oe,  
	output [DQS_WIDTH-1:0]             ddr_dqs_out_hi,
	output [DQS_WIDTH-1:0]             ddr_dqs_out_lo,
	output [DQ_WIDTH-1:0]              ddr_dq_out_hi,
	output [DQ_WIDTH-1:0]              ddr_dq_out_lo,
	output [DM_WIDTH-1:0]              ddr_dm_hi,
	output [DM_WIDTH-1:0]              ddr_dm_lo,
	output [ODT_WIDTH-1:0]             ddr_odt,

       //LED
       output [3:0] led,

       // MIPI DSI
       input	wire	                     i_mipi_tx_pclk		,
       output	wire	                     mipi_dp_clk_LP_P_OUT		,
       output	wire	                     mipi_dp_clk_LP_N_OUT		,
       output	wire	[7:0] 	              mipi_dp_clk_HS_OUT		,
       output	wire	                     mipi_dp_clk_HS_OE		,
       output	wire	                     mipi_dp_data3_LP_P_OUT	,
       output	wire	                     mipi_dp_data2_LP_P_OUT	,
       output	wire	                     mipi_dp_data1_LP_P_OUT	,
       output	wire	                     mipi_dp_data0_LP_P_OUT	,
       output	wire	                     mipi_dp_data3_LP_N_OUT	,
       output	wire	                     mipi_dp_data2_LP_N_OUT	,
       output	wire	                     mipi_dp_data1_LP_N_OUT	,
       output	wire	                     mipi_dp_data0_LP_N_OUT	,
       output	wire	[7:0] 	              mipi_dp_data0_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data1_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data2_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data3_HS_OUT	       ,
       output	wire	                     mipi_dp_data3_HS_OE		,
       output	wire	                     mipi_dp_data2_HS_OE		,
       output	wire	                     mipi_dp_data1_HS_OE		,
       output	wire	                     mipi_dp_data0_HS_OE		,

       output	wire	                     mipi_dp_clk_RST		,
       output	wire	                     mipi_dp_data0_RST		,
       output	wire	                     mipi_dp_data1_RST		,
       output	wire	                     mipi_dp_data2_RST		,
       output	wire	                     mipi_dp_data3_RST		,
       output	wire	                     mipi_dp_clk_LP_P_OE		,
       output	wire	                     mipi_dp_clk_LP_N_OE		,
       output	wire	                     mipi_dp_data3_LP_P_OE	,
       output	wire	                     mipi_dp_data3_LP_N_OE	,
       output	wire	                     mipi_dp_data2_LP_P_OE	,
       output	wire	                     mipi_dp_data2_LP_N_OE	,
       output	wire	                     mipi_dp_data1_LP_P_OE	,
       output	wire	                     mipi_dp_data1_LP_N_OE	,
       output	wire	                     mipi_dp_data0_LP_P_OE	,
       output	wire	                     mipi_dp_data0_LP_N_OE	,

       input  wire	                     mipi_dp_data0_LP_P_IN	,
       input  wire	                     mipi_dp_data0_LP_N_IN	,
       output	wire	                     LCD_RST_P			,
       output wire                        LCD_POWER			,

       // hdmi interface

    output tmds_tx_clk_TX_OE,
    output [9:0] tmds_tx_clk_TX_DATA,
    output tmds_tx_clk_TX_RST,
    output tmds_tx_data0_TX_OE,
    output [9:0] tmds_tx_data0_TX_DATA,
    output tmds_tx_data0_TX_RST,
    output tmds_tx_data1_TX_OE,
    output [9:0] tmds_tx_data1_TX_DATA,
    output tmds_tx_data1_TX_RST,
    output tmds_tx_data2_TX_OE,
    output [9:0] tmds_tx_data2_TX_DATA,
    output tmds_tx_data2_TX_RST


);

function integer log2;
	input	integer	val;
	integer	i;
	begin
		log2 = 0;
		for (i=0; 2**i<val; i=i+1)
			log2 = i+1;
	end
endfunction


//===============================================================================
//localparam
//===============================================================================
localparam WR_FIFO_DEPTH  = 1024;
localparam RD_FIFO_DEPTH  = 1024;

// localparam	MAX_HRES		= 12'd1920;
// localparam	MAX_VRES		= 12'd1080;
// localparam	HSP			= 8'd2;
// localparam	HBP			= 8'd88;
// localparam	HFP			= 8'd120;
// localparam	VSP			= 8'd2;
// localparam	VBP			= 8'd20;
// localparam	VFP			= 8'd20;

// 1920x1080@60 (CEA-861) ---- 保留备用
// localparam MAX_HRES = 1920;
// localparam HFP      = 88;
// localparam HSP      = 44;
// localparam HBP      = 148;
// localparam MAX_VRES = 1080;
// localparam VFP      = 4;
// localparam VSP      = 5;
// localparam VBP      = 36;

// 1024x600 (小尺寸HDMI屏常用时序, H总长1344, V总长635)
localparam MAX_HRES = 1920;
localparam HFP      = 88;
localparam HSP      = 44;
localparam HBP      = 148;

localparam MAX_VRES = 1080;
localparam VFP      = 4;
localparam VSP      = 5;
localparam VBP      = 36;   // V total 1125 (1080p60)
//===============================================================================
//signal
//===============================================================================
   
wire                              app_sr_active;
wire                              app_ref_ack;
wire                              app_zq_ack;
wire                              cal_done;

// Slave Interface Write Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_awid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_awaddr;
wire [7:0]                        s_axi_awlen;
wire [2:0]                        s_axi_awsize;
wire [1:0]                        s_axi_awburst;
wire [0:0]                        s_axi_awlock;
wire [3:0]                        s_axi_awcache;
wire [2:0]                        s_axi_awprot;
wire                              s_axi_awvalid;
wire                              s_axi_awready;
// Slave Interface Write Data Ports
wire [AXI_DATA_WIDTH-1:0]         s_axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb;
wire                              s_axi_wlast;
wire                              s_axi_wvalid;
wire                              s_axi_wready;
// Slave Interface Write Response Ports
wire                              s_axi_bready;
wire [AXI_ID_WIDTH-1:0]           s_axi_bid;
wire [1:0]                        s_axi_bresp;
wire                              s_axi_bvalid;
// Slave Interface Read Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_arid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_araddr;
wire [7:0]                        s_axi_arlen;
wire [2:0]                        s_axi_arsize;
wire [1:0]                        s_axi_arburst;
wire [0:0]                        s_axi_arlock;
wire [3:0]                        s_axi_arcache;
wire [2:0]                        s_axi_arprot;
wire                              s_axi_arvalid;
wire                              s_axi_arready;
// Slave Interface Read Data Ports
wire                              s_axi_rready;
wire [AXI_ID_WIDTH-1:0]           s_axi_rid;

// AXI_ID_WIDTH widened 4 -> 8: frame_buffer's ID ports are 6 bit wide, so the upper
// bits of s_axi_awid/s_axi_arid must be zero-extended explicitly (otherwise undriven).
wire [AXI_DATA_WIDTH-1:0]         s_axi_rdata;
wire [1:0]                        s_axi_rresp;
wire                              s_axi_rlast;
wire                              s_axi_rvalid;




////////////////////////////////////////////////////////////////
// System & Debugger
wire    w_arstn;
// wire	w_sysclk_mcu_arstn;
// wire	w_sysclk_mcu_arst;
wire	w_mipi_rx_pclk_arstn;
wire	w_mipi_rx_pclk_arst;

wire		       w_mipi_rx_vs;
wire		       w_mipi_rx_hs;
wire	       w_mipi_rx_de;
wire	[63:0]			w_mipi_rx_data	;

wire					io_systemReset;



//===================================================================================================
//reset module
//===================================================================================================

assign w_arstn  		       = i_pll_locked & pll_locked & user_pll_locked;
assign pll_inst1_RSTN  		= 1'b1;
assign USER_PLL_RSTN      		= 1'b1;
assign mipi_dsi_tx_pll_RSTN 	= 1'b1;
assign DDR3_PLL_RSTN 		= 1'b1;
reset_ctrl
#(
	.NUM_RST		(2),
	.CYCLE			(1),
	.IN_RST_ACTIVE	(4'b00),
	.OUT_RST_ACTIVE	(4'b10)
)
inst_reset_ctrl
(
	.i_arst		({2{w_arstn}}),//({{4{i_pll_locked}},                  {2{i_arstn}}}),
	.i_clk			({2{i_mipi_rx_pclk}}),
	.o_srst		({w_mipi_rx_pclk_arst, w_mipi_rx_pclk_arstn})
);



reg [25:0] cnt = 'd0;
always @( posedge core_clk)
begin 
       cnt <= cnt + 1'b1;
end
assign led[0]  = cal_done ? cnt[24] : 1'b0;

//========================================================================================================
//MIPI RX
//========================================================================================================
wire i_mipi_clk ;
assign i_mipi_clk = core_clk;

		assign	cam_d0_RST		= 1'b0;
		assign	cam_d1_RST		= 1'b0;
		assign  cam_d2_RST = 1'b0;
    assign  cam_d3_RST = 1'b0;
	
wire [15:0] mipi_debug_out;
		

		csi_rx_controller inst_efx_csi2_rx
		(
              .reset_n			(w_arstn),
              .clk				(i_mipi_clk),
              .reset_byte_HS_n	(w_arstn),
              .clk_byte_HS		  (i_cam_ck_CLKOUT),
              .reset_pixel_n		(w_mipi_rx_pclk_arstn),
              .clk_pixel			  (i_mipi_rx_pclk),
              
              .Rx_LP_CLK_P		  (i_cam_ck_LP_P_IN),
              .Rx_LP_CLK_N		  (i_cam_ck_LP_N_IN),
              .Rx_HS_enable_C		(o_cam_ck_HS_ENA),
              .LVDS_termen_C		(o_cam_ck_HS_TERM),
              
              .Rx_LP_D_P			({cam_d3_LP_P_IN, cam_d2_LP_P_IN, cam_d1_LP_P_IN, cam_d0_LP_P_IN}),//(r_mipi_rx_data_LP_P_IN_2P),
              .Rx_LP_D_N			({cam_d3_LP_N_IN, cam_d2_LP_N_IN, cam_d1_LP_N_IN, cam_d0_LP_N_IN}),//(r_mipi_rx_data_LP_N_IN_2P),
              .Rx_HS_D_0			(cam_d0_HS_IN),//(r_mipi_rx_data_HS_IN_2P[0*8+:8]),
              .Rx_HS_D_1			(cam_d1_HS_IN),//(r_mipi_rx_data_HS_IN_2P[1*8+:8]),
              .Rx_HS_D_2			(cam_d2_HS_IN),
              .Rx_HS_D_3			(cam_d3_HS_IN),
              .Rx_HS_D_4			(),
              .Rx_HS_D_5			(),
              .Rx_HS_D_6			(),
              .Rx_HS_D_7			(),
              .Rx_HS_enable_D		({cam_d3_HS_ENA    ,cam_d2_HS_ENA    ,cam_d1_HS_ENA    ,cam_d0_HS_ENA    }),//( w_cam_d_HS_ENA),
              .LVDS_termen_D		({cam_d3_HS_TERM   ,cam_d2_HS_TERM   ,cam_d1_HS_TERM   ,cam_d0_HS_TERM   }),
              .fifo_rd_enable		({cam_d3_FIFO_RD   ,cam_d2_FIFO_RD   ,cam_d1_FIFO_RD   ,cam_d0_FIFO_RD   }),
              .fifo_rd_empty		({cam_d3_FIFO_EMPTY,cam_d2_FIFO_EMPTY,cam_d1_FIFO_EMPTY,cam_d0_FIFO_EMPTY}),
              .DLY_enable_D		       (),
              .DLY_inc_D			(),
              .u_dly_enable_D		(),
              .u_dly_inc_D		       (),
              
              .axi_clk			(1'b0),
              .axi_reset_n		       (1'b0),
              .axi_awaddr			(6'b0),
              .axi_awvalid		       (1'b0),
              .axi_awready		       (),
              .axi_wdata			(32'b0),
              .axi_wvalid			(1'b0),
              .axi_wready			(),
              
              .axi_bvalid			(),
              .axi_bready			(1'b0),
              .axi_araddr			(6'b0),
              .axi_arvalid		       (1'b0),
              .axi_arready		       (),
              .axi_rdata			(),
              .axi_rvalid			(),
              .axi_rready			(1'b1),
              
              .hsync_vc0			(w_mipi_rx_hs),
              .hsync_vc1			(),
              .hsync_vc2			(),
              .hsync_vc3			(),
              .vsync_vc0			(w_mipi_rx_vs),
              .vsync_vc1			(),
              .vsync_vc2			(),
              .vsync_vc3			(),
              .vc				(),
              .word_count			(),
              .shortpkt_data_field        (),
              .datatype			(),
              .pixel_per_clk		(),
              .pixel_data			(w_mipi_rx_data),
              .pixel_data_valid	       (w_mipi_rx_de),
              .irq				(),
              .mipi_debug_out(mipi_debug_out)
		);

//     wire		       w1_mipi_rx_vs;
// wire		       w1_mipi_rx_hs;
// wire	       w1_mipi_rx_de;
// wire	[39:0]			w1_mipi_rx_data	;
// sensor_clipper  sensor_clipper_inst (
//     .clk(i_mipi_rx_pclk),
//     .i_vs(w_mipi_rx_vs),
//     .i_hs(w_mipi_rx_hs),
//     .i_de(w_mipi_rx_de),
//     .i_dat(w_mipi_rx_data[39:0]),

//     .o_hs(w1_mipi_rx_hs),
//     .o_vs(w1_mipi_rx_vs),
//     .o_de(w1_mipi_rx_de),
//     .o_dat(w1_mipi_rx_data)
   
//   );


wire mdebug_pixel_fifo_full     = mipi_debug_out[0] ;
wire mdebug_pixel_fifo_empty    = mipi_debug_out[1] ;
wire mdebug_crc_error           = mipi_debug_out[2] ;
wire mdebug_ecc_1bit_error      = mipi_debug_out[3] ;
wire mdebug_ecc_2bit_error      = mipi_debug_out[4] ;
wire mdebug_undersize_pkt_error = mipi_debug_out[5] ;
wire mdebug_line_vc0_error      = mipi_debug_out[6] ;
wire mdebug_frame_vc0_error    = mipi_debug_out[10];   
wire mdebug_receive_error      = mipi_debug_out[14];


//========================================================================================================
//
//========================================================================================================
		

//*************** imx219 config********************/
// mipi_config_imx219_top u_config_imx219(
// 										.i_sys_clk(CLK_5M)    	,    /////48M 
// 										.sys_rstn(vid_rst_n )    ,
// 										.o_sen_rst_n(o_cam_rstn)  	,
										
										// .o_iic_sda_OE(io_cam_sda_OE) ,
										// .i_iic_sda(io_cam_sda_IN)   	,
										// .o_iic_sda(io_cam_sda_OUT)   	,
										// .o_iic_scl(io_cam_scl)    	
										// ); 	

wire scl_padoen_o;
wire sda_padoen_o;


reg [12:0] i2c_rst_cnt = '0;

always @( posedge CLK_5M or negedge w_arstn )
begin
    if( !w_arstn )
       i2c_rst_cnt <= 'd0;
    else 
       i2c_rst_cnt <= i2c_rst_cnt[12] ? i2c_rst_cnt : i2c_rst_cnt + 1'b1;
end
wire i2c_rst_n = i2c_rst_cnt[12];

i2c_master_ctrl_top u2_i2c_master_ctrl_top(
  /*i*/.clk			(CLK_5M		),
  /*i*/.rst_n			(i2c_rst_n		),
  /*i*/.scl_pad_i     (io_cam_scl_IN),//(1'b1),
  /*o*/.scl_pad_o     (io_cam_scl_OUT),
  /*o*/.scl_padoen_o  (scl_padoen_o),
  /*i*/.sda_pad_i     (io_cam_sda_IN),
  /*o*/.sda_pad_o     (io_cam_sda_OUT),
  /*o*/.sda_padoen_o  (sda_padoen_o)
  
  );
assign o_cam_rst_p = ~w_arstn;
assign io_cam_scl_OE = ~scl_padoen_o;
assign io_cam_sda_OE = ~sda_padoen_o;

//=====================================================================================
//frame buffer
//=====================================================================================
wire [7:0] 	ch0_r;
wire [7:0]    ch0_g;
wire [7:0]    ch0_b;
wire ch0_vs;
wire ch0_hs;
wire ch0_de;
// IMX219
  frame_buffer #(
.I_VID_WIDTH         (32),
.O_VID_WIDTH         (16),
.START_ADDR          (32'h0100_0000   ),
.AXI_DATA_WIDTH      ( AXI_DATA_WIDTH	),
.AXI_ADDR_WIDTH      ( AXI_ADDR_WIDTH	),
.WR_FIFO_DEPTH	      ( 1024		),    
.RD_FIFO_DEPTH 	      ( 1024 	),
.BURST_LEN  	       (127),
.FB_NUM	            (3),
.MAX_VID_WIDTH	    (960) ,
.MAX_VID_HIGHT	    (1080)


)checker0(
       .axi_clk		(core_clk 	        ),
       .rst_n			(vid_rst_n   ),

/*i*/.i_clk			(i_mipi_rx_pclk      ),
/*i*/.i_vs			(w_mipi_rx_vs	),
/*i*/.i_de			(w_mipi_rx_de & w_mipi_rx_hs	),
/*i*/.vin 			({w_mipi_rx_data[9:2],w_mipi_rx_data[19:12],w_mipi_rx_data[29:22],w_mipi_rx_data[39:32]}	),
                     
/*i*/.o_clk			(vid_clk_dvi2),//(i_mipi_rx_pclk	),
/*i*/.o_hs    		(ch0_hs		),			
/*i*/.o_vs    		(ch0_vs		),			
/*i*/.o_de    		(ch0_de		),			
/*i*/.vout    		({ch0_g,ch0_b}	),//ch0_r,

/*i*/.H_FRONT_PORCH (HFP/2  		),//
/*i*/.H_SYNC 	 	    (HSP/2	 	),///2
/*i*/.H_VALID 	 	  (MAX_HRES/2     ),//		
/*i*/.H_BACK_PORCH	(HBP/2		),//		
/*i*/.V_FRONT_PORCH (VFP  		),//		
/*i*/.V_SYNC 	 	    (VSP 	 	),//		
/*i*/.V_VALID 	 	  (MAX_VRES     ),//		
/*i*/.V_BACK_PORCH	(VBP		),//		

       .awid			(),      
       .awaddr		(x2_awaddr	),
       .awlen			(x2_awlen	),
       .awsize		(x2_awsize	),
       .awburst		(x2_awburst),
       .awprot    (x2_awprot ),
       .awcache   (x2_awcache),
       .awlock		(x2_awlock	),
       .awvalid		(x2_awvalid),
       .awready		(x2_awready),

       .arid			(),
       .araddr		(x2_araddr	),
       .arlen			(x2_arlen	),
       .arsize		(x2_arsize	),
       .arburst 	(x2_arburst),

       .arprot    (x2_arprot ),
       .arcache   (x2_arcache),
       .arlock 		(x2_arlock	),
       .arvalid		(x2_arvalid),
       .arready		(x2_arready),

       .wdata			(x2_wdata	),
       .wstrb			(x2_wstrb	),
       .wlast			(x2_wlast	),
       .wvalid		(x2_wvalid	),
       .wready		(x2_wready	),


       .rid			  (x2_rid[5:0]	),
       .rdata			(x2_rdata	),
       .rlast			(x2_rlast	),
       .rvalid 		(x2_rvalid	),
       .rready		(x2_rready	),
       .rresp			(x2_rresp	),

       .bid			  (x2_bid[5:0]	),
       .bvalid		(x2_bvalid	),
       .bready	  (x2_bready	)
);


ddr3_top                 u_ddr3_top
(

.axi_clk                (core_clk            ),
.core_clk               (core_clk            ),
.sdram_clk              (sdram_clk           ),  
.rx_cal_clk             (rx_cal_clk          ),
.tx_cal_clk             (tx_cal_clk          ),
.tx_cal_clk_90edge      (tx_cal_clk_90edge   ),
.rstn                   (w_arstn             ),      
.pll_shift              (pll_shift           ),
.pll_shift_sel          (pll_shift_sel       ),
.pll_shift_ena          (pll_shift_ena       ),       
///////////////DDR BUS
.ddr_ck_hi              (ddr_ck_hi           ),
.ddr_ck_lo              (ddr_ck_lo           ),
.ddr_cke                (ddr_cke             ),    
.ddr_reset_n            (ddr_reset_n         ),
.ddr_cs_n               (ddr_cs_n            ),
.ddr_ras_n              (ddr_ras_n           ),
.ddr_cas_n              (ddr_cas_n           ),
.ddr_we_n               (ddr_we_n            ),     
.ddr_addr               (ddr_addr            ),
.ddr_ba                 (ddr_ba              ),

.ddr_dqs_oe             (ddr_dqs_oe          ),
.ddr_dqs_oe_n           (ddr_dqs_oe_n        ),
.ddr_dq_oe              (ddr_dq_oe           ),
.ddr_dqs_in_hi          (ddr_dqs_in_hi       ),
.ddr_dqs_in_lo          (ddr_dqs_in_lo       ),
.ddr_dq_in_hi           (ddr_dq_in_hi        ),
.ddr_dq_in_lo           (ddr_dq_in_lo        ),

.ddr_dqs_out_hi         (ddr_dqs_out_hi      ),
.ddr_dqs_out_lo         (ddr_dqs_out_lo      ),
.ddr_dq_out_hi          (ddr_dq_out_hi       ),
.ddr_dq_out_lo          (ddr_dq_out_lo       ),

.ddr_dm_hi              (ddr_dm_hi           ),
.ddr_dm_lo              (ddr_dm_lo           ),
.ddr_odt                (ddr_odt             ),

// Application interface ports
.app_sr_req                     (1'b0),
.app_ref_req                    (1'b0),
.app_zq_req                     (1'b0),
.app_sr_active                  (app_sr_active),
.app_ref_ack                    (app_ref_ack),
.app_zq_ack                     (app_zq_ack),

// Slave Interface Write Address Ports
.s_axi_awid                     (s_axi_awid        ),
.s_axi_awaddr                   (s_axi_awaddr      ),
.s_axi_awlen                    (s_axi_awlen       ),
.s_axi_awsize                   (s_axi_awsize      ),
.s_axi_awburst                  (s_axi_awburst     ),
.s_axi_awlock                   (s_axi_awlock      ),
.s_axi_awcache                  (s_axi_awcache     ),
.s_axi_awprot                   (s_axi_awprot      ),
.s_axi_awqos                    (4'h0              ),
.s_axi_awvalid                  (s_axi_awvalid     ),
.s_axi_awready                  (s_axi_awready     ),
// Slave Interface Write Data Ports
.s_axi_wdata                    (s_axi_wdata       ),
.s_axi_wstrb                    (s_axi_wstrb       ),
.s_axi_wlast                    (s_axi_wlast       ),
.s_axi_wvalid                   (s_axi_wvalid      ),
.s_axi_wready                   (s_axi_wready      ),
// Slave Interface Write Response Ports
.s_axi_bid                      (s_axi_bid         ),
.s_axi_bresp                    (s_axi_bresp       ),
.s_axi_bvalid                   (s_axi_bvalid      ),
.s_axi_bready                   (s_axi_bready      ),
// Slave Interface Read Address Ports
.s_axi_arid                     (s_axi_arid        ),
.s_axi_araddr                   (s_axi_araddr      ),
.s_axi_arlen                    (s_axi_arlen       ),
.s_axi_arsize                   (s_axi_arsize      ),
.s_axi_arburst                  (s_axi_arburst     ),
.s_axi_arlock                   (s_axi_arlock      ),
.s_axi_arcache                  (s_axi_arcache     ),
.s_axi_arprot                   (s_axi_arprot      ),
.s_axi_arqos                    (4'h0              ),
.s_axi_arvalid                  (s_axi_arvalid     ),
.s_axi_arready                  (s_axi_arready     ),
// Slave Interface Read Data Ports
.s_axi_rid                      (s_axi_rid         ),
.s_axi_rdata                    (s_axi_rdata       ),
.s_axi_rresp                    (s_axi_rresp       ),
.s_axi_rlast                    (s_axi_rlast       ),
.s_axi_rvalid                   (s_axi_rvalid      ),
.s_axi_rready                   (s_axi_rready      ),
//DEBUG       
.wrlvl_dq_check                 (wrlvl_dq_check    ) ,
.rd_level_dqs_check             (rd_level_dqs_check) ,
.init_cur_state                 (init_cur_state    ) ,
.idelay_ld                      (idelay_ld         ) ,
.mpr_rdlvl_dly                  (mpr_rdlvl_dly     ) ,
.cal_done                       (cal_done          ) 
);

//***************************************************************************
// debayer
//***************************************************************************


wire        rgb_vs;
wire        rgb_hs;
wire        rgb_de;
wire        rgb_valid;
wire [47:0] rgb_datax2;
wire [15:0] r_gain;
wire [15:0] g_gain;
wire [15:0] b_gain;

debayer_top_2to1 debayer_top
(
	.in_pclk		  (vid_clk_dvi2),//(i_mipi_rx_pclk ),
	.in_rstn		  (vid_rst_n	),
	
	.raw_vs_i		  (ch0_vs		      ),
	.raw_hs_i		  (ch0_hs		      ),
	.raw_de_i		  (ch0_de		      ),
	.raw_valid_i	(ch0_de	        ),
	.raw_datax4_i	({ch0_b,ch0_g}	),
	.r_gain       (|r_gain? r_gain:255 ),
  .g_gain       (|g_gain? g_gain:255 ),
  .b_gain       (|b_gain? b_gain:255 ),
	.rgb_vs_o		  (rgb_vs         ),
	.rgb_hs_o		  (rgb_hs         ),
	.rgb_de_o		  (rgb_de         ),
	.rgb_valid_o	(rgb_valid      ),
	.rgb_datax2_o (rgb_datax2     )//b,g,r,b,g,r
);
reg rgb_vs_r = 'd0;
always @( posedge hdmi_scale_clk )
begin
  rgb_vs_r <= rgb_vs;
end
assign pos_vs = {rgb_vs_r,rgb_vs} == 2'b01;
reg vid_cnt = 'd0;
reg [7:0] hdmi_tx_rdata ;
reg [7:0] hdmi_tx_gdata ;
reg [7:0] hdmi_tx_bdata ;
reg hdmi_tx_vs;
reg hdmi_tx_hs;
reg hdmi_tx_de;
always @( posedge hdmi_scale_clk or negedge vid_rst_n )
begin
    if( !vid_rst_n )
    begin
        vid_cnt       <= 1'b0;
        hdmi_tx_rdata <= 8'd0;
        hdmi_tx_gdata <= 8'd0;
        hdmi_tx_bdata <= 8'd0;
        hdmi_tx_vs    <= 1'b0;
        hdmi_tx_hs    <= 1'b0;
        hdmi_tx_de    <= 1'b0;
    end
    else
    begin
        hdmi_tx_vs <= rgb_vs;
        hdmi_tx_hs <= rgb_hs;
        hdmi_tx_de <= rgb_de;

        // re-align to the first pixel of each line during blanking
        if( !rgb_de )
        begin
            vid_cnt       <= 1'b0;
            hdmi_tx_rdata <= 8'd0;
            hdmi_tx_gdata <= 8'd0;
            hdmi_tx_bdata <= 8'd0;
        end
        else
        begin
            if( !vid_cnt )
              {hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[23:0];
            else
              {hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[47:24];

            vid_cnt <= ~vid_cnt;
        end
    end
end

//==============================================================================
// scaler + clock crossing + 640x480 output raster   (M3)
//   split stage (hdmi_scale_clk 148.5MHz) -> scaler -> DC_FIFO
//   -> 640x480@60 raster on hdmi_tx_slow_clk (24.75MHz pixel clock)
//==============================================================================
wire [23:0] scaled_rgb   ;
wire        scaled_de    ;
wire        scaled_hs    ;
wire        scaled_vs    ;
wire        scaled_fdone ;
wire [15:0] dbg_underflow;
wire [15:0] dbg_scale_rowmiss;
wire [15:0] dbg_sof_wait;
wire [7:0]  scaled_r = scaled_rgb[7:0];
wire [7:0]  scaled_g = scaled_rgb[15:8];
wire [7:0]  scaled_b = scaled_rgb[23:16];

video_scale_out #(
    .SRC_W          (MAX_HRES     ),
    .SRC_H          (MAX_VRES     ),
    .DST_W          (640          ),
    .DST_H          (480          ),
    .BANKS          (4            ),
    .ADDR_W         (11           ),
    .MAX_SUB        (4            ),
    .H_FP           (16           ),
    .H_SYNC         (96           ),
    .H_BP           (73           ),
    .V_FP           (10           ),
    .V_SYNC         (2            ),
    .V_BP           (7            ),
    .V_DELAY        (1            ),
    .USE_BILINEAR   (0            ),
    .AA_FILTER      (0            ),
    .NEG_SYNC       (1            )
) u_video_scale_out (
    .src_clk        (hdmi_scale_clk           ),
    .src_rst_n      (vid_rst_n               ),
    .src_de         (hdmi_tx_de              ),
    .src_vs         (hdmi_tx_vs              ),
    .src_rgb        ({hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata}),
    .out_clk        (hdmi_tx_slow_clk         ),
    .out_rst_n      (vid_rst_n               ),
    .out_rgb        (scaled_rgb              ),
    .out_de         (scaled_de               ),
    .out_hs         (scaled_hs               ),
    .out_vs         (scaled_vs               ),
    .out_frame_done (scaled_fdone            ),
    .dbg_underflow  (dbg_underflow           ),
    .dbg_row_miss   (dbg_scale_rowmiss       ),
    .dbg_sof_wait   (dbg_sof_wait            )
);

// 128x96 sample/hold -> 640x480 nearest 5x.  The q_out reader runs on the
// same genlocked raster as the original video so the two halves stay aligned.
wire [23:0] block_rgb;
wire        block_de, block_hs, block_vs;
wire [23:0] qout_rgb;
wire [1:0]  style_accel_display_mode;
wire [7:0]  style_accel_mix_strength;
wire        style_accel_hud_visible;
wire [1:0]  style_accel_hud_type;

/* Display-side style interpolation: mixed = original + (styled-original)*a/255.
 * The module also registers the original/styled pixels and timing, so all three
 * display mux sources remain pixel-aligned after its two-clock pipeline. */
wire [23:0] mix_original_rgb;
wire [23:0] mix_styled_rgb;
wire [23:0] mix_rgb;
wire        mix_de, mix_hs, mix_vs;

reg  [1:0] display_mode_meta, display_mode_sync;
reg  [7:0] mix_strength_meta, mix_strength_sync;
reg        hud_visible_meta, hud_visible_sync;
reg  [1:0] hud_type_meta, hud_type_sync;
always @(posedge hdmi_tx_slow_clk or negedge vid_rst_n) begin
    if (!vid_rst_n) begin
        display_mode_meta  <= 2'd0;
        display_mode_sync  <= 2'd0;
        mix_strength_meta  <= 8'd0;
        mix_strength_sync  <= 8'd0;
        hud_visible_meta   <= 1'b0;
        hud_visible_sync   <= 1'b0;
        hud_type_meta      <= 2'd0;
        hud_type_sync      <= 2'd0;
    end else begin
        display_mode_meta  <= style_accel_display_mode;
        display_mode_sync  <= display_mode_meta;
        mix_strength_meta  <= style_accel_mix_strength;
        mix_strength_sync  <= mix_strength_meta;
        hud_visible_meta   <= style_accel_hud_visible;
        hud_visible_sync   <= hud_visible_meta;
        hud_type_meta      <= style_accel_hud_type;
        hud_type_sync      <= hud_type_meta;
    end
end

video_scale_block #(
    .SRC_W(640), .SRC_H(480), .STEP(5)
) u_video_scale_block (
    .clk    (hdmi_tx_slow_clk),
    .rst_n  (vid_rst_n),
    .in_de  (scaled_de),
    .in_hs  (scaled_hs),
    .in_vs  (scaled_vs),
    .in_rgb (qout_rgb),
    .out_de (block_de),
    .out_hs (block_hs),
    .out_vs (block_vs),
    .out_rgb(block_rgb)
);

style_mix_3ch u_style_mix (
    .clk            (hdmi_tx_slow_clk),
    .rst_n          (vid_rst_n),
    .original_rgb   (scaled_rgb),
    .styled_rgb     (block_rgb),
    .strength       (mix_strength_sync),
    .in_de          (block_de),
    .in_hs          (block_hs),
    .in_vs          (block_vs),
    .original_rgb_out(mix_original_rgb),
    .styled_rgb_out (mix_styled_rgb),
    .mixed_rgb_out  (mix_rgb),
    .out_de         (mix_de),
    .out_hs         (mix_hs),
    .out_vs         (mix_vs)
);

/* Direct split-screen comparison: left half original, right half styled. */
reg  [9:0] compare_x;
always @(posedge hdmi_tx_slow_clk or negedge vid_rst_n) begin
    if (!vid_rst_n)
        compare_x <= 10'd0;
    else if (!mix_de)
        compare_x <= 10'd0;
    else if (compare_x != 10'd639)
        compare_x <= compare_x + 10'd1;
end
wire compare_left = (compare_x < 10'd320);

/* 0 = left/right comparison, 1 = full original, 2 = full styled,
 * 3 = full-screen original/style interpolation. */
wire [23:0] compare_rgb = (display_mode_sync == 2'd1) ? mix_original_rgb :
                          (display_mode_sync == 2'd2) ? mix_styled_rgb :
                          (display_mode_sync == 2'd3) ? mix_rgb :
                          (compare_left ? mix_original_rgb : mix_styled_rgb);

//==============================================================================
// MIPI DSI
//==============================================================================
// signal 

reg		[25:0]	r_rst_cnt;

wire	[31:0]	w_axi_rdata;
wire			w_axi_awready;
wire			w_axi_wready;
wire			w_axi_arready;
wire			w_axi_rvalid;
wire			w_axi_bvalid;

wire	[6:0]	w_axi_awaddr;
wire			w_axi_awvalid;
wire	[31:0]	w_axi_wdata;
wire			w_axi_wvalid;
wire			w_axi_bready;
wire	[6:0]	w_axi_araddr;
wire			w_axi_arvalid;
wire			w_axi_rready;

wire			w_confdone;
assign w_confdone = 1'b1;

assign  LCD_POWER 			= 1'b1;
assign	LCD_RST_P	      = ~w_arstn;//~r_rst_cnt[23]; LCD复位先释放，然后再释放MIPI 的复位
assign	mipi_dp_clk_RST		= ~w_arstn;
assign	mipi_dp_data0_RST	= ~w_arstn;
assign	mipi_dp_data1_RST	= ~w_arstn;
assign	mipi_dp_data2_RST	= ~w_arstn;
assign	mipi_dp_data3_RST	= ~w_arstn;
////////////////////////////////////////////////////////////////
always@(posedge i_mipi_clk or  negedge w_arstn )
begin
  if ( !w_arstn ) begin
    r_rst_cnt	<= 'd0;
  end else 		
    r_rst_cnt	<= r_rst_cnt[25] ? r_rst_cnt :r_rst_cnt + 1'b1;
end

wire axi_rst_n = r_rst_cnt[25];

reg [26:0] dly_cnt = 'd0;

always @( posedge vid_clk_dvi2 or negedge w_arstn )
begin
  if( !w_arstn )
    dly_cnt <= 'd0;
  else if( w_confdone )
    dly_cnt <= dly_cnt[26] ? dly_cnt :(dly_cnt + 1'b1);
  else 
    dly_cnt <= 'd0;
end 

assign vid_rst_n = dly_cnt[26];




wire hs;
wire vs;
wire de;
wire [7:0] rgb_r;
wire [7:0] rgb_g;
wire [7:0] rgb_b;
  
  // color_bar_rgb #(
  // .HS_POLORY 		(1'b1		),
  // .VS_POLORY 		(1'b1		),
  // .H_FRONT_PORCH 	(HFP		),///2
  // .H_SYNC 		(HSP		),//
  // .H_VALID 		(MAX_HRES	),//
  // .H_BACK_PORCH 	(HBP		),//
  // .V_FRONT_PORCH 	(VFP		),
  // .V_SYNC 		(VSP		),
  // .V_VALID 		(MAX_VRES	),
  // .V_BACK_PORCH 	(VBP		),
  // .TEST_MODE 		(2'd2)
  // )u_color_bar_rgb1(
  // /*i*/.clk	(vid_clk_dvi2),//(vid_clk),
  // /*i*/.rst_n	(vid_rst_n),
  // /*o*/.hs	(hs),
  // /*o*/.vs	(vs),
  // /*o*/.de	(de),
  // // /*O*/.h_cnt (h_cnt),
  // // /*O*/.v_cnt (v_cnt),
  // /*o*/.rgb_r	(rgb_r),    //像素数据、红色分量
  // /*o*/.rgb_g	(rgb_g),    //像素数据、绿色分量
  // /*o*/.rgb_b (rgb_b)    //像素数据、蓝色分量
  
  // );

//=================================================================================
//hdmi tx ctrl 
//=================================================================================
wire                            video_hs;
wire                            video_vs;
wire                            video_de;
wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;

assign tmds_tx_data0_TX_OE = 1'b1;
assign tmds_tx_data1_TX_OE = 1'b1;
assign tmds_tx_data2_TX_OE = 1'b1;
assign tmds_tx_clk_TX_OE   = 1'b1;

assign tmds_tx_data0_TX_RST = 1'b0;
assign tmds_tx_data1_TX_RST = 1'b0;
assign tmds_tx_data2_TX_RST = 1'b0;
assign tmds_tx_clk_TX_RST   = 1'b0;

// 	  color_bar color_bar_m0(
// 	.clk(hdmi_tx_slow_clk),
// 	.rst(~vid_rst_n),
// 	.hs(video_hs),
// 	.vs(video_vs),
// 	.de(video_de),
// 	.rgb_r(video_r),
// 	.rgb_g(video_g),
// 	.rgb_b(video_b)
// );

wire [9:0] tmds_data0;
wire [9:0] tmds_data1;
wire [9:0] tmds_data2;
wire [9:0] tmds_clk ;

wire [7:0] con_rdata ;
wire [7:0] con_gdata ;
wire [7:0] con_bdata ;
wire con_de;
wire con_hs;
wire con_vs;
wire con_sel;

wire [7:0] BRIGHT_SIG    ;
wire CONTRAST_SIG_G;
wire CONTRAST_SIG_R;
wire [7:0] CONTRAST_G    ;
wire CONTRAST_SIG_B;
wire [7:0] BRIGHT        ;
wire [7:0] CONTRAST_R    ;


wire CONTRAST_B    ;



//==============================================================================
// gamma correction 已移除 (2026-10-14): scaler 输出直接进 OSD / DVI。
//   . 省掉 3 块 RAM (原 gamma 的 3 个 BRAM ROM) 与一级延迟
//   . R/B 映射与原旁路完全一致 => 画面不变
//   . 原 gamma_sel=1 会把 R/B 换回来 (即开 gamma 就变色的陷阱), 该通路现已不存在
//==============================================================================
//==============================================================================
// real-time frame-rate OSD overlay (drawn last, on the final pixel stream)
//   CLK_HZ must equal the pixel clock of this raster.
//     current build  (1024x600 -> 640x480 @58.9Hz) : vid_clk_dvi2 = 24.75MHz
//     1080p build    (1080p    -> 1024x600 @60Hz ) : vid_clk_dvi2 = 74.25MHz
//==============================================================================

wire [7:0] osd_r_pre  = compare_rgb[23:16]; // left=original, right=styled
wire [7:0] osd_g_pre  = compare_rgb[15:8];
wire [7:0] osd_b_pre  = compare_rgb[7:0];
wire       osd_de_pre = mix_de;
wire       osd_hs_pre = mix_hs;
wire       osd_vs_pre = mix_vs;

wire [7:0] fps_r, fps_g, fps_b;
wire       fps_de, fps_hs, fps_vs;
wire [7:0] osd_r, osd_g, osd_b;
wire       osd_de, osd_hs, osd_vs;

/* The OSD follows the selected display source.  The frame-buffer output and
 * scaled_fdone run at the free-running 60 Hz read raster, so they cannot show
 * a 30 fps camera: the same camera frame is read twice.  Carry the camera
 * VSYNC edge across as a toggle and count that in full-original mode. */
reg        camera_vs_d;
reg        camera_frame_toggle;
always @(posedge i_mipi_rx_pclk or negedge w_mipi_rx_pclk_arstn) begin
    if (!w_mipi_rx_pclk_arstn) begin
        camera_vs_d         <= 1'b0;
        camera_frame_toggle <= 1'b0;
    end else begin
        camera_vs_d <= w_mipi_rx_vs;
        if (w_mipi_rx_vs && !camera_vs_d)
            camera_frame_toggle <= ~camera_frame_toggle;
    end
end

reg        camera_frame_meta, camera_frame_sync, camera_frame_sync_d;
wire       camera_frame_pulse;
always @(posedge hdmi_tx_slow_clk or negedge vid_rst_n) begin
    if (!vid_rst_n) begin
        camera_frame_meta   <= 1'b0;
        camera_frame_sync   <= 1'b0;
        camera_frame_sync_d <= 1'b0;
    end else begin
        camera_frame_meta   <= camera_frame_toggle;
        camera_frame_sync   <= camera_frame_meta;
        camera_frame_sync_d <= camera_frame_sync;
    end
end
assign camera_frame_pulse = camera_frame_sync ^ camera_frame_sync_d;

wire       osd_frame_is_original = (display_mode_sync == 2'd1);
wire       osd_frame_pulse = osd_frame_is_original ? camera_frame_pulse
                                                   : processed_frame_pulse;

fps_overlay #(
	.CLK_HZ   (24_750_000),
	.BOX_X    (16),
	.BOX_Y    (16),
	.PAD      (6),
	.SCALE    (2),
	.DRAW_BOX (0),
	.TEXT_COL (24'hFFFFFF),
	.BOX_COL  (24'h202020)
) u_fps_overlay (
	.clk         (hdmi_tx_slow_clk),
	.rst_n       (vid_rst_n),
	.de_in       (osd_de_pre),
	.hs_in       (osd_hs_pre),
	.vs_in       (osd_vs_pre),
	.frame_pulse (osd_frame_pulse),
	.show        (display_mode_sync != 2'd3),
	.r_in        (osd_r_pre),
	.g_in        (osd_g_pre),
	.b_in        (osd_b_pre),
	.de_out      (fps_de),
	.hs_out      (fps_hs),
	.vs_out      (fps_vs),
	.r_out       (fps_r),
	.g_out       (fps_g),
	.b_out       (fps_b),
	.fps_x10_dbg ()
);

style_hud_overlay u_style_hud (
    .clk       (hdmi_tx_slow_clk),
    .rst_n     (vid_rst_n),
    .de_in     (fps_de),
    .hs_in     (fps_hs),
    .vs_in     (fps_vs),
    .rgb_in    ({fps_r, fps_g, fps_b}),
    .visible   (hud_visible_sync),
    .hud_type  (hud_type_sync),
    .strength  (mix_strength_sync),
    .de_out    (osd_de),
    .hs_out    (osd_hs),
    .vs_out    (osd_vs),
    .rgb_out   ({osd_r, osd_g, osd_b})
);

dvi_encoder dvi_encoder_m0
(
	.pixelclk      		(hdmi_tx_slow_clk          ),// system clock
	.rst_p         		(~vid_rst_n      ),// reset
	.i_bdata      		(osd_b 	),//(hdmi_tx_rdata ),//(video_b            ),//(bdata_in	),   //
	.i_gdata     		(osd_g  ),//(hdmi_tx_gdata ),//(video_g            ),//(gdata_in	),   //
	.i_rdata       		(osd_r 	),//(hdmi_tx_bdata ),//(video_r            ),//(rdata_in	),   //
  .i_de            	(osd_de ),//(hdmi_tx_de    ),//(video_de           ),//(rx_de		  ),   //
	.i_hs         		(osd_hs ),//(video_hs           ),//(rx_hsync	),   //
	.i_vs         		(osd_vs ),//(video_vs           ),//(rx_vsync	),   //
	
  .video_format     (video_format), //// 00 = RGB, 01 = YCbCr 4:2:2, 10 = YCbCr 4:4:4
  .video_VIC        (0),
	.audio_L			    (audio_L),
  .audio_R			    (audio_R),
  .audio_valid		  (audio_valid),
  .audio_N                (6144),     //(20'h01880),//     
  .audio_CTS              (148500),      //(20'h28488),//      
  .audio_sample_frequency (audio_samp_freq),    //(3'b000),// 
  .audio_word_length      ({audio_samp_word_len,audio_max_word_length}),//(4'b1011),//

	.tmds_data0    		(tmds_data0),
  .tmds_data1    		(tmds_data1),
  .tmds_data2    		(tmds_data2),
  .tmds_clk      	  (tmds_clk  )
);
assign tmds_tx_clk_TX_DATA   = ~tmds_clk;
assign tmds_tx_data0_TX_DATA = ~tmds_data0;
assign tmds_tx_data1_TX_DATA = ~tmds_data1;
assign tmds_tx_data2_TX_DATA = ~tmds_data2;

// JTAG(jtag_inst1) 让给 SoC 的 jtagCtrl；原 debug_edb_top(vio0) 不再例化。
// r/g/b gain 用原 vio0 的初值固定下来（rgb_gain 内部对 0 有 fallback 到 255 的行为，不能直接置 0）。
assign r_gain = 16'h0118;
assign g_gain = 16'h00ff;
assign b_gain = 16'h015e;

//==============================================================================
// 2026-10-14 合并：SoC + 风格迁移加速器 + 视频帧缓存   三路 AXI master 共享 DDR3
//   axi_xbar (efx_axi_interconnect, S_PORTS=3 / M_PORTS=1) 仲裁：
//     slave0 = Sapphire SoC 的 io_ddrA      (ID 由 SoC 内部决定)
//     slave1 = style_accel_top 的 m_axi     (ID 固定 0x40)
//     slave2 = frame_buffer 的 AXI master   (ID 固定 0x20)
//   master0 -> ddr3_top 的 s_axi_*         (AXI_ID_WIDTH = 8)
//   DDR 地址划分：
//     0x0000_1000 - 0x0002_0000  SoC 固件 + 栈
//     0x0100_0000 -              视频帧缓存 (3 bank x 4.15 MB)
//     0x0400_0000 - 0x0510_0000  模型 blob / run cfg / arena
//   JTAG：整个 jtag_inst1 让给 SoC 的 jtagCtrl_* (RISC-V 调试 + load_image)；
//        原来的 debug_edb_top(vio0) 不再例化，r/g/b gain 改为常量(取原 vio0 的初值)。
//==============================================================================

// ---- slave 0: SoC io_ddrA ----
wire [31:0]  x0_awaddr   ; wire [7:0]  x0_awlen   ; wire [2:0]  x0_awsize  ; wire [1:0]  x0_awburst ;
wire [0:0]   x0_awlock   ; wire [7:0]  x0_awid    ; wire        x0_awvalid ; wire        x0_awready ;
wire [127:0] x0_wdata    ; wire [15:0] x0_wstrb   ; wire        x0_wlast   ; wire        x0_wvalid  ; wire x0_wready ;
wire [7:0]   x0_bid      ; wire [1:0]  x0_bresp   ; wire        x0_bvalid  ; wire        x0_bready  ;
wire [31:0]  x0_araddr   ; wire [7:0]  x0_arlen   ; wire [2:0]  x0_arsize  ; wire [1:0]  x0_arburst ;
wire [0:0]   x0_arlock   ; wire [7:0]  x0_arid    ; wire        x0_arvalid ; wire        x0_arready ;
wire [127:0] x0_rdata    ; wire [7:0]  x0_rid     ; wire [1:0]  x0_rresp   ; wire        x0_rlast   ; wire x0_rvalid ; wire x0_rready ;

// ---- slave 1: 加速器 m_axi (无 ID 口 -> 顶层固定 0x40) ----
wire [31:0]  accel_axi_awaddr  ; wire [7:0]  accel_axi_awlen  ; wire [2:0] accel_axi_awsize ; wire [1:0] accel_axi_awburst ;
wire         accel_axi_awvalid ; wire        accel_axi_awready;
wire [127:0] accel_axi_wdata   ; wire [15:0] accel_axi_wstrb  ; wire       accel_axi_wlast    ; wire       accel_axi_wvalid ; wire accel_axi_wready ;
wire [1:0]   accel_axi_bresp   ; wire        accel_axi_bvalid ; wire       accel_axi_bready ;
wire [31:0]  accel_axi_araddr  ; wire [7:0]  accel_axi_arlen  ; wire [2:0] accel_axi_arsize ; wire [1:0] accel_axi_arburst ;
wire         accel_axi_arvalid ; wire        accel_axi_arready;
wire [127:0] accel_axi_rdata   ; wire [1:0]  accel_axi_rresp  ; wire       accel_axi_rlast    ; wire       accel_axi_rvalid ; wire accel_axi_rready ;
wire [7:0]   x1_awid           ; wire [1:0]  x1_awburst        ; wire [0:0] x1_awlock ;
wire [7:0]   x1_arid           ; wire [1:0]  x1_arburst        ; wire [0:0] x1_arlock ;
wire [7:0]   x1_bid            ; wire [7:0]  x1_rid            ;
wire         x1_awready        ; wire        x1_wready         ; wire       x1_arready ;

// ---- slave 2: 视频帧缓存 (ID 固定 0x20) ----
wire [31:0]  x2_awaddr   ; wire [7:0]  x2_awlen   ; wire [2:0]  x2_awsize  ; wire [1:0]  x2_awburst ; wire [0:0] x2_awlock ;
wire [7:0]   x2_awid     ; wire        x2_awvalid ; wire        x2_awready ;
wire [127:0] x2_wdata    ; wire [15:0] x2_wstrb   ; wire        x2_wlast   ; wire        x2_wvalid  ; wire x2_wready ;
wire [7:0]   x2_bid      ; wire [1:0]  x2_bresp   ; wire        x2_bvalid  ; wire        x2_bready  ;
wire [31:0]  x2_araddr   ; wire [7:0]  x2_arlen   ; wire [2:0]  x2_arsize  ; wire [1:0]  x2_arburst ; wire [0:0] x2_arlock ;
wire [7:0]   x2_arid     ; wire        x2_arvalid ; wire        x2_arready ;
wire [127:0] x2_rdata    ; wire [7:0]  x2_rid     ; wire [1:0]  x2_rresp   ; wire        x2_rlast   ; wire x2_rvalid ; wire x2_rready ;

// ---- 加速器控制/APB ----
wire [831:0] style_accel_cfg        ;
wire         style_accel_start      ;
wire         style_accel_abort      ;
wire         style_accel_busy       ;
wire         style_accel_done       ;
wire         style_accel_error      ;
wire [31:0]  style_accel_error_code ;
wire [63:0]  style_accel_cycle_count;
wire [31:0]  style_accel_dbg        ;
wire         style_accel_irq        ;
wire         style_accel_ddr_reset  ;
wire [11:0]  apb_paddr     ;
wire         apb_psel      ;
wire         apb_penable   ;
wire         apb_pwrite    ;
wire [31:0]  apb_pwdata    ;
wire [31:0]  apb_prdata    ;
wire         apb_pready    ;
wire         apb_pslverror ;

// ---- video q_out static bring-up reader (borrows x1 while accel idle) ----
wire [31:0] qin_frame_count;
wire        qin_frame_done;
wire        qout_bank_sel;

/* Processed-frame event for the OSD: the firmware toggles qout_bank_sel once
 * per completed 19-pass frame.  Synchronize that core-domain level into the
 * HDMI pixel clock domain and turn either edge into a one-clock pulse. */
reg         qout_bank_meta;
reg         qout_bank_sync;
reg         qout_bank_sync_d;
wire        processed_frame_pulse;
always @(posedge hdmi_tx_slow_clk or negedge vid_rst_n) begin
    if (!vid_rst_n) begin
        qout_bank_meta   <= 1'b0;
        qout_bank_sync   <= 1'b0;
        qout_bank_sync_d <= 1'b0;
    end else begin
        qout_bank_meta   <= qout_bank_sel;
        qout_bank_sync   <= qout_bank_meta;
        qout_bank_sync_d <= qout_bank_sync;
    end
end
assign processed_frame_pulse = qout_bank_sync ^ qout_bank_sync_d;
wire        qout_busy;
wire [31:0] qout_diag_count;
wire [31:0] video_diag2;
reg         qin_overlap_seen;
reg         accel_display_collision_seen;
wire [31:0] qout_araddr;
wire [7:0]  qout_arlen;
wire [2:0]  qout_arsize;
wire [1:0]  qout_arburst;
wire        qout_arvalid, qout_arready, qout_rready, qout_rvalid;
wire [31:0] x1_araddr;
wire [7:0]  x1_arlen;
wire [2:0]  x1_arsize;
wire        x1_arvalid;
wire [127:0] x1_rdata;
wire        x1_rvalid, x1_rlast, x1_rready;

video_qout_reader #(
    .BASE_ADDR    (32'h04AC8800),
    .BASE_ADDR_ALT(32'h04B20000),
    .SRC_W        (640),
    .SRC_H        (480),
    .DST_W        (128),
    .DST_H        (96)
) u_video_qout_reader (
    .core_clk(core_clk), .core_rst_n(w_arstn),
    .vid_clk(hdmi_tx_slow_clk), .vid_rst_n(vid_rst_n),
    .en(1'b1), .bank_sel(qout_bank_sel),
    .vid_de(scaled_de), .vid_hs(scaled_hs), .vid_vs(scaled_vs),
    .m_axi_araddr(qout_araddr), .m_axi_arlen(qout_arlen),
    .m_axi_arsize(qout_arsize), .m_axi_arburst(qout_arburst),
    .m_axi_arvalid(qout_arvalid), .m_axi_arready(qout_arready),
    .m_axi_rdata(x1_rdata), .m_axi_rlast(x1_rlast),
    .m_axi_rvalid(qout_rvalid), .m_axi_rready(qout_rready),
    .out_rgb(qout_rgb), .busy(qout_busy), .diag_count(qout_diag_count)
);

/* The display reader and accelerator share the x1 AXI master.  They use
 * different AXI IDs and are switched only at burst boundaries, with at most
 * one outstanding read burst on the shared port.  This lets the q_out reader
 * refresh the previous frame while a 19-pass frame is computing; limiting the
 * display to accelerator-idle periods would freeze a single line on HDMI. */
reg  accel_rd_outstanding;
reg  qout_rd_outstanding;
/* Both readers use the x1 port's historical fixed AXI ID 0x40.  Only one
 * read burst may be outstanding at a time, and responses are routed by the
 * latched owner rather than by a dynamically changing ID. */
wire qout_ar_sel = qout_rd_outstanding ||
                   (!accel_rd_outstanding && qout_arvalid);

assign x1_araddr  = qout_ar_sel ? qout_araddr  : accel_axi_araddr;
assign x1_arlen   = qout_ar_sel ? qout_arlen   : accel_axi_arlen;
assign x1_arsize  = qout_ar_sel ? qout_arsize  : accel_axi_arsize;
assign x1_arburst = qout_ar_sel ? qout_arburst : accel_axi_arburst;
assign x1_arvalid = qout_ar_sel ? qout_arvalid : accel_axi_arvalid;
assign qout_arready = qout_ar_sel ? x1_arready : 1'b0;
assign accel_axi_arready = qout_ar_sel ? 1'b0 : x1_arready;

assign qout_rvalid       = qout_rd_outstanding  ? x1_rvalid : 1'b0;
assign accel_axi_rvalid  = accel_rd_outstanding ? x1_rvalid : 1'b0;
assign accel_axi_rdata   = x1_rdata;
assign accel_axi_rlast   = accel_rd_outstanding ? x1_rlast  : 1'b0;
assign x1_rready         = qout_rd_outstanding  ? qout_rready :
                           accel_rd_outstanding ? accel_axi_rready : 1'b0;

always @(posedge core_clk or negedge w_arstn) begin
    if (!w_arstn) begin
        accel_rd_outstanding <= 1'b0;
        qout_rd_outstanding  <= 1'b0;
    end else begin
        if (x1_arvalid && x1_arready) begin
            if (qout_ar_sel)
                qout_rd_outstanding <= 1'b1;
            else
                accel_rd_outstanding <= 1'b1;
        end
        if (x1_rvalid && x1_rready && x1_rlast) begin
            if (qout_rd_outstanding)
                qout_rd_outstanding <= 1'b0;
            else if (accel_rd_outstanding)
                accel_rd_outstanding <= 1'b0;
        end
    end
end

// ---- camera -> q_in writer (borrows x1 write channels while accel idle) ----
wire        qin_owner;
wire        qin_busy;
wire [31:0] qin_awaddr;
wire [7:0]  qin_awlen;
wire [2:0]  qin_awsize;
wire [1:0]  qin_awburst;
wire        qin_awvalid, qin_awready;
wire [127:0] qin_wdata;
wire [15:0] qin_wstrb;
wire        qin_wlast, qin_wvalid, qin_wready;
wire [1:0]  qin_bresp;
wire        qin_bvalid, qin_bready;
wire [31:0] x1_awaddr;
wire [7:0]  x1_awlen;
wire [2:0]  x1_awsize;
wire        x1_awvalid;
wire [127:0] x1_wdata;
wire [15:0] x1_wstrb;
wire        x1_wlast, x1_wvalid;
wire [1:0]  x1_bresp;
wire        x1_bvalid, x1_bready;

always @(posedge core_clk or negedge w_arstn) begin
    if (!w_arstn) begin
        qin_overlap_seen <= 1'b0;
        accel_display_collision_seen <= 1'b0;
    end else begin
        if (style_accel_busy && qin_busy)
            qin_overlap_seen <= 1'b1;
        if (style_accel_busy &&
            ((style_accel_cfg[703:672] == 32'h04AC8800 && !qout_bank_sel) ||
             (style_accel_cfg[703:672] == 32'h04B20000 &&  qout_bank_sel)))
            accel_display_collision_seen <= 1'b1;
    end
end
assign video_diag2 = {30'd0, accel_display_collision_seen, qin_overlap_seen};

video_qin_writer #(
    .QIN_ADDR(32'h04800000),
    .SRC_W  (640),
    .SRC_H  (480),
    .DST_W  (128),
    .DST_H  (96)
) u_video_qin_writer (
    .vid_clk(hdmi_tx_slow_clk), .vid_rst_n(vid_rst_n),
    .core_clk(core_clk), .core_rst_n(w_arstn),
    .en(~style_accel_busy),
    .vid_de(scaled_de), .vid_vs(scaled_vs), .vid_rgb(scaled_rgb),
    .m_axi_awaddr(qin_awaddr), .m_axi_awlen(qin_awlen),
    .m_axi_awsize(qin_awsize), .m_axi_awburst(qin_awburst),
    .m_axi_awvalid(qin_awvalid), .m_axi_awready(qin_awready),
    .m_axi_wdata(qin_wdata), .m_axi_wstrb(qin_wstrb),
    .m_axi_wlast(qin_wlast), .m_axi_wvalid(qin_wvalid), .m_axi_wready(qin_wready),
    .m_axi_bresp(qin_bresp), .m_axi_bvalid(qin_bvalid), .m_axi_bready(qin_bready),
    .busy(qin_busy), .frame_done(qin_frame_done),
    .frame_count(qin_frame_count)
);

assign qin_owner = (~style_accel_busy) || qin_busy;
assign x1_awvalid = qin_owner ? qin_awvalid : accel_axi_awvalid;
assign x1_awaddr  = qin_owner ? qin_awaddr  : accel_axi_awaddr;
assign x1_awlen   = qin_owner ? qin_awlen   : accel_axi_awlen;
assign x1_awsize  = qin_owner ? qin_awsize  : accel_axi_awsize;
assign x1_awburst = qin_owner ? qin_awburst : accel_axi_awburst;
assign x1_wvalid  = qin_owner ? qin_wvalid  : accel_axi_wvalid;
assign x1_wdata   = qin_owner ? qin_wdata   : accel_axi_wdata;
assign x1_wstrb   = qin_owner ? qin_wstrb   : accel_axi_wstrb;
assign x1_wlast   = qin_owner ? qin_wlast   : accel_axi_wlast;
assign x1_bready  = qin_owner ? qin_bready  : accel_axi_bready;
assign accel_axi_awready = qin_owner ? 1'b0 : x1_awready;
assign qin_awready = qin_owner ? x1_awready : 1'b0;
assign accel_axi_wready  = qin_owner ? 1'b0 : x1_wready;
assign qin_wready = qin_owner ? x1_wready : 1'b0;
assign accel_axi_bvalid = qin_owner ? 1'b0 : x1_bvalid;
assign qin_bvalid = qin_owner ? x1_bvalid : 1'b0;
assign accel_axi_bresp  = x1_bresp;
assign qin_bresp        = x1_bresp;



// 加速器/帧缓存的 AXI ID（xbar 按 ID 回路由，三个 master 必须互不相同）
assign x1_awid = 8'h40;
assign x1_arid = 8'h40;
assign x2_awid = 8'h20;  assign x2_arid = 8'h20;
// 加速器不需要 lock/burst 之外的字段
assign x1_awlock = 1'b0;
assign x1_arlock = 1'b0;

axi_xbar u_axi_xbar (
    .clk        ( core_clk ),
    .rst_n      ( w_arstn  ),
    .s_axi_awvalid ( { x2_awvalid , x1_awvalid, x0_awvalid } ),
    .s_axi_awaddr  ( { x2_awaddr  , x1_awaddr, x0_awaddr } ),
    .s_axi_awlock  ( { {1'b0,x2_awlock}, {1'b0,x1_awlock}, {1'b0,x0_awlock} } ),
    .s_axi_awburst ( { x2_awburst , x1_awburst  , x0_awburst } ),
    .s_axi_awsize  ( { x2_awsize  , x1_awsize, x0_awsize } ),
    .s_axi_awlen   ( { x2_awlen   , x1_awlen , x0_awlen  } ),
    .s_axi_awid    ( { x2_awid    , x1_awid     , x0_awid    } ),
    .s_axi_awprot  ( { 3'b0       , 3'b0        , 3'b0       } ),
    .s_axi_awcache ( { 4'b0       , 4'b0        , 4'b0       } ),
    .s_axi_awqos   ( { 4'b0       , 4'b0        , 4'b0       } ),
    .s_axi_awuser  ( { 1'b0       , 1'b0        , 1'b0       } ),
    .s_axi_awready ( { x2_awready , x1_awready  , x0_awready } ),
    .s_axi_wvalid  ( { x2_wvalid  , x1_wvalid , x0_wvalid } ),
    .s_axi_wdata   ( { x2_wdata   , x1_wdata  , x0_wdata  } ),
    .s_axi_wstrb   ( { x2_wstrb   , x1_wstrb  , x0_wstrb  } ),
    .s_axi_wlast   ( { x2_wlast   , x1_wlast  , x0_wlast  } ),
    .s_axi_wid     ( { 8'h20      , 8'h40       , 8'h00      } ),
    .s_axi_wuser   ( { 1'b0       , 1'b0        , 1'b0       } ),
    .s_axi_wready  ( { x2_wready  , x1_wready   , x0_wready  } ),
    .s_axi_bvalid  ( { x2_bvalid  , x1_bvalid , x0_bvalid } ),
    .s_axi_bresp   ( { x2_bresp   , x1_bresp  , x0_bresp  } ),
    .s_axi_bid     ( { x2_bid     , x1_bid      , x0_bid     } ),
    .s_axi_buser   ( ),
    .s_axi_bready  ( { x2_bready  , x1_bready , x0_bready } ),
    .s_axi_arvalid ( { x2_arvalid , x1_arvalid, x0_arvalid } ),
    .s_axi_araddr  ( { x2_araddr  , x1_araddr, x0_araddr } ),
    .s_axi_arlock  ( { {1'b0,x2_arlock}, {1'b0,x1_arlock}, {1'b0,x0_arlock} } ),
    .s_axi_arburst ( { x2_arburst , x1_arburst  , x0_arburst } ),
    .s_axi_arsize  ( { x2_arsize  , x1_arsize, x0_arsize } ),
    .s_axi_arlen   ( { x2_arlen   , x1_arlen , x0_arlen  } ),
    .s_axi_arid    ( { x2_arid    , x1_arid     , x0_arid    } ),
    .s_axi_arprot  ( { 3'b0       , 3'b0        , 3'b0       } ),
    .s_axi_arcache ( { 4'b0       , 4'b0        , 4'b0       } ),
    .s_axi_arqos   ( { 4'b0       , 4'b0        , 4'b0       } ),
    .s_axi_aruser  ( { 1'b0       , 1'b0        , 1'b0       } ),
    .s_axi_arready ( { x2_arready , x1_arready  , x0_arready } ),
    .s_axi_rvalid  ( { x2_rvalid  , x1_rvalid , x0_rvalid } ),
    .s_axi_rdata   ( { x2_rdata   , x1_rdata  , x0_rdata  } ),
    .s_axi_rresp   ( { x2_rresp   , accel_axi_rresp  , x0_rresp  } ),
    .s_axi_rid     ( { x2_rid     , x1_rid      , x0_rid     } ),
    .s_axi_ruser   ( ),
    .s_axi_rlast   ( { x2_rlast   , x1_rlast  , x0_rlast  } ),
    .s_axi_rready  ( { x2_rready  , x1_rready , x0_rready } ),
    // master0 -> ddr3_top 的 s_axi_*（位宽与控制器一致：8/32/128）
    .m_axi_awvalid ( s_axi_awvalid ),
    .m_axi_awaddr  ( s_axi_awaddr  ),
    .m_axi_awlen   ( s_axi_awlen   ),
    .m_axi_awsize  ( s_axi_awsize  ),
    .m_axi_awburst ( s_axi_awburst ),
    .m_axi_awlock  (               ),
    .m_axi_awid    ( s_axi_awid    ),
    .m_axi_awprot  ( s_axi_awprot  ),
    .m_axi_awcache ( s_axi_awcache ),
    .m_axi_awqos   (               ),
    .m_axi_awuser  (               ),
    .m_axi_awregion(               ),
    .m_axi_awready ( s_axi_awready ),
    .m_axi_wvalid  ( s_axi_wvalid  ),
    .m_axi_wdata   ( s_axi_wdata   ),
    .m_axi_wstrb   ( s_axi_wstrb   ),
    .m_axi_wlast   ( s_axi_wlast   ),
    .m_axi_wuser   (               ),
    .m_axi_wready  ( s_axi_wready  ),
    .m_axi_bvalid  ( s_axi_bvalid  ),
    .m_axi_bresp   ( s_axi_bresp   ),
    .m_axi_bid     ( s_axi_bid     ),
    .m_axi_buser   ( 1'b0          ),
    .m_axi_bready  ( s_axi_bready  ),
    .m_axi_arvalid ( s_axi_arvalid ),
    .m_axi_araddr  ( s_axi_araddr  ),
    .m_axi_arlen   ( s_axi_arlen   ),
    .m_axi_arsize  ( s_axi_arsize  ),
    .m_axi_arburst ( s_axi_arburst ),
    .m_axi_arlock  (               ),
    .m_axi_arid    ( s_axi_arid    ),
    .m_axi_arprot  ( s_axi_arprot  ),
    .m_axi_arcache ( s_axi_arcache ),
    .m_axi_arqos   (               ),
    .m_axi_aruser  (               ),
    .m_axi_arregion(               ),
    .m_axi_arready ( s_axi_arready ),
    .m_axi_rvalid  ( s_axi_rvalid  ),
    .m_axi_rdata   ( s_axi_rdata   ),
    .m_axi_rresp   ( s_axi_rresp   ),
    .m_axi_rid     ( s_axi_rid     ),
    .m_axi_ruser   ( 1'b0          ),
    .m_axi_rlast   ( s_axi_rlast   ),
    .m_axi_rready  ( s_axi_rready  )
);

//==============================================================================
// Sapphire SoC (RISC-V) —— 只用到 io_ddrA（->xbar）、APB 从机（->加速器寄存器）、
// UART（调试打印）、jtagCtrl（RISC-V 调试/固件灌入）。SPI/I2C/GPIO/DDRMasters 拉掉。
//==============================================================================
my_soc u_my_soc (
    .io_asyncReset           ( ~w_arstn              ),
    .io_systemClk            ( core_clk              ),
    .io_memoryClk            ( core_clk              ),
    .io_memoryReset          (                       ),
    .io_systemReset          (                       ),
    .system_uart_0_io_txd    ( system_uart_0_io_txd  ),
    .system_uart_0_io_rxd    ( system_uart_0_io_rxd  ),
    .io_ddrA_aw_payload_addr ( x0_awaddr    ),
    .io_ddrA_aw_payload_len  ( x0_awlen     ),
    .io_ddrA_aw_payload_size ( x0_awsize    ),
    .io_ddrA_aw_payload_burst( x0_awburst   ),
    .io_ddrA_aw_payload_lock ( x0_awlock    ),
    .io_ddrA_aw_payload_id   ( x0_awid      ),
    .io_ddrA_aw_payload_prot (               ),
    .io_ddrA_aw_payload_cache(               ),
    .io_ddrA_aw_payload_qos  (               ),
    .io_ddrA_aw_payload_region(              ),
    .io_ddrA_aw_valid        ( x0_awvalid   ),
    .io_ddrA_aw_ready        ( x0_awready   ),
    .io_ddrA_w_payload_data  ( x0_wdata     ),
    .io_ddrA_w_payload_strb  ( x0_wstrb     ),
    .io_ddrA_w_payload_last  ( x0_wlast     ),
    .io_ddrA_w_valid         ( x0_wvalid    ),
    .io_ddrA_w_ready         ( x0_wready    ),
    .io_ddrA_b_payload_id    ( x0_bid       ),
    .io_ddrA_b_payload_resp  ( x0_bresp     ),
    .io_ddrA_b_valid         ( x0_bvalid    ),
    .io_ddrA_b_ready         ( x0_bready    ),
    .io_ddrA_ar_payload_addr ( x0_araddr    ),
    .io_ddrA_ar_payload_len  ( x0_arlen     ),
    .io_ddrA_ar_payload_size ( x0_arsize    ),
    .io_ddrA_ar_payload_burst( x0_arburst   ),
    .io_ddrA_ar_payload_lock ( x0_arlock    ),
    .io_ddrA_ar_payload_id   ( x0_arid      ),
    .io_ddrA_ar_payload_prot (               ),
    .io_ddrA_ar_payload_cache(               ),
    .io_ddrA_ar_payload_qos  (               ),
    .io_ddrA_ar_payload_region(              ),
    .io_ddrA_ar_valid        ( x0_arvalid   ),
    .io_ddrA_ar_ready        ( x0_arready   ),
    .io_ddrA_r_payload_data  ( x0_rdata     ),
    .io_ddrA_r_payload_id    ( x0_rid       ),
    .io_ddrA_r_payload_resp  ( x0_rresp     ),
    .io_ddrA_r_payload_last  ( x0_rlast     ),
    .io_ddrA_r_valid         ( x0_rvalid    ),
    .io_ddrA_r_ready         ( x0_rready    ),
    .io_apbSlave_0_PADDR     ( apb_paddr    ),
    .io_apbSlave_0_PSEL      ( apb_psel     ),
    .io_apbSlave_0_PENABLE   ( apb_penable  ),
    .io_apbSlave_0_PWRITE    ( apb_pwrite   ),
    .io_apbSlave_0_PWDATA    ( apb_pwdata   ),
    .io_apbSlave_0_PRDATA    ( apb_prdata   ),
    .io_apbSlave_0_PREADY    ( apb_pready   ),
    .io_apbSlave_0_PSLVERROR ( apb_pslverror),
    .userInterruptA          ( style_accel_irq ),
    .system_spi_0_io_sclk_write       ( system_spi_0_io_sclk_write       ),
    .system_spi_0_io_data_0_writeEnable( system_spi_0_io_data_0_OE       ),
    .system_spi_0_io_data_0_read      ( system_spi_0_io_data_0_IN       ),
    .system_spi_0_io_data_0_write     ( system_spi_0_io_data_0_OUT      ),
    .system_spi_0_io_data_1_writeEnable( system_spi_0_io_data_1_OE       ),
    .system_spi_0_io_data_1_read      ( system_spi_0_io_data_1_IN       ),
    .system_spi_0_io_data_1_write     ( system_spi_0_io_data_1_OUT      ),
    .system_spi_0_io_data_2_writeEnable(                                ),
    .system_spi_0_io_data_2_read      ( 1'b1                           ),
    .system_spi_0_io_data_2_write     (                                ),
    .system_spi_0_io_data_3_writeEnable(                                ),
    .system_spi_0_io_data_3_read      ( 1'b1                           ),
    .system_spi_0_io_data_3_write     (                                ),
    .system_spi_0_io_ss               ( system_spi_0_io_ss               ),
    .jtagCtrl_tck            ( jtag_inst1_TCK     ),
    .jtagCtrl_tdi            ( jtag_inst1_TDI     ),
    .jtagCtrl_tdo            ( jtag_inst1_TDO     ),
    .jtagCtrl_enable         ( jtag_inst1_SEL     ),
    .jtagCtrl_capture        ( jtag_inst1_CAPTURE ),
    .jtagCtrl_shift          ( jtag_inst1_SHIFT   ),
    .jtagCtrl_update         ( jtag_inst1_UPDATE  ),
    .jtagCtrl_reset          ( jtag_inst1_RESET   )
);

//==============================================================================
// 风格迁移加速器：APB 寄存器块 + 数据通路
//==============================================================================
style_accel_apb u_style_accel_apb (
    .clk        ( core_clk ),
    .resetn     ( w_arstn  ),
    .PADDR      ( apb_paddr[11:0] ),
    .PSEL       ( apb_psel ),
    .PENABLE    ( apb_penable ),
    .PREADY     ( apb_pready ),
    .PWRITE     ( apb_pwrite ),
    .PWDATA     ( apb_pwdata ),
    .PRDATA     ( apb_prdata ),
    .PSLVERROR  ( apb_pslverror ),
    .busy       ( style_accel_busy ),
    .done       ( style_accel_done ),
    .error      ( style_accel_error ),
    .error_code ( style_accel_error_code ),
    .cycle_count( style_accel_cycle_count ),
    .dbg        ( style_accel_dbg ),
    .ddr_rst    ( style_accel_ddr_reset ),
    .key0       ( key0 ),
    .key1       ( key1 ),
    .key2       ( key2 ),
    .key3       ( key3 ),
    .display_mode(style_accel_display_mode),
    .style_strength(style_accel_mix_strength),
    .hud_visible(style_accel_hud_visible),
    .hud_type   (style_accel_hud_type),
    .cfg        ( style_accel_cfg ),
    .start_pulse( style_accel_start ),
    .abort_pulse( style_accel_abort ),
    .irq        ( style_accel_irq ),
    .video_frame_count(qin_frame_count),
    .video_display_bank(qout_bank_sel),
    .qout_diag_count(qout_diag_count),
    .video_diag2(video_diag2)
);

style_accel_top #(
    .ADDR_W (32), .DATA_W (128), .CFG_W (832),
    .IC (16), .OC (32), .RAW_W (320), .RAW_H (240),
    .STRIDE (2), .LANES (32), .MAX_OC (24), .MAX_IC (24), .MAX_UW (320)
) u_style_accel_top (
    .clk   ( core_clk ),
    .rst_n ( w_arstn && !style_accel_ddr_reset ),
    .start ( style_accel_start ),
    .abort ( style_accel_abort ),
    .cfg   ( style_accel_cfg ),
    .busy  ( style_accel_busy ),
    .done  ( style_accel_done ),
    .error ( style_accel_error ),
    .error_code ( style_accel_error_code ),
    .cycle_count( style_accel_cycle_count ),
    .dbg   ( style_accel_dbg ),
    .dbg_xbar_arready ( accel_axi_arready ),
    .dbg_xbar_rvalid  ( accel_axi_rvalid  ),
    .sum_flat  ( ),
    .sumsq_flat( ),
    .count_out ( ),
    .m_axi_awaddr ( accel_axi_awaddr ),
    .m_axi_awlen  ( accel_axi_awlen ),
    .m_axi_awsize ( accel_axi_awsize ),
    .m_axi_awburst( accel_axi_awburst ),
    .m_axi_awvalid( accel_axi_awvalid ),
    .m_axi_awready( accel_axi_awready ),
    .m_axi_wdata  ( accel_axi_wdata ),
    .m_axi_wstrb  ( accel_axi_wstrb ),
    .m_axi_wlast  ( accel_axi_wlast ),
    .m_axi_wvalid ( accel_axi_wvalid ),
    .m_axi_wready ( accel_axi_wready ),
    .m_axi_bresp  ( accel_axi_bresp ),
    .m_axi_bvalid ( accel_axi_bvalid ),
    .m_axi_bready ( accel_axi_bready ),
    .m_axi_araddr ( accel_axi_araddr ),
    .m_axi_arlen  ( accel_axi_arlen ),
    .m_axi_arsize ( accel_axi_arsize ),
    .m_axi_arburst( accel_axi_arburst ),
    .m_axi_arvalid( accel_axi_arvalid ),
    .m_axi_arready( accel_axi_arready ),
    .m_axi_rdata  ( accel_axi_rdata ),
    .m_axi_rresp  ( accel_axi_rresp ),
    .m_axi_rlast  ( accel_axi_rlast ),
    .m_axi_rvalid ( accel_axi_rvalid ),
    .m_axi_rready ( accel_axi_rready )
);
endmodule


/* ==========================================================================
 * video_scale_block -- 128x96 -> 640x480 nearest-neighbour sample/hold.
 *
 * The display path still produces a 640x480 raster.  Sample one pixel out of
 * every STEP x STEP source block (STEP=5 for 128x96) and hold it for the full
 * block.  DE/HS/VS pass through with one cycle of latency so data and timing
 * stay aligned at the DVI encoder.
 * ========================================================================== */
module video_scale_block #(
    parameter integer SRC_W = 640,
    parameter integer SRC_H = 480,
    parameter integer STEP  = 5
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_de,
    input  wire        in_hs,
    input  wire        in_vs,
    input  wire [23:0] in_rgb,
    output wire        out_de,
    output wire        out_hs,
    output wire        out_vs,
    output wire [23:0] out_rgb
);

    localparam integer DST_W = SRC_W / STEP;

    reg [9:0]  x_cnt;
    reg [8:0]  y_cnt;
    reg [23:0] pix_hold;
    reg [23:0] line_q;
    reg        de_d, hs_d, vs_d, non_sample_d;

    wire       sample_x = ((x_cnt % STEP) == 0);
    wire       sample_y = ((y_cnt % STEP) == 0);
    wire [8:0] src_x    = x_cnt / STEP;

    (* syn_ram_style = "block" *) reg [23:0] linebuf [0:DST_W-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt        <= 10'd0;
            y_cnt        <= 9'd0;
            pix_hold     <= 24'd0;
            line_q       <= 24'd0;
            de_d         <= 1'b0;
            hs_d         <= 1'b0;
            vs_d         <= 1'b0;
            non_sample_d <= 1'b0;
        end else begin
            if (!in_de)
                x_cnt <= 10'd0;
            else if (x_cnt == SRC_W-1)
                x_cnt <= 10'd0;
            else
                x_cnt <= x_cnt + 10'd1;

            if (in_de && (x_cnt == SRC_W-1))
                y_cnt <= (y_cnt == SRC_H-1) ? 9'd0 : (y_cnt + 9'd1);

            if (in_de && sample_x && sample_y) begin
                pix_hold       <= in_rgb;
                linebuf[src_x] <= in_rgb;
            end

            line_q       <= linebuf[src_x];
            de_d         <= in_de;
            hs_d         <= in_hs;
            vs_d         <= in_vs;
            non_sample_d <= (in_de && !sample_y);
        end
    end

    assign out_de  = de_d;
    assign out_hs  = hs_d;
    assign out_vs  = vs_d;
    assign out_rgb = non_sample_d ? line_q : pix_hold;

endmodule

/* ==========================================================================
 * video_qout_reader -- static q_out bring-up path.
 *
 * Reads one 128x96 q_out frame (4 B/pixel, int8 RGB + pad) from DDR,
 * one source line at a time, into a 128-bit line buffer, and presents a
 * 24-bit RGB stream aligned to the existing 640x480 raster.
 * The video_scale_block below performs the 5x5 sample/hold.
 *
 * The AXI read master shares the accelerator's x1 port.  The top level
 * arbitrates complete read bursts by AXI ID, allowing the previous q_out
 * frame to remain visible while the next frame is computing.
 * ========================================================================== */
module video_qout_reader #(
    parameter [31:0] BASE_ADDR     = 32'h04AC8800,
    parameter [31:0] BASE_ADDR_ALT = 32'h04B20000,
    parameter integer SRC_W = 640,
    parameter integer SRC_H = 480,
    parameter integer DST_W = 320,
    parameter integer DST_H = 240
)(
    input  wire         core_clk,
    input  wire         core_rst_n,
    input  wire         vid_clk,
    input  wire         vid_rst_n,
    input  wire         en,
    input  wire         bank_sel,
    input  wire         vid_de,
    input  wire         vid_hs,
    input  wire         vid_vs,
    output reg  [31:0]  m_axi_araddr,
    output reg  [7:0]   m_axi_arlen,
    output reg  [2:0]   m_axi_arsize,
    output reg  [1:0]   m_axi_arburst,
    output reg          m_axi_arvalid,
    input  wire         m_axi_arready,
    input  wire [127:0] m_axi_rdata,
    input  wire         m_axi_rlast,
    input  wire         m_axi_rvalid,
    output wire         m_axi_rready,
    output wire [23:0]  out_rgb,
    output reg          busy,
    output wire [31:0]  diag_count
);
    /* ---- video-side line/column tracking ---- */
    localparam integer STEP           = SRC_W / DST_W;
    localparam integer LINE_BYTES     = DST_W * 4;
    localparam integer BEATS_PER_LINE = LINE_BYTES / 16;

    reg [9:0] x_cnt;
    reg [8:0] y_cnt;
    reg       hs_d, vs_d;
    reg       frame_started;
    reg [1:0] prefetch_init;
    reg [1:0] rd_bank_d;
    reg       load_tgl;
    reg [7:0] load_line;
    reg       base_sel_latched;
    reg [1:0] bank_sel_sync;
    wire      hs_fall = !vid_hs && hs_d;
    wire      vs_rise = vid_vs && !vs_d;

    always @(posedge vid_clk or negedge vid_rst_n) begin
        if (!vid_rst_n) begin
            x_cnt <= 10'd0;
            y_cnt <= 9'd0;
            hs_d <= 1'b0;
            vs_d <= 1'b0;
            frame_started <= 1'b0;
            prefetch_init <= 2'd0;
            rd_bank_d <= 2'd0;
            load_tgl <= 1'b0;
            load_line <= 8'd0;
            base_sel_latched <= 1'b0;
            bank_sel_sync <= 2'd0;
        end else begin
            hs_d <= vid_hs;
            vs_d <= vid_vs;
            bank_sel_sync <= {bank_sel_sync[0], bank_sel};
            rd_bank_d <= (y_cnt / STEP) % 4;

            if (!vid_de) x_cnt <= 10'd0;
            else if (x_cnt == SRC_W-1) x_cnt <= 10'd0;
            else x_cnt <= x_cnt + 10'd1;

            if (vid_de && (x_cnt == SRC_W-1))
                y_cnt <= (y_cnt == SRC_H-1) ? 9'd0 : (y_cnt + 9'd1);

            if (vs_rise) begin
                y_cnt <= 9'd0;
                frame_started <= 1'b0;
                prefetch_init <= 2'd0;
                /* Request line 0 during vertical blank.  Waiting for the first
                 * hsync leaves only hblank for the 512-byte DDR fetch. */
                load_tgl <= ~load_tgl;
                load_line <= 8'd0;
                /* Publish the software-selected bank only at frame start so a
                 * mid-frame bank change can never mix two displayed frames. */
                base_sel_latched <= bank_sel_sync[1];
            end else begin
                if (vid_de) frame_started <= 1'b1;
                if (en && hs_fall) begin
                    if (prefetch_init < 2'd2) begin
                        /* Start with line 1 at y=0 and line 2 at y=1. */
                        load_tgl <= ~load_tgl;
                        load_line <= {6'd0, prefetch_init} + 8'd1;
                        prefetch_init <= prefetch_init + 2'd1;
                    end else if (frame_started &&
                                 ((y_cnt % STEP) == 0) &&
                                 (y_cnt >= STEP) &&
                                 (((y_cnt / STEP) + 2) < DST_H)) begin
                        /* Stay two source lines ahead.  For 640x480 -> 128x96
                         * this requests line 3 when y=5, line 4 at y=10, ...
                         * line 95 at y=465. */
                        load_tgl <= ~load_tgl;
                        load_line <= (y_cnt / STEP) + 8'd2;
                    end
                end
            end
        end
    end

    /* ---- cross the line-load request into core_clk ---- */
    reg [2:0] load_sync;
    always @(posedge core_clk or negedge core_rst_n) begin
        if (!core_rst_n) load_sync <= 3'd0;
        else load_sync <= {load_sync[1:0], load_tgl};
    end
    wire load_req = load_sync[2] ^ load_sync[1];

    /* ---- AXI read FSM: 128-bit R beats -> four 32-bit line-buffer writes ---- */
    localparam [1:0] ST_IDLE = 2'd0, ST_AR = 2'd1, ST_R = 2'd2, ST_WR = 2'd3;

    reg [1:0]   state;
    reg [31:0]  addr_cur;
    reg [7:0]   beat_idx;
    reg [1:0]   wr_idx;
    reg [127:0] wr_word;
    reg         rlast_r;
    reg [1:0]   wr_bank;
    reg         ram_we;
    reg [8:0]   ram_waddr;
    reg [31:0]  ram_wdata;
    reg [1:0]   req_count;
    reg [7:0]   req_line0, req_line1;
    reg         req_base0, req_base1;
    reg [15:0]  req_drop_cnt;

    /* Two-entry line-request FIFO.  The previous depth-1 slot silently
     * overwrote requests when DDR arbitration kept a 512-byte fetch busy. */
    wire req_pop  = (state == ST_IDLE) && (req_count != 2'd0);
    wire req_push = load_req && en;
    always @(posedge core_clk or negedge core_rst_n) begin
        if (!core_rst_n) begin
            req_count <= 2'd0;
            req_line0 <= 8'd0;
            req_line1 <= 8'd0;
            req_base0 <= 1'b0;
            req_base1 <= 1'b0;
            req_drop_cnt <= 16'd0;
        end else if (req_pop && req_push) begin
            if (req_count == 2'd1) begin
                req_line0 <= load_line;
                req_base0 <= base_sel_latched;
                req_count <= 2'd1;
            end else begin
                req_line0 <= req_line1;
                req_base0 <= req_base1;
                req_line1 <= load_line;
                req_base1 <= base_sel_latched;
                req_count <= 2'd2;
            end
        end else if (req_pop) begin
            if (req_count == 2'd1) begin
                req_count <= 2'd0;
            end else begin
                req_line0 <= req_line1;
                req_base0 <= req_base1;
                req_count <= 2'd1;
            end
        end else if (req_push) begin
            if (req_count == 2'd0) begin
                req_line0 <= load_line;
                req_base0 <= base_sel_latched;
                req_count <= 2'd1;
            end else if (req_count == 2'd1) begin
                req_line1 <= load_line;
                req_base1 <= base_sel_latched;
                req_count <= 2'd2;
            end else begin
                req_drop_cnt <= req_drop_cnt + 16'd1;
            end
        end
    end

    wire [31:0] beats_left  = BEATS_PER_LINE - {24'd0, beat_idx};
    wire [31:0] bytes_to_4k = 32'd4096 - {20'd0, addr_cur[11:0]};
    wire [31:0] beats_fit   = bytes_to_4k >> 4;
    wire [31:0] burst_len_c = (beats_left < beats_fit) ? beats_left : beats_fit;
    wire [7:0]  burst_len_8 = burst_len_c[7:0];

    assign m_axi_rready = (state == ST_R);

    always @(posedge core_clk or negedge core_rst_n) begin
        if (!core_rst_n) begin
            state <= ST_IDLE;
            addr_cur <= 32'd0;
            beat_idx <= 8'd0;
            wr_idx <= 2'd0;
            wr_word <= 128'd0;
            rlast_r <= 1'b0;
            wr_bank <= 2'd0;
            ram_we <= 1'b0;
            ram_waddr <= 9'd0;
            ram_wdata <= 32'd0;
            m_axi_araddr <= 32'd0;
            m_axi_arlen <= 8'd0;
            m_axi_arsize <= 3'd4;
            m_axi_arburst <= 2'b01;
            m_axi_arvalid <= 1'b0;
            busy <= 1'b0;
        end else begin
            ram_we <= 1'b0;
            case (state)
            ST_IDLE: begin
                m_axi_arvalid <= 1'b0;
                busy <= 1'b0;
                if (req_count != 2'd0) begin
                    addr_cur <= (req_base0 ? BASE_ADDR_ALT : BASE_ADDR)
                              + ({24'd0, req_line0} * LINE_BYTES);
                    wr_bank <= req_line0[1:0];
                    beat_idx <= 8'd0;
                    busy <= 1'b1;
                    state <= ST_AR;
                end
            end
            ST_AR: begin
                if (!m_axi_arvalid) begin
                    m_axi_araddr  <= addr_cur;
                    m_axi_arlen   <= burst_len_8 - 8'd1;
                    m_axi_arsize  <= 3'd4;
                    m_axi_arburst <= 2'b01;
                    m_axi_arvalid <= 1'b1;
                end else if (m_axi_arready) begin
                    m_axi_arvalid <= 1'b0;
                    state <= ST_R;
                end
            end
            ST_R: begin
                if (m_axi_rvalid) begin
                    wr_word <= m_axi_rdata;
                    rlast_r <= m_axi_rlast;
                    wr_idx <= 2'd0;
                    addr_cur <= addr_cur + 32'd16;
                    state <= ST_WR;
                end
            end
            ST_WR: begin
                ram_we <= 1'b1;
                ram_waddr <= {beat_idx[6:0], 2'b00} + {7'd0, wr_idx};
                ram_wdata <= wr_word[wr_idx*32 +: 32];
                if (wr_idx == 2'd3) begin
                    if (rlast_r) begin
                        if (beat_idx == BEATS_PER_LINE-1) begin
                            busy <= 1'b0;
                            state <= ST_IDLE;
                        end else begin
                            beat_idx <= beat_idx + 8'd1;
                            state <= ST_AR;
                        end
                    end else begin
                        beat_idx <= beat_idx + 8'd1;
                        state <= ST_R;
                    end
                end else begin
                    wr_idx <= wr_idx + 2'd1;
                end
            end
            default: state <= ST_IDLE;
            endcase
        end
    end

    /* ---- diagnostic counters: {bank collision, request drops} ---- */
    reg [2:0] load_status_m, load_status_s;
    reg       vid_de_d;
    reg [15:0] bank_collision_cnt;
    always @(posedge vid_clk or negedge vid_rst_n) begin
        if (!vid_rst_n) begin
            load_status_m <= 3'd0;
            load_status_s <= 3'd0;
            vid_de_d <= 1'b0;
            bank_collision_cnt <= 16'd0;
        end else begin
            load_status_m <= {busy, wr_bank};
            load_status_s <= load_status_m;
            vid_de_d <= vid_de;
            if (vid_de && !vid_de_d && load_status_s[2] &&
                (load_status_s[1:0] == rd_bank_d))
                bank_collision_cnt <= bank_collision_cnt + 16'd1;
        end
    end
    assign diag_count = {bank_collision_cnt, req_drop_cnt};

    /* ---- four source-line banks in one dual-clock RAM ----
     * Address {source_line[1:0], pixel} selects the bank.  Two-line-ahead
     * prefetch plus the request queue keeps a delayed DDR fetch away from the
     * line currently being scanned out. */
    wire [8:0]  rd_addr = x_cnt / STEP;
    wire [10:0] line_waddr = {wr_bank, ram_waddr};
    wire [10:0] line_raddr = {rd_bank_d, rd_addr};
    wire [31:0] rd_data;

    true_dual_port_ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(11),
        .WRITE_MODE_1("READ_FIRST"),
        .WRITE_MODE_2("READ_FIRST"),
        .OUTPUT_REG_1("FALSE"),
        .OUTPUT_REG_2("FALSE"),
        .RAM_INIT_FILE(""),
        .RAM_INIT_RADIX("HEX")
    ) u_qout_line_ram (
        .we1(ram_we), .clka(core_clk), .din1(ram_wdata), .addr1(line_waddr), .dout1(),
        .we2(1'b0), .clkb(vid_clk), .din2(32'd0), .addr2(line_raddr), .dout2(rd_data)
    );

    assign out_rgb = {rd_data[7:0]^8'h80, rd_data[15:8]^8'h80, rd_data[23:16]^8'h80};
endmodule

/* ==========================================================================
 * video_qin_writer -- camera/scaler -> q_in DDR writer.
 *
 * Samples the scaler's 640x480 RGB output 5:1 in both directions to make a
 * 128x96 frame, converts RGB888 to the accelerator's int8 q_in layout
 * (scale=1.0, zp=-128: q = pixel - 128, bytes R,G,B,pad), and writes one
 * 512-byte line at a time to QIN_ADDR via the accelerator's x1 write master.
 *
 * Line buffer: 32-bit x 512 (320 used, two RAM10 blocks).
 * AXI: four pixels per full 128-bit beat, awsize=4, wstrb=0xFFFF.
 * beat_idx is the burst start; local_beat is the beat inside the burst.
 * ========================================================================== */
module video_qin_writer #(
    parameter [31:0] QIN_ADDR = 32'h04800000,
    parameter integer SRC_W = 640,
    parameter integer SRC_H = 480,
    parameter integer DST_W = 320,
    parameter integer DST_H = 240
)(
    input  wire         vid_clk,
    input  wire         vid_rst_n,
    input  wire         core_clk,
    input  wire         core_rst_n,
    input  wire         en,
    input  wire         vid_de,
    input  wire         vid_vs,
    input  wire [23:0]  vid_rgb,
    output reg  [31:0]  m_axi_awaddr,
    output reg  [7:0]   m_axi_awlen,
    output reg  [2:0]   m_axi_awsize,
    output reg  [1:0]   m_axi_awburst,
    output reg          m_axi_awvalid,
    input  wire         m_axi_awready,
    output reg  [127:0] m_axi_wdata,
    output reg  [15:0]  m_axi_wstrb,
    output reg          m_axi_wlast,
    output reg          m_axi_wvalid,
    input  wire         m_axi_wready,
    input  wire [1:0]   m_axi_bresp,
    input  wire         m_axi_bvalid,
    output wire         m_axi_bready,
    output wire         busy,
    output wire         frame_done,
    output reg  [31:0]  frame_count
);
    localparam integer STEP           = SRC_W / DST_W;
    localparam integer LINE_BYTES     = DST_W * 4;
    localparam integer BEATS_PER_LINE = LINE_BYTES / 16;

    reg [9:0] sx;
    reg [8:0] sy;
    reg       vs_d;
    wire      vs_rise = vid_vs && !vs_d;

    reg [8:0]   samp_idx;
    reg [31:0]  cap_data;
    reg         en_sync1, en_sync2, en_sync3;
    reg         capture_armed;
    reg         cap_we;
    reg [8:0]   cap_waddr;

    reg         cap_active;
    reg         cap_line_busy;
    reg         cap_buf_free;
    reg         line_ready_tgl;
    reg [7:0]   line_num;
    reg [7:0]   cap_line;
    reg         frame_done_r;

    reg         written_sync1, written_sync2;
    reg         written_tgl;

    wire en_active = en_sync2;
    wire en_rise   = en_sync2 && !en_sync3;

    wire [31:0] qword = {8'h00,
                         vid_rgb[7:0]   ^ 8'h80,  /* B -> byte2 */
                         vid_rgb[15:8]  ^ 8'h80,  /* G -> byte1 */
                         vid_rgb[23:16] ^ 8'h80}; /* R -> byte0 */

    always @(posedge vid_clk or negedge vid_rst_n) begin
        if (!vid_rst_n) begin
            sx <= 10'd0;
            sy <= 9'd0;
            vs_d <= 1'b0;
            samp_idx <= 9'd0;
            cap_data <= 32'd0;
            cap_we <= 1'b0;
            cap_waddr <= 9'd0;
            cap_active <= 1'b0;
            cap_line_busy <= 1'b0;
            cap_buf_free <= 1'b1;
            line_ready_tgl <= 1'b0;
            line_num <= 8'd0;
            cap_line <= 8'd0;
            written_sync1 <= 1'b0;
            written_sync2 <= 1'b0;
            en_sync1 <= 1'b0;
            en_sync2 <= 1'b0;
            en_sync3 <= 1'b0;
            capture_armed <= 1'b0;
        end else begin
            vs_d <= vid_vs;
            en_sync1 <= en;
            en_sync2 <= en_sync1;
            en_sync3 <= en_sync2;
            if (en_rise) capture_armed <= 1'b1;
            written_sync1 <= written_tgl;
            written_sync2 <= written_sync1;
            if (written_sync2 != written_sync1)
                cap_buf_free <= 1'b1;

            if (!vid_de) sx <= 10'd0;
            else if (sx == SRC_W-1) sx <= 10'd0;
            else sx <= sx + 10'd1;

            if (vid_de && (sx == SRC_W-1))
                sy <= (sy == SRC_H-1) ? 9'd0 : (sy + 9'd1);

            if (vs_rise) begin
                sy <= 9'd0;
                cap_line <= 8'd0;
                cap_line_busy <= 1'b0;
                if (en_active && capture_armed) begin
                    cap_active <= 1'b1;
                    cap_buf_free <= 1'b1;
                end else begin
                    cap_active <= 1'b0;
                end
            end

            /* One complete frame per accelerator-idle interval.  The next
             * frame is armed only by the low-to-high edge of en, which is
             * driven by ~style_accel_busy in the top level. */
            if (!en_active) begin
                capture_armed <= 1'b0;
                cap_active <= 1'b0;
                cap_line_busy <= 1'b0;
            end

            cap_we <= 1'b0;
            if (cap_active && vid_de &&
                ((sy % STEP) == 0) && ((sx % STEP) == 0)) begin
                if (sx == 10'd0) begin
                    if (cap_buf_free) begin
                        samp_idx <= 9'd0;
                        line_num <= cap_line;
                        cap_buf_free <= 1'b0;
                        cap_line_busy <= 1'b1;
                        cap_we <= 1'b1;
                        cap_waddr <= 9'd0;
                        cap_data <= qword;
                        samp_idx <= 9'd1;
                    end
                end else if (cap_line_busy) begin
                    cap_we <= 1'b1;
                    cap_waddr <= samp_idx;
                    cap_data <= qword;
                    samp_idx <= samp_idx + 9'd1;
                    if (samp_idx == DST_W-1) begin
                        line_ready_tgl <= ~line_ready_tgl;
                        cap_line <= cap_line + 8'd1;
                        samp_idx <= 9'd0;
                        cap_line_busy <= 1'b0;
                        if (cap_line == DST_H-1) begin
                            capture_armed <= 1'b0;
                            cap_active <= 1'b0;
                        end
                    end
                end
            end
        end
    end

    assign frame_done = frame_done_r;

    reg [2:0] ready_sync;
    always @(posedge core_clk or negedge core_rst_n) begin
        if (!core_rst_n) ready_sync <= 3'd0;
        else ready_sync <= {ready_sync[1:0], line_ready_tgl};
    end
    wire line_req = ready_sync[2] ^ ready_sync[1];

    localparam [2:0] ST_IDLE = 3'd0, ST_AW = 3'd1, ST_PACK = 3'd2,
                     ST_W = 3'd3, ST_B = 3'd4;

    reg [2:0]  state;
    reg [7:0]  wr_line;
    reg [7:0]  beat_idx;    /* burst start, 0..BEATS_PER_LINE-1 */
    reg [7:0]  burst_len;
    reg [7:0]  local_beat;  /* 0..burst_len-1 */
    reg [1:0]  pack_idx;
    reg [1:0]  pack_wait;
    reg [8:0]  rd_addr;
    reg [127:0] pack_reg;
    reg        wr_busy;

    wire [7:0] cur_beat = beat_idx + local_beat;

    wire [31:0] awaddr_c = QIN_ADDR
                         + ({24'd0, wr_line} * LINE_BYTES)
                         + {20'd0, beat_idx, 4'd0};
    wire [31:0] beats_left  = BEATS_PER_LINE - {24'd0, beat_idx};
    wire [31:0] bytes_to_4k = 32'd4096 - {20'd0, awaddr_c[11:0]};
    wire [31:0] beats_fit   = bytes_to_4k >> 4;
    wire [31:0] burst_len_c = (beats_left < beats_fit) ? beats_left : beats_fit;
    wire [7:0]  burst_len_8 = burst_len_c[7:0];

    wire [31:0] rd_data;

    assign m_axi_bready = (state == ST_B);
    assign busy = wr_busy;

    always @(posedge core_clk or negedge core_rst_n) begin
        if (!core_rst_n) begin
            state <= ST_IDLE;
            wr_line <= 8'd0;
            beat_idx <= 8'd0;
            burst_len <= 8'd0;
            local_beat <= 8'd0;
            pack_idx <= 2'd0;
            pack_wait <= 2'd0;
            rd_addr <= 9'd0;
            pack_reg <= 128'd0;
            wr_busy <= 1'b0;
            written_tgl <= 1'b0;
            m_axi_awaddr <= 32'd0;
            m_axi_awlen <= 8'd0;
            m_axi_awsize <= 3'd4;
            m_axi_awburst <= 2'b01;
            m_axi_awvalid <= 1'b0;
            m_axi_wdata <= 128'd0;
            m_axi_wstrb <= 16'd0;
            m_axi_wlast <= 1'b0;
            m_axi_wvalid <= 1'b0;
            frame_done_r <= 1'b0;
            frame_count <= 32'd0;
        end else begin
            frame_done_r <= 1'b0;
            case (state)
            ST_IDLE: begin
                m_axi_awvalid <= 1'b0;
                m_axi_wvalid <= 1'b0;
                wr_busy <= 1'b0;
                if (line_req) begin
                    wr_line <= line_num;
                    beat_idx <= 8'd0;
                    local_beat <= 8'd0;
                    wr_busy <= 1'b1;
                    state <= ST_AW;
                end
            end
            ST_AW: begin
                if (!m_axi_awvalid) begin
                    m_axi_awaddr  <= awaddr_c;
                    m_axi_awlen   <= burst_len_8 - 8'd1;
                    m_axi_awsize  <= 3'd4;
                    m_axi_awburst <= 2'b01;
                    m_axi_awvalid <= 1'b1;
                    burst_len <= burst_len_8;
                end else if (m_axi_awready) begin
                    m_axi_awvalid <= 1'b0;
                    pack_idx <= 2'd0;
                    pack_wait <= 2'd2;
                    local_beat <= 8'd0;
                    pack_reg <= 128'd0;
                    rd_addr <= {beat_idx[6:0], 2'b00};
                    state <= ST_PACK;
                end
            end
            ST_PACK: begin
                case (pack_wait)
                2'd2: pack_wait <= 2'd1;  /* first address propagates */
                2'd1: begin
                    case (pack_idx)
                    2'd0: begin
                        pack_reg[31:0] <= rd_data;
                        pack_idx <= 2'd1;
                        rd_addr <= {cur_beat[6:0], 2'b00} + 9'd1;
                        pack_wait <= 2'd0;
                    end
                    2'd1: begin
                        pack_reg[63:32] <= rd_data;
                        pack_idx <= 2'd2;
                        rd_addr <= {cur_beat[6:0], 2'b00} + 9'd2;
                        pack_wait <= 2'd0;
                    end
                    2'd2: begin
                        pack_reg[95:64] <= rd_data;
                        pack_idx <= 2'd3;
                        rd_addr <= {cur_beat[6:0], 2'b00} + 9'd3;
                        pack_wait <= 2'd0;
                    end
                    default: begin
                        m_axi_wdata <= {rd_data, pack_reg[95:0]};
                        m_axi_wstrb <= 16'hFFFF;
                        m_axi_wlast <= (local_beat == burst_len - 8'd1);
                        m_axi_wvalid <= 1'b1;
                        state <= ST_W;
                    end
                    endcase
                end
                default: pack_wait <= 2'd1;  /* one settle cycle per RAM read */
                endcase
            end
            ST_W: begin
                if (m_axi_wvalid && m_axi_wready) begin
                    if (m_axi_wlast) begin
                        m_axi_wvalid <= 1'b0;
                        state <= ST_B;
                    end else begin
                        local_beat <= local_beat + 8'd1;
                        pack_idx <= 2'd0;
                        pack_wait <= 2'd2;
                        pack_reg <= 128'd0;
                        rd_addr <= {cur_beat[6:0] + 7'd1, 2'b00};
                        m_axi_wvalid <= 1'b0;
                        state <= ST_PACK;
                    end
                end
            end
            ST_B: begin
                if (m_axi_bvalid) begin
                    if ((beat_idx + burst_len) == BEATS_PER_LINE) begin
                        wr_busy <= 1'b0;
                        written_tgl <= ~written_tgl;
                        state <= ST_IDLE;
                        if ((wr_line == DST_H-1) && (m_axi_bresp == 2'b00)) begin
                            frame_count <= frame_count + 32'd1;
                            frame_done_r <= 1'b1;
                        end
                    end else begin
                        beat_idx <= beat_idx + burst_len;
                        state <= ST_AW;
                    end
                end
            end
            default: state <= ST_IDLE;
            endcase
        end
    end

    true_dual_port_ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(9),
        .WRITE_MODE_1("READ_FIRST"),
        .WRITE_MODE_2("READ_FIRST"),
        .OUTPUT_REG_1("FALSE"),
        .OUTPUT_REG_2("FALSE"),
        .RAM_INIT_FILE(""),
        .RAM_INIT_RADIX("HEX")
    ) u_qin_line_ram (
        .we1(cap_we), .clka(vid_clk), .din1(cap_data), .addr1(cap_waddr), .dout1(),
        .we2(1'b0), .clkb(core_clk), .din2(32'd0), .addr2(rd_addr), .dout2(rd_data)
    );
endmodule
