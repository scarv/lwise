//Co-processor interface for Ascon ISE
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
    if (ISE_V[0] == 1'b1) begin : RB64B_IMP
wire   op_rori   = (funct[6:5] == 2'b10)      && (cop_insn[6:0] == CUSTOM_0);
wire   op_iorn   = (funct[6:0] == 7'b0000000) && (cop_insn[6:0] == CUSTOM_2);
wire   op_andn   = (funct[6:0] == 7'b0000001) && (cop_insn[6:0] == CUSTOM_2);
assign rv64b_sel = op_rori | op_iorn | op_andn;
rv64b_ise rv64b_ins(
    .rs1(      cop_rs1  ),
    .rs2(      cop_rs2  ),
    .rd (      rv64b_rd ),
    .imm(     funct[4:0]),
    .op_rori(  op_rori  ),
    .op_iorn(  op_iorn  ),
    .op_andn(  op_andn  )
);
end else begin            : No_RB64B
assign  rv64b_sel =  1'b0;
assign  rv64b_rd  = 64'd0;  
    end
endgenerate

//decode ascon_ise
wire        ascon_ise_sel;
wire [63:0] ascon_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : ASCON_ISE_IMP
wire   op_sigma       = (funct[6:5] == 2'b10) && (cop_insn[6:0] == CUSTOM_1);
assign ascon_ise_sel  = op_sigma;

ascon_ise ascon_ise_ins2(
    .rs1(      cop_rs1      ),
    .rs2(      cop_rs2      ),
    .rd (      ascon_ise_rd ),
    .imm(      funct[4:0]   ),
    .op_sigma( op_sigma     )
);
end else begin            : No_ASCON_ISE
assign  ascon_ise_sel =  1'b0;
assign  ascon_ise_rd  = 64'd0;  
    end
endgenerate

wire [63:0] dout = {64{     rv64b_sel }} &     rv64b_rd |
                   {64{ ascon_ise_sel }} & ascon_ise_rd ;

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && (rv64b_sel | ascon_ise_sel);
assign cop_rd = dout;

endmodule

