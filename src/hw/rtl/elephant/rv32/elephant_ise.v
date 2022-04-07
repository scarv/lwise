module elephant_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 2:0]  imm,

input  wire         op_pstep2_x,   
input  wire         op_pstep2_y,   


output wire [31:0]  rd
);
 
`define swapmv(x, y, msk, N, x_y, t)   (x_y) ? (x ^ { t[31-N:0], {N{1'b0}} }) : (y ^ t); \
        assign                           t   = (y ^ { {N{1'b0}},  x[31:N]  }) & msk    

wire [31:0] t0, t1, t2, t3, t4, t5, t6;

wire [31:0] pstep2_imm0 = `swapmv(rs1, rs2, 32'h000000FF,  8, op_pstep2_x, t0);
wire [31:0] pstep2_imm1 = `swapmv(rs1, rs2, 32'h000000FF, 16, op_pstep2_x, t1);
wire [31:0] pstep2_imm2 = `swapmv(rs1, rs2, 32'h000000FF, 24, op_pstep2_x, t2);
wire [31:0] pstep2_imm3 = `swapmv(rs1, rs2, 32'h0000FF00,  8, op_pstep2_x, t3);

wire [31:0] pstep2_4    = `swapmv(rs1, rs2, 32'h000000FF, 24, op_pstep2_x, t4);
wire [31:0] pstep2_5    = `swapmv(rs1, rs2, 32'h0000FF00, 16, op_pstep2_x, t5);
wire [31:0] pstep2_6    = `swapmv(rs1, rs2, 32'h00FF0000,  8, op_pstep2_x, t6);

wire [31:0] pstep2_imm4 = (op_pstep2_y)? pstep2_4: {pstep2_4[23:0], pstep2_4[31:24]};
wire [31:0] pstep2_imm5 = (op_pstep2_y)? pstep2_5: {pstep2_5[15:0], pstep2_5[31:16]};
wire [31:0] pstep2_imm6 = (op_pstep2_y)? pstep2_6: {pstep2_6[ 7:0], pstep2_6[31: 8]};

wire [31:0] pstep2      = (imm == 3'h0) ? pstep2_imm0 :
                          (imm == 3'h1) ? pstep2_imm1 :
                          (imm == 3'h2) ? pstep2_imm2 :
                          (imm == 3'h3) ? pstep2_imm3 :
                          (imm == 3'h4) ? pstep2_imm4 :
                          (imm == 3'h5) ? pstep2_imm5 :
                          (imm == 3'h6) ? pstep2_imm6 :
                           /*(others)*/   32'h00000000;

assign        rd  = {32{ op_pstep2_x || op_pstep2_y }} & pstep2;   

`undef swapmv
endmodule

