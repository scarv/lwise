module gift_cofb_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire [ 4:0]  imm,

input  wire         op_swapmove,
input  wire         op_keyupdate, 
input  wire         op_keyarrange,
input  wire         op_fskeyupdate, //FixslicedKeyUpdate

output wire [31:0]  rd
);

`define rotmsk( x, A, M )    ({ x[ A-1:0], x[31: A] } & M)                  //right rotation and mask
`define mskshl( x, A, M )    ({ x[31-A:0],{A{ 1'b0}}} &(M<<A))
`define shrmsk( x, A, M )    ({{A{ 1'b0}}, x[31: A] } & M)
`define swapmvc(x, A, M, L ) (  x ^ {t``L[31-S:0] , {A{1'b0}}}  ^ t``L); \
        wire[31:0]    t``L  =( (x ^ {{  A{  1'b0}},  x[31:S] }) &    M)     //swapmove with constants

`define swapmv(x, xshf, msk, t, tshf)   (x ^ tshf  ^ t); \
                        assign  t     = (x ^ xshf) & msk

wire [31:0] rt1;
wire [31:0] rs1_rsh   = `shr(rs1, imm, rsh0);
wire [31:0] rt1_lsh   = `lsh(rt1, imm, lsh0);
wire [31:0] swapmove  = `swapmv(rs1, rs1_rsh, rs2, rt1, rt1_lsh);


wire keyarrange_0 = op_keyarrange && (imm == 0);  
wire keyarrange_1 = op_keyarrange && (imm == 1);  
wire keyarrange_2 = op_keyarrange && (imm == 2);  
wire keyarrange_3 = op_keyarrange && (imm == 3);  

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

wire    fs_keyupdate_0 = op_fskeyupdate && (imm == 0);  
wire    fs_keyupdate_1 = op_fskeyupdate && (imm == 1);  
wire    fs_keyupdate_2 = op_fskeyupdate && (imm == 2);  
wire    fs_keyupdate_3 = op_fskeyupdate && (imm == 3);  
wire    fs_keyupdate_4 = op_fskeyupdate && (imm == 4);  
wire    fs_keyupdate_5 = op_fskeyupdate && (imm == 5);  
wire    fs_keyupdate_6 = op_fskeyupdate && (imm == 6);  
wire    fs_keyupdate_7 = op_fskeyupdate && (imm == 7);  
wire    fs_keyupdate_8 = op_fskeyupdate && (imm == 8);  
wire    fs_keyupdate_9 = op_fskeyupdate && (imm == 9);  

wire [31:0]        rt0 = `swapmvc(rs1, 16, 32'h00003333, _rt0);
wire [31:0] fs_upkey_0 = `swapmvc(rs1,  1, 32'h55554444, _fs0);

wire [31:0]        rt1 = `rotmsk(rs1, 24, 32'h33333333) | `rotmsk(rs1, 16, 32'hcccccccc); 
wire [31:0] fs_upkey_1 = `swapmvc(rt1,  1, 32'h55551100, _fs1);

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

wire [31:0] keyupdate  = `shrmsk(rs1, 12, 32'h0000000f) | `mskshl(rs1,  4, 32'h00000fff) |
                         `shrmsk(rs1,  2, 32'h3fff0000) | `mskshl(rs1, 14, 32'h00030000) ;

assign        rd  = {32{  keyarrange_0 }} & ka0        |
                    {32{  keyarrange_1 }} & ka1        |
                    {32{  keyarrange_2 }} & ka2        |
                    {32{  keyarrange_3 }} & ka3        |
                    {32{ fskeyupdate_0 }} & fs_upkey_0 |
                    {32{ fskeyupdate_1 }} & fs_upkey_1 |
                    {32{ fskeyupdate_2 }} & fs_upkey_2 |
                    {32{ fskeyupdate_3 }} & fs_upkey_3 |
                    {32{ fskeyupdate_4 }} & fs_upkey_4 |
                    {32{ fskeyupdate_5 }} & fs_upkey_5 |
                    {32{ fskeyupdate_6 }} & fs_upkey_6 |
                    {32{ fskeyupdate_7 }} & fs_upkey_7 |
                    {32{ fskeyupdate_8 }} & fs_upkey_8 |
                    {32{ fskeyupdate_9 }} & fs_upkey_9 |
                    {32{ op_swapmove   }} & sm_ins2    |
                    {32{ op_keyupdate  }} & keyupdate  ;
endmodule







