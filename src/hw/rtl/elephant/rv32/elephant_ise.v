module elephant_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 2:0]  imm,

input  wire         op_pstep2_x,   
input  wire         op_pstep2_y,   


output wire [31:0]  rd
);

`define swapmv(x, xshf, y, msk, t, tshf, x_y)   (x_y) ? (x ^ tshf): (y ^ t); \
        assign  t     = (y ^ xshf) & msk        

wire [31:0] x_rsh08 = { 8'd0,rs1[31: 8]};
wire [31:0] x_rsh16 = {16'd0,rs1[31:16]};
wire [31:0] x_rsh24 = {24'd0,rs1[31:24]};

wire [31:0] t_imm0;
wire [31:0] t0_lsh = {t_imm0[23:0],  8'd0};

wire [31:0] t_imm1;
wire [31:0] t1_lsh = {t_imm1[15:0], 16'd0};

wire [31:0] t_imm2;
wire [31:0] t2_lsh = {t_imm2[ 7:0], 24'd0};

wire [31:0] t_imm3;
wire [31:0] t3_lsh = {t_imm3[23:0],  8'd0};

wire [31:0] t_imm4;
wire [31:0] t4_lsh = {t_imm4[ 7:0], 24'd0};

wire [31:0] t_imm5;
wire [31:0] t5_lsh = {t_imm5[15:0], 16'd0};

wire [31:0] t_imm6;
wire [31:0] t6_lsh = {t_imm6[23:0],  8'd0};

wire [31:0] pstep2_imm0 = `swapmv(rs1, x_rsh08, rs2, 32'h000000FF, t_imm0, t0_lsh, op_pstep2_x);
wire [31:0] pstep2_imm1 = `swapmv(rs1, x_rsh16, rs2, 32'h000000FF, t_imm1, t1_lsh, op_pstep2_x);
wire [31:0] pstep2_imm2 = `swapmv(rs1, x_rsh24, rs2, 32'h000000FF, t_imm2, t2_lsh, op_pstep2_x);
wire [31:0] pstep2_imm3 = `swapmv(rs1, x_rsh08, rs2, 32'h0000FF00, t_imm3, t3_lsh, op_pstep2_x);

wire [31:0] pstep2_4    = `swapmv(rs1, x_rsh24, rs2, 32'h000000FF, t_imm4, t4_lsh, op_pstep2_x);
wire [31:0] pstep2_5    = `swapmv(rs1, x_rsh16, rs2, 32'h0000FF00, t_imm5, t5_lsh, op_pstep2_x);
wire [31:0] pstep2_6    = `swapmv(rs1, x_rsh08, rs2, 32'h00FF0000, t_imm6, t6_lsh, op_pstep2_x);

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

