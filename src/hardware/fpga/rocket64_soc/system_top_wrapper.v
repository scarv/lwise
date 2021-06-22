//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
//Date        : Mon Jul 30 16:28:21 2018
//Host        : TP-Precision-Tower running 64-bit Ubuntu 18.04 LTS
//Command     : generate_target system_top_wrapper.bd
//Design      : system_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_top_wrapper
   (
`ifdef Differential_clock_capable_pin
    k_clk_osc0_clk_p,   // input clk_in1_p
    k_clk_osc0_clk_n,  // input clk_in1_n
`else
	k_clk_osc0_clk,   // input clk_in1_p
`endif  
    k_resetb,
    uart_rtl_0_rxd,
    uart_rtl_0_txd,
    gpio_tri_o,
    gpio_led);
localparam MEM_DATA_WIDTH = 64;
localparam BRAM_ADDR_WIDTH = 15;     // 32 KB
localparam BRAM_LINE = 2 ** BRAM_ADDR_WIDTH  * 8 / MEM_DATA_WIDTH;
localparam BRAM_LINE_OFFSET = $clog2(MEM_DATA_WIDTH/8);

`ifdef Differential_clock_capable_pin
input k_clk_osc0_clk_p;   // input clk_in1_p
input k_clk_osc0_clk_n;  // input clk_in1_n
`else
input k_clk_osc0_clk;   // input clk_in1_p
`endif  

input k_resetb;
input uart_rtl_0_rxd;
output uart_rtl_0_txd;
output [0:0]gpio_tri_o;
output [0:0]gpio_led;

wire k_clk_osc0_clk_n;
wire k_clk_osc0_clk_p;
wire k_resetb;                  //reset active hight
wire uart_rtl_0_rxd;
wire uart_rtl_0_txd;
wire [0:0]gpio_tri_o;
wire [0:0]gpio_led;

assign gpio_led = gpio_tri_o;
  
wire clk_50M;  
wire locked, sys_rstn;
assign sys_rstn = locked;        //reset active low

clk_wiz_0 clk_gen
   (
    // Clock out ports
    .clk_out1(clk_50M),             // output clk_out1
    // Status and control signals
    .reset(k_resetb),               // input reset
    .locked(locked),                // output locked
   // Clock in ports
`ifdef Differential_clock_capable_pin
    .clk_in1_p(k_clk_osc0_clk_p),   // input clk_in1_p
    .clk_in1_n(k_clk_osc0_clk_n));  // input clk_in1_n
`else
	.clk_in1(k_clk_osc0_clk));   // input clk_in1_p
`endif  
    
wire            bram_clk;  
wire            bram_ena;
wire    [7:0]   bram_wea;
wire    [14:0]  bram_addra;
wire    [63:0]  bram_dina;
wire    [63:0]  bram_douta;
/*blk_mem_gen_0 mem_gen_ins (
    .clka( bram_clk),           // input wire clka
    .ena(  bram_ena),           // input wire ena
    .wea(  bram_wea),           // input wire [3 : 0] wea
    .addra(bram_addra[14:2]),   // input wire [12 : 0] addra
    .dina( bram_dina),          // input wire [31 : 0] dina
    .douta(bram_douta));        // output wire [31 : 0] douta*/
// the inferred BRAMs
reg [MEM_DATA_WIDTH-1:0] ram [0 : BRAM_LINE-1];
initial $readmemh("prog.mem", ram);
reg [BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET] ram_addr_dly;

always@(posedge bram_clk) begin
    if(bram_ena) begin
        ram_addr_dly <= bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET];
        
        if(bram_wea[0]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][7 : 0] <= bram_dina[7 : 0];
        if(bram_wea[1]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][15: 8] <= bram_dina[15: 8];
        if(bram_wea[2]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][23:16] <= bram_dina[23:16];
        if(bram_wea[3]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][31:24] <= bram_dina[31:24];
        if(bram_wea[4]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][39:32] <= bram_dina[39:32];
        if(bram_wea[5]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][47:40] <= bram_dina[47:40];
        if(bram_wea[6]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][55:48] <= bram_dina[55:48];
        if(bram_wea[7]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][63:56] <= bram_dina[63:56];
/*
        if(bram_wea[0]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][7 : 0] <= bram_dina[39:32];
        if(bram_wea[1]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][15: 8] <= bram_dina[47:40];
        if(bram_wea[2]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][23:16] <= bram_dina[55:48];
        if(bram_wea[3]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][31:24] <= bram_dina[63:56];
        if(bram_wea[4]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][39:32] <= bram_dina[7 : 0];
        if(bram_wea[5]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][47:40] <= bram_dina[15: 8];
        if(bram_wea[6]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][55:48] <= bram_dina[23:16];
        if(bram_wea[7]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][63:56] <= bram_dina[31:24];
*/
    end
end
assign bram_douta = ram[ram_addr_dly];
//assign bram_douta[31: 0] = ram[ram_addr_dly][63:32];
//assign bram_douta[63:32] = ram[ram_addr_dly][31: 0];


//assign bram_douta[7 : 0] = ram[ram_addr_dly][31:24];
//assign bram_douta[15: 8] = ram[ram_addr_dly][23:16];
//assign bram_douta[23:16] = ram[ram_addr_dly][15: 8];
//assign bram_douta[31:24] = ram[ram_addr_dly][7 : 0]; 

/* 
wire                mem_axi_awvalid;
wire                mem_axi_awready;
wire    [30: 0]     mem_axi_awaddr;
wire    [2 : 0]     mem_axi_awprot; //
wire                mem_axi_wvalid;
wire                mem_axi_wready;
wire    [63: 0]     mem_axi_wdata;
wire    [7 : 0]     mem_axi_wstrb;  //
wire                mem_axi_bvalid;
wire                mem_axi_bready; //
wire                mem_axi_arvalid;
wire                mem_axi_arready;
wire    [30: 0]     mem_axi_araddr;
wire    [2 : 0]     mem_axi_arprot; //
wire                mem_axi_rvalid;
wire                mem_axi_rready;
wire    [63: 0]     mem_axi_rdata;
*/

wire [3:0]     mmio_axi4_0_aw_bits_id; 
wire [30:0]    mmio_axi4_0_aw_bits_addr; 
wire [7:0]     mmio_axi4_0_aw_bits_len;
wire [2:0]     mmio_axi4_0_aw_bits_size; 
wire [1:0]     mmio_axi4_0_aw_bits_burst;
wire           mmio_axi4_0_aw_valid; 
wire           mmio_axi4_0_aw_ready; 

wire [63:0]    mmio_axi4_0_w_bits_data;
wire [7:0]     mmio_axi4_0_w_bits_strb;
wire           mmio_axi4_0_w_bits_last;
wire           mmio_axi4_0_w_valid;
wire           mmio_axi4_0_w_ready; 

wire [3:0]     mmio_axi4_0_b_bits_id;
wire [1:0]     mmio_axi4_0_b_bits_resp;
wire           mmio_axi4_0_b_valid;  
wire           mmio_axi4_0_b_ready;

wire [3:0]     mmio_axi4_0_ar_bits_id;
wire [30:0]    mmio_axi4_0_ar_bits_addr;
wire [7:0]     mmio_axi4_0_ar_bits_len;
wire [2:0]     mmio_axi4_0_ar_bits_size;
wire [1:0]     mmio_axi4_0_ar_bits_burst; 
wire           mmio_axi4_0_ar_valid;
wire           mmio_axi4_0_ar_ready; 

wire [3:0]     mmio_axi4_0_r_bits_id;
wire [63:0]    mmio_axi4_0_r_bits_data;
wire [1:0]     mmio_axi4_0_r_bits_resp;
wire           mmio_axi4_0_r_bits_last;
wire           mmio_axi4_0_r_valid;  
wire           mmio_axi4_0_r_ready; 

/*
wire [1:0] mem_axi_bresp, mem_axi_rresp;
 axi_protocol_converter_0 axi_protocol_converter_ins (
   .aclk(clk_50M),                      // input wire aclk
   .aresetn(locked),                // input wire aresetn
   .s_axi_awid(     mmio_axi4_0_aw_bits_id),          // input wire [3 : 0] s_axi_awid
   .s_axi_awaddr(   mmio_axi4_0_aw_bits_addr),      // input wire [30 : 0] s_axi_awaddr
   .s_axi_awlen(    mmio_axi4_0_aw_bits_len),        // input wire [7 : 0] s_axi_awlen
   .s_axi_awsize(   mmio_axi4_0_aw_bits_size),      // input wire [2 : 0] s_axi_awsize
   .s_axi_awburst(  mmio_axi4_0_aw_bits_burst),    // input wire [1 : 0] s_axi_awburst
   .s_axi_awlock(   1'b0),      // unlock               input wire [0 : 0] s_axi_awlock
   .s_axi_awcache(  4'b0000),    // device unbufferable  input wire [3 : 0] s_axi_awcache
   .s_axi_awprot(   3'b000),      // input wire [2 : 0] s_axi_awprot
   .s_axi_awregion( 4'b0000),  // input wire [3 : 0] s_axi_awregion
   .s_axi_awqos(    4'b0000),        // input wire [3 : 0] s_axi_awqos
   .s_axi_awvalid(  mmio_axi4_0_aw_valid),    // input wire s_axi_awvalid
   .s_axi_awready(  mmio_axi4_0_aw_ready),    // output wire s_axi_awready
   .s_axi_wdata(    mmio_axi4_0_w_bits_data),        // input wire [63 : 0] s_axi_wdata
   .s_axi_wstrb(    mmio_axi4_0_w_bits_strb),        // input wire [7 : 0] s_axi_wstrb
   .s_axi_wlast(    mmio_axi4_0_w_bits_last),        // input wire s_axi_wlast
   .s_axi_wvalid(   mmio_axi4_0_w_valid),      // input wire s_axi_wvalid
   .s_axi_wready(   mmio_axi4_0_w_ready),      // output wire s_axi_wready
   .s_axi_bid(      mmio_axi4_0_b_bits_id),            // output wire [3 : 0] s_axi_bid
   .s_axi_bresp(    mmio_axi4_0_b_bits_resp),        // output wire [1 : 0] s_axi_bresp
   .s_axi_bvalid(   mmio_axi4_0_b_valid),      // output wire s_axi_bvalid
   .s_axi_bready(   mmio_axi4_0_b_ready),      // input wire s_axi_bready
   .s_axi_arid(     mmio_axi4_0_ar_bits_id),          // input wire [3 : 0] s_axi_arid
   .s_axi_araddr(   mmio_axi4_0_ar_bits_addr),      // input wire [30 : 0] s_axi_araddr
   .s_axi_arlen(    mmio_axi4_0_ar_bits_len),        // input wire [7 : 0] s_axi_arlen
   .s_axi_arsize(   mmio_axi4_0_ar_bits_size),      // input wire [2 : 0] s_axi_arsize
   .s_axi_arburst(  mmio_axi4_0_ar_bits_burst),    // input wire [1 : 0] s_axi_arburst
   .s_axi_arlock(   1'b0),      // input wire [0 : 0] s_axi_arlock
   .s_axi_arcache(  4'b0000),    // input wire [3 : 0] s_axi_arcache
   .s_axi_arprot(   3'b000),      // input wire [2 : 0] s_axi_arprot
   .s_axi_arregion( 4'b0000),  // input wire [3 : 0] s_axi_arregion
   .s_axi_arqos(    4'b0000),        // input wire [3 : 0] s_axi_arqos
   .s_axi_arvalid(  mmio_axi4_0_ar_valid),    // input wire s_axi_arvalid
   .s_axi_arready(  mmio_axi4_0_ar_ready),    // output wire s_axi_arready
   .s_axi_rid(      mmio_axi4_0_r_bits_id),            // output wire [3 : 0] s_axi_rid
   .s_axi_rdata(    mmio_axi4_0_r_bits_data),        // output wire [63 : 0] s_axi_rdata
   .s_axi_rresp(    mmio_axi4_0_r_bits_resp),        // output wire [1 : 0] s_axi_rresp
   .s_axi_rlast(    mmio_axi4_0_r_bits_last),        // output wire s_axi_rlast
   .s_axi_rvalid(   mmio_axi4_0_r_valid),      // output wire s_axi_rvalid
   .s_axi_rready(   mmio_axi4_0_r_ready),      // input wire s_axi_rready
 
   .m_axi_awaddr(    mem_axi_awaddr),      // output wire [30 : 0] m_axi_awaddr
   .m_axi_awprot(    mem_axi_awprot),      // output wire [2 : 0] m_axi_awprot
   .m_axi_awvalid(   mem_axi_awvalid),    // output wire m_axi_awvalid
   .m_axi_awready(   mem_axi_awready),    // input wire m_axi_awready
   .m_axi_wdata(     mem_axi_wdata),        // output wire [63 : 0] m_axi_wdata
   .m_axi_wstrb(     mem_axi_wstrb),        // output wire [7 : 0] m_axi_wstrb
   .m_axi_wvalid(    mem_axi_wvalid),      // output wire m_axi_wvalid
   .m_axi_wready(    mem_axi_wready),      // input wire m_axi_wready
   .m_axi_bresp(     mem_axi_bresp),        // input wire [1 : 0] m_axi_bresp
   .m_axi_bvalid(    mem_axi_bvalid),      // input wire m_axi_bvalid
   .m_axi_bready(    mem_axi_bready),      // output wire m_axi_bready
   .m_axi_araddr(    mem_axi_araddr),      // output wire [30 : 0] m_axi_araddr
   .m_axi_arprot(    mem_axi_arprot),      // output wire [2 : 0] m_axi_arprot
   .m_axi_arvalid(   mem_axi_arvalid),    // output wire m_axi_arvalid
   .m_axi_arready(   mem_axi_arready),    // input wire m_axi_arready
   .m_axi_rdata(     mem_axi_rdata),        // input wire [63 : 0] m_axi_rdata
   .m_axi_rresp(     mem_axi_rresp),        // input wire [1 : 0] m_axi_rresp
   .m_axi_rvalid(    mem_axi_rvalid),      // input wire m_axi_rvalid
   .m_axi_rready(    mem_axi_rready)      // output wire m_axi_rready
 );
*/ 
SCARVRocketSystem RocketSystem_Ins ( // @[SaseboRocketTest.scala 14:19:freechips.rocketchip.system.SaseboRocketConfig.fir@156658.4]
      .clock(clk_50M),
      .reset(~sys_rstn),
      .debug_systemjtag_jtag_TCK( 1'b0),         // input
      .debug_systemjtag_jtag_TMS( 1'b0),         // input
      .debug_systemjtag_jtag_TDI( 1'b0),         // input
      .debug_systemjtag_jtag_TDO_data(),    // output
      .debug_systemjtag_jtag_TDO_driven(),  // output
      .debug_systemjtag_reset(    k_resetb),         // input
      .debug_ndreset(),                     // output
      .mmio_axi4_0_aw_ready(        mmio_axi4_0_aw_ready),
      .mmio_axi4_0_aw_valid(        mmio_axi4_0_aw_valid),
      .mmio_axi4_0_aw_bits_id(      mmio_axi4_0_aw_bits_id),
      .mmio_axi4_0_aw_bits_addr(    mmio_axi4_0_aw_bits_addr),
      .mmio_axi4_0_aw_bits_len(     mmio_axi4_0_aw_bits_len),
      .mmio_axi4_0_aw_bits_size(    mmio_axi4_0_aw_bits_size),
      .mmio_axi4_0_aw_bits_burst(   mmio_axi4_0_aw_bits_burst),
      .mmio_axi4_0_w_ready(         mmio_axi4_0_w_ready),
      .mmio_axi4_0_w_valid(         mmio_axi4_0_w_valid),
      .mmio_axi4_0_w_bits_data(     mmio_axi4_0_w_bits_data),
      .mmio_axi4_0_w_bits_strb(     mmio_axi4_0_w_bits_strb),
      .mmio_axi4_0_w_bits_last(     mmio_axi4_0_w_bits_last),
      .mmio_axi4_0_b_ready(         mmio_axi4_0_b_ready),
      .mmio_axi4_0_b_valid(         mmio_axi4_0_b_valid),
      .mmio_axi4_0_b_bits_id(       mmio_axi4_0_b_bits_id),
      .mmio_axi4_0_b_bits_resp(     mmio_axi4_0_b_bits_resp),
      .mmio_axi4_0_ar_ready(        mmio_axi4_0_ar_ready),
      .mmio_axi4_0_ar_valid(        mmio_axi4_0_ar_valid),
      .mmio_axi4_0_ar_bits_id(      mmio_axi4_0_ar_bits_id),
      .mmio_axi4_0_ar_bits_addr(    mmio_axi4_0_ar_bits_addr),
      .mmio_axi4_0_ar_bits_len(     mmio_axi4_0_ar_bits_len),
      .mmio_axi4_0_ar_bits_size(    mmio_axi4_0_ar_bits_size),
      .mmio_axi4_0_ar_bits_burst(   mmio_axi4_0_ar_bits_burst),
      .mmio_axi4_0_r_ready(         mmio_axi4_0_r_ready),
      .mmio_axi4_0_r_valid(         mmio_axi4_0_r_valid),
      .mmio_axi4_0_r_bits_id(       mmio_axi4_0_r_bits_id),
      .mmio_axi4_0_r_bits_data(     mmio_axi4_0_r_bits_data),
      .mmio_axi4_0_r_bits_resp(     mmio_axi4_0_r_bits_resp),
      .mmio_axi4_0_r_bits_last(     mmio_axi4_0_r_bits_last)
    );
wire  [30: 0]  m00_axi_awaddr,   m01_axi_awaddr,   m02_axi_awaddr;
wire  [7 : 0]  m00_axi_awlen,    m01_axi_awlen,    m02_axi_awlen;
wire  [2 : 0]  m00_axi_awsize,   m01_axi_awsize,   m02_axi_awsize;
wire  [1 : 0]  m00_axi_awburst,  m01_axi_awburst,  m02_axi_awburst;
wire           m00_axi_awlock,   m01_axi_awlock,   m02_axi_awlock;
wire  [3 : 0]  m00_axi_awcache,  m01_axi_awcache,  m02_axi_awcache;
wire  [2 : 0]  m00_axi_awprot,   m01_axi_awprot,   m02_axi_awprot;
wire  [3 : 0]  m00_axi_awregion, m01_axi_awregion, m02_axi_awregion;
wire  [3 : 0]  m00_axi_awqos,    m01_axi_awqos,    m02_axi_awqos;
wire           m00_axi_awvalid,  m01_axi_awvalid,  m02_axi_awvalid;
wire           m00_axi_awready,  m01_axi_awready,  m02_axi_awready;
wire  [63: 0]  m00_axi_wdata,    m01_axi_wdata,    m02_axi_wdata;
wire  [7 : 0]  m00_axi_wstrb,    m01_axi_wstrb,    m02_axi_wstrb;
wire           m00_axi_wlast,    m01_axi_wlast,    m02_axi_wlast;
wire           m00_axi_wvalid,   m01_axi_wvalid,   m02_axi_wvalid;
wire           m00_axi_wready,   m01_axi_wready,   m02_axi_wready;
wire  [2 : 0]  m00_axi_bresp,    m01_axi_bresp,    m02_axi_bresp;
wire           m00_axi_bvalid,   m01_axi_bvalid,   m02_axi_bvalid;
wire           m00_axi_bready,   m01_axi_bready,   m02_axi_bready;
wire  [30: 0]  m00_axi_araddr,   m01_axi_araddr,   m02_axi_araddr;
wire  [7 : 0]  m00_axi_arlen,    m01_axi_arlen,    m02_axi_arlen;
wire  [3 : 0]  m00_axi_arsize,   m01_axi_arsize,   m02_axi_arsize;
wire  [2 : 0]  m00_axi_arburst,  m01_axi_arburst,  m02_axi_arburst;
wire           m00_axi_arlock,   m01_axi_arlock,   m02_axi_arlock;
wire  [3 : 0]  m00_axi_arcache,  m01_axi_arcache,  m02_axi_arcache;
wire  [2 : 0]  m00_axi_arprot,   m01_axi_arprot,   m02_axi_arprot;
wire  [3 : 0]  m00_axi_arregion, m01_axi_arregion, m02_axi_arregion;
wire  [3 : 0]  m00_axi_arqos,    m01_axi_arqos,    m02_axi_arqos;
wire           m00_axi_arvalid,  m01_axi_arvalid,  m02_axi_arvalid;
wire           m00_axi_arready,  m01_axi_arready,  m02_axi_arready;
wire  [63: 0]  m00_axi_rdata,    m01_axi_rdata,    m02_axi_rdata;
wire  [1 : 0]  m00_axi_rresp,    m01_axi_rresp,    m02_axi_rresp;
wire           m00_axi_rlast,    m01_axi_rlast,    m02_axi_rlast;
wire           m00_axi_rvalid,   m01_axi_rvalid,   m02_axi_rvalid;
wire           m00_axi_rready,   m01_axi_rready,   m02_axi_rready;
    
axi_crossbar_0  axi_crossbar_ins(
  .aclk(clk_50M),                             // input wire aclk
  .aresetn(locked),                           // input wire aresetn
  .s_axi_awid(      mmio_axi4_0_aw_bits_id),          // input wire [3 : 0] s_axi_awid
  .s_axi_awaddr(    mmio_axi4_0_aw_bits_addr),  // input wire [30 : 0] s_axi_awaddr
  .s_axi_awlen(     mmio_axi4_0_aw_bits_len),   // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(    mmio_axi4_0_aw_bits_size),  // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(   mmio_axi4_0_aw_bits_burst), // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(    1'b0),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(   4'b0000),   // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(    3'b000),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awqos(     4'b0000),   // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(   mmio_axi4_0_aw_valid),      // input wire [0 : 0] s_axi_awvalid
  .s_axi_awready(   mmio_axi4_0_aw_ready),      // output wire [0 : 0] s_axi_awready
  .s_axi_wdata(     mmio_axi4_0_w_bits_data),   // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(     mmio_axi4_0_w_bits_strb),   // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(     mmio_axi4_0_w_bits_last),   // input wire [0 : 0] s_axi_wlast
  .s_axi_wvalid(    mmio_axi4_0_w_valid),       // input wire [0 : 0] s_axi_wvalid
  .s_axi_wready(    mmio_axi4_0_w_ready),       // output wire [0 : 0] s_axi_wready
  .s_axi_bid(       mmio_axi4_0_b_bits_id),            // output wire [3 : 0] s_axi_bid
  .s_axi_bresp(     mmio_axi4_0_b_bits_resp),   // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(    mmio_axi4_0_b_valid),       // output wire [0 : 0] s_axi_bvalid
  .s_axi_bready(    mmio_axi4_0_b_ready),       // input wire [0 : 0] s_axi_bready
  .s_axi_arid(      mmio_axi4_0_ar_bits_id),          // input wire [3 : 0] s_axi_arid
  .s_axi_araddr(    mmio_axi4_0_ar_bits_addr),  // input wire [30 : 0] s_axi_araddr
  .s_axi_arlen(     mmio_axi4_0_ar_bits_len),   // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(    mmio_axi4_0_ar_bits_size),  // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(   mmio_axi4_0_ar_bits_burst), // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(    1'b0),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(   4'b0000),   // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(    3'b000),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arqos(     4'b0000),   // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(   mmio_axi4_0_ar_valid),      // input wire [0 : 0] s_axi_arvalid
  .s_axi_arready(   mmio_axi4_0_ar_ready),      // output wire [0 : 0] s_axi_arready
  .s_axi_rid(       mmio_axi4_0_r_bits_id),            // output wire [3 : 0] s_axi_rid
  .s_axi_rdata(     mmio_axi4_0_r_bits_data),   // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(     mmio_axi4_0_r_bits_resp),   // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(     mmio_axi4_0_r_bits_last),   // output wire [0 : 0] s_axi_rlast
  .s_axi_rvalid(    mmio_axi4_0_r_valid),       // output wire [0 : 0] s_axi_rvalid
  .s_axi_rready(    mmio_axi4_0_r_ready),       // input wire [0 : 0] s_axi_rready
  .m_axi_awaddr(  {m02_axi_awaddr,  m01_axi_awaddr,  m00_axi_awaddr}),      // output wire [92 : 0] m_axi_awaddr
  .m_axi_awlen(   {m02_axi_awlen,   m01_axi_awlen,   m00_axi_awlen}),        // output wire [23 : 0] m_axi_awlen
  .m_axi_awsize(  {m02_axi_awsize,  m01_axi_awsize,  m00_axi_awsize}),      // output wire [8 : 0] m_axi_awsize
  .m_axi_awburst( {m02_axi_awburst, m01_axi_awburst, m00_axi_awburst}),    // output wire [5 : 0] m_axi_awburst
  .m_axi_awlock(  {m02_axi_awlock,  m01_axi_awlock,  m00_axi_awlock}),      // output wire [2 : 0] m_axi_awlock
  .m_axi_awcache( {m02_axi_awcache, m01_axi_awcache, m00_axi_awcache}),    // output wire [11 : 0] m_axi_awcache
  .m_axi_awprot(  {m02_axi_awprot,  m01_axi_awprot,  m00_axi_awprot}),      // output wire [8 : 0] m_axi_awprot
  .m_axi_awregion({m02_axi_awregion,m01_axi_awregion,m00_axi_awregion}),  // output wire [11 : 0] m_axi_awregion
  .m_axi_awqos(   {m02_axi_awqos,   m01_axi_awqos,   m00_axi_awqos}),        // output wire [11 : 0] m_axi_awqos
  .m_axi_awvalid( {m02_axi_awvalid, m01_axi_awvalid, m00_axi_awvalid}),    // output wire [2 : 0] m_axi_awvalid
  .m_axi_awready( {m02_axi_awready, m01_axi_awready, m00_axi_awready}),    // input wire [2 : 0] m_axi_awready
  .m_axi_wdata(   {m02_axi_wdata,   m01_axi_wdata,   m00_axi_wdata}),        // output wire [191 : 0] m_axi_wdata
  .m_axi_wstrb(   {m02_axi_wstrb,   m01_axi_wstrb,   m00_axi_wstrb}),        // output wire [23 : 0] m_axi_wstrb
  .m_axi_wlast(   {m02_axi_wlast,   m01_axi_wlast,   m00_axi_wlast}),        // output wire [2 : 0] m_axi_wlast
  .m_axi_wvalid(  {m02_axi_wvalid,  m01_axi_wvalid,  m00_axi_wvalid}),      // output wire [2 : 0] m_axi_wvalid
  .m_axi_wready(  {m02_axi_wready,  m01_axi_wready,  m00_axi_wready}),      // input wire [2 : 0] m_axi_wready
  .m_axi_bresp(   {m02_axi_bresp,   m01_axi_bresp,   m00_axi_bresp}),        // input wire [5 : 0] m_axi_bresp
  .m_axi_bvalid(  {m02_axi_bvalid,  m01_axi_bvalid,  m00_axi_bvalid}),      // input wire [2 : 0] m_axi_bvalid
  .m_axi_bready(  {m02_axi_bready,  m01_axi_bready,  m00_axi_bready}),      // output wire [2 : 0] m_axi_bready
  .m_axi_araddr(  {m02_axi_araddr,  m01_axi_araddr,  m00_axi_araddr}),      // output wire [92 : 0] m_axi_araddr
  .m_axi_arlen(   {m02_axi_arlen,   m01_axi_arlen,   m00_axi_arlen}),        // output wire [23 : 0] m_axi_arlen
  .m_axi_arsize(  {m02_axi_arsize,  m01_axi_arsize,  m00_axi_arsize}),      // output wire [8 : 0] m_axi_arsize
  .m_axi_arburst( {m02_axi_arburst, m01_axi_arburst, m00_axi_arburst}),    // output wire [5 : 0] m_axi_arburst
  .m_axi_arlock(  {m02_axi_arlock,  m01_axi_arlock,  m00_axi_arlock}),      // output wire [2 : 0] m_axi_arlock
  .m_axi_arcache( {m02_axi_arcache, m01_axi_arcache, m00_axi_arcache}),    // output wire [11 : 0] m_axi_arcache
  .m_axi_arprot(  {m02_axi_arprot,  m01_axi_arprot,  m00_axi_arprot}),      // output wire [8 : 0] m_axi_arprot
  .m_axi_arregion({m02_axi_arregion,m01_axi_arregion,m00_axi_arregion}),  // output wire [11 : 0] m_axi_arregion
  .m_axi_arqos(   {m02_axi_arqos,   m01_axi_arqos,   m00_axi_arqos}),        // output wire [11 : 0] m_axi_arqos
  .m_axi_arvalid( {m02_axi_arvalid, m01_axi_arvalid, m00_axi_arvalid}),    // output wire [2 : 0] m_axi_arvalid
  .m_axi_arready( {m02_axi_arready, m01_axi_arready, m00_axi_arready}),    // input wire [2 : 0] m_axi_arready
  .m_axi_rdata(   {m02_axi_rdata,   m01_axi_rdata,   m00_axi_rdata}),        // input wire [191 : 0] m_axi_rdata
  .m_axi_rresp(   {m02_axi_rresp,   m01_axi_rresp,   m00_axi_rresp}),        // input wire [5 : 0] m_axi_rresp
  .m_axi_rlast(   {m02_axi_rlast,   m01_axi_rlast,   m00_axi_rlast}),        // input wire [2 : 0] m_axi_rlast
  .m_axi_rvalid(  {m02_axi_rvalid,  m01_axi_rvalid,  m00_axi_rvalid}),      // input wire [2 : 0] m_axi_rvalid
  .m_axi_rready(  {m02_axi_rready,  m01_axi_rready,  m00_axi_rready})      // output wire [2 : 0] m_axi_rready
);


axi_bram_ctrl_0 bram_ctrl_ins (
  .s_axi_aclk(   clk_50M),              // input wire s_axi_aclk
  .s_axi_aresetn(locked),               // input wire s_axi_aresetn
  .s_axi_awaddr( m00_axi_awaddr[14:0]),    // input wire [14 : 0] s_axi_awaddr
  .s_axi_awlen(  m00_axi_awlen),      // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize( m00_axi_awsize),    // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(m00_axi_awburst),  // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock( m00_axi_awlock),    // input wire s_axi_awlock
  .s_axi_awcache(m00_axi_awcache),  // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot( m00_axi_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(m00_axi_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(m00_axi_awready),  // output wire s_axi_awready
  .s_axi_wdata(  m00_axi_wdata),      // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(  m00_axi_wstrb),      // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(  m00_axi_wlast),      // input wire s_axi_wlast
  .s_axi_wvalid( m00_axi_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready( m00_axi_wready),    // output wire s_axi_wready
  .s_axi_bresp(  m00_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid( m00_axi_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready( m00_axi_bready),    // input wire s_axi_bready
  .s_axi_araddr( m00_axi_araddr[14:0]),    // input wire [14 : 0] s_axi_araddr
  .s_axi_arlen(  m00_axi_arlen),      // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize( m00_axi_arsize),    // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(m00_axi_arburst),  // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock( m00_axi_arlock),    // input wire s_axi_arlock
  .s_axi_arcache(m00_axi_arcache),  // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot( m00_axi_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(m00_axi_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(m00_axi_arready),  // output wire s_axi_arready
  .s_axi_rdata(  m00_axi_rdata),      // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(  m00_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(  m00_axi_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid( m00_axi_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready( m00_axi_rready),    // input wire s_axi_rready
  .bram_rst_a( ),                       // output wire bram_rst_a
  .bram_clk_a(   bram_clk),             // output wire bram_clk_a
  .bram_en_a(    bram_ena),             // output wire bram_en_a
  .bram_we_a(    bram_wea),             // output wire [7 : 0] bram_we_a
  .bram_addr_a(  bram_addra),           // output wire [14 : 0] bram_addr_a
  .bram_wrdata_a(bram_dina),            // output wire [31 : 0] bram_wrdata_a
  .bram_rddata_a(bram_douta)            // input wire [31 : 0] bram_rddata_a
);


/*    
wire                m00_axi_awvalid,m01_axi_awvalid,m02_axi_awvalid;
wire                m00_axi_awready,m01_axi_awready,m02_axi_awready;
wire    [30: 0]     m00_axi_awaddr, m01_axi_awaddr, m02_axi_awaddr;
wire    [2 : 0]     m00_axi_awprot, m01_axi_awprot, m02_axi_awprot; //
wire                m00_axi_wvalid, m01_axi_wvalid, m02_axi_wvalid;
wire                m00_axi_wready, m01_axi_wready, m02_axi_wready;
wire    [63: 0]     m00_axi_wdata,  m01_axi_wdata,  m02_axi_wdata;
wire    [7 : 0]     m00_axi_wstrb,  m01_axi_wstrb,  m02_axi_wstrb;  //
wire    [1 : 0]     m00_axi_bresp,  m01_axi_bresp,  m02_axi_bresp;
wire                m00_axi_bvalid, m01_axi_bvalid, m02_axi_bvalid;
wire                m00_axi_bready, m01_axi_bready, m02_axi_bready; //
wire                m00_axi_arvalid,m01_axi_arvalid,m02_axi_arvalid;
wire                m00_axi_arready,m01_axi_arready,m02_axi_arready;
wire    [30: 0]     m00_axi_araddr, m01_axi_araddr, m02_axi_araddr;
wire    [2 : 0]     m00_axi_arprot, m01_axi_arprot, m02_axi_arprot; //
wire                m00_axi_rvalid, m01_axi_rvalid, m02_axi_rvalid;
wire                m00_axi_rready, m01_axi_rready, m02_axi_rready;
wire    [63: 0]     m00_axi_rdata,  m01_axi_rdata,  m02_axi_rdata;
wire    [1 : 0]     m00_axi_rresp,  m01_axi_rresp,  m02_axi_rresp;
axi_crossbar_0 axi_crossbar_ins (
  .aclk(clk_50M),                       // input wire aclk
  .aresetn(locked),                     // input wire aresetn
  .s_axi_awaddr(    mem_axi_awaddr),    // input wire [30 : 0] s_axi_awaddr
  .s_axi_awprot(    mem_axi_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(   mem_axi_awvalid),   // input wire [0 : 0] s_axi_awvalid
  .s_axi_awready(   mem_axi_awready),   // output wire [0 : 0] s_axi_awready
  .s_axi_wdata(     mem_axi_wdata),     // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(     mem_axi_wstrb),     // input wire [7 : 0] s_axi_wstrb
  .s_axi_wvalid(    mem_axi_wvalid),    // input wire [0 : 0] s_axi_wvalid
  .s_axi_wready(    mem_axi_wready),    // output wire [0 : 0] s_axi_wready
  .s_axi_bresp(     mem_axi_bresp),     // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(    mem_axi_bvalid),    // output wire [0 : 0] s_axi_bvalid
  .s_axi_bready(    mem_axi_bready),    // input wire [0 : 0] s_axi_bready
  .s_axi_araddr(    mem_axi_araddr),    // input wire [30 : 0] s_axi_araddr
  .s_axi_arprot(    mem_axi_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(   mem_axi_arvalid),   // input wire [0 : 0] s_axi_arvalid
  .s_axi_arready(   mem_axi_arready),   // output wire [0 : 0] s_axi_arready
  .s_axi_rdata(     mem_axi_rdata),     // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(     mem_axi_rresp),     // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(    mem_axi_rvalid),    // output wire [0 : 0] s_axi_rvalid
  .s_axi_rready(    mem_axi_rready),    // input wire [0 : 0] s_axi_rready
  .m_axi_awaddr( {m02_axi_awaddr, m01_axi_awaddr, m00_axi_awaddr}),    // output wire [92 : 0] m_axi_awaddr
  .m_axi_awprot( {m02_axi_awprot, m01_axi_awprot, m00_axi_awprot}),    // output wire [8 : 0] m_axi_awprot
  .m_axi_awvalid({m02_axi_awvalid,m01_axi_awvalid,m00_axi_awvalid}),  // output wire [2 : 0] m_axi_awvalid
  .m_axi_awready({m02_axi_awready,m01_axi_awready,m00_axi_awready}),  // input wire [2 : 0] m_axi_awready
  .m_axi_wdata(  {m02_axi_wdata,  m01_axi_wdata,  m00_axi_wdata}),      // output wire [191 : 0] m_axi_wdata
  .m_axi_wstrb(  {m02_axi_wstrb,  m01_axi_wstrb,  m00_axi_wstrb}),      // output wire [23 : 0] m_axi_wstrb
  .m_axi_wvalid( {m02_axi_wvalid, m01_axi_wvalid, m00_axi_wvalid}),    // output wire [2 : 0] m_axi_wvalid
  .m_axi_wready( {m02_axi_wready, m01_axi_wready, m00_axi_wready}),    // input wire [2 : 0] m_axi_wready
  .m_axi_bresp(  {m02_axi_bresp,  m01_axi_bresp,  m00_axi_bresp}),      // input wire [5 : 0] m_axi_bresp
  .m_axi_bvalid( {m02_axi_bvalid, m01_axi_bvalid, m00_axi_bvalid}),    // input wire [2 : 0] m_axi_bvalid
  .m_axi_bready( {m02_axi_bready, m01_axi_bready, m00_axi_bready}),    // output wire [2 : 0] m_axi_bready
  .m_axi_araddr( {m02_axi_araddr, m01_axi_araddr, m00_axi_araddr}),    // output wire [92 : 0] m_axi_araddr
  .m_axi_arprot( {m02_axi_arprot, m01_axi_arprot, m00_axi_arprot}),    // output wire [8 : 0] m_axi_arprot
  .m_axi_arvalid({m02_axi_arvalid,m01_axi_arvalid,m00_axi_arvalid}),  // output wire [2 : 0] m_axi_arvalid
  .m_axi_arready({m02_axi_arready,m01_axi_arready,m00_axi_arready}),  // input wire [2 : 0] m_axi_arready
  .m_axi_rdata(  {m02_axi_rdata,  m01_axi_rdata,  m00_axi_rdata}),      // input wire [191 : 0] m_axi_rdata
  .m_axi_rresp(  {m02_axi_rresp,  m01_axi_rresp,  m00_axi_rresp}),      // input wire [5 : 0] m_axi_rresp
  .m_axi_rvalid( {m02_axi_rvalid, m01_axi_rvalid, m00_axi_rvalid}),    // input wire [2 : 0] m_axi_rvalid
  .m_axi_rready( {m02_axi_rready, m01_axi_rready, m00_axi_rready})    // output wire [2 : 0] m_axi_rready
);

axi_bram_ctrl_0 bram_ctrl_ins (
  .s_axi_aclk(   clk_50M),              // input wire s_axi_aclk
  .s_axi_aresetn(locked),               // input wire s_axi_aresetn
  .s_axi_awaddr( m00_axi_awaddr[14:0]), // input wire [14 : 0] s_axi_awaddr
  .s_axi_awprot( m00_axi_awprot),       // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(m00_axi_awvalid),      // input wire s_axi_awvalid
  .s_axi_awready(m00_axi_awready),      // output wire s_axi_awready
  .s_axi_wdata(  m00_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(  m00_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wvalid( m00_axi_wvalid),       // input wire s_axi_wvalid
  .s_axi_wready( m00_axi_wready),       // output wire s_axi_wready
  .s_axi_bresp(  m00_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid( m00_axi_bvalid),       // output wire s_axi_bvalid
  .s_axi_bready( m00_axi_bready),       // input wire s_axi_bready
  .s_axi_araddr( m00_axi_araddr[14:0]), // input wire [14 : 0] s_axi_araddr
  .s_axi_arprot( m00_axi_arprot),       // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(m00_axi_arvalid),      // input wire s_axi_arvalid
  .s_axi_arready(m00_axi_arready),      // output wire s_axi_arready
  .s_axi_rdata(  m00_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(  m00_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid( m00_axi_rvalid),       // output wire s_axi_rvalid
  .s_axi_rready( m00_axi_rready),       // input wire s_axi_rready
  .bram_rst_a( ),                       // output wire bram_rst_a
  .bram_clk_a(   bram_clk),             // output wire bram_clk_a
  .bram_en_a(    bram_ena),             // output wire bram_en_a
  .bram_we_a(    bram_wea),             // output wire [3 : 0] bram_we_a
  .bram_addr_a(  bram_addra),           // output wire [14 : 0] bram_addr_a
  .bram_wrdata_a(bram_dina),            // output wire [31 : 0] bram_wrdata_a
  .bram_rddata_a(bram_douta)            // input wire [31 : 0] bram_rddata_a
);  
*/

wire                gpio_axilite_awvalid,uart_axilite_awvalid;
wire                gpio_axilite_awready,uart_axilite_awready;
wire    [30: 0]     gpio_axilite_awaddr, uart_axilite_awaddr;
wire    [2 : 0]     gpio_axilite_awprot, uart_axilite_awprot; 
wire                gpio_axilite_wvalid, uart_axilite_wvalid;
wire                gpio_axilite_wready, uart_axilite_wready;
wire    [63: 0]     gpio_axilite_wdata,  uart_axilite_wdata;
wire    [7 : 0]     gpio_axilite_wstrb,  uart_axilite_wstrb;  
wire    [1 : 0]     gpio_axilite_bresp,  uart_axilite_bresp;
wire                gpio_axilite_bvalid, uart_axilite_bvalid;
wire                gpio_axilite_bready, uart_axilite_bready; 
wire                gpio_axilite_arvalid,uart_axilite_arvalid;
wire                gpio_axilite_arready,uart_axilite_arready;
wire    [30: 0]     gpio_axilite_araddr, uart_axilite_araddr;
wire    [2 : 0]     gpio_axilite_arprot, uart_axilite_arprot; 
wire                gpio_axilite_rvalid, uart_axilite_rvalid;
wire                gpio_axilite_rready, uart_axilite_rready;
wire    [63: 0]     gpio_axilite_rdata,  uart_axilite_rdata;
wire    [1 : 0]     gpio_axilite_rresp,  uart_axilite_rresp;

axi_protocol_converter_0 axi_protocol_converter_uart_ins (
  .aclk(clk_50M),                      // input wire aclk
  .aresetn(locked),                // input wire aresetn
  .s_axi_awaddr(  m02_axi_awaddr),      // input wire [30 : 0] s_axi_awaddr
  .s_axi_awlen(   m02_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(  m02_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst( m02_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(  m02_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache( m02_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(  m02_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(m02_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(   m02_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid( m02_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready( m02_axi_awready),    // output wire s_axi_awready
  .s_axi_wdata(   m02_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(   m02_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(   m02_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(  m02_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(  m02_axi_wready),      // output wire s_axi_wready
  .s_axi_bresp(   m02_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(  m02_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(  m02_axi_bready),      // input wire s_axi_bready
  .s_axi_araddr(  m02_axi_araddr),      // input wire [30 : 0] s_axi_araddr
  .s_axi_arlen(   m02_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(  m02_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst( m02_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(  m02_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache( m02_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(  m02_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(m02_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(   m02_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid( m02_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready( m02_axi_arready),    // output wire s_axi_arready
  .s_axi_rdata(   m02_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(   m02_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(   m02_axi_rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(  m02_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(  m02_axi_rready),      // input wire s_axi_rready
  .m_axi_awaddr( uart_axilite_awaddr),      // output wire [30 : 0] m_axi_awaddr
  .m_axi_awprot( uart_axilite_awprot),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(uart_axilite_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(uart_axilite_awready),    // input wire m_axi_awready
  .m_axi_wdata(  uart_axilite_wdata),        // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(  uart_axilite_wstrb),        // output wire [7 : 0] m_axi_wstrb
  .m_axi_wvalid( uart_axilite_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready( uart_axilite_wready),      // input wire m_axi_wready
  .m_axi_bresp(  uart_axilite_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid( uart_axilite_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready( uart_axilite_bready),      // output wire m_axi_bready
  .m_axi_araddr( uart_axilite_araddr),      // output wire [30 : 0] m_axi_araddr
  .m_axi_arprot( uart_axilite_arprot),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(uart_axilite_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(uart_axilite_arready),    // input wire m_axi_arready
  .m_axi_rdata(  uart_axilite_rdata),        // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(  uart_axilite_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rvalid( uart_axilite_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready( uart_axilite_rready)      // output wire m_axi_rready
);

axi_uartlite_0 uartlite_ins (
  .s_axi_aclk(   clk_50M),              // input wire s_axi_aclk
  .s_axi_aresetn(locked),               // input wire s_axi_aresetn
  .interrupt( ),                        // output wire interrupt
  .s_axi_awaddr( uart_axilite_awaddr[3:0]),  // input wire [3 : 0] s_axi_awaddr
  .s_axi_awvalid(uart_axilite_awvalid),      // input wire s_axi_awvalid
  .s_axi_awready(uart_axilite_awready),      // output wire s_axi_awready
  .s_axi_wdata(  uart_axilite_wdata[31:0]),  // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(  uart_axilite_wstrb[3:0]),        // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid( uart_axilite_wvalid),       // input wire s_axi_wvalid
  .s_axi_wready( uart_axilite_wready),       // output wire s_axi_wready
  .s_axi_bresp(  uart_axilite_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid( uart_axilite_bvalid),       // output wire s_axi_bvalid
  .s_axi_bready( uart_axilite_bready),       // input wire s_axi_bready
  .s_axi_araddr( uart_axilite_araddr[3:0]),  // input wire [3 : 0] s_axi_araddr
  .s_axi_arvalid(uart_axilite_arvalid),      // input wire s_axi_arvalid
  .s_axi_arready(uart_axilite_arready),      // output wire s_axi_arready
  .s_axi_rdata(  uart_axilite_rdata[31:0]),        // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(  uart_axilite_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid( uart_axilite_rvalid),       // output wire s_axi_rvalid
  .s_axi_rready( uart_axilite_rready),       // input wire s_axi_rready
  .rx(uart_rtl_0_rxd),                  // input wire rx
  .tx(uart_rtl_0_txd)                   // output wire tx
);
assign uart_axilite_rdata[63:32]=32'd0;

axi_protocol_converter_0 axi_protocol_converter_gpio_ins (
  .aclk(clk_50M),                      // input wire aclk
  .aresetn(locked),                // input wire aresetn
  .s_axi_awaddr(  m01_axi_awaddr),      // input wire [30 : 0] s_axi_awaddr
  .s_axi_awlen(   m01_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(  m01_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst( m01_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(  m01_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache( m01_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(  m01_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(m01_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(   m01_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid( m01_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready( m01_axi_awready),    // output wire s_axi_awready
  .s_axi_wdata(   m01_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(   m01_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(   m01_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(  m01_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(  m01_axi_wready),      // output wire s_axi_wready
  .s_axi_bresp(   m01_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(  m01_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(  m01_axi_bready),      // input wire s_axi_bready
  .s_axi_araddr(  m01_axi_araddr),      // input wire [30 : 0] s_axi_araddr
  .s_axi_arlen(   m01_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(  m01_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst( m01_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(  m01_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache( m01_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(  m01_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(m01_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(   m01_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid( m01_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready( m01_axi_arready),    // output wire s_axi_arready
  .s_axi_rdata(   m01_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(   m01_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(   m01_axi_rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(  m01_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(  m01_axi_rready),      // input wire s_axi_rready
  .m_axi_awaddr( gpio_axilite_awaddr),      // output wire [30 : 0] m_axi_awaddr
  .m_axi_awprot( gpio_axilite_awprot),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(gpio_axilite_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(gpio_axilite_awready),    // input wire m_axi_awready
  .m_axi_wdata(  gpio_axilite_wdata),        // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(  gpio_axilite_wstrb),        // output wire [7 : 0] m_axi_wstrb
  .m_axi_wvalid( gpio_axilite_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready( gpio_axilite_wready),      // input wire m_axi_wready
  .m_axi_bresp(  gpio_axilite_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid( gpio_axilite_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready( gpio_axilite_bready),      // output wire m_axi_bready
  .m_axi_araddr( gpio_axilite_araddr),      // output wire [30 : 0] m_axi_araddr
  .m_axi_arprot( gpio_axilite_arprot),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(gpio_axilite_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(gpio_axilite_arready),    // input wire m_axi_arready
  .m_axi_rdata(  gpio_axilite_rdata),        // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(  gpio_axilite_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rvalid( gpio_axilite_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready( gpio_axilite_rready)      // output wire m_axi_rready
);

axi_gpio_0 gpio_ins (
  .s_axi_aclk(   clk_50M),              // input wire s_axi_aclk
  .s_axi_aresetn(locked),               // input wire s_axi_aresetn
  .s_axi_awaddr( gpio_axilite_awaddr[8:0]),  // input wire [8 : 0] s_axi_awaddr
  .s_axi_awvalid(gpio_axilite_awvalid),      // input wire s_axi_awvalid
  .s_axi_awready(gpio_axilite_awready),      // output wire s_axi_awready
  .s_axi_wdata(  gpio_axilite_wdata[31:0]),        // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(  gpio_axilite_wstrb[3:0]),        // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid( gpio_axilite_wvalid),       // input wire s_axi_wvalid
  .s_axi_wready( gpio_axilite_wready),       // output wire s_axi_wready
  .s_axi_bresp(  gpio_axilite_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid( gpio_axilite_bvalid),       // output wire s_axi_bvalid
  .s_axi_bready( gpio_axilite_bready),       // input wire s_axi_bready
  .s_axi_araddr( gpio_axilite_araddr[8:0]),  // input wire [8 : 0] s_axi_araddr
  .s_axi_arvalid(gpio_axilite_arvalid),      // input wire s_axi_arvalid
  .s_axi_arready(gpio_axilite_arready),      // output wire s_axi_arready
  .s_axi_rdata(  gpio_axilite_rdata[31:0]),        // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(  gpio_axilite_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid( gpio_axilite_rvalid),       // output wire s_axi_rvalid
  .s_axi_rready( gpio_axilite_rready),       // input wire s_axi_rready
  .gpio_io_o(gpio_tri_o)                // output wire [0 : 0] gpio_io_o
);
assign gpio_axilite_rdata[63:32]= 32'd0;

endmodule
