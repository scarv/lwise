`timescale 1 ps / 1 ps

module system_top_wrapper
   (
`ifdef Differential_clock_capable_pin
    k_clk_osc0_clk_p,       // input clk_in1_p
    k_clk_osc0_clk_n,       // input clk_in1_n
`else
	k_clk_osc0_clk,         // input clk_in1_p
`endif  
    k_resetb,
    uart_rtl_0_rxd,
    uart_rtl_0_txd,
    gpio_tri_o,
    gpio_led);

`ifdef Differential_clock_capable_pin
input k_clk_osc0_clk_p;     // input clk_in1_p
input k_clk_osc0_clk_n;     // input clk_in1_n
`else
input k_clk_osc0_clk;       // input clk_in1_p
`endif  

input k_resetb;
input uart_rtl_0_rxd;
output uart_rtl_0_txd;
output [0:0]gpio_tri_o;
output [0:0]gpio_led;

wire k_clk_osc0_clk_n;
wire k_clk_osc0_clk_p;
wire k_resetb;              //reset active hight
wire uart_rtl_0_rxd;
wire uart_rtl_0_txd;
wire [0:0] gpio_tri_o;
wire [0:0] gpio_led;

wire [1:0] gpio;

assign gpio_tri_o = gpio[0];
assign gpio_led   = gpio[0];
  
wire clk_50M;  
wire locked, sys_rstn;
wire rst_request;

assign sys_rstn = locked && (~rst_request);   //reset active low

int_reset int_reset_ins(
    .sys_clk(     clk_50M   ),
    .sys_rst(     k_resetb  ),
    .rst_detect(  gpio[1]    ),
    .rst_request( rst_request) );

clk_wiz_0 clk_gen
   (
    // Clock out ports
    .clk_out1(clk_50M),                // output clk_out1
    // Status and control signals
    .reset(k_resetb),   // input reset
    .locked(locked),                   // output locked
   // Clock in ports
`ifdef Differential_clock_capable_pin
    .clk_in1_p(k_clk_osc0_clk_p),      // input clk_in1_p
    .clk_in1_n(k_clk_osc0_clk_n));     // input clk_in1_n
`else
	.clk_in1(k_clk_osc0_clk));         // input clk_in1_p
`endif  

/*    

localparam MEM_DATA_WIDTH = 32;
localparam BRAM_ADDR_WIDTH = 17;     // 32 KB
localparam BRAM_LINE = 2 ** BRAM_ADDR_WIDTH  * 8 / MEM_DATA_WIDTH;
localparam BRAM_LINE_OFFSET = $clog2(MEM_DATA_WIDTH/8);

wire                       bram_clk;  
wire                       bram_ena;
wire [                3:0] bram_wea;
wire [BRAM_ADDR_WIDTH-1:0] bram_addra;
wire [               31:0] bram_dina;
wire [               31:0] bram_douta;
reg  [ MEM_DATA_WIDTH-1:0] ram [0 : BRAM_LINE-1];
initial $readmemh("prog.mem", ram);
reg [BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET] ram_addr_dly;

always@(posedge bram_clk) begin
    if(bram_ena) begin
        ram_addr_dly <= bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET];
        if(bram_wea[0]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][7 : 0] <= bram_dina[7 : 0];
        if(bram_wea[1]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][15: 8] <= bram_dina[15: 8];
        if(bram_wea[2]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][23:16] <= bram_dina[23:16];
        if(bram_wea[3]) ram[bram_addra[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][31:24] <= bram_dina[31:24];
    end
end
assign bram_douta = ram[ram_addr_dly];
//assign bram_douta[7 : 0] = ram[ram_addr_dly][31:24];
//assign bram_douta[15: 8] = ram[ram_addr_dly][23:16];
//assign bram_douta[23:16] = ram[ram_addr_dly][15: 8];
//assign bram_douta[31:24] = ram[ram_addr_dly][7 : 0]; 
*/ 
wire           mmio_axi_lite_awvalid;
wire           mmio_axi_lite_awready;
wire [31: 0]   mmio_axi_lite_awaddr;
wire [ 2: 0]   mmio_axi_lite_awprot; 
wire           mmio_axi_lite_wvalid;
wire           mmio_axi_lite_wready;
wire [31: 0]   mmio_axi_lite_wdata;
wire [ 3: 0]   mmio_axi_lite_wstrb;  
wire           mmio_axi_lite_bvalid;
wire           mmio_axi_lite_bready; 
wire           mmio_axi_lite_arvalid;
wire           mmio_axi_lite_arready;
wire [31: 0]   mmio_axi_lite_araddr;
wire [ 2: 0]   mmio_axi_lite_arprot; 
wire           mmio_axi_lite_rvalid;
wire           mmio_axi_lite_rready;
wire [31: 0]   mmio_axi_lite_rdata;
wire [ 1: 0]   mmio_axi_lite_bresp; 
wire [ 1: 0]   mmio_axi_lite_rresp;


wire [3:0]     mmio_axi4_0_aw_bits_id; 
wire [30:0]    mmio_axi4_0_aw_bits_addr; 
wire [7:0]     mmio_axi4_0_aw_bits_len;
wire [2:0]     mmio_axi4_0_aw_bits_size; 
wire [1:0]     mmio_axi4_0_aw_bits_burst;
wire           mmio_axi4_0_aw_bits_lock;
wire [3:0]     mmio_axi4_0_aw_bits_cache;
wire [2:0]     mmio_axi4_0_aw_bits_prot;
wire [3:0]     mmio_axi4_0_aw_bits_qos;

//[3:0]region
wire           mmio_axi4_0_aw_valid; 
wire           mmio_axi4_0_aw_ready; 

wire [31:0]    mmio_axi4_0_w_bits_data;
wire [3:0]     mmio_axi4_0_w_bits_strb;
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
wire           mmio_axi4_0_ar_bits_lock;
wire [3:0]     mmio_axi4_0_ar_bits_cache;
wire [2:0]     mmio_axi4_0_ar_bits_prot;
wire [3:0]     mmio_axi4_0_ar_bits_qos; 
// [3:0]region

wire           mmio_axi4_0_ar_valid;
wire           mmio_axi4_0_ar_ready; 

wire [3:0]     mmio_axi4_0_r_bits_id;
wire [31:0]    mmio_axi4_0_r_bits_data;
wire [1:0]     mmio_axi4_0_r_bits_resp;
wire           mmio_axi4_0_r_bits_last;
wire           mmio_axi4_0_r_valid;  
wire           mmio_axi4_0_r_ready; 


wire [3:0]     mem_axi4_0_aw_bits_id; 
wire [31:0]    mem_axi4_0_aw_bits_addr; 
wire [7:0]     mem_axi4_0_aw_bits_len;
wire [2:0]     mem_axi4_0_aw_bits_size; 
wire [1:0]     mem_axi4_0_aw_bits_burst;
wire           mem_axi4_0_aw_bits_lock;
wire [3:0]     mem_axi4_0_aw_bits_cache;
wire [2:0]     mem_axi4_0_aw_bits_prot;
wire [3:0]     mem_axi4_0_aw_bits_qos;
wire           mem_axi4_0_aw_valid; 
wire           mem_axi4_0_aw_ready; 

wire [31:0]    mem_axi4_0_w_bits_data;
wire [3:0]     mem_axi4_0_w_bits_strb;
wire           mem_axi4_0_w_bits_last;
wire           mem_axi4_0_w_valid;
wire           mem_axi4_0_w_ready; 

wire [3:0]     mem_axi4_0_b_bits_id;
wire [1:0]     mem_axi4_0_b_bits_resp;
wire           mem_axi4_0_b_valid;  
wire           mem_axi4_0_b_ready;

wire [3:0]     mem_axi4_0_ar_bits_id;
wire [31:0]    mem_axi4_0_ar_bits_addr;
wire [7:0]     mem_axi4_0_ar_bits_len;
wire [2:0]     mem_axi4_0_ar_bits_size;
wire [1:0]     mem_axi4_0_ar_bits_burst; 
wire           mem_axi4_0_ar_bits_lock;
wire [3:0]     mem_axi4_0_ar_bits_cache;
wire [2:0]     mem_axi4_0_ar_bits_prot;
wire [3:0]     mem_axi4_0_ar_bits_qos; 
wire           mem_axi4_0_ar_valid;
wire           mem_axi4_0_ar_ready; 

wire [3:0]     mem_axi4_0_r_bits_id;
wire [31:0]    mem_axi4_0_r_bits_data;
wire [1:0]     mem_axi4_0_r_bits_resp;
wire           mem_axi4_0_r_bits_last;
wire           mem_axi4_0_r_valid;  
wire           mem_axi4_0_r_ready;

axi_bram_ctrl_0 bram_ctrl_ins (
  .s_axi_aclk(      clk_50M),                       // input wire s_axi_aclk
  .s_axi_aresetn(   sys_rstn),                        // input wire s_axi_aresetn
  .s_axi_awid(      mem_axi4_0_aw_bits_id),         // input wire [3 : 0] s_axi_awid
  .s_axi_awaddr(    mem_axi4_0_aw_bits_addr[18:0]), // input wire [18 : 0] s_axi_awaddr
  .s_axi_awlen(     mem_axi4_0_aw_bits_len),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(    mem_axi4_0_aw_bits_size),       // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(   mem_axi4_0_aw_bits_burst),      // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(    mem_axi4_0_aw_bits_lock),       // input wire s_axi_awlock
  .s_axi_awcache(   mem_axi4_0_aw_bits_cache),      // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(    mem_axi4_0_aw_bits_prot),       // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(   mem_axi4_0_aw_valid),           // input wire s_axi_awvalid
  .s_axi_awready(   mem_axi4_0_aw_ready),           // output wire s_axi_awready
  .s_axi_wdata(     mem_axi4_0_w_bits_data),        // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(     mem_axi4_0_w_bits_strb),        // input wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(     mem_axi4_0_w_bits_last),        // input wire s_axi_wlast
  .s_axi_wvalid(    mem_axi4_0_w_valid),            // input wire s_axi_wvalid
  .s_axi_wready(    mem_axi4_0_w_ready),            // output wire s_axi_wready
  .s_axi_bid(       mem_axi4_0_b_bits_id),          // output wire [3 : 0] s_axi_bid
  .s_axi_bresp(     mem_axi4_0_b_bits_resp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(    mem_axi4_0_b_valid),            // output wire s_axi_bvalid
  .s_axi_bready(    mem_axi4_0_b_ready),            // input wire s_axi_bready
  .s_axi_arid(      mem_axi4_0_ar_bits_id),         // input wire [3 : 0] s_axi_arid
  .s_axi_araddr(    mem_axi4_0_ar_bits_addr[18:0]), // input wire [18 : 0] s_axi_araddr
  .s_axi_arlen(     mem_axi4_0_ar_bits_len),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(    mem_axi4_0_ar_bits_size),       // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(   mem_axi4_0_ar_bits_burst),      // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(    mem_axi4_0_ar_bits_lock),       // input wire s_axi_arlock
  .s_axi_arcache(   mem_axi4_0_ar_bits_cache),      // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(    mem_axi4_0_ar_bits_prot),       // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(   mem_axi4_0_ar_valid),           // input wire s_axi_arvalid
  .s_axi_arready(   mem_axi4_0_ar_ready),           // output wire s_axi_arready
  .s_axi_rid(       mem_axi4_0_r_bits_id),          // output wire [3 : 0] s_axi_rid
  .s_axi_rdata(     mem_axi4_0_r_bits_data),        // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(     mem_axi4_0_r_bits_resp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(     mem_axi4_0_r_bits_last),        // output wire s_axi_rlast
  .s_axi_rvalid(    mem_axi4_0_r_valid),            // output wire s_axi_rvalid
  .s_axi_rready(    mem_axi4_0_r_ready)             // input wire s_axi_rready
/*  .bram_rst_a( ),                                   // output wire bram_rst_a
  .bram_clk_a(   bram_clk),                         // output wire bram_clk_a
  .bram_en_a(    bram_ena),                         // output wire bram_en_a
  .bram_we_a(    bram_wea),                         // output wire [3 : 0] bram_we_a
  .bram_addr_a(  bram_addra),                       // output wire [16 : 0] bram_addr_a
  .bram_wrdata_a(bram_dina),                        // output wire [31 : 0] bram_wrdata_a
  .bram_rddata_a(bram_douta)                        // input wire [31 : 0] bram_rddata_a
*/
);

SCARVRocketFPGASystem RocketSystem_Ins ( 
      .clock(clk_50M),
      .reset(~sys_rstn),
      .debug_systemjtag_jtag_TCK( 1'b0),            // input
      .debug_systemjtag_jtag_TMS( 1'b0),            // input
      .debug_systemjtag_jtag_TDI( 1'b0),            // input
      .debug_systemjtag_jtag_TDO_data(),            // output
      .debug_systemjtag_jtag_TDO_driven(),          // output
      .debug_systemjtag_reset(    k_resetb),        // input
      .debug_systemjtag_mfr_id(11'd0), 
      .debug_systemjtag_part_number(16'd0),
      .debug_systemjtag_version(4'd0),
      .debug_ndreset(),                             // output
      .debug_dmactive(), 
      .interrupts(2'b00),

      .mem_axi4_0_aw_ready(         mem_axi4_0_aw_ready), 
      .mem_axi4_0_aw_valid(         mem_axi4_0_aw_valid), 
      .mem_axi4_0_aw_bits_id(       mem_axi4_0_aw_bits_id), 
      .mem_axi4_0_aw_bits_addr(     mem_axi4_0_aw_bits_addr), 
      .mem_axi4_0_aw_bits_len(      mem_axi4_0_aw_bits_len), 
      .mem_axi4_0_aw_bits_size(     mem_axi4_0_aw_bits_size), 
      .mem_axi4_0_aw_bits_burst(    mem_axi4_0_aw_bits_burst), 
      .mem_axi4_0_aw_bits_lock(     mem_axi4_0_aw_bits_lock), 
      .mem_axi4_0_aw_bits_cache(    mem_axi4_0_aw_bits_cache), 
      .mem_axi4_0_aw_bits_prot(     mem_axi4_0_aw_bits_prot), 
      .mem_axi4_0_aw_bits_qos(      mem_axi4_0_aw_bits_qos), 
      .mem_axi4_0_w_ready(          mem_axi4_0_w_ready), 
      .mem_axi4_0_w_valid(          mem_axi4_0_w_valid), 
      .mem_axi4_0_w_bits_data(      mem_axi4_0_w_bits_data), 
      .mem_axi4_0_w_bits_strb(      mem_axi4_0_w_bits_strb), 
      .mem_axi4_0_w_bits_last(      mem_axi4_0_w_bits_last), 
      .mem_axi4_0_b_ready(          mem_axi4_0_b_ready), 
      .mem_axi4_0_b_valid(          mem_axi4_0_b_valid), 
      .mem_axi4_0_b_bits_id(        mem_axi4_0_b_bits_id), 
      .mem_axi4_0_b_bits_resp(      mem_axi4_0_b_bits_resp), 
      .mem_axi4_0_ar_ready(         mem_axi4_0_ar_ready), 
      .mem_axi4_0_ar_valid(         mem_axi4_0_ar_valid), 
      .mem_axi4_0_ar_bits_id(       mem_axi4_0_ar_bits_id), 
      .mem_axi4_0_ar_bits_addr(     mem_axi4_0_ar_bits_addr), 
      .mem_axi4_0_ar_bits_len(      mem_axi4_0_ar_bits_len), 
      .mem_axi4_0_ar_bits_size(     mem_axi4_0_ar_bits_size), 
      .mem_axi4_0_ar_bits_burst(    mem_axi4_0_ar_bits_burst), 
      .mem_axi4_0_ar_bits_lock(     mem_axi4_0_ar_bits_lock), 
      .mem_axi4_0_ar_bits_cache(    mem_axi4_0_ar_bits_cache), 
      .mem_axi4_0_ar_bits_prot(     mem_axi4_0_ar_bits_prot), 
      .mem_axi4_0_ar_bits_qos(      mem_axi4_0_ar_bits_qos), 
      .mem_axi4_0_r_ready(          mem_axi4_0_r_ready), 
      .mem_axi4_0_r_valid(          mem_axi4_0_r_valid), 
      .mem_axi4_0_r_bits_id(        mem_axi4_0_r_bits_id), 
      .mem_axi4_0_r_bits_data(      mem_axi4_0_r_bits_data), 
      .mem_axi4_0_r_bits_resp(      mem_axi4_0_r_bits_resp), 
      .mem_axi4_0_r_bits_last(      mem_axi4_0_r_bits_last),
 
      .mmio_axi4_0_aw_ready(        mmio_axi4_0_aw_ready),
      .mmio_axi4_0_aw_valid(        mmio_axi4_0_aw_valid),
      .mmio_axi4_0_aw_bits_id(      mmio_axi4_0_aw_bits_id),
      .mmio_axi4_0_aw_bits_addr(    mmio_axi4_0_aw_bits_addr),
      .mmio_axi4_0_aw_bits_len(     mmio_axi4_0_aw_bits_len),
      .mmio_axi4_0_aw_bits_size(    mmio_axi4_0_aw_bits_size),
      .mmio_axi4_0_aw_bits_burst(   mmio_axi4_0_aw_bits_burst),
      .mmio_axi4_0_aw_bits_lock(    mmio_axi4_0_aw_bits_lock),
      .mmio_axi4_0_aw_bits_cache(   mmio_axi4_0_aw_bits_cache),
      .mmio_axi4_0_aw_bits_prot(    mmio_axi4_0_aw_bits_prot),
      .mmio_axi4_0_aw_bits_qos(     mmio_axi4_0_aw_bits_qos),     
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
      .mmio_axi4_0_ar_bits_lock(    mmio_axi4_0_ar_bits_lock),
      .mmio_axi4_0_ar_bits_cache(   mmio_axi4_0_ar_bits_cache),
      .mmio_axi4_0_ar_bits_prot(    mmio_axi4_0_ar_bits_prot),
      .mmio_axi4_0_ar_bits_qos(     mmio_axi4_0_ar_bits_qos),     
      .mmio_axi4_0_r_ready(         mmio_axi4_0_r_ready),
      .mmio_axi4_0_r_valid(         mmio_axi4_0_r_valid),
      .mmio_axi4_0_r_bits_id(       mmio_axi4_0_r_bits_id),
      .mmio_axi4_0_r_bits_data(     mmio_axi4_0_r_bits_data),
      .mmio_axi4_0_r_bits_resp(     mmio_axi4_0_r_bits_resp),
      .mmio_axi4_0_r_bits_last(     mmio_axi4_0_r_bits_last)
    );

axi_protocol_converter_0 axi_protocol_converter_ins (
   .aclk(           clk_50M ),                  // input wire aclk
   .aresetn(        sys_rstn),                  // input wire aresetn
   .s_axi_awid(     mmio_axi4_0_aw_bits_id),    // input wire [3 : 0] s_axi_awid
   .s_axi_awaddr(   mmio_axi4_0_aw_bits_addr),  // input wire [30 : 0] s_axi_awaddr
   .s_axi_awlen(    mmio_axi4_0_aw_bits_len),   // input wire [7 : 0] s_axi_awlen
   .s_axi_awsize(   mmio_axi4_0_aw_bits_size),  // input wire [2 : 0] s_axi_awsize
   .s_axi_awburst(  mmio_axi4_0_aw_bits_burst), // input wire [1 : 0] s_axi_awburst
   .s_axi_awlock(   mmio_axi4_0_aw_bits_lock),  // unlock               input wire [0 : 0] s_axi_awlock
   .s_axi_awcache(  mmio_axi4_0_aw_bits_cache), // device unbufferable  input wire [3 : 0] s_axi_awcache
   .s_axi_awprot(   mmio_axi4_0_aw_bits_prot),  // input wire [2 : 0] s_axi_awprot
   .s_axi_awqos(    mmio_axi4_0_aw_bits_qos),   // input wire [3 : 0] s_axi_awqos
   .s_axi_awregion( 4'b0000),                   // input wire [3 : 0] s_axi_awregion
   .s_axi_awvalid(  mmio_axi4_0_aw_valid),     // input wire s_axi_awvalid
   .s_axi_awready(  mmio_axi4_0_aw_ready),     // output wire s_axi_awready
   .s_axi_wdata(    mmio_axi4_0_w_bits_data),  // input wire [31 : 0] s_axi_wdata
   .s_axi_wstrb(    mmio_axi4_0_w_bits_strb),  // input wire [3 : 0] s_axi_wstrb
   .s_axi_wlast(    mmio_axi4_0_w_bits_last),  // input wire s_axi_wlast
   .s_axi_wvalid(   mmio_axi4_0_w_valid),      // input wire s_axi_wvalid
   .s_axi_wready(   mmio_axi4_0_w_ready),      // output wire s_axi_wready
   .s_axi_bid(      mmio_axi4_0_b_bits_id),    // output wire [3 : 0] s_axi_bid
   .s_axi_bresp(    mmio_axi4_0_b_bits_resp),  // output wire [1 : 0] s_axi_bresp
   .s_axi_bvalid(   mmio_axi4_0_b_valid),      // output wire s_axi_bvalid
   .s_axi_bready(   mmio_axi4_0_b_ready),      // input wire s_axi_bready
   .s_axi_arid(     mmio_axi4_0_ar_bits_id),   // input wire [3 : 0] s_axi_arid
   .s_axi_araddr(   mmio_axi4_0_ar_bits_addr), // input wire [30 : 0] s_axi_araddr
   .s_axi_arlen(    mmio_axi4_0_ar_bits_len),  // input wire [7 : 0] s_axi_arlen
   .s_axi_arsize(   mmio_axi4_0_ar_bits_size), // input wire [2 : 0] s_axi_arsize
   .s_axi_arburst(  mmio_axi4_0_ar_bits_burst),// input wire [1 : 0] s_axi_arburst
   .s_axi_arlock(   mmio_axi4_0_ar_bits_lock), // input wire [0 : 0] s_axi_arlock
   .s_axi_arcache(  mmio_axi4_0_ar_bits_cache),// input wire [3 : 0] s_axi_arcache
   .s_axi_arprot(   mmio_axi4_0_ar_bits_prot),// input wire [2 : 0] s_axi_arprot
   .s_axi_arqos(    mmio_axi4_0_ar_bits_qos), // input wire [3 : 0] s_axi_arqos
   .s_axi_arregion( 4'b0000),                 // input wire [3 : 0] s_axi_arregion
   .s_axi_arvalid(  mmio_axi4_0_ar_valid),    // input wire s_axi_arvalid
   .s_axi_arready(  mmio_axi4_0_ar_ready),    // output wire s_axi_arready
   .s_axi_rid(      mmio_axi4_0_r_bits_id),   // output wire [3 : 0] s_axi_rid
   .s_axi_rdata(    mmio_axi4_0_r_bits_data), // output wire [31 : 0] s_axi_rdata
   .s_axi_rresp(    mmio_axi4_0_r_bits_resp), // output wire [1 : 0] s_axi_rresp
   .s_axi_rlast(    mmio_axi4_0_r_bits_last), // output wire s_axi_rlast
   .s_axi_rvalid(   mmio_axi4_0_r_valid),     // output wire s_axi_rvalid
   .s_axi_rready(   mmio_axi4_0_r_ready),     // input wire s_axi_rready
 
   .m_axi_awaddr(    mmio_axi_lite_awaddr),   // output wire [31 : 0] m_axi_awaddr
   .m_axi_awprot(    mmio_axi_lite_awprot),   // output wire [2 : 0] m_axi_awprot
   .m_axi_awvalid(   mmio_axi_lite_awvalid),  // output wire m_axi_awvalid
   .m_axi_awready(   mmio_axi_lite_awready),  // input wire m_axi_awready
   .m_axi_wdata(     mmio_axi_lite_wdata),    // output wire [31 : 0] m_axi_wdata
   .m_axi_wstrb(     mmio_axi_lite_wstrb),    // output wire [3 : 0] m_axi_wstrb
   .m_axi_wvalid(    mmio_axi_lite_wvalid),   // output wire m_axi_wvalid
   .m_axi_wready(    mmio_axi_lite_wready),   // input wire m_axi_wready
   .m_axi_bresp(     mmio_axi_lite_bresp),    // input wire [1 : 0] m_axi_bresp
   .m_axi_bvalid(    mmio_axi_lite_bvalid),   // input wire m_axi_bvalid
   .m_axi_bready(    mmio_axi_lite_bready),   // output wire m_axi_bready
   .m_axi_araddr(    mmio_axi_lite_araddr),   // output wire [31 : 0] m_axi_araddr
   .m_axi_arprot(    mmio_axi_lite_arprot),   // output wire [2 : 0] m_axi_arprot
   .m_axi_arvalid(   mmio_axi_lite_arvalid),  // output wire m_axi_arvalid
   .m_axi_arready(   mmio_axi_lite_arready),  // input wire m_axi_arready
   .m_axi_rdata(     mmio_axi_lite_rdata),    // input wire [31 : 0] m_axi_rdata
   .m_axi_rresp(     mmio_axi_lite_rresp),    // input wire [1 : 0] m_axi_rresp
   .m_axi_rvalid(    mmio_axi_lite_rvalid),   // input wire m_axi_rvalid
   .m_axi_rready(    mmio_axi_lite_rready)    // output wire m_axi_rready
 );

    
wire                m00_axi_awvalid,m01_axi_awvalid;
wire                m00_axi_awready,m01_axi_awready;
wire    [31: 0]     m00_axi_awaddr, m01_axi_awaddr;
wire    [2 : 0]     m00_axi_awprot, m01_axi_awprot; 
wire                m00_axi_wvalid, m01_axi_wvalid;
wire                m00_axi_wready, m01_axi_wready;
wire    [31: 0]     m00_axi_wdata,  m01_axi_wdata;
wire    [3 : 0]     m00_axi_wstrb,  m01_axi_wstrb;  
wire    [1 : 0]     m00_axi_bresp,  m01_axi_bresp;
wire                m00_axi_bvalid, m01_axi_bvalid;
wire                m00_axi_bready, m01_axi_bready;
wire                m00_axi_arvalid,m01_axi_arvalid;
wire                m00_axi_arready,m01_axi_arready;
wire    [31: 0]     m00_axi_araddr, m01_axi_araddr;
wire    [2 : 0]     m00_axi_arprot, m01_axi_arprot; 
wire                m00_axi_rvalid, m01_axi_rvalid;
wire                m00_axi_rready, m01_axi_rready;
wire    [31: 0]     m00_axi_rdata,  m01_axi_rdata;
wire    [1 : 0]     m00_axi_rresp,  m01_axi_rresp;
axi_crossbar_0 axi_crossbar_ins (
  .aclk(            clk_50M),                 // input wire aclk
  .aresetn(         sys_rstn),                // input wire aresetn
  .s_axi_awaddr(    mmio_axi_lite_awaddr),    // input wire [31 : 0] s_axi_awaddr
  .s_axi_awprot(    mmio_axi_lite_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(   mmio_axi_lite_awvalid),   // input wire [0 : 0] s_axi_awvalid
  .s_axi_awready(   mmio_axi_lite_awready),   // output wire [0 : 0] s_axi_awready
  .s_axi_wdata(     mmio_axi_lite_wdata),     // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(     mmio_axi_lite_wstrb),     // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(    mmio_axi_lite_wvalid),    // input wire [0 : 0] s_axi_wvalid
  .s_axi_wready(    mmio_axi_lite_wready),    // output wire [0 : 0] s_axi_wready
  .s_axi_bresp(     mmio_axi_lite_bresp),     // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(    mmio_axi_lite_bvalid),    // output wire [0 : 0] s_axi_bvalid
  .s_axi_bready(    mmio_axi_lite_bready),    // input wire [0 : 0] s_axi_bready
  .s_axi_araddr(    mmio_axi_lite_araddr),    // input wire [31 : 0] s_axi_araddr
  .s_axi_arprot(    mmio_axi_lite_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(   mmio_axi_lite_arvalid),   // input wire [0 : 0] s_axi_arvalid
  .s_axi_arready(   mmio_axi_lite_arready),   // output wire [0 : 0] s_axi_arready
  .s_axi_rdata(     mmio_axi_lite_rdata),     // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(     mmio_axi_lite_rresp),     // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(    mmio_axi_lite_rvalid),    // output wire [0 : 0] s_axi_rvalid
  .s_axi_rready(    mmio_axi_lite_rready),    // input wire [0 : 0] s_axi_rready
  .m_axi_awaddr( {m01_axi_awaddr, m00_axi_awaddr}),    // output wire [63 : 0] m_axi_awaddr
  .m_axi_awprot( {m01_axi_awprot, m00_axi_awprot}),    // output wire [5 : 0] m_axi_awprot
  .m_axi_awvalid({m01_axi_awvalid,m00_axi_awvalid}),   // output wire [1 : 0] m_axi_awvalid
  .m_axi_awready({m01_axi_awready,m00_axi_awready}),   // input wire [1 : 0] m_axi_awready
  .m_axi_wdata(  {m01_axi_wdata,  m00_axi_wdata}),     // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(  {m01_axi_wstrb,  m00_axi_wstrb}),     // output wire [7 : 0] m_axi_wstrb
  .m_axi_wvalid( {m01_axi_wvalid, m00_axi_wvalid}),    // output wire [1 : 0] m_axi_wvalid
  .m_axi_wready( {m01_axi_wready, m00_axi_wready}),    // input wire [1 : 0] m_axi_wready
  .m_axi_bresp(  {m01_axi_bresp,  m00_axi_bresp}),     // input wire [3 : 0] m_axi_bresp
  .m_axi_bvalid( {m01_axi_bvalid, m00_axi_bvalid}),    // input wire [1 : 0] m_axi_bvalid
  .m_axi_bready( {m01_axi_bready, m00_axi_bready}),    // output wire [1 : 0] m_axi_bready
  .m_axi_araddr( {m01_axi_araddr, m00_axi_araddr}),    // output wire [63 : 0] m_axi_araddr
  .m_axi_arprot( {m01_axi_arprot, m00_axi_arprot}),    // output wire [5 : 0] m_axi_arprot
  .m_axi_arvalid({m01_axi_arvalid,m00_axi_arvalid}),   // output wire [1 : 0] m_axi_arvalid
  .m_axi_arready({m01_axi_arready,m00_axi_arready}),   // input wire [1 : 0] m_axi_arready
  .m_axi_rdata(  {m01_axi_rdata,  m00_axi_rdata}),     // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(  {m01_axi_rresp,  m00_axi_rresp}),     // input wire [3 : 0] m_axi_rresp
  .m_axi_rvalid( {m01_axi_rvalid, m00_axi_rvalid}),    // input wire [1 : 0] m_axi_rvalid
  .m_axi_rready( {m01_axi_rready, m00_axi_rready})     // output wire [1 : 0] m_axi_rready
);

axi_uartlite_0 uartlite_ins (
  .s_axi_aclk(   clk_50M),              // input wire s_axi_aclk
  .s_axi_aresetn(sys_rstn),             // input wire s_axi_aresetn
  .interrupt( ),                        // output wire interrupt
  .s_axi_awaddr( m01_axi_awaddr[3:0]),  // input wire [3 : 0] s_axi_awaddr
  .s_axi_awvalid(m01_axi_awvalid),      // input wire s_axi_awvalid
  .s_axi_awready(m01_axi_awready),      // output wire s_axi_awready
  .s_axi_wdata(  m01_axi_wdata),        // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(  m01_axi_wstrb),        // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid( m01_axi_wvalid),       // input wire s_axi_wvalid
  .s_axi_wready( m01_axi_wready),       // output wire s_axi_wready
  .s_axi_bresp(  m01_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid( m01_axi_bvalid),       // output wire s_axi_bvalid
  .s_axi_bready( m01_axi_bready),       // input wire s_axi_bready
  .s_axi_araddr( m01_axi_araddr[3:0]),  // input wire [3 : 0] s_axi_araddr
  .s_axi_arvalid(m01_axi_arvalid),      // input wire s_axi_arvalid
  .s_axi_arready(m01_axi_arready),      // output wire s_axi_arready
  .s_axi_rdata(  m01_axi_rdata),        // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(  m01_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid( m01_axi_rvalid),       // output wire s_axi_rvalid
  .s_axi_rready( m01_axi_rready),       // input wire s_axi_rready
  .rx(uart_rtl_0_rxd),                  // input wire rx
  .tx(uart_rtl_0_txd)                   // output wire tx
);

axi_gpio_0 gpio_ins (
  .s_axi_aclk(   clk_50M),              // input wire s_axi_aclk
  .s_axi_aresetn(sys_rstn),             // input wire s_axi_aresetn
  .s_axi_awaddr( m00_axi_awaddr[8:0]),  // input wire [8 : 0] s_axi_awaddr
  .s_axi_awvalid(m00_axi_awvalid),      // input wire s_axi_awvalid
  .s_axi_awready(m00_axi_awready),      // output wire s_axi_awready
  .s_axi_wdata(  m00_axi_wdata),        // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(  m00_axi_wstrb),        // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid( m00_axi_wvalid),       // input wire s_axi_wvalid
  .s_axi_wready( m00_axi_wready),       // output wire s_axi_wready
  .s_axi_bresp(  m00_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid( m00_axi_bvalid),       // output wire s_axi_bvalid
  .s_axi_bready( m00_axi_bready),       // input wire s_axi_bready
  .s_axi_araddr( m00_axi_araddr[8:0]),  // input wire [8 : 0] s_axi_araddr
  .s_axi_arvalid(m00_axi_arvalid),      // input wire s_axi_arvalid
  .s_axi_arready(m00_axi_arready),      // output wire s_axi_arready
  .s_axi_rdata(  m00_axi_rdata),        // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(  m00_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid( m00_axi_rvalid),       // output wire s_axi_rvalid
  .s_axi_rready( m00_axi_rready),       // input wire s_axi_rready
  .gpio_io_o(gpio)                      // output wire [1 : 0] gpio_io_o
);

endmodule


module int_reset (
    sys_clk,
    sys_rst,
    rst_detect,
    rst_request );
input           sys_clk, sys_rst;
input 	        rst_detect;
output          rst_request; 

reg signal_latch;
always @(posedge sys_clk or posedge sys_rst) begin
    if (sys_rst)  signal_latch <=1'b1;
    else          signal_latch <=rst_detect;
end

assign  rst_request = (~signal_latch) && rst_detect;
endmodule

