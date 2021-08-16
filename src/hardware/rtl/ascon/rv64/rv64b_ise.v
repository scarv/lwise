module rv64b_ise (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_rori,
input  wire         op_iorn,
input  wire         op_andn,

output wire [63:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

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

// ornot r = x | ~y
wire [31:0] iornot = rs1 | (~rs2);

// andnot r = x & ~y
wire [31:0] andnot = rs1 & (~rs2);

assign      rd     = {64{ op_rori }} & { l16_64 } |
                     {64{ op_iorn }} & { iornot } |
                     {64{ op_andn }} & { andnot } ;
endmodule

