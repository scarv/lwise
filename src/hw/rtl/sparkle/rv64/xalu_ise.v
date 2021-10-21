//Alzette Instruction Set Extension
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
input  [ 5:0]   ise_fn;
input  [ 6:0]   ise_imm;
input  [63:0]   ise_in1;
input  [63:0]   ise_in2;
input           ise_val;
output          ise_oval;
output [63:0]   ise_out; 

parameter [5:0] ISE_V  = 6'b111111;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode rv64b_ise
wire        rv64b_sel;
wire [63:0] rv64b_rd;  
generate 
    if (ISE_V[0] == 1'b1) begin : RB64B
wire   op_rori     = ise_val && (funct[6:5] == 2'b00)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_roriw    = ise_val && (funct[6:5] == 2'b01)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_pack     = ise_val && (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_3);
wire   op_packu    = ise_val && (funct[6:0] == 7'b0000001) && (ise_fn[1:0] == CUSTOM_3);
assign rv64b_sel = op_rori | op_roriw | op_pack | op_packu;
rv64b_ise rv64b_ins(
    .rs1(      ise_in1  ),
    .rs2(      ise_in2  ),
    .rd (      rv64b_rd ),
    .imm(     funct[4:0]),
    .op_rori(  op_rori  ),
    .op_roriw( op_roriw ),
    .op_pack(  op_pack  ),
    .op_packu( op_packu )
);
end else begin            : No_RB64B
assign  rv64b_sel =  1'b0; 
assign  rv64b_rd  = 64'd0;  
    end
endgenerate

//decode rv64ell_ise
wire        rv64ell_sel;
wire [63:0] rv64ell_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : RB64ELL
wire   op_ell      = ise_val && (funct[6:0] == 7'b0000010) && (ise_fn[1:0] == CUSTOM_3);
wire   op_ellrev   = ise_val && (funct[6:0] == 7'b0000011) && (ise_fn[1:0] == CUSTOM_3);
assign rv64ell_sel = op_ell | op_ellrev;
rv64ell_ise rv64ell_ins(
    .rs1(       ise_in1   ),
    .rs2(       ise_in2   ),
    .rd (      rv64ell_rd ),
    .op_ell(    op_ell    ),
    .op_ellrev( op_ellrev )
);
end else begin            : No_RB64ELL
assign  rv64ell_sel =  1'b0;
assign  rv64ell_rd  = 64'd0;  
    end
endgenerate

//decode alzette_ise
wire        v02_sel;
wire [63:0] v02_rd;  
generate 
    if (ISE_V[2] == 1'b1) begin : ISE_V2
wire   op_enc_v2 = ise_val && (funct[6:2] == 5'b01000) && (ise_fn[1:0] == CUSTOM_2);
wire   op_dec_v2 = ise_val && (funct[6:2] == 5'b01010) && (ise_fn[1:0] == CUSTOM_2);
assign v02_sel   = op_enc_v2  | op_dec_v2;

alzette_ise_v2 alzetteise_ins2(
    .rs1(ise_in1),
    .rs2(ise_in2),
    .rd (v02_rd ),
    .imm(funct[1:0]),
    .op_enc(op_enc_v2)
);
end else begin            : No_ISE_V2
assign  v02_sel =  1'b0;
assign  v02_rd  = 64'd0;  
    end
endgenerate

wire        v03_sel;
wire [63:0] v03_rd;  
generate 
    if (ISE_V[3] == 1'b1) begin : ISE_V3
wire   op_funct_v3 = ise_val && (funct[6:3] == 4'b1000) && (ise_fn[1:0] == CUSTOM_3);  
assign v03_sel = op_funct_v3;

alzette_ise_v3 alzetteise_ins3(
    .rs1(ise_in1),
    .rs2(ise_in2),
    .rd (v03_rd ),
    .funct(funct[2:0])
);

    end else begin            : No_ISE_V3
assign  v03_sel =  1'b0;
assign  v03_rd  = 64'd0;  
    end
endgenerate


wire        v04_sel;
wire [63:0] v04_rd;  
generate 
    if (ISE_V[4] == 1'b1) begin : ISE_V4
wire   op_enc_v4 = ise_val && (funct[6:3] == 4'b1100) && (ise_fn[1:0] == CUSTOM_2);
wire   op_dec_v4 = ise_val && (funct[6:3] == 4'b1101) && (ise_fn[1:0] == CUSTOM_2);
assign v04_sel   = op_enc_v4  | op_dec_v4;

alzette_ise_v4 alzetteise_ins4(
    .rs1(ise_in1),
    .rd (v04_rd ),
    .imm(funct[2:0]),
    .op_enc(op_enc_v4)
);
    end else begin            : No_ISE_V4
assign v04_sel =  1'b0;
assign v04_rd  = 64'd0;  
    end
endgenerate

wire        v05_sel;
wire [63:0] v05_rd;  
generate 
    if (ISE_V[5] == 1'b1) begin : ISE_V5
wire   op_enc_v5 = ise_val && (funct[6:0] == 7'b1100000) && (ise_fn[1:0] == CUSTOM_3);
wire   op_dec_v5 = ise_val && (funct[6:0] == 7'b1100001) && (ise_fn[1:0] == CUSTOM_3);
assign v05_sel   = op_enc_v5  | op_dec_v5;

alzette_ise_v5 alzetteise_ins5(
    .rs1(ise_in1),
    .rs2(ise_in2),
    .rd (v05_rd ),
    .op_enc(op_enc_v5)
);

    end else begin            : No_ISE_V5
assign  v05_sel =  1'b0;
assign  v05_rd  = 64'd0;  
    end
endgenerate


wire [63:0] dout = {64{  rv64b_sel}} &   rv64b_rd |
                   {64{rv64ell_sel}} & rv64ell_rd |
                   {64{    v02_sel}} &     v02_rd |
                   {64{    v03_sel}} &     v03_rd |
                   {64{    v04_sel}} &     v04_rd |
                   {64{    v05_sel}} &     v05_rd ;

assign ise_oval = ise_val && (rv64b_sel | rv64ell_sel | v02_sel | v03_sel | v04_sel | v05_sel);
assign ise_out  = dout;

endmodule

