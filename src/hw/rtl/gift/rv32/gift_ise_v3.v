module gift_ise_v3(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_key_updstd, 
input  wire         op_permbits_step,

output wire [31:0]  rd
);

`define mskshl( x, A, M )    ({ x[31-A:0],{A{ 1'b0}}} &(M<<A))
`define shrmsk( x, A, M )    ({{A{ 1'b0}}, x[31: A] } & M)
`define swapmvc(x, A, M, t ) (  x ^ {t[31-A:0], {A{1'b0}}}  ^ t); \
        assign           t = ( (x ^ {{A{1'b0}},  x[31:A] }) & M)     //swapmove with constants

`define ror32(x,  imm,  l)  ({32{imm[4]}} & {l8``l[15:0], l8``l[31:16]}) | ({32{!imm[4]}} & l8``l[31:0]); \
    wire   [31:0]   l8``l = ({32{imm[3]}} & {l4``l[ 7:0], l4``l[31: 8]}) | ({32{!imm[3]}} & l4``l[31:0]); \
    wire   [31:0]   l4``l = ({32{imm[2]}} & {l2``l[ 3:0], l2``l[31: 4]}) | ({32{!imm[2]}} & l2``l[31:0]); \
    wire   [31:0]   l2``l = ({32{imm[1]}} & {l1``l[ 1:0], l1``l[31: 2]}) | ({32{!imm[1]}} & l1``l[31:0]); \
    wire   [31:0]   l1``l = ({32{imm[0]}} & {l0``l[   0], l0``l[31: 1]}) | ({32{!imm[0]}} & l0``l[31:0]); \
    wire   [31:0]   l0``l = x  

wire [31:0] key_updstd = `shrmsk(rs1, 12, 32'h0000000f) | `mskshl(rs1,  4, 32'h00000fff) |
                         `shrmsk(rs1,  2, 32'h3fff0000) | `mskshl(rs1, 14, 32'h00030000) ;                        
             
wire [31:0] t0, t1, t2, t3;
wire [31:0] sm0 = `swapmvc(rs1,  3, 32'h0a0a0a0a, t0);
wire [31:0] sm1 = `swapmvc(sm0,  6, 32'h00cc00cc, t1);
wire [31:0] sm2 = `swapmvc(sm1, 12, 32'h0000f0f0, t2);
wire [31:0] sm3 = `swapmvc(sm2, 24, 32'h000000ff, t3);

wire [31:0] permbits_step = `ror32(sm3, imm, _tror);

assign        rd  = {32{op_key_updstd   }} & key_updstd   |
                    {32{op_permbits_step}} & permbits_step;   

`undef mskshl
`undef shrmsk
`undef swapmvc
`undef ror32
endmodule

