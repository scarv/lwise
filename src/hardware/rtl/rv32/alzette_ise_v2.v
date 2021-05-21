module alzette_ise_v2 (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_add,
input  wire         op_sub,
input  wire         op_xor,

output wire [31:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

wire [31:0]    l0 =  rs2;
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

wire [31:0] rs2_rori = l16;

wire [31:0] addrori  = rs1 + rs2_rori;   //rs1 + rs2>>>op_rot
wire [31:0] subrori  = rs1 - rs2_rori;   //rs1 - rs2>>>op_rot
wire [31:0] xorrori  = rs1 ^ rs2_rori;   //rs1 ^ rs2>>>op_rot

assign           rd  = op_add ? addrori : 
                       op_sub ? subrori :
                    /* op_xor */xorrori ; 
endmodule

