//Co-processor interface for Xoodyak ISE
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

parameter [1:0] ISE_V  = 2'b11;

localparam [6:0] CUSTOM_0 = 7'b0001011;
localparam [6:0] CUSTOM_1 = 7'b0101011;
localparam [6:0] CUSTOM_2 = 7'b1011011;
localparam [6:0] CUSTOM_3 = 7'b1111011; 

assign     cop_wait = 1'b0;
wire [6:0] funct    = cop_insn[31:25];

//decode rv32b_ise
wire        rv32b_sel;
wire [31:0] rv32b_rd;  
generate 
    if (ISE_V[0] == 1'b1) begin : RB32B_IMP
wire   op_roli    = (funct[6:5] == 2'b00     ) && (cop_insn[6:0] == CUSTOM_0);
wire   op_andn    = (funct[6:0] == 7'b0000000) && (cop_insn[6:0] == CUSTOM_1);
assign rv32b_sel  = op_roli | op_andnot;
rv32b_ise rv32b_ins(
    .rs1(      cop_rs1  ),
    .rs2(      cop_rs2  ),
    .rd (      rv32b_rd ),
    .imm(     funct[4:0]),
    .op_roli(  op_roli  ),
    .op_andn(  op_andn  )
);
end else begin            : No_RB32B
assign  rv32b_sel =  1'b0;
assign  rv32b_rd  = 32'd0;  
    end
endgenerate

//decode xoodyak_ise
wire        xoodyak_ise_sel;
wire [31:0] xoodyak_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : XOODYAK_ISE_IMP
wire   op_xorrol     = (funct[6:0] == 7'b0100000) && (cop_insn[6:0] == CUSTOM_1);
assign xoodyak_ise_sel   = op_xorrol;

xoodyak_ise xoodyak_ise_ins(
    .rs1(       cop_rs1      ),
    .rs2(       cop_rs2      ),
    .rd (     xoodyak_ise_rd ),
    .imm(       funct[4:0]   ),
    .op_xorrol( op_xorrol    )
);
end else begin            : No_XOODYAK_ISE
assign  xoodyak_ise_sel =  1'b0;
assign  xoodyak_ise_rd  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{      rv32b_sel}} &       rv32b_rd | 
                   {32{xoodyak_ise_sel}} & xoodyak_ise_rd ;

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && (rv32b_sel | xoodyak_ise_sel);
assign cop_rd = dout;

endmodule


