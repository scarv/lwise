module elephant_ise_v2(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_bsllxor,      
input  wire         op_bup,      
input  wire         op_pstep1,      


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

wire [31:0] rs2mask = {24'd0,rs2[7:0]};
wire [31:0] rs2mlsh = `lsh(rs2mask, imm, _rs2m);
wire [31:0] bsllxor = rs1 ^ rs2mlsh;

wire  [4:0] imm_rs2 = imm - rs2[4:0];
wire [31:0] rs1_lsh = `lsh(rs1, imm_rs2, _rs1ls);
wire [31:0] maskbit = `lsh(32'd1, imm, _mb);
wire [31:0] bup     = rs1_lsh & maskbit;

wire [31:0] pstep1_swm0 = `swapmvc(rs1         ,  3, 32'h0A0A0A0A, _swm0);
wire [31:0] pstep1_swm1 = `swapmvc(pstep1_swm0 ,  6, 32'h00CC00CC, _swm1);
wire [31:0] pstep1_swm2 = `swapmvc(pstep1_swm1 , 12, 32'h0000F0F0, _swm2);
wire [31:0] pstep1      = `swapmvc(pstep1_swm2 , 24, 32'h000000FF, _swm3);

assign        rd  = {32{op_bsllxor  }} & bsllxor |
                    {32{op_bup      }} & bup     |
                    {32{op_pstep1   }} & pstep1  ;   

`undef lsh
`undef swapmvc
endmodule

