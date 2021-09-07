module rv32b_ise (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_rori,
input  wire         op_xnor,
output wire [31:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

//32-bit right rotation
wire [31:0]    l0 =  rs1;
wire [31:0]    l1 = {32{ shamt[0]}} & {l0[   0], l0[31: 1]} |
                    {32{!shamt[0]}} &  l0[31:0];
wire [31:0]    l2 = {32{ shamt[1]}} & {l1[ 1:0], l1[31: 2]} |
                    {32{!shamt[1]}} &  l1[31:0];
wire [31:0]    l4 = {32{ shamt[2]}} & {l2[ 3:0], l2[31: 4]} |
                    {32{!shamt[2]}} &  l2[31:0];
wire [31:0]    l8 = {32{ shamt[3]}} & {l4[ 7:0], l4[31: 8]} |
                    {32{!shamt[3]}} &  l4[31:0];
wire [31:0]   l16 = {32{ shamt[4]}} & {l8[15:0], l8[31:16]} |
                    {32{!shamt[4]}} &  l8[31:0];

// xnor r = x ^ ~y
wire [31:0] xnor32 = rs1 | (~rs2);

assign        rd  = {32{op_rori}} & l16[   31: 0] |
                    {32{op_xnor}} & xnor32[31: 0] ; 
endmodule

