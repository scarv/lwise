module jambu_ise_v2 (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_fsri,

output wire [31:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

//64-bit right rotation
wire [63:0] opr_rot = {rs2, rs1};

wire [63:0]    l0 =  opr_rot;
wire [63:0]    l1 = {64{ shamt[0]}} & {l0[   0], l0[63: 1]} |
                    {64{!shamt[0]}} &  l0[63:0];
wire [63:0]    l2 = {64{ shamt[1]}} & {l1[ 1:0], l1[63: 2]} |
                    {64{!shamt[1]}} &  l1[63:0];
wire [63:0]    l4 = {64{ shamt[2]}} & {l2[ 3:0], l2[63: 4]} |
                    {64{!shamt[2]}} &  l2[63:0];
wire [63:0]    l8 = {64{ shamt[3]}} & {l4[ 7:0], l4[63: 8]} |
                    {64{!shamt[3]}} &  l4[63:0];
wire [63:0]   l16 = {64{ shamt[4]}} & {l8[15:0], l8[63:16]} |
                    {64{!shamt[4]}} &  l8[63:0];

assign        rd  = {32{op_fsri}} & l16[   31: 0];
endmodule


