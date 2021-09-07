module rv64b_ise (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_roli,
input  wire         op_roliw,
input  wire         op_andn,

output wire [63:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

// op_roliw
wire [31:0]    l0 = rs1[31:0];
wire [31:0]    l1 = {32{ shamt[0]}} & {l0[30:0], l0[   31]} |
                    {32{!shamt[0]}} &  l0[31:0];
wire [31:0]    l2 = {32{ shamt[1]}} & {l1[29:0], l1[31:30]} |
                    {32{!shamt[1]}} &  l1[31:0];
wire [31:0]    l4 = {32{ shamt[2]}} & {l2[27:0], l2[31:28]} |
                    {32{!shamt[2]}} &  l2[31:0];
wire [31:0]    l8 = {32{ shamt[3]}} & {l4[23:0], l4[31:24]} |
                    {32{!shamt[3]}} &  l4[31:0];
wire [31:0]   l16 = {32{ shamt[4]}} & {l8[15:0], l8[31:16]} |
                    {32{!shamt[4]}} &  l8[31:0];

// op_roli
wire [63:0]  l0_64 =  rs1;
wire [63:0]  l1_64 = {64{ shamt[0]}} & {l0_64[   0], l0_64[   63]} |
                     {64{!shamt[0]}} &  l0_64[63:0];
wire [63:0]  l2_64 = {64{ shamt[1]}} & {l1_64[61:0], l1_64[63:62]} |
                     {64{!shamt[1]}} &  l1_64[63:0];
wire [63:0]  l4_64 = {64{ shamt[2]}} & {l2_64[59:0], l2_64[63:60]} |
                     {64{!shamt[2]}} &  l2_64[63:0];
wire [63:0]  l8_64 = {64{ shamt[3]}} & {l4_64[55:0], l4_64[63:56]} |
                     {64{!shamt[3]}} &  l4_64[63:0];
wire [63:0] l16_64 = {64{ shamt[4]}} & {l8_64[47:0], l8_64[63:48]} |
                     {64{!shamt[4]}} &  l8_64[63:0];

// andnot r = x & ~y
wire [31:0] andnot = rs1 & (~rs2);

assign      rd     = {64{ op_roliw }} & {r1[63:32], l16    } |
                     {64{ op_roli  }} & {           l16_64 } |
                     {64{ op_andn  }} & {           andnot } ;
endmodule

