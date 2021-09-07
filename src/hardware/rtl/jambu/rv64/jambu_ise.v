module jambu_ise (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,

input  wire         op_block_0,
input  wire         op_block_1,
input  wire         op_block_2,
input  wire         op_block_3,

output wire [63:0]  rd
);

`define wror64(val,amt) {val[amt-1:0], val[64:amt]}

wire [31:0] s0 = rs1[31: 0];
wire [31:0] s1 = rs1[63:32];
wire [31:0] s2 = rs1[31: 0];
wire [31:0] s3 = rs1[63:32];

wire [63:0] s10 = {s1, s0};
wire [63:0] s21 = {s2, s1};
wire [63:0] s32 = {s3, s2};
wire [63:0] s03 = {s0, s3};

wire [63:0] t0  = (op_block_0) ? s21 :
                  (op_block_1) ? s32 :
                  (op_block_2) ? s03 :
                /*(op_block_3)*/ s10 ;

wire [63:0] t1  = (op_block_0) ? s32 :
                  (op_block_1) ? s03 :
                  (op_block_2) ? s10 :
                /*(op_block_3)*/ s21 ;
                 
wire [63:0] res = wror64(t0,15) ^ (~ (wror64(t1,6) & wror64(t1,21))) ^ wror64(t1,27);

assign op_block = op_block_0 | op_block_1 | op_block_2 | op_block_3;
assign      rd  = {64{op_block}} & res;

endmodule


