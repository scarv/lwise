module photon_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 2:0]  imm,
input  wire         op_step,

output wire [31:0]  rd
);


//  SBOX[ 16 ] = {
//  0xC, 0x5, 0x6, 0xB, 0x9, 0x0, 0xA, 0xD, 
//  0x3, 0xE, 0xF, 0x8, 0x4, 0x7, 0x1, 0x2
//};

function [3:0] photon_SBOX;
    input[3:0] a;
    photon_SBOX = (a == 4'h0) ? 4'hc :
                  (a == 4'h1) ? 4'h5 :
                  (a == 4'h2) ? 4'h6 :
                  (a == 4'h3) ? 4'hb :
                  (a == 4'h4) ? 4'h9 :
                  (a == 4'h5) ? 4'h0 :
                  (a == 4'h6) ? 4'ha :
                  (a == 4'h7) ? 4'hd :
                  (a == 4'h8) ? 4'h3 :
                  (a == 4'h9) ? 4'he :
                  (a == 4'ha) ? 4'hf :
                  (a == 4'hb) ? 4'h8 :
                  (a == 4'hc) ? 4'h4 :
                  (a == 4'hd) ? 4'h7 :
                  (a == 4'he) ? 4'h1 :
                /*(a == 4'hf)*/ 4'h2 ;
endfunction

// M    = {
//  { 0x2, 0x4, 0x2, 0xB, 0x2, 0x8, 0x5, 0x6 },
//  { 0xC, 0x9, 0x8, 0xD, 0x7, 0x7, 0x5, 0x2 },
//  { 0x4, 0x4, 0xD, 0xD, 0x9, 0x4, 0xD, 0x9 },
//  { 0x1, 0x6, 0x5, 0x1, 0xC, 0xD, 0xF, 0xE },
//  { 0xF, 0xC, 0x9, 0xD, 0xE, 0x5, 0xE, 0xD },
//  { 0x9, 0xE, 0x5, 0xF, 0x4, 0xC, 0x9, 0x6 },
//  { 0xC, 0x2, 0x2, 0xA, 0x3, 0x1, 0x1, 0xE },
//  { 0xF, 0x1, 0xD, 0xA, 0x5, 0xA, 0x2, 0x3 },
// }

function [3:0] photon_M0;
    input[2:0] imm;
    photon_M0 = (imm == 3'h0) ? 4'h2 :
                (imm == 3'h1) ? 4'h4 :
                (imm == 3'h2) ? 4'h2 :
                (imm == 3'h3) ? 4'hb :
                (imm == 3'h4) ? 4'h2 :
                (imm == 3'h5) ? 4'h8 :
                (imm == 3'h6) ? 4'h5 :
              /*(imm == 3'h7)*/ 4'h6 ;
endfunction
function [3:0] photon_M1;
    input[2:0] imm;
    photon_M1 = (imm == 3'h0) ? 4'hc :
                (imm == 3'h1) ? 4'h9 :
                (imm == 3'h2) ? 4'h8 :
                (imm == 3'h3) ? 4'hd :
                (imm == 3'h4) ? 4'h7 :
                (imm == 3'h5) ? 4'h7 :
                (imm == 3'h6) ? 4'h5 :
              /*(imm == 3'h7)*/ 4'h2 ;
endfunction
function [3:0] photon_M2;
    input[2:0] imm;
    photon_M2 = (imm == 3'h0) ? 4'h4 :
                (imm == 3'h1) ? 4'h4 :
                (imm == 3'h2) ? 4'hd :
                (imm == 3'h3) ? 4'hd :
                (imm == 3'h4) ? 4'h9 :
                (imm == 3'h5) ? 4'h4 :
                (imm == 3'h6) ? 4'hd :
              /*(imm == 3'h7)*/ 4'h9 ;
endfunction
function [3:0] photon_M3;
    input[2:0] imm;
    photon_M3 = (imm == 3'h0) ? 4'h1 :
                (imm == 3'h1) ? 4'h6 :
                (imm == 3'h2) ? 4'h5 :
                (imm == 3'h3) ? 4'h1 :
                (imm == 3'h4) ? 4'hc :
                (imm == 3'h5) ? 4'hd :
                (imm == 3'h6) ? 4'hf :
              /*(imm == 3'h7)*/ 4'he ;
endfunction
function [3:0] photon_M4;
    input[2:0] imm;
    photon_M4 = (imm == 3'h0) ? 4'hf :
                (imm == 3'h1) ? 4'hc :
                (imm == 3'h2) ? 4'h9 :
                (imm == 3'h3) ? 4'hd :
                (imm == 3'h4) ? 4'he :
                (imm == 3'h5) ? 4'h5 :
                (imm == 3'h6) ? 4'he :
              /*(imm == 3'h7)*/ 4'hd ;
endfunction
function [3:0] photon_M5;
    input[2:0] imm;
    photon_M5 = (imm == 3'h0) ? 4'h9 :
                (imm == 3'h1) ? 4'he :
                (imm == 3'h2) ? 4'h5 :
                (imm == 3'h3) ? 4'hf :
                (imm == 3'h4) ? 4'h4 :
                (imm == 3'h5) ? 4'hc :
                (imm == 3'h6) ? 4'h9 :
              /*(imm == 3'h7)*/ 4'h6 ;
endfunction
function [3:0] photon_M6;
    input[2:0] imm;
    photon_M6 = (imm == 3'h0) ? 4'hc :
                (imm == 3'h1) ? 4'h2 :
                (imm == 3'h2) ? 4'h2 :
                (imm == 3'h3) ? 4'ha :
                (imm == 3'h4) ? 4'h3 :
                (imm == 3'h5) ? 4'h1 :
                (imm == 3'h6) ? 4'h1 :
              /*(imm == 3'h7)*/ 4'he ;
endfunction
function [3:0] photon_M7;
    input[2:0] imm;
    photon_M7 = (imm == 3'h0) ? 4'hf :
                (imm == 3'h1) ? 4'h1 :
                (imm == 3'h2) ? 4'hd :
                (imm == 3'h3) ? 4'ha :
                (imm == 3'h4) ? 4'h5 :
                (imm == 3'h5) ? 4'ha :
                (imm == 3'h6) ? 4'h2 :
              /*(imm == 3'h7)*/ 4'h3 ;
endfunction

// Multiply by 2 in GF(2^4) modulo 4'h3
function [3:0] photon_x2;
    input [3:0] a;
    photon_x2  = {a[2:0],1'b0} ^ (a[3] ? 4'h3 : 4'b0 );
endfunction

// Paired down multiply by X in GF(2^4)
function [3:0] photon_xN;
    input[3:0] a;
    input[3:0] b;
    photon_xN =
        (b[0] ?                                a   : 0) ^
        (b[1] ? photon_x2(                     a)  : 0) ^
        (b[2] ? photon_x2(photon_x2(           a)) : 0) ^
        (b[3] ? photon_x2(photon_x2(photon_x2( a))): 0) ;
endfunction

wire [3:0] ty = (imm == 3'h0) ? rs2[ 3: 0] :
                (imm == 3'h1) ? rs2[ 7: 4] :
                (imm == 3'h2) ? rs2[11: 8] :
                (imm == 3'h3) ? rs2[15:12] :
                (imm == 3'h4) ? rs2[19:16] :
                (imm == 3'h5) ? rs2[23:20] :
                (imm == 3'h6) ? rs2[27:24] :
              /*(imm == 3'h7)*/ rs2[31:28] ;

wire [3:0] t = photon_SBOX(ty);

wire [3:0] n0 = photon_xN( photon_M0(imm), t );
wire [3:0] n1 = photon_xN( photon_M1(imm), t );
wire [3:0] n2 = photon_xN( photon_M2(imm), t );
wire [3:0] n3 = photon_xN( photon_M3(imm), t );
wire [3:0] n4 = photon_xN( photon_M4(imm), t );
wire [3:0] n5 = photon_xN( photon_M5(imm), t );
wire [3:0] n6 = photon_xN( photon_M6(imm), t );
wire [3:0] n7 = photon_xN( photon_M7(imm), t );

wire [31:0] res = rs1 ^ {n7, n6, n5, n4, n3, n2, n1, n0};

assign      rd  = {32{op_step}} & res[   31: 0];
endmodule


