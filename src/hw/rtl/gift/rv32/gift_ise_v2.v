module gift_ise_v2(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_key_reorg,
input  wire         op_key_updstd, 
input  wire         op_key_updfix, //FixslicedKeyUpdate
input  wire         op_swapmove,
input  wire         op_rori_n,      //used in Fixsliced
input  wire         op_rori_b,      //used in Fixsliced
input  wire         op_rori_h,      //used in Fixsliced


output wire [31:0]  rd
);

`define rotmsk( x, A, M )    ({ x[ A-1:0], x[31: A] } & M)                  //right rotation and mask
`define mskshl( x, A, M )    ({ x[31-A:0],{A{ 1'b0}}} &(M<<A))
`define shrmsk( x, A, M )    ({{A{ 1'b0}}, x[31: A] } & M)
`define swapmvc(x, A, M, L ) (  x ^ {t``L[31-A:0] , {A{1'b0}}}  ^ t``L); \
        wire[31:0]    t``L  =( (x ^ {{  A{  1'b0}},  x[31:A] }) &    M)     //swapmove with constants

`define rsh(x,imm, l)       ({32{imm[4]}} & {16'd0, l8``l[31:16]}) | ({32{!imm[4]}} & l8``l[31:0]); \
        wire [31:0] l8``l = ({32{imm[3]}} & { 8'd0, l4``l[31: 8]}) | ({32{!imm[3]}} & l4``l[31:0]); \
        wire [31:0] l4``l = ({32{imm[2]}} & { 4'd0, l2``l[31: 4]}) | ({32{!imm[2]}} & l2``l[31:0]); \
        wire [31:0] l2``l = ({32{imm[1]}} & { 2'd0, l1``l[31: 2]}) | ({32{!imm[1]}} & l1``l[31:0]); \
        wire [31:0] l1``l = ({32{imm[0]}} & { 1'd0, l0``l[31: 1]}) | ({32{!imm[0]}} & l0``l[31:0]); \
        wire [31:0] l0``l = x  

`define lsh(x,imm, l)       ({32{imm[4]}} & {l8``l[15:0], 16'd0 }) | ({32{!imm[4]}} & l8``l[31:0]); \
        wire [31:0] l8``l = ({32{imm[3]}} & {l4``l[23:0],  8'd0 }) | ({32{!imm[3]}} & l4``l[31:0]); \
        wire [31:0] l4``l = ({32{imm[2]}} & {l2``l[27:0],  4'd0 }) | ({32{!imm[2]}} & l2``l[31:0]); \
        wire [31:0] l2``l = ({32{imm[1]}} & {l1``l[29:0],  2'd0 }) | ({32{!imm[1]}} & l1``l[31:0]); \
        wire [31:0] l1``l = ({32{imm[0]}} & {l0``l[30:0],  1'd0 }) | ({32{!imm[0]}} & l0``l[31:0]); \
        wire [31:0] l0``l = x

`define swapmv(x, xshf, msk, t, tshf)   (x ^ tshf  ^ t); \
        assign  t     = (x ^ xshf) & msk

`define rori4( x,imm,n,l)   ({ 4{imm[1]}} & {l1``l[ 1:0], l1``l[ 3: 2]}) | ({ 4{!imm[1]}} & l1``l[ 3:0]); \
        wire [ 3:0] l1``l = ({ 4{imm[0]}} & {l0``l[   0], l0``l[ 3: 1]}) | ({ 4{!imm[0]}} & l0``l[ 3:0]); \
        wire [31:0] l0``l = x[ 4*n +:4]  
                
`define rori8( x,imm,n,l)   ({ 8{imm[2]}} & {l2``l[ 3:0], l2``l[ 7: 4]}) | ({ 8{!imm[2]}} & l2``l[ 7:0]); \
        wire [ 7:0] l2``l = ({ 8{imm[1]}} & {l1``l[ 1:0], l1``l[ 7: 2]}) | ({ 8{!imm[1]}} & l1``l[ 7:0]); \
        wire [ 7:0] l1``l = ({ 8{imm[0]}} & {l0``l[   0], l0``l[ 7: 1]}) | ({ 8{!imm[0]}} & l0``l[ 7:0]); \
        wire [31:0] l0``l = x[ 8*n +:8]  
                
`define rori16(x,imm,n,l)   ({16{imm[3]}} & {l4``l[ 7:0], l4``l[15: 8]}) | ({16{!imm[3]}} & l4``l[15:0]); \
        wire [15:0] l4``l = ({16{imm[2]}} & {l2``l[ 3:0], l2``l[15: 4]}) | ({16{!imm[2]}} & l2``l[15:0]); \
        wire [15:0] l2``l = ({16{imm[1]}} & {l1``l[ 1:0], l1``l[15: 2]}) | ({16{!imm[1]}} & l1``l[15:0]); \
        wire [15:0] l1``l = ({16{imm[0]}} & {l0``l[   0], l0``l[15: 1]}) | ({16{!imm[0]}} & l0``l[15:0]); \
        wire [15:0] l0``l = x[16*n +:16]

wire [31:0] rt1;
wire [31:0] rs1_rsh   = `rsh(rs1, imm, rsh0);
wire [31:0] rt1_lsh   = `lsh(rt1, imm, lsh0);


wire [31:0] key_updstd = `shrmsk(rs1, 12, 32'h0000000f) | `mskshl(rs1,  4, 32'h00000fff) |
                        `shrmsk(rs1,  2, 32'h3fff0000) | `mskshl(rs1, 14, 32'h00030000) ;                        
             
wire key_reorg_0 = op_key_reorg && (imm == 0);  
wire key_reorg_1 = op_key_reorg && (imm == 1);  
wire key_reorg_2 = op_key_reorg && (imm == 2);  
wire key_reorg_3 = op_key_reorg && (imm == 3);  

wire [31:0]  ka00 = `swapmvc(rs1 ,  9, 32'h00550055, _ka00);
wire [31:0]  ka01 = `swapmvc(ka00, 18, 32'h00003333, _ka01);
wire [31:0]  ka02 = `swapmvc(ka01, 12, 32'h000f000f, _ka02);
wire [31:0]  ka0  = `swapmvc(ka02, 24, 32'h000000ff, _ka03);

wire [31:0]  ka10 = `swapmvc(rs1 ,  3, 32'h11111111, _ka10);
wire [31:0]  ka11 = `swapmvc(ka10,  6, 32'h03030303, _ka11);
wire [31:0]  ka12 = `swapmvc(ka11, 12, 32'h000f000f, _ka12);
wire [31:0]  ka1  = `swapmvc(ka12, 24, 32'h000000ff, _ka13);

wire [31:0]  ka20 = `swapmvc(rs1 , 15, 32'h0000aaaa, _ka20);
wire [31:0]  ka21 = `swapmvc(ka20, 18, 32'h00003333, _ka21);
wire [31:0]  ka22 = `swapmvc(ka21, 12, 32'h0000f0f0, _ka22);
wire [31:0]  ka2  = `swapmvc(ka22, 24, 32'h000000ff, _ka23);

wire [31:0]  ka30 = `swapmvc(rs1 ,  3, 32'h0a0a0a0a, _ka30);
wire [31:0]  ka31 = `swapmvc(ka30,  6, 32'h00cc00cc, _ka31);
wire [31:0]  ka32 = `swapmvc(ka31, 12, 32'h0000f0f0, _ka32);
wire [31:0]  ka3  = `swapmvc(ka32, 24, 32'h000000ff, _ka33);

wire [31:0] key_updfix;
wire [31:0] swapmove;
wire [31:0] rori_h;
wire [31:0] rori_b;
wire [31:0] rori_n;

wire     key_updfix_0 = op_key_updfix && (imm == 0);  
wire     key_updfix_1 = op_key_updfix && (imm == 1);  
wire     key_updfix_2 = op_key_updfix && (imm == 2);  
wire     key_updfix_3 = op_key_updfix && (imm == 3);  
wire     key_updfix_4 = op_key_updfix && (imm == 4);  
wire     key_updfix_5 = op_key_updfix && (imm == 5);  
wire     key_updfix_6 = op_key_updfix && (imm == 6);  
wire     key_updfix_7 = op_key_updfix && (imm == 7);  
wire     key_updfix_8 = op_key_updfix && (imm == 8);  
wire     key_updfix_9 = op_key_updfix && (imm == 9);  

wire [31:0]        rt0 = `swapmvc(rs1, 16, 32'h00003333, _rt0);
wire [31:0] fs_upkey_0 = `swapmvc(rt0,  1, 32'h55554444, _fs0);

wire [31:0]        rt2 = `rotmsk(rs1, 24, 32'h33333333) | `rotmsk(rs1, 16, 32'hcccccccc); 
wire [31:0] fs_upkey_1 = `swapmvc(rt2,  1, 32'h55551100, _fs1);

wire [31:0] fs_upkey_2 = `shrmsk(rs1,  4, 32'h0f000f00) | `mskshl(rs1,  4, 32'h0f000f00) |
                         `shrmsk(rs1,  6, 32'h00030003) | `mskshl(rs1,  2, 32'h003f003f) ;

wire [31:0] fs_upkey_3 = `shrmsk(rs1,  6, 32'h03000300) | `mskshl(rs1,  2, 32'h3f003f00) |
                         `shrmsk(rs1,  5, 32'h00070007) | `mskshl(rs1,  3, 32'h001f001f) ;

wire [31:0] fs_upkey_4 = `rotmsk(rs1, 24, 32'haaaaaaaa) | `rotmsk(rs1, 16, 32'h55555555);

wire [31:0] fs_upkey_5 = `rotmsk(rs1, 24, 32'h55555555) | `rotmsk(rs1, 20, 32'haaaaaaaa);

wire [31:0] fs_upkey_6 = `shrmsk(rs1,  2, 32'h03030303) | `mskshl(rs1,  2, 32'h03030303) |
                         `shrmsk(rs1,  1, 32'h70707070) | `mskshl(rs1,  3, 32'h10101010) ;

wire [31:0] fs_upkey_7 = `shrmsk(rs1, 18, 32'h00003030) | `mskshl(rs1,  3, 32'h01010101) |
                         `shrmsk(rs1, 14, 32'h0000c0c0) | `mskshl(rs1, 15, 32'h0000e0e0) |
                         `shrmsk(rs1,  1, 32'h07070707) | `mskshl(rs1, 19, 32'h00001010) ;

wire [31:0] fs_upkey_8 = `shrmsk(rs1,  4, 32'h0fff0000) | `mskshl(rs1, 12, 32'h000f0000) |
                         `shrmsk(rs1,  8, 32'h000000ff) | `mskshl(rs1,  8, 32'h000000ff) ;

wire [31:0] fs_upkey_9 = `shrmsk(rs1,  6, 32'h03ff0000) | `mskshl(rs1, 10, 32'h003f0000) |
                         `shrmsk(rs1,  4, 32'h00000fff) | `mskshl(rs1, 12, 32'h0000000f) ;

assign key_updfix = {32{ key_updfix_0 }} & fs_upkey_0 |
                    {32{ key_updfix_1 }} & fs_upkey_1 |
                    {32{ key_updfix_2 }} & fs_upkey_2 |
                    {32{ key_updfix_3 }} & fs_upkey_3 |
                    {32{ key_updfix_4 }} & fs_upkey_4 |
                    {32{ key_updfix_5 }} & fs_upkey_5 |
                    {32{ key_updfix_6 }} & fs_upkey_6 |
                    {32{ key_updfix_7 }} & fs_upkey_7 |
                    {32{ key_updfix_8 }} & fs_upkey_8 |
                    {32{ key_updfix_9 }} & fs_upkey_9 ;

assign  swapmove  = `swapmv(rs1, rs1_rsh, rs2, rt1, rt1_lsh);

assign  rori_h[1*16+:16] = `rori16(rs1, imm, 1, i16_1);
assign  rori_h[0   +:16] = `rori16(rs1, imm, 0, i16_0);

assign  rori_b[3*8 +: 8] = `rori8( rs1, imm, 3, i8_3 );
assign  rori_b[2*8 +: 8] = `rori8( rs1, imm, 2, i8_2 );
assign  rori_b[1*8 +: 8] = `rori8( rs1, imm, 1, i8_1 );
assign  rori_b[0   +: 8] = `rori8( rs1, imm, 0, i8_0 );

assign  rori_n[7*4 +: 4] = `rori4( rs1, imm, 7, i4_7 );
assign  rori_n[6*4 +: 4] = `rori4( rs1, imm, 6, i4_6 );
assign  rori_n[5*4 +: 4] = `rori4( rs1, imm, 5, i4_5 );
assign  rori_n[4*4 +: 4] = `rori4( rs1, imm, 4, i4_4 );
assign  rori_n[3*4 +: 4] = `rori4( rs1, imm, 3, i4_3 );
assign  rori_n[2*4 +: 4] = `rori4( rs1, imm, 2, i4_2 );
assign  rori_n[1*4 +: 4] = `rori4( rs1, imm, 1, i4_1 );
assign  rori_n[0   +: 4] = `rori4( rs1, imm, 0, i4_0 );           

assign        rd  = {32{key_reorg_0   }} & ka0        |
                    {32{key_reorg_1   }} & ka1        |
                    {32{key_reorg_2   }} & ka2        |
                    {32{key_reorg_3   }} & ka3        |
                    {32{op_key_updstd }} & key_updstd |
                    {32{op_key_updfix }} & key_updfix |
                    {32{op_swapmove   }} & swapmove   |
                    {32{op_rori_n     }} & rori_n     |
                    {32{op_rori_b     }} & rori_b     |
                    {32{op_rori_h     }} & rori_h     ;   
endmodule

