module rv32b_ise (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_roli,
input  wire         op_andn,
output wire [31:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

wire [31:0]    l0 =  rs1;
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

// andnot r = x & ~y
wire [31:0] andnot = rs1 & (~rs2);

assign        rd  = {32{ op_roli }} & l16   |
                    {32{ op_andn }} & andnot; 
endmodule

