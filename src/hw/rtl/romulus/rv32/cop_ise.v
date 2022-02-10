//Co-processor interface for romulus ISE
module cop_ise (
    cop_clk,
    cop_rst,
    cop_valid,
    cop_rdywr,
    cop_ready,
    cop_wait,
    cop_wr,
    cop_insn,   
    cop_rs1,   
    cop_rs2,           
    cop_rd    );
input           cop_clk, cop_rst;
input           cop_valid;
input 	        cop_rdywr;
output          cop_ready; 
output          cop_wait;
output          cop_wr;
input  [31:0]   cop_insn;
input  [31:0]   cop_rs1;
input  [31:0]   cop_rs2;
output [31:0]   cop_rd;  

parameter [1:0] ISE_V  = 2'b10;

localparam [6:0] CUSTOM_0 = 7'b0001011;
localparam [6:0] CUSTOM_1 = 7'b0101011;
localparam [6:0] CUSTOM_2 = 7'b1011011;
localparam [6:0] CUSTOM_3 = 7'b1111011; 

assign     cop_wait = 1'b0;
wire [6:0] funct    = cop_insn[31:25];

//decode romulus_ise
wire        romulus_ise_sel;
wire [31:0] romulus_ise_rd;
generate 
    if (ISE_V[1] == 1'b1) begin : ROMULUS_ISE_IMP
wire   op_rstep    = (funct[6:3] == 4'b0000) && (cop_insn[6:0] == CUSTOM_2);
wire   op_rc_upd   = (funct[6:3] == 4'b0000) && (cop_insn[6:0] == CUSTOM_0);
wire   op_tk_upd_0 = (funct[6:3] == 4'b0001) && (cop_insn[6:0] == CUSTOM_1);
wire   op_tk_upd_1 = (funct[6:3] == 4'b0010) && (cop_insn[6:0] == CUSTOM_1);
wire   op_rc_use_0 = (funct[6:3] == 4'b0010) && (cop_insn[6:0] == CUSTOM_0);
wire   op_rc_use_1 = (funct[6:3] == 4'b0011) && (cop_insn[6:0] == CUSTOM_0);
assign romulus_ise_sel   = op_rstep | op_rc_upd | op_tk_upd_0 | op_tk_upd_1 | op_rc_use_0 | op_rc_use_1;

romulus_ise romulus_ise_ins(
    .rs1(         cop_rs1     ),
    .rs2(         cop_rs2     ),
    .rd (      romulus_ise_rd ),
    .imm(         funct[2:0]  ),
    .op_rstep(    op_rstep    ),
    .op_rc_upd(   op_rc_upd   ),
    .op_rc_use_0( op_rc_use_0 ),
    .op_rc_use_1( op_rc_use_1 ),
    .op_tk_upd_0( op_tk_upd_0 ),
    .op_tk_upd_1( op_tk_upd_1 )
);
end else begin            : No_ROMULUS_ISE
assign  romulus_ise_sel =  1'b0;
assign  romulus_ise_rd  = 32'd0;
    end
endgenerate

wire [31:0] dout = {32{romulus_ise_sel}} & romulus_ise_rd ;

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && romulus_ise_sel;
assign cop_rd = dout;

endmodule


