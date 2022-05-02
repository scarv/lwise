module grain_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,
input  wire         op_extr,
input  wire         op_fln0,
input  wire         op_fln2,
input  wire         op_gnn0,
input  wire         op_gnn1,
input  wire         op_gnn2,
input  wire         op_hnn0,
input  wire         op_hnn1,
input  wire         op_hnn2,
input  wire         op_hln0,

output wire [31:0]  rd
);

`define RSHI(a,I) (a >> I)
`define rsh64(x,  imm,  l)   ({64{imm[4]}} & {16'd0,  l8``l[63:16]}) | ({64{!imm[4]}} &  l8``l[63:0]); \
        wire [63:0]  l8``l = ({64{imm[3]}} & { 8'd0,  l4``l[63: 8]}) | ({64{!imm[3]}} &  l4``l[63:0]); \
        wire [63:0]  l4``l = ({64{imm[2]}} & { 4'd0,  l2``l[63: 4]}) | ({64{!imm[2]}} &  l2``l[63:0]); \
        wire [63:0]  l2``l = ({64{imm[1]}} & { 2'd0,  l1``l[63: 2]}) | ({64{!imm[1]}} &  l1``l[63:0]); \
        wire [63:0]  l1``l = ({64{imm[0]}} & { 1'd0,  l0``l[63: 1]}) | ({64{!imm[0]}} &  l0``l[63:0]); \
        wire [63:0]  l0``l = x  

wire [63:0] x = {rs1, rs2};
wire [63:0] x_sh_i = `rsh64(x,imm,sh_i);
wire [63:0] x_sh31 = `RSHI(  x, 31);
wire [63:0] x_sh29 = `RSHI(  x, 29);
wire [63:0] x_sh28 = `RSHI(  x, 28);
wire [63:0] x_sh27 = `RSHI(  x, 27);
wire [63:0] x_sh26 = `RSHI(  x, 26);
wire [63:0] x_sh25 = `RSHI(  x, 25);
wire [63:0] x_sh24 = `RSHI(  x, 24);
wire [63:0] x_sh22 = `RSHI(  x, 22);
wire [63:0] x_sh20 = `RSHI(  x, 20);
wire [63:0] x_sh18 = `RSHI(  x, 18);
wire [63:0] x_sh17 = `RSHI(  x, 17);
wire [63:0] x_sh16 = `RSHI(  x, 16);
wire [63:0] x_sh15 = `RSHI(  x, 15);
wire [63:0] x_sh14 = `RSHI(  x, 14);
wire [63:0] x_sh13 = `RSHI(  x, 13);
wire [63:0] x_sh11 = `RSHI(  x, 11);
wire [63:0] x_sh09 = `RSHI(  x,  9);
wire [63:0] x_sh08 = `RSHI(  x,  8);
wire [63:0] x_sh07 = `RSHI(  x,  7);
wire [63:0] x_sh06 = `RSHI(  x,  6);
wire [63:0] x_sh04 = `RSHI(  x,  4);
wire [63:0] x_sh02 = `RSHI(  x,  2);

wire [31:0] extr = x_sh_i[31:0];
wire [31:0] fln0 = rs2 ^ x_sh07;
wire [31:0] fln2 = rs1 ^ x_sh06[31:0] ^  x_sh17[31:0];
wire [31:0] gnn0 = rs2 ^ x_sh26[31:0] ^ (x_sh11[31:0] & x_sh13[31:0]) 
                                      ^ (x_sh17[31:0] & x_sh18[31:0])
                                      ^ (x_sh22[31:0] & x_sh24[31:0] & x_sh25[31:0]);
wire [31:0] gnn1 =       x_sh24[31:0] ^ (x_sh08[31:0] & x_sh16[31:0]);

wire [31:0] gnn2 = rs1 ^ x_sh27[31:0] ^ (x_sh04[31:0] & x_sh20[31:0]) 
                                      ^ (x_sh24[31:0] & x_sh28[31:0] & x_sh29[31:0] & x_sh31[31:0]) 
                                      ^ (x_sh06[31:0] & x_sh14[31:0] & x_sh18[31:0] );
wire [31:0] hnn0 =       x_sh02[31:0] ^  x_sh15[31:0];
wire [31:0] hnn1 =       x_sh04[31:0] ^  x_sh13[31:0];
wire [31:0] hnn2 = rs2 ^ x_sh09[31:0] ^  x_sh25[31:0]; 
wire [31:0] hln0 =       x_sh13[31:0] &  x_sh20[31:0];


assign      rd  = {32{ op_extr }} & extr |
                  {32{ op_fln0 }} & fln0 |
                  {32{ op_fln2 }} & fln2 |
                  {32{ op_gnn0 }} & gnn0 |
                  {32{ op_gnn1 }} & gnn1 |
                  {32{ op_gnn2 }} & gnn2 |
                  {32{ op_hnn0 }} & hnn0 |
                  {32{ op_hnn1 }} & hnn1 |
                  {32{ op_hnn2 }} & hnn2 |
                  {32{ op_hln0 }} & hln0 ;

`undef RSHI
`undef rsh64

endmodule


