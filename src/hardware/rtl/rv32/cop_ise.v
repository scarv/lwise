//Alzette Instruction Set Extension
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

parameter [4:0] ISE_V  = 5'b11111;

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
    if (ISE_V[0] == 1'b1) begin : RB32B
wire   op_rori     = (funct[6:5] == 2'b00) && (cop_insn[6:0] == CUSTOM_0);
assign rv32b_sel = op_rori;
rv32b_ise rv32b_ins(
    .rs1(cop_rs1),
    .rd (rv32b_rd ),
    .imm(funct[4:0]),
    .op_rori(op_rori)
);
end else begin            : No_RB32B
assign  rv32b_sel =  1'b0;
assign  rv32b_rd  = 32'd0;  
    end
endgenerate

//decode rv32ell_ise
wire        rv32ell_sel;
wire [31:0] rv32ell_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : RB32ELL
wire   op_ell     = (funct[6:0] == 7'b0000010) && (cop_insn[6:0] == CUSTOM_3);
assign rv32ell_sel = op_ell;
rv32ell_ise rv32ell_ins(
    .rs1(cop_rs1),
    .rd (rv32ell_rd ),
    .op_ell(op_ell)
);
end else begin            : No_RB32ELL
assign  rv32ell_sel =  1'b0;
assign  rv32ell_rd  = 32'd0;  
    end
endgenerate

//decode alzette_ise
wire        v02_sel;
wire [31:0] v02_rd;  
generate 
    if (ISE_V[2] == 1'b1) begin : ISE_V2
wire   op_add_v2     = (funct[6:5] == 2'b00) && (cop_insn[6:0] == CUSTOM_1);
wire   op_sub_v2     = (funct[6:5] == 2'b01) && (cop_insn[6:0] == CUSTOM_1);
wire   op_xor_v2     = (funct[6:5] == 2'b10) && (cop_insn[6:0] == CUSTOM_1);
assign v02_sel = op_add_v2  | op_sub_v2  |  op_xor_v2;

alzette_ise_v2 alzetteise_ins2(
    .rs1(cop_rs1),
    .rs2(cop_rs2),
    .rd (v02_rd ),
    .imm(funct[4:0]),
    .op_add(op_add_v2),
    .op_sub(op_sub_v2),
    .op_xor(op_xor_v2)
);
end else begin            : No_ISE_V2
assign  v02_sel =  1'b0;
assign  v02_rd  = 32'd0;  
    end
endgenerate

wire        v03_sel;
wire [31:0] v03_rd;  
generate 
    if (ISE_V[3] == 1'b1) begin : ISE_V3
wire   op_addror_31_v3 = (funct[6:0] == 7'b0100000) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_addror_17_v3 = (funct[6:0] == 7'b0100001) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_addror_24_v3 = (funct[6:0] == 7'b0100010) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_subror_31_v3 = (funct[6:0] == 7'b0100011) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_subror_17_v3 = (funct[6:0] == 7'b0100100) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_subror_24_v3 = (funct[6:0] == 7'b0100101) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_xorror_31_v3 = (funct[6:0] == 7'b0100110) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_xorror_17_v3 = (funct[6:0] == 7'b0100111) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_xorror_24_v3 = (funct[6:0] == 7'b0101000) && (cop_insn[6:0] == CUSTOM_3);  
wire   op_xorror_16_v3 = (funct[6:0] == 7'b0101001) && (cop_insn[6:0] == CUSTOM_3);  

assign v03_sel = op_addror_31_v3 | op_addror_24_v3 | op_addror_17_v3 | 
                 op_subror_31_v3 | op_subror_24_v3 | op_subror_17_v3 |
                 op_xorror_31_v3 | op_xorror_24_v3 | op_xorror_17_v3 | op_xorror_16_v3;

alzette_ise_v3 alzetteise_ins3(
    .rs1(cop_rs1),
    .rs2(cop_rs2),
    .rd (v03_rd ),
    .op_addror_31(op_addror_31_v3),
    .op_addror_24(op_addror_24_v3),
    .op_addror_17(op_addror_17_v3),
    .op_subror_31(op_subror_31_v3),
    .op_subror_24(op_subror_24_v3),
    .op_subror_17(op_subror_17_v3),
    .op_xorror_31(op_xorror_31_v3),
    .op_xorror_24(op_xorror_24_v3),
    .op_xorror_17(op_xorror_17_v3),
    .op_xorror_16(op_xorror_16_v3)
);

    end else begin            : No_ISE_V3
assign  v03_sel =  1'b0;
assign  v03_rd  = 32'd0;  
    end
endgenerate


wire        v04_sel;
wire [31:0] v04_rd;  
generate 
    if (ISE_V[4] == 1'b1) begin : ISE_V4
wire   op_enc_x     = (funct[6:3] == 4'b0100) && (cop_insn[6:0] == CUSTOM_2);  
wire   op_enc_y     = (funct[6:3] == 4'b0101) && (cop_insn[6:0] == CUSTOM_2);  
wire   op_dec_x     = (funct[6:3] == 4'b0110) && (cop_insn[6:0] == CUSTOM_2);  
wire   op_dec_y     = (funct[6:3] == 4'b0111) && (cop_insn[6:0] == CUSTOM_2); 

wire   op_x_v4      = op_enc_x | op_dec_x ;
wire   op_enc_v4    = op_enc_x | op_enc_y ;

assign v04_sel      = op_enc_x | op_enc_y | op_dec_x | op_dec_y;

alzette_ise_v4 alzetteise_ins4(
    .rs1(cop_rs1),
    .rs2(cop_rs2),
    .rd (v04_rd ),
    .imm(funct[2:0]),
    .op_x(  op_x_v4),
    .op_enc(op_enc_v4)
);
    end else begin            : No_ISE_V4
assign v04_sel =  1'b0;
assign v04_rd  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{  rv32b_sel}} &   rv32b_rd | 
                   {32{rv32ell_sel}} & rv32ell_rd |
                   {32{    v02_sel}} &     v02_rd |
                   {32{    v03_sel}} &     v03_rd |
                   {32{    v04_sel}} &     v04_rd ;

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && (rv32b_sel | rv32ell_sel | v02_sel | v03_sel | v04_sel);
assign cop_rd = dout;

endmodule

