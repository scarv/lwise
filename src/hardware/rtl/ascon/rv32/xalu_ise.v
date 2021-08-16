//Ascon Instruction Set Extension
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
wire   op_rori_l     = ise_val && (funct[6:5] == 2'b00)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori_h     = ise_val && (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_iornot     = ise_val && (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_2);
wire   op_andnot     = ise_val && (funct[6:0] == 7'b0000001) && (ise_fn[1:0] == CUSTOM_2);
assign rv32b_sel = op_rori_l | op_rori_h | op_iornot | op_andnot;
rv32b_ise rv32b_ins(
    .rs1(      ise_in1  ),
    .rs2(      ise_in2  ),
    .rd (      rv32b_rd ),
    .imm(     funct[4:0]),
    .op_rori_l(op_rori_l),
    .op_rori_h(op_rori_h),
    .op_iornot(op_iornot),
    .op_andnot(op_andnot)
);
end else begin            : No_RB32B
assign  rv32b_sel =  1'b0;
assign  rv32b_rd  = 32'd0;  
    end
endgenerate
 
//decode ascon_ise
wire        ascon_ise_sel;
wire [31:0] ascon_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : ASCON_ISE_IMP
wire   op_sigma_lo     = (funct[6:5] == 2'b00) && (ise_fn[1:0] == CUSTOM_1);
wire   op_sigma_hi     = (funct[6:5] == 2'b01) && (ise_fn[1:0] == CUSTOM_1);
assign ascon_ise_sel   = op_sigma_lo  | op_sigma_hi;

ascon_ise ascon_ise_ins2(
    .rs1(         ise_in1      ),
    .rs2(         ise_in2      ),
    .rd (         ascon_ise_rd ),
    .imm(         funct[4:0]   ),
    .op_sigma_lo( op_add_v2    ),
    .op_sigma_hi( op_xor_v2    )
);
end else begin            : No_ASCON_ISE
assign  ascon_ise_sel =  1'b0;
assign  ascon_ise_rd  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{    rv32b_sel}} &     rv32b_rd | 
                   {32{ascon_ise_sel}} & ascon_ise_rd ;

assign ise_oval = ise_val && (rv32b_sel | ascon_ise_sel);
assign ise_out  = dout;

endmodule


