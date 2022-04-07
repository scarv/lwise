module romulus_ise_v3(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 2:0]  imm,
input  wire         op_mixcolumns,
input  wire         op_swapmove_x,
input  wire         op_swapmove_y,
input  wire         op_permtk,
input  wire         op_tkupd_0,
input  wire         op_tkupd_1,
input  wire         op_lfsr2,
input  wire         op_lfsr3,

output wire [31:0]  rd
);
`define RORI32(a,b) ((a >> b) | (a << 32-b))
`define SLLI32(a,b) ((a << b)              )
`define SRLI32(a,b) ((a >> b)              )

`define swapmvxy(x, y, msk, N, x_y, t) (x_y) ? (x ^ { t[31-N:0], {N{1'b0}} }) : (y ^ t); \
        assign                             t   = (y ^ { {N{1'b0}},  x[31:N]  }) & msk   

`define swapmv(x, msk, N, t)   (x ^ { t[31-N:0], {N{1'b0}} }  ^ t ); \
        assign             t  = (x ^ { {N{1'b0}},  x[31:N]  }) & msk

// mixcolumns instruction ============================================================    
wire [31:0] mixc_r0_0 = rs1       ^  (`RORI32(rs1      ,22) & 32'h30303030) ; //0x0C0C0C0C >>> 30
wire [31:0] mixc_r0_1 = mixc_r0_0 ^  (`RORI32(mixc_r0_0,20) & 32'h0C0C0C0C) ; //0xC0C0C0C0 >>> 4 
wire [31:0] mixc_r0   = mixc_r0_1 ^  (`RORI32(mixc_r0_1,10) & 32'h03030303) ; //0x0C0C0C0C >>> 2 

wire [31:0] mixc_r1_0 = rs1       ^  (`RORI32(rs1      ,14) & 32'hC0C0C0C0) ; //0x30303030 >>> 30
wire [31:0] mixc_r1_1 = mixc_r1_0 ^  (`RORI32(mixc_r1_0,28) & 32'h30303030) ; //0x03030303 >>> 28 
wire [31:0] mixc_r1   = mixc_r1_1 ^  (`RORI32(mixc_r1_1,18) & 32'h0C0C0C0C) ; //0x30303030 >>> 2 

wire [31:0] mixc_r2_0 = rs1       ^  (`RORI32(rs1      ,14) & 32'h03030303) ; //0xC0C0C0C0 >>>  6
wire [31:0] mixc_r2_1 = mixc_r2_0 ^  (`RORI32(mixc_r2_0,12) & 32'hC0C0C0C0) ; //0x0C0C0C0C >>> 28 
wire [31:0] mixc_r2   = mixc_r2_1 ^  (`RORI32(mixc_r2_1,26) & 32'h30303030) ; //0xC0C0C0C0 >>>  2 

wire [31:0] mixc_r3_0 = rs1       ^  (`RORI32(rs1      ,30) & 32'h0C0C0C0C) ; //0x03030303 >>> 30
wire [31:0] mixc_r3_1 = mixc_r3_0 ^  (`RORI32(mixc_r3_0, 4) & 32'h03030303) ; //0x30303030 >>>  4 
wire [31:0] mixc_r3   = mixc_r3_1 ^  (`RORI32(mixc_r3_1,26) & 32'hC0C0C0C0) ; //0x03030303 >>> 26 

wire [31:0] mixcolumn = (imm == 3'h0) ? mixc_r0 :
                        (imm == 3'h1) ? mixc_r1 :
                        (imm == 3'h2) ? mixc_r2 :
                        (imm == 3'h3) ? mixc_r3 :
                         /* others */   32'h00000000;
// ===================================================================================    


// swapmove instruction ==============================================================        
wire        op_swapmove_xy = op_swapmove_x | op_swapmove_y;
wire [31:0] t0, t1, t2, t3, t4, t5, t6, t7;

wire [31:0] swapmove_imm0 = `swapmvxy(rs1, rs2, 32'h55555555, 1, op_swapmove_x, t0);
wire [31:0] swapmove_imm1 = `swapmvxy(rs1, rs2, 32'h30303030, 2, op_swapmove_x, t1);
wire [31:0] swapmove_imm2 = `swapmvxy(rs1, rs2, 32'h0C0C0C0C, 4, op_swapmove_x, t2);
wire [31:0] swapmove_imm3 = `swapmvxy(rs1, rs2, 32'h03030303, 6, op_swapmove_x, t3);        
wire [31:0] swapmove_imm4 = `swapmvxy(rs1, rs2, 32'h0C0C0C0C, 2, op_swapmove_x, t4);
wire [31:0] swapmove_imm5 = `swapmvxy(rs1, rs2, 32'h03030303, 4, op_swapmove_x, t5);
wire [31:0] swapmove_imm6 = `swapmvxy(rs1, rs2, 32'h03030303, 2, op_swapmove_x, t6);
wire [31:0] swapmove      = `swapmv(  rs1,      32'h0A0A0A0A, 3,                t7);
wire [31:0] swapmove_xy   = (imm == 3'h0) ? swapmove_imm0 :
                            (imm == 3'h1) ? swapmove_imm1 :
                            (imm == 3'h2) ? swapmove_imm2 :
                            (imm == 3'h3) ? swapmove_imm3 :
                            (imm == 3'h4) ? swapmove_imm4 :
                            (imm == 3'h5) ? swapmove_imm5 :
                            (imm == 3'h6) ? swapmove_imm6 :
                          /*(imm == 3'h7)*/ (op_swapmove_x ? swapmove : 32'h00000000);
// ===================================================================================    

// tk permutation instruction ========================================================        
wire [31:0] x_rotmsk0_0 = (`RORI32(rs1,14)) & 32'hCC00CC00;
wire [31:0] x_shfmsk0_1 = (`SLLI32(rs1,16)) & 32'h00FF0000; //0x000000FF << 16
wire [31:0] x_shfmsk0_2 = (`SRLI32(rs1, 2)) & 32'h33000000; //0xCC000000 >>  2
wire [31:0] x_shfmsk0_3 = (`SRLI32(rs1, 8)) & 32'h000033CC; //0x0033CC00 >>  8
wire [31:0] x_shfmsk0_4 = (`SRLI32(rs1,18)) & 32'h00000033; //0x00CC0000 >> 18
wire [31:0] r_imm0      = x_rotmsk0_0 | x_shfmsk0_1 | x_shfmsk0_2 | x_shfmsk0_3 | x_shfmsk0_4 ;

wire [31:0] x_rotmsk1_0 = (`RORI32(rs1,22)) & 32'hCC0000CC;
wire [31:0] x_rotmsk1_1 = (`RORI32(rs1,16)) & 32'h3300CC00;
wire [31:0] x_rotmsk1_2 = (`RORI32(rs1,24)) & 32'h00CC3300;
wire [31:0] x_shfmsk1_3 = (`SRLI32(rs1, 2)) & 32'h00330033; //0x00CC00CC >>  2
wire [31:0] r_imm1      = x_rotmsk1_0 | x_rotmsk1_1 | x_rotmsk1_2 | x_shfmsk1_3 ;

wire [31:0] x_rotmsk2_0 = (`RORI32(rs1, 6)) & 32'hCCCC0000;
wire [31:0] x_rotmsk2_1 = (`RORI32(rs1,24)) & 32'h330000CC;
wire [31:0] x_rotmsk2_2 = (`RORI32(rs1,10)) & 32'h00003333;
wire [31:0] x_shfmsk2_3 = (`SLLI32(rs1,14)) & 32'h00330000; //0x000000CC << 14
wire [31:0] x_shfmsk2_4 = (`SLLI32(rs1, 2)) & 32'h0000CC00; //0x00003300 <<  2
wire [31:0] r_imm2      = x_rotmsk2_0 | x_rotmsk2_1 | x_rotmsk2_2 | x_shfmsk2_3 | x_shfmsk2_4 ;

wire [31:0] x_rotmsk3_0 = (`RORI32(rs1,24)) & 32'hCC000033;
wire [31:0] x_rotmsk3_1 = (`RORI32(rs1, 8)) & 32'h33CC0000;
wire [31:0] x_rotmsk3_2 = (`RORI32(rs1,26)) & 32'h00333300;
wire [31:0] x_shfmsk3_3 = (`SRLI32(rs1, 6)) & 32'h0000CCCC;  //0x00333300 >> 6
wire [31:0] r_imm3      = x_rotmsk3_0 | x_rotmsk3_1 | x_rotmsk3_2 | x_shfmsk3_3 ;

wire [31:0] x_rotmsk4_0 = (`RORI32(rs1, 8)) & 32'hCC330000;
wire [31:0] x_rotmsk4_1 = (`RORI32(rs1,26)) & 32'h33000033;
wire [31:0] x_rotmsk4_2 = (`RORI32(rs1,22)) & 32'h00CCCC00;
wire [31:0] x_shfmsk4_3 = (`SRLI32(rs1,14)) & 32'h000000CC; //0x00330000 >> 14
wire [31:0] x_shfmsk4_4 = (`SRLI32(rs1, 2)) & 32'h00003300; //0x0000CC00 >>  2
wire [31:0] r_imm4      = x_rotmsk4_0 | x_rotmsk4_1 | x_rotmsk4_2 | x_shfmsk4_3 | x_shfmsk4_4 ;

wire [31:0] x_rotmsk5_0 = (`RORI32(rs1, 8)) & 32'h0000CC33;
wire [31:0] x_rotmsk5_1 = (`RORI32(rs1,30)) & 32'h00CC00CC;
wire [31:0] x_rotmsk5_2 = (`RORI32(rs1,10)) & 32'h33330000;
wire [31:0] x_shfmsk5_3 = (`RORI32(rs1,16)) & 32'hCC003300; 
wire [31:0] r_imm5      = x_rotmsk5_0 | x_rotmsk5_1 | x_rotmsk5_2 | x_shfmsk5_3 ;

wire [31:0] x_rotmsk6_0 = (`RORI32(rs1,24)) & 32'h0033CC00;
wire [31:0] x_rotmsk6_1 = (`RORI32(rs1,14)) & 32'h00CC0000;
wire [31:0] x_rotmsk6_2 = (`RORI32(rs1,30)) & 32'hCC000000;
wire [31:0] x_shfmsk6_3 = (`RORI32(rs1,16)) & 32'h000000FF; 
wire [31:0] x_shfmsk6_4 = (`RORI32(rs1,18)) & 32'h33003300; 
wire [31:0] r_imm6      = x_rotmsk6_0 | x_rotmsk6_1 | x_rotmsk6_2 | x_shfmsk6_3 | x_shfmsk6_4 ;

wire [31:0] permtk  =   (imm == 3'h0) ? r_imm0 :
                        (imm == 3'h1) ? r_imm1 :
                        (imm == 3'h2) ? r_imm2 :
                        (imm == 3'h3) ? r_imm3 :
                        (imm == 3'h4) ? r_imm4 :
                        (imm == 3'h5) ? r_imm5 :
                        (imm == 3'h6) ? r_imm6 :
                      /*(imm == 3'h7)*/ 32'h00000000;
// ===================================================================================    

// tk update instruction =============================================================        
wire [31:0] tkupd0_xrotmsk_0 = (`RORI32(rs1,26)) & 32'hC3C3C3C3;
wire [31:0] tkupd0_xrotmsk_1 = (`RORI32(rs1,16)) & 32'hF0F0F0F0;
wire [31:0] tkupd0_xrotmsk_2 = (`RORI32(rs1,10)) & 32'hC3C3C3C3;
wire [31:0] tkupd0  =   (imm == 3'h0) ? tkupd0_xrotmsk_0 :
                        (imm == 3'h1) ? tkupd0_xrotmsk_1 :
                        (imm == 3'h2) ? tkupd0_xrotmsk_2 :
                         /* others */   32'h00000000;

wire [31:0] tkupd1_xrotmsk0_0 = (`RORI32(rs1,28)) & 32'h03030303;
wire [31:0] tkupd1_xrotmsk0_1 = (`RORI32(rs1,12)) & 32'h0C0C0C0C;

wire [31:0] tkupd1_xrotmsk1_0 = (`RORI32(rs1,14)) & 32'h30303030;
wire [31:0] tkupd1_xrotmsk1_1 = (`RORI32(rs1, 6)) & 32'h0C0C0C0C;

wire [31:0] tkupd1_xrotmsk2_0 = (`RORI32(rs1,12)) & 32'h03030303;
wire [31:0] tkupd1_xrotmsk2_1 = (`RORI32(rs1,28)) & 32'h0C0C0C0C;

wire [31:0] tkupd1_xrotmsk3_0 = (`RORI32(rs1,30)) & 32'h30303030;
wire [31:0] tkupd1_xrotmsk3_1 = (`RORI32(rs1,22)) & 32'h0C0C0C0C;

wire [31:0] tkupd1  =   (imm == 3'h0) ? (tkupd1_xrotmsk0_0 | tkupd1_xrotmsk0_1) :
                        (imm == 3'h1) ? (tkupd1_xrotmsk1_0 | tkupd1_xrotmsk1_1) :
                        (imm == 3'h2) ? (tkupd1_xrotmsk2_0 | tkupd1_xrotmsk2_1) :
                        (imm == 3'h3) ? (tkupd1_xrotmsk3_0 | tkupd1_xrotmsk3_1) :
                         /* others */   32'h00000000;                        
// ===================================================================================    

// lfsr instruction ==================================================================        
wire [31:0] lfsr2_r =   rs1 ^ (rs2        & 32'hAAAAAAAA) ;
wire [31:0] lfsr2   = (`SRLI32(lfsr2_r,1) & 32'h55555555) |  //0xAAAAAAAA >> 1
                      (`SLLI32(lfsr2_r,1) & 32'hAAAAAAAA) ;

wire [31:0] y_shf   =  `SRLI32(rs2,1);
wire [31:0] lfsr3_r =   rs1 ^ (y_shf      & 32'h55555555) ;  //0xAAAAAAAA >> 1;
wire [31:0] lfsr3   = (`SRLI32(lfsr3_r,1) & 32'h55555555) |  //0xAAAAAAAA >> 1
                      (`SLLI32(lfsr3_r,1) & 32'hAAAAAAAA) ;
// ===================================================================================    

assign      rd  = {32{op_mixcolumns }} & mixcolumn   |
                  {32{op_swapmove_xy}} & swapmove_xy |
                  {32{op_permtk     }} & permtk      |
                  {32{op_tkupd_0    }} & tkupd0      |
                  {32{op_tkupd_1    }} & tkupd1      |
                  {32{op_lfsr2      }} & lfsr2       |
                  {32{op_lfsr3      }} & lfsr3       ;

`undef RORI32
`undef SRLI32
`undef SLLI32
`undef swapmvxy
`undef swapmv

endmodule
