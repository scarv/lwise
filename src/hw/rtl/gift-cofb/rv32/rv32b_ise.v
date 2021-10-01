module rv32b_ise (
input  wire [31:0]  rs1,
input  wire [ 4:0]  imm,

input  wire         op_rori_n,
input  wire         op_rori_b,
input  wire         op_rori_h,
input  wire         op_rori_w,
output wire [31:0]  rd
);

`define rori4( x,imm,n,l)   ({ 4{imm[1]}} & {l1``l[ 1:0], l1``l[ 3: 2]}) | ({ 4{!imm[1]}} & l1``l[ 3:0]); \
        wire [ 3:0] l1``l = ({ 4{imm[0]}} & {l0``l[   0], l0``l[ 3: 1]}) | ({ 4{!imm[0]}} & l0``l[ 3:0]); \
        wire [31:0] l0``l = x[ 4*n +:4]  

`define rori8( x,imm,n,l)   ({ 8{imm[2]}} & {l2``l[ 3:0], l2``l[ 7: 4]}) | ({ 8{!imm[2]}} & l2``l[ 7:0]); \
        wire [ 7:0] l2``l = ({ 8{imm[1]}} & {l1``l[ 1:0], l1``l[ 7: 2]}) | ({ 8{!imm[1]}} & l1``l[ 7:0]); \
        wire [ 7:0] l1``l = ({ 8{imm[0]}} & {l0``l[   0], l0``l[ 7: 1]}) | ({ 8{!imm[0]}} & l0``l[ 7:0]); \
        wire [31:0] l0``l = x[ 8*n +:8]  

`define rori16(x,imm,n,l)   ({16{imm[3]}} & {l4``l[ 7:0], l4``l[15: 8]}) | ({16{!imm[3]}} & l4``l[15:0]); \
        wire [15:0] l4``l = ({16{imm[2]}} & {l2``l[ 3:0], l2``l[15: 4]}) | ({16{!imm[2]}} & l2``l[15:0]); \
        wire [15:0] l2``l = ({16{imm[1]}} & {l1``l[ 1:0], l1``l[15: 2]}) | ({16{!imm[1]}} & l1``l[15:0]); \
        wire [15:0] l1``l = ({16{imm[0]}} & {l0``l[   0], l0``l[15: 1]}) | ({16{!imm[0]}} & l0``l[15:0]); \
        wire [15:0] l0``l = x[16*n +:16]	
        
`define rori32(x,imm,  l)   ({32{imm[4]}} & {l8``l[15:0], l8``l[31:16]}) | ({32{!imm[4]}} & l8``l[31:0]); \
        wire [31:0] l8``l = ({32{imm[3]}} & {l4``l[ 7:0], l4``l[31: 8]}) | ({32{!imm[3]}} & l4``l[31:0]); \
        wire [31:0] l4``l = ({32{imm[2]}} & {l2``l[ 3:0], l2``l[31: 4]}) | ({32{!imm[2]}} & l2``l[31:0]); \
        wire [31:0] l2``l = ({32{imm[1]}} & {l1``l[ 1:0], l1``l[31: 2]}) | ({32{!imm[1]}} & l1``l[31:0]); \
        wire [31:0] l1``l = ({32{imm[0]}} & {l0``l[   0], l0``l[31: 1]}) | ({32{!imm[0]}} & l0``l[31:0]); \
        wire [31:0] l0``l = x  
       

wire   [31:0] rori_w           = `rori32(rs1, imm,    i32  );

wire   [31:0] rori_h;
assign        rori_h[1*16+:16] = `rori16(rs1, imm, 1, i16_1);
assign        rori_h[0   +:16] = `rori16(rs1, imm, 0, i16_0);

wire   [31:0] rori_b;
assign        rori_b[3*8 +: 8] = `rori8( rs1, imm, 3, i8_3 );
assign        rori_b[2*8 +: 8] = `rori8( rs1, imm, 2, i8_2 );
assign        rori_b[1*8 +: 8] = `rori8( rs1, imm, 1, i8_1 );
assign        rori_b[0   +: 8] = `rori8( rs1, imm, 0, i8_0 );

wire   [31:0] rori_n;
assign        rori_n[7*4 +: 4] = `rori4( rs1, imm, 7, i4_7 );
assign        rori_n[6*4 +: 4] = `rori4( rs1, imm, 6, i4_6 );
assign        rori_n[5*4 +: 4] = `rori4( rs1, imm, 5, i4_5 );
assign        rori_n[4*4 +: 4] = `rori4( rs1, imm, 4, i4_4 );
assign        rori_n[3*4 +: 4] = `rori4( rs1, imm, 3, i4_3 );
assign        rori_n[2*4 +: 4] = `rori4( rs1, imm, 2, i4_2 );
assign        rori_n[1*4 +: 4] = `rori4( rs1, imm, 1, i4_1 );
assign        rori_n[0   +: 4] = `rori4( rs1, imm, 0, i4_0 );

wire [31:0] rori_w = rori32(rs1,imm, i32)


assign        rd  = {32{ op_rori_n }} & rori_n |
                    {32{ op_rori_b }} & rori_b |
                    {32{ op_rori_h }} & rori_h |
                    {32{ op_rori_w }} & rori_w ; 
endmodule



