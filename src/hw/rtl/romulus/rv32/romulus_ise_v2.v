module romulus_ise_v2(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 2:0]  imm,
input  wire         op_rstep,
input  wire         op_rc_upd,
input  wire         op_tk_upd_0,
input  wire         op_tk_upd_1,
input  wire         op_rc_use_0,
input  wire         op_rc_use_1,

output wire [31:0]  rd
);

`define ROLI32(a,b) ((a << b) | (a >> 32-b))
function [7:0] SBOX;
    input[7:0] x;
    reg  [7:0] x1, x2, x3;
    reg        t0_7, t0_6, t0_5, t0_4, t0_3, t0_2, t0_1, t0_0;
    reg        t1_7, t1_6, t1_5, t1_4, t1_3, t1_2, t1_1, t1_0;
    reg        t2_7, t2_6, t2_5, t2_4, t2_3, t2_2, t2_1, t2_0;
    reg        t3_7, t3_6, t3_5, t3_4, t3_3, t3_2, t3_1, t3_0;
    begin
    t0_0 = x[0] ^ ~( x[2] | x[3] );
    t0_1 = x[1];
    t0_2 = x[2];
    t0_3 = x[3];
    t0_4 = x[4] ^ ~( x[6] | x[7] );
    t0_5 = x[5];
    t0_6 = x[6];
    t0_7 = x[7];

    x1 = {t0_2, t0_1, t0_7, t0_6, t0_4, t0_0, t0_3, t0_5};

    t1_0 = x1[0] ^ ~( x1[2] | x1[3] );
    t1_1 = x1[1];
    t1_2 = x1[2];
    t1_3 = x1[3];
    t1_4 = x1[4] ^ ~( x1[6] | x1[7] );
    t1_5 = x1[5];
    t1_6 = x1[6];
    t1_7 = x1[7];

    x2 = {t1_2, t1_1, t1_7, t1_6, t1_4, t1_0, t1_3, t1_5};

    t2_0 = x2[0] ^ ~( x2[2] | x2[3] );
    t2_1 = x2[1];
    t2_2 = x2[2];
    t2_3 = x2[3];
    t2_4 = x2[4] ^ ~( x2[6] | x2[7] );
    t2_5 = x2[5];
    t2_6 = x2[6];
    t2_7 = x2[7];

    x3 = {t2_2, t2_1, t2_7, t2_6, t2_4, t2_0, t2_3, t2_5};

    t3_0 = x3[0] ^ ~( x3[2] | x3[3] );
    t3_1 = x3[1];
    t3_2 = x3[2];
    t3_3 = x3[3];
    t3_4 = x3[4] ^ ~( x3[6] | x3[7] );
    t3_5 = x3[5];
    t3_6 = x3[6];
    t3_7 = x3[7];

    SBOX = {t3_7, t3_6, t3_5, t3_4, t3_3, t3_1, t3_2, t3_0};
    end
endfunction

function [7:0] rc_lfsr;
    input[7:0] x;
    rc_lfsr = {2'b00, x[4:0], x[5]^x[4]^1'b1};
endfunction

function [7:0] tk2_lfsr;
    input[7:0] x;
    tk2_lfsr = {x[6:0], x[7]^x[5]};
endfunction

function [7:0] tk3_lfsr;
    input[7:0] x;
    tk3_lfsr = {x[6]^x[0], x[7:1]};
endfunction

wire [31:0] rc_upd   = {24'h000000, rc_lfsr(rs1[7:0])};
wire [31:0] rc_use_0 = {rs2[31:4], rs2[3:0] ^ rs1[3:0]};
wire [31:0] rc_use_1 = {rs2[31:2], rs2[1:0] ^ rs1[5:4]};

wire [31:0] sr = {SBOX(rs1[31:24]),
                  SBOX(rs1[23:16]),
                  SBOX(rs1[15: 8]),
                  SBOX(rs1[ 7: 0])};

wire [31:0]  r = (imm == 3'h2) ? (sr ^ 2) :
                 (imm == 3'h3) ?  sr      :
                                  sr ^ rs2;
wire [31:0] rstep = (imm == 3'h1) ? `ROLI32(r, 8) :
                    (imm == 3'h2) ? `ROLI32(r,16) :
                    (imm == 3'h3) ? `ROLI32(r,24) :
                  /*(imm == 3'h0)*/         r     ;

wire [31:0] tt     = (op_tk_upd_0) ? {rs2[15: 8], rs1[7:0], rs2[31:24], rs1[15: 8]} :
                   /*(op_tk_upd_1)*/ {rs1[31:24], rs2[7:0], rs2[23:16], rs1[23:16]} ;

wire [31:0] tk_upd = (imm == 3'h1) ?            tt   :
                     (imm == 3'h2) ? { tk2_lfsr(tt[31:24]), tk2_lfsr(tt[23:16]), tk2_lfsr(tt[15:8]), tk2_lfsr(tt[7:0]) } :
                     (imm == 3'h3) ? { tk3_lfsr(tt[31:24]), tk3_lfsr(tt[23:16]), tk3_lfsr(tt[15:8]), tk3_lfsr(tt[7:0]) } :
                                               32'd0 ;

assign      rd  = {32{op_rc_upd  }} & rc_upd   |
                  {32{op_rc_use_0}} & rc_use_0 |
                  {32{op_rc_use_1}} & rc_use_1 |
                  {32{op_rstep   }} & rstep    |
                  {32{op_tk_upd_0}} & tk_upd   |
                  {32{op_tk_upd_1}} & tk_upd   ;

endmodule


