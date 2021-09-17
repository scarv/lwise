//Co-processor interface for Jambu ISE
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
input  [63:0]   cop_rs1;
input  [63:0]   cop_rs2;
output [63:0]   cop_rd;  

parameter [1:0] ISE_V  = 2'b11;

localparam [6:0] CUSTOM_0 = 7'b0001011;
localparam [6:0] CUSTOM_1 = 7'b0101011;
localparam [6:0] CUSTOM_2 = 7'b1011011;
localparam [6:0] CUSTOM_3 = 7'b1111011; 

assign     cop_wait = 1'b0;
wire [6:0] funct    = cop_insn[31:25];

//decode rv64b_ise
wire        rv64b_sel;
wire [63:0] rv64b_rd;  
generate 
    if (ISE_V[0] == 1'b1) begin : RB64B
wire   op_roriw  = (funct[6:5] == 2'b01)      && (cop_insn[6:0] == CUSTOM_0);
wire   op_rori   = (funct[6:5] == 2'b00)      && (cop_insn[6:0] == CUSTOM_0);
wire   op_xnor   = (funct[6:0] == 7'b0000000) && (cop_insn[6:0] == CUSTOM_2);
wire   op_pack   = (funct[6:0] == 7'b0000001) && (cop_insn[6:0] == CUSTOM_2);
wire   op_packu  = (funct[6:0] == 7'b0000010) && (cop_insn[6:0] == CUSTOM_2);

assign rv64b_sel = op_roriw | op_rori | op_xnor | op_pack | op_packu;
rv64b_ise rv64b_ins(
    .rs1(      ise_in1  ),
    .rs2(      ise_in2  ),
    .rd (      rv64b_rd ),
    .imm(     funct[4:0]),
    .op_roriw( op_roriw ),
    .op_rori(  op_rori  ),
    .op_xnor(  op_xnor  ),
    .op_pack(  op_pack  ),
    .op_packu( op_packu )
);
end else begin            : No_RB64B
assign  rv64b_sel =  1'b0; 
assign  rv64b_rd  = 64'd0;  
    end
endgenerate

//decode jambu_ise
wire        jambu_ise_sel;
wire [63:0] jambu_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : JAMBU_ISE_IMP
wire   op_block_0    = (funct[6:0] == 7'b0100000) && (cop_insn[6:0] == CUSTOM_3);
wire   op_block_1    = (funct[6:0] == 7'b0100001) && (cop_insn[6:0] == CUSTOM_3);
wire   op_block_2    = (funct[6:0] == 7'b0100010) && (cop_insn[6:0] == CUSTOM_3);
wire   op_block_3    = (funct[6:0] == 7'b0100011) && (cop_insn[6:0] == CUSTOM_3);
assign jambu_ise_sel = op_block_0 | op_block_1 | op_block_2 | op_block_3;

jambu_ise jambu_ise_ins2(
    .rs1(        ise_in1      ),
    .rs2(        ise_in2      ),
    .rd (        jambu_ise_rd ),
    .op_block_0( op_block_0   ),
    .op_block_1( op_block_1   ),
    .op_block_2( op_block_2   ),
    .op_block_3( op_block_3   )
);
end else begin            : No_JAMBU_ISE
assign  jambu_ise_sel =  1'b0;
assign  jambu_ise_rd  = 64'd0;  
    end
endgenerate

wire [63:0] dout = {64{     rv64b_sel }} &     rv64b_rd |
                   {64{ ascon_ise_sel }} & ascon_ise_rd ;

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && (rv64b_sel | ascon_ise_sel);
assign cop_rd = dout;

endmodule

