//Jambu Instruction Set Extension
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

parameter [2:0] ISE_V  = 3'b111;

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
wire   op_rori     = ise_val && (funct[6:5] == 2'b00)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_xnor     = ise_val && (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_2);

assign rv32b_sel = op_rori | op_xnor;
rv32b_ise rv32b_ins(
    .rs1(      ise_in1  ),
    .rs2(      ise_in2  ),
    .rd (      rv32b_rd ),
    .imm(     funct[4:0]),
    .op_rori(  op_rori  ),
    .op_xnor(  op_xnor  )
);
end else begin            : No_RB32B
assign  rv32b_sel =  1'b0;
assign  rv32b_rd  = 32'd0;  
    end
endgenerate
 
//decode jambu_ise_v2
wire        jambu_ise_v2_sel;
wire [31:0] jambu_ise_v2_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : JAMBU_ISE_V2_IMP
wire   op_fsri            = (funct[6:5] == 2'b00) && (ise_fn[1:0] == CUSTOM_1);
assign jambu_ise_v2_sel   = op_fsri;

jambu_ise_v2 jambu_ise_v2_ins(
    .rs1(     ise_in1      ),
    .rs2(     ise_in2      ),
    .rd (     jambu_ise_v2_rd ),
    .imm(     funct[4:0]   ),
    .op_fsri( op_xor_v2    )
);
end else begin            : No_JAMBU_ISE_V2
assign  jambu_ise_v2_sel =  1'b0;
assign  jambu_ise_v2_rd  = 32'd0;  
    end
endgenerate

//decode jambu_ise_v3
wire        jambu_ise_v3_sel;
wire [31:0] jambu_ise_v3_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : JAMBU_ISE_V3_IMP
wire   op_fsr_27            = (funct[6:0] == 7'b0000011) && (ise_fn[1:0] == CUSTOM_3);
wire   op_fsr_21            = (funct[6:0] == 7'b0000010) && (ise_fn[1:0] == CUSTOM_3);
wire   op_fsr_15            = (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_3);
wire   op_fsr_06            = (funct[6:0] == 7'b0000001) && (ise_fn[1:0] == CUSTOM_3);
assign jambu_ise_v3_sel   = op_fsr_27 | op_fsr_21 | op_fsr_15 | op_fsr_06;

jambu_ise_v3 jambu_ise_v3_ins(
    .rs1(       ise_in1         ),
    .rs2(       ise_in2         ),
    .rd (       jambu_ise_v3_rd ),
    .op_fsr_27( op_fsr_27       ),
    .op_fsr_21( op_fsr_21       ),
    .op_fsr_15( op_fsr_15       ),
    .op_fsr_06( op_fsr_06       )
);
end else begin            : No_JAMBU_ISE_V3
assign  jambu_ise_v3_sel =  1'b0;
assign  jambu_ise_v3_rd  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{       rv32b_sel}} &        rv32b_rd | 
                   {32{jambu_ise_v2_sel}} & jambu_ise_v2_rd |
                   {32{jambu_ise_v3_sel}} & jambu_ise_v3_rd ;

assign ise_oval = ise_val && (rv32b_sel | jambu_ise_v2_sel | jambu_ise_v3_sel);
assign ise_out  = dout;

endmodule


