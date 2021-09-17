//xoodyak Instruction Set Extension
module xalu_ise (
    ise_clk,
    ise_rst,
    ise_fn,
    ise_imm,   
    ise_in1,   
    ise_in2,  
    ise_val,
    ise_oval,         
    ise_out    );
input           ise_clk, ise_rst;
input  [ 4:0]   ise_fn;
input  [ 6:0]   ise_imm;
input  [31:0]   ise_in1;
input  [31:0]   ise_in2;
input           ise_val; 
output          ise_oval;
output [31:0]   ise_out;  

parameter [1:0] ISE_V  = 2'b11;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode rv32b_ise
wire        rv32b_sel;
wire [31:0] rv32b_rd;  
generate 
    if (ISE_V[0] == 1'b1) begin : RB32B_IMP
wire   op_roli    = (funct[6:5] == 2'b00     ) && (ise_fn[6:0] == CUSTOM_0);
wire   op_andn    = (funct[6:0] == 7'b0000000) && (ise_fn[6:0] == CUSTOM_1);
assign rv32b_sel  = op_roli | op_andnot;
rv32b_ise rv32b_ins(
    .rs1(      cop_rs1  ),
    .rs2(      cop_rs2  ),
    .rd (      rv32b_rd ),
    .imm(     funct[4:0]),
    .op_roli(  op_roli  ),
    .op_andnot(op_andn  )
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
wire   op_xorrol     = (funct[6:0] == 7'b0100000) && (ise_fn[6:0] == CUSTOM_1);
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

assign ise_oval = ise_val && (rv32b_sel | xoodyak_ise_sel);
assign ise_out  = dout;

endmodule


