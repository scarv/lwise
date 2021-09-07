module rv64b_ise (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_roriw,
input  wire         op_rori,
input  wire         op_xnor,
input  wire         op_pack,
input  wire         op_packu,

output wire [63:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

// op_roriw
wire [31:0]  l0    =  rs1[31:0];
wire [31:0]  l1    = {32{ shamt[0]}} & {l0[   0], l0[31: 1]} |
                     {32{!shamt[0]}} &  l0[31:0];
wire [31:0]  l2    = {32{ shamt[1]}} & {l1[ 1:0], l1[31: 2]} |
                     {32{!shamt[1]}} &  l1[31:0];
wire [31:0]  l4    = {32{ shamt[2]}} & {l2[ 3:0], l2[31: 4]} |
                     {32{!shamt[2]}} &  l2[31:0];
wire [31:0]  l8    = {32{ shamt[3]}} & {l4[ 7:0], l4[31: 8]} |
                     {32{!shamt[3]}} &  l4[31:0];
wire [31:0]  l16   = {32{ shamt[4]}} & {l8[15:0], l8[31:16]} |
                     {32{!shamt[4]}} &  l8[31:0];
// op_rori
wire [63:0]  l0_64 =  rs1;
wire [63:0]  l1_64 = {64{ shamt[0]}} & {l0_64[   0], l0_64[63: 1]} |
                     {64{!shamt[0]}} &  l0_64[63:0];
wire [63:0]  l2_64 = {64{ shamt[1]}} & {l1_64[ 1:0], l1_64[63: 2]} |
                     {64{!shamt[1]}} &  l1_64[63:0];
wire [63:0]  l4_64 = {64{ shamt[2]}} & {l2_64[ 3:0], l2_64[63: 4]} |
                     {64{!shamt[2]}} &  l2_64[63:0];
wire [63:0]  l8_64 = {64{ shamt[3]}} & {l4_64[ 7:0], l4_64[63: 8]} |
                     {64{!shamt[3]}} &  l4_64[63:0];
wire [63:0] l16_64 = {64{ shamt[4]}} & {l8_64[15:0], l8_64[63:16]} |
                     {64{!shamt[4]}} &  l8_64[63:0];

// xnor r = x ^ ~y
wire [63:0] xnor64 = rs1 ^ (~rs2);

// pack r = {y[31: 0], x[31: 0]}
wire [63:0] pack64  = {rs2[31: 0], rs1[31: 0]};

// pack r = {y[63:32], x[63:32]}
wire [63:0] packu64 = {rs2[63:32], rs1[63:32]};

assign      rd     = {64{ op_roliw }} & {r1[63:32], l16    } |
                     {64{ op_roli  }} & {           l16_64 } |
                     {64{ op_xnor  }} & {           xnor64 } |
                     {64{ op_pack  }} & {           pack64 } |
                     {64{ op_packu }} & {           packu64} ;
endmodule

