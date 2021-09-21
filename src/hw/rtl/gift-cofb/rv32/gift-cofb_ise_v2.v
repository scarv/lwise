module gift-cofb_ise(
input  wire [31:0]  rs1,
input  wire [ 4:0]  imm,

input  wire         swapmove,
input  wire         keyupdate, 
input  wire         keyarrange,
input  wire         fs_keyupdate, //FixslicedKeyUpdate

output wire [31:0]  rd
);

`define rotmsk(x, A, M) ({ x[ A-1:0], x[31: A] } & M)  //right rotation and mask
`define mskshl(x, A, M) ({ x[31-A:0],{A{ 1'b0}}} &(M<<A))
`define shrmsk(x, A, M) ({{A{ 1'b0}}, x[31: A] } & M)


wire swapmove_0   = swapmove   && (imm = 0);  // swapmov : mask = 0x55555555 shamt =  1
wire swapmove_1   = swapmove   && (imm = 1);  // swapmov : mask = 0x00005555 shamt =  1
wire swapmove_2   = swapmove   && (imm = 2);  // swapmov : mask = 0x55550000 shamt =  1

wire [31:0] sm_ins0, sm_ins1, sm_ins2;
swapmove #(32'h55555555,1) sm_0 (rs1, sm_ins0);
swapmove #(32'h00005555,1) sm_1 (rs1, sm_ins1);
swapmove #(32'h55550000,1) sm_2 (rs1, sm_ins2);


wire [31:0]         tem =  {28'h0000000,rs1[16:12]}     | {16'h0000,rs1[11:0],4'h0};         //   ((x >> 12) & 0x0000000f) | ((x & 0x00000fff) <<  4);
wire [31:0] updated_key =  { 2'b00,rs1[31:18],16'h0000} | {rs1[17:16],30'd0} | tem;          // | ((x >>  2) & 0x3fff0000) | ((x & 0x00030000) << 14);


wire keyarrange_0 = keyarrange && (imm = 0);  
wire keyarrange_1 = keyarrange && (imm = 1);  
wire keyarrange_2 = keyarrange && (imm = 2);  
wire keyarrange_3 = keyarrange && (imm = 3);  

wire [31:0] ka00, ka01, ka02, ka03;
swapmove #(32'h00550055, 9) sm_ka00 (rs1 , ka00);
swapmove #(32'h00003333,18) sm_ka01 (ka00, ka01);
swapmove #(32'h000f000f,12) sm_ka02 (ka01, ka02);
swapmove #(32'h000000ff,24) sm_ka03 (ka02, ka03);

wire [31:0] ka10, ka11, ka12, ka13;
swapmove #(32'h11111111, 3) sm_ka10 (rs1 , ka10);
swapmove #(32'h03030303, 6) sm_ka11 (ka10, ka11);
swapmove #(32'h000f000f,12) sm_ka12 (ka11, ka12);
swapmove #(32'h000000ff,24) sm_ka13 (ka12, ka13);

wire [31:0] ka20, ka21, ka22, ka23;
swapmove #(32'h0000aaaa,15) sm_ka20 (rs1 , ka20);
swapmove #(32'h00003333,18) sm_ka21 (ka20, ka21);
swapmove #(32'h0000f0f0,12) sm_ka22 (ka21, ka22);
swapmove #(32'h000000ff,24) sm_ka23 (ka22, ka23);

wire [31:0] ka30, ka31, ka32, ka33;
swapmove #(32'h0a0a0a0a, 3) sm_ka30 (rs1 , ka30);
swapmove #(32'h00cc00cc, 6) sm_ka31 (ka30, ka31);
swapmove #(32'h0000f0f0,12) sm_ka32 (ka31, ka32);
swapmove #(32'h000000ff,24) sm_ka33 (ka32, ka33);

wire fs_keyupdate_0 = fs_keyupdate && (imm = 0);  
wire fs_keyupdate_1 = fs_keyupdate && (imm = 1);  
wire fs_keyupdate_2 = fs_keyupdate && (imm = 2);  
wire fs_keyupdate_3 = fs_keyupdate && (imm = 3);  
wire fs_keyupdate_4 = fs_keyupdate && (imm = 4);  
wire fs_keyupdate_5 = fs_keyupdate && (imm = 5);  
wire fs_keyupdate_6 = fs_keyupdate && (imm = 6);  
wire fs_keyupdate_7 = fs_keyupdate && (imm = 7);  
wire fs_keyupdate_8 = fs_keyupdate && (imm = 8);  
wire fs_keyupdate_9 = fs_keyupdate && (imm = 9);  

wire [31:0] fs_upkey_0, rt0;
swapmove #(32'h00003333,16) sm_fsuk00 (rs1, rt0);
swapmove #(32'h55554444, 1) sm_fsup01 (rt0, fs_upkey_0);

wire [31:0] fs_upkey_1, rt1;
assign        rt1 = `rotmsk(rs1, 24, 32'h33333333) | `rotmsk(rs1, 16, 32'hcccccccc); 
swapmove #(32'h55554444, 1) sm_fsuk10 (rt1, fs_upkey_1);

wire [31:0] fs_upkey_2;
assign fs_upkey_2 = `shrmsk(rs1,  4, 32'h0f000f00) | `mskshl(rs1,  4, 32'h0f000f00) |
                    `shrmsk(rs1,  6, 32'h00030003) | `mskshl(rs1,  2, 32'h003f003f) ;

wire [31:0] fs_upkey_3;
assign fs_upkey_3 = `shrmsk(rs1,  6, 32'h03000300) | `mskshl(rs1,  2, 32'h3f003f00) |
                    `shrmsk(rs1,  5, 32'h00070007) | `mskshl(rs1,  3, 32'h001f001f) ;

wire [31:0] fs_upkey_4;
assign fs_upkey_4 = `rotmsk(rs1, 24, 32'haaaaaaaa) | `rotmsk(rs1, 16, 32'h55555555);

wire [31:0] fs_upkey_5;
assign fs_upkey_5 = `rotmsk(rs1, 24, 32'h55555555) | `rotmsk(rs1, 20, 32'haaaaaaaa);

wire [31:0] fs_upkey_6;
assign fs_upkey_6 = `shrmsk(rs1,  2, 32'h03030303) | `mskshl(rs1,  2, 32'h03030303) |
                    `shrmsk(rs1,  1, 32'h70707070) | `mskshl(rs1,  3, 32'h10101010) ;

wire [31:0] fs_upkey_7;
assign fs_upkey_7 = `shrmsk(rs1, 18, 32'h00003030) | `mskshl(rs1,  3, 32'h01010101) |
                    `shrmsk(rs1, 14, 32'h0000c0c0) | `mskshl(rs1, 15, 32'h0000e0e0) |
                    `shrmsk(rs1,  1, 32'h07070707) | `mskshl(rs1, 19, 32'h00001010) ;

wire [31:0] fs_upkey_8;
assign fs_upkey_8 = `shrmsk(rs1,  4, 32'h0fff0000) | `mskshl(rs1, 12, 32'h000f0000) |
                    `shrmsk(rs1,  8, 32'h000000ff) | `mskshl(rs1,  8, 32'h000000ff) ;

wire [31:0] fs_upkey_9;
assign fs_upkey_9 = `shrmsk(rs1,  6, 32'h03ff0000) | `mskshl(rs1, 10, 32'h003f0000) |
                    `shrmsk(rs1,  4, 32'h00000fff) | `mskshl(rs1, 12, 32'h0000000f) ;

assign        rd  = {32{swapmove | keyarrange}} & sm3        |
                    {32{     keyupdate       }} & updated_key;
endmodule

module swapmove #(
	parameter [31:0] M = 32'h00000000,  //mask
    parameter        A = 0			    //amount
) (
    input  wire [31:0] x,
    output wire [31:0] r
)

wire [31:0]   t = (x ^ {{A{1'b0}},  x[31:A]}) & M; //x ^ (x >> n)) & mask;
assign        r =  x ^ {t[31-S:0], {A{1'b0}}} ^ t; 
endmodule






