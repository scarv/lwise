module elephant_ise_v3(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,
  
input  wire         op_pstep2_0,     
input  wire         op_pstep2_8,
input  wire         op_pstep2_16,
input  wire         op_pstep2_24,
input  wire         op_pstep1,      
input  wire         op_bupd, 

output wire [31:0]  rd
);

`define lsh(x,imm, l)       ({32{imm[4]}} & {l8``l[15:0], 16'd0 }) | ({32{!imm[4]}} & l8``l[31:0]); \
        wire [31:0] l8``l = ({32{imm[3]}} & {l4``l[23:0],  8'd0 }) | ({32{!imm[3]}} & l4``l[31:0]); \
        wire [31:0] l4``l = ({32{imm[2]}} & {l2``l[27:0],  4'd0 }) | ({32{!imm[2]}} & l2``l[31:0]); \
        wire [31:0] l2``l = ({32{imm[1]}} & {l1``l[29:0],  2'd0 }) | ({32{!imm[1]}} & l1``l[31:0]); \
        wire [31:0] l1``l = ({32{imm[0]}} & {l0``l[30:0],  1'd0 }) | ({32{!imm[0]}} & l0``l[31:0]); \
        wire [31:0] l0``l = x

`define swapmvc(x, A, M, L ) (  x ^ {t``L[31-A:0] , {A{1'b0}}}  ^ t``L); \
        wire[31:0]    t``L  =( (x ^ {{  A{  1'b0}},  x[31:A] }) &    M)     //swapmove with constants


wire  [4:0] imm_rs2   = imm - rs2[4:0];
wire  [4:0] imm_rs2_3 = imm_rs2 - 5'd3;
wire [31:0] rs1_lsh_0 = `lsh(rs1, imm_rs2  , _rs1lsh0);
wire [31:0] rs1_lsh_1 = `lsh(rs1, imm_rs2_3, _rs1lsh1);
wire [31:0] onelsh    = `lsh(32'd1, imm, _onelsh);
wire [31:0] twolsh    = `lsh(32'd2, imm, _twolsh);
wire [31:0] bupd      = (rs1_lsh_0 & onelsh) ^(rs1_lsh_1 & twolsh);

wire [31:0] pstep1_swm0 = `swapmvc(rs1         ,  3, 32'h0A0A0A0A, _swm0);
wire [31:0] pstep1_swm1 = `swapmvc(pstep1_swm0 ,  6, 32'h00CC00CC, _swm1);
wire [31:0] pstep1_swm2 = `swapmvc(pstep1_swm1 , 12, 32'h0000F0F0, _swm2);
wire [31:0] pstep1      = `swapmvc(pstep1_swm2 , 24, 32'h000000FF, _swm3);

wire [31:0] rs2_0     = {24'd0,rs2[ 7: 0]};
wire [31:0] rs2_8     = {24'd0,rs2[15: 8]};
wire [31:0] rs2_16    = {24'd0,rs2[23:16]};
wire [31:0] rs2_24    = {24'd0,rs2[31:24]};

wire [31:0] rs2_0_lsh  = `lsh(rs2_0,  imm, _rs2_0lsh);
wire [31:0] rs2_8_lsh  = `lsh(rs2_8,  imm, _rs2_8lsh);
wire [31:0] rs2_16_lsh = `lsh(rs2_16, imm, _rs2_16lsh);
wire [31:0] rs2_24_lsh = `lsh(rs2_24, imm, _rs2_24lsh);

wire [31:0] pstep2_0  = rs1 ^ rs2_0_lsh;
wire [31:0] pstep2_8  = rs1 ^ rs2_8_lsh;
wire [31:0] pstep2_16 = rs1 ^ rs2_16_lsh;
wire [31:0] pstep2_24 = rs1 ^ rs2_24_lsh;

assign        rd  = {32{op_bupd      }} & bupd      |
                    {32{op_pstep2_0  }} & pstep2_0  |
                    {32{op_pstep2_8  }} & pstep2_8  |
                    {32{op_pstep2_16 }} & pstep2_16 |
                    {32{op_pstep2_24 }} & pstep2_24 |
                    {32{op_pstep1    }} & pstep1    ;   

`undef lsh
`undef swapmvc

endmodule

