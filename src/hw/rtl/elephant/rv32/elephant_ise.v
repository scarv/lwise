module elephant_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 2:0]  imm,

input  wire         op_pstep_x,   
input  wire         op_pstep_y,   
input  wire         op_sstep,   

output wire [31:0]  rd
);
 
`define swapmv_xy(x, y, msk, N, x_y, t)   (x_y) ? (x ^ { t[31-N:0], {N{1'b0}} }) : (y ^ t); \
        assign                       t  = (y ^ { {N{1'b0}},  x[31:N]  }) & msk    
`define swapmv(   x,    msk, N,      t)   (x ^ t  ^ { t[31-N:0], {N{1'b0}} }); \
        assign                       t  = (x ^ { {N{1'b0}},  x[31:N]  }) & msk
/*
uint8_t SBOX[ 16 ] = {
  0xE, 0xD, 0xB, 0x0, 0x2, 0x1, 0x4, 0xF, 
  0x7, 0xA, 0x8, 0x5, 0x9, 0xC, 0x3, 0x6
};*/
function [3:0] SBOX;
        input [3:0] xn;
        begin
                case (xn)
                4'b0000:  SBOX = 4'hE;
                4'b0001:  SBOX = 4'hD;
                4'b0010:  SBOX = 4'hB;
                4'b0011:  SBOX = 4'h0;
                4'b0100:  SBOX = 4'h2;
                4'b0101:  SBOX = 4'h1;
                4'b0110:  SBOX = 4'h4;
                4'b0111:  SBOX = 4'hF;
                4'b1000:  SBOX = 4'h7;
                4'b1001:  SBOX = 4'hA;
                4'b1010:  SBOX = 4'h8;
                4'b1011:  SBOX = 4'h5;
                4'b1100:  SBOX = 4'h9;
                4'b1101:  SBOX = 4'hC;
                4'b1110:  SBOX = 4'h3;
                4'b1111:  SBOX = 4'h6;
                default:  SBOX = 4'hx;
                endcase
        end
endfunction

wire [31:0] sbstep = {  SBOX(rs1[31:28]),
                        SBOX(rs1[27:24]),
                        SBOX(rs1[23:20]),
                        SBOX(rs1[19:16]),
                        SBOX(rs1[15:12]),
                        SBOX(rs1[11: 8]),
                        SBOX(rs1[ 7: 4]),
                        SBOX(rs1[ 3: 0]) };

wire [31:0] st0, st1, st2, st3;
wire [31:0] sstep_0 = `swapmv(sbstep,  32'h0A0A0A0A,  3, st0);
wire [31:0] sstep_1 = `swapmv(sstep_0, 32'h00CC00CC,  6, st1);
wire [31:0] sstep_2 = `swapmv(sstep_1, 32'h0000F0F0, 12, st2);
wire [31:0] sstep   = `swapmv(sstep_2, 32'h0000FF00,  8, st3);

wire [31:0] t0, t1, t2, t3, t4, t5, t6;

wire [31:0] pstep_imm0 = `swapmv_xy(rs1, rs2, 32'h000000FF,  8, op_pstep_x, t0);
wire [31:0] pstep_imm1 = `swapmv_xy(rs1, rs2, 32'h000000FF, 16, op_pstep_x, t1);
wire [31:0] pstep_imm2 = `swapmv_xy(rs1, rs2, 32'h000000FF, 24, op_pstep_x, t2);
wire [31:0] pstep_imm3 = `swapmv_xy(rs1, rs2, 32'h0000FF00,  8, op_pstep_x, t3);

wire [31:0] pstep_4    = `swapmv_xy(rs1, rs2, 32'h000000FF, 24, op_pstep_x, t4);
wire [31:0] pstep_5    = `swapmv_xy(rs1, rs2, 32'h0000FF00, 16, op_pstep_x, t5);
wire [31:0] pstep_6    = `swapmv_xy(rs1, rs2, 32'h00FF0000,  8, op_pstep_x, t6);

wire [31:0] pstep_imm4 = (op_pstep_y)? pstep_4: {pstep_4[23:0], pstep_4[31:24]};
wire [31:0] pstep_imm5 = (op_pstep_y)? pstep_5: {pstep_5[15:0], pstep_5[31:16]};
wire [31:0] pstep_imm6 = (op_pstep_y)? pstep_6: {pstep_6[ 7:0], pstep_6[31: 8]};

wire [31:0] pstep      =  (imm == 3'h0) ? pstep_imm0 :
                          (imm == 3'h1) ? pstep_imm1 :
                          (imm == 3'h2) ? pstep_imm2 :
                          (imm == 3'h3) ? pstep_imm3 :
                          (imm == 3'h4) ? pstep_imm4 :
                          (imm == 3'h5) ? pstep_imm5 :
                          (imm == 3'h6) ? pstep_imm6 :
                           /*(others)*/   32'h00000000;

assign        rd  =  {32{ op_sstep}}                  & sstep |     
                     {32{ op_pstep_x || op_pstep_y }} & pstep ;   

`undef swapmv
endmodule

