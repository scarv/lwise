//Ascon Instruction Set Extension
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
wire   op_rori_l     = (funct[6:5] == 2'b00     ) && (cop_insn[6:0] == CUSTOM_0);
wire   op_rori_h     = (funct[6:5] == 2'b01     ) && (cop_insn[6:0] == CUSTOM_0);
wire   op_iornot     = (funct[6:0] == 7'b0000000) && (cop_insn[6:0] == CUSTOM_2);
wire   op_andnot     = (funct[6:0] == 7'b0000001) && (cop_insn[6:0] == CUSTOM_2);
assign rv32b_sel     = op_rori_l | op_rori_h | op_iornot | op_andnot;
rv32b_ise rv32b_ins(
    .rs1(      cop_rs1  ),
    .rs2(      cop_rs2  ),
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
wire   op_sigma_lo     = (funct[6:5] == 2'b00) && (cop_insn[6:0] == CUSTOM_1);
wire   op_sigma_hi     = (funct[6:5] == 2'b01) && (cop_insn[6:0] == CUSTOM_1);
assign ascon_ise_sel   = op_sigma_lo  | op_sigma_hi;

ascon_ise ascon_ise_ins2(
    .rs1(         cop_rs1      ),
    .rs2(         cop_rs2      ),
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

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && (rv32b_sel | ascon_ise_sel);
assign cop_rd = dout;

endmodule


