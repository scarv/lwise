//Bit Manipulation Instruction Set Extension for Cryptography
module balu_ise (
    ise_clk,
    ise_rst,
    ise_fn,
    ise_in1,   
    ise_in2,  
    ise_val,
    ise_oval,         
    ise_out    );
input           ise_clk, ise_rst;
input  [ 5:0]   ise_fn;
input  [31:0]   ise_in1;
input  [31:0]   ise_in2;
input           ise_val; 
output          ise_oval;
output [31:0]   ise_out;  

`define ror32(x,  imm,  l)  ({32{imm[4]}} & {l8``l[15:0], l8``l[31:16]}) | ({32{!imm[4]}} & l8``l[31:0]); \
        wire [31:0] l8``l = ({32{imm[3]}} & {l4``l[ 7:0], l4``l[31: 8]}) | ({32{!imm[3]}} & l4``l[31:0]); \
        wire [31:0] l4``l = ({32{imm[2]}} & {l2``l[ 3:0], l2``l[31: 4]}) | ({32{!imm[2]}} & l2``l[31:0]); \
        wire [31:0] l2``l = ({32{imm[1]}} & {l1``l[ 1:0], l1``l[31: 2]}) | ({32{!imm[1]}} & l1``l[31:0]); \
        wire [31:0] l1``l = ({32{imm[0]}} & {l0``l[   0], l0``l[31: 1]}) | ({32{!imm[0]}} & l0``l[31:0]); \
        wire [31:0] l0``l = x  

`define rol32(x,  imm,  l)  ({32{imm[4]}} & {l8``l[15:0], l8``l[31:16]}) | ({32{!imm[4]}} & l8``l[31:0]); \
        wire [31:0] l8``l = ({32{imm[3]}} & {l4``l[23:0], l4``l[31:24]}) | ({32{!imm[3]}} & l4``l[31:0]); \
        wire [31:0] l4``l = ({32{imm[2]}} & {l2``l[27:0], l2``l[31:28]}) | ({32{!imm[2]}} & l2``l[31:0]); \
        wire [31:0] l2``l = ({32{imm[1]}} & {l1``l[29:0], l1``l[31:30]}) | ({32{!imm[1]}} & l1``l[31:0]); \
        wire [31:0] l1``l = ({32{imm[0]}} & {l0``l[30:0], l0``l[31   ]}) | ({32{!imm[0]}} & l0``l[31:0]); \
        wire [31:0] l0``l = x  

`define rev(x, d, l)  rb``l; \
        wire [7:0]  rb``l; \
        for (genvar i = 0;  i < d; i = i + 1) begin: rev``l \
            assign rb``l[i] = x[d-i-1]; \
        end

`define zip32(x, l)  {zh``l, zl``l}; \
        wire [15:0]   zh``l, zl``l; \
        for (genvar i = 0;  i < 16; i = i + 1) begin: zip32``l \
            assign zh``l[i] = x[2*i + 1]; \
            assign zl``l[i] = x[2*i    ]; \
        end

`define unzip32(x, l) uz``l; \
        wire [31:0]   uz``l; \
        for (genvar i = 0;  i < 16; i = i + 1) begin: unzip32``l \
            assign uz``l[2*i  ] = x[i]; \
            assign uz``l[2*i+1] = x[i+16]; \
        end

`define lut4(x, i, l) res``l; \
        wire [3:0]    res``l = (i == 0) ? x[ 3: 0] : \
                               (i == 1) ? x[ 7: 4] : \
                               (i == 2) ? x[11: 8] : \
                               (i == 3) ? x[15:12] : \
                               (i == 4) ? x[19:16] : \
                               (i == 5) ? x[23:20] : \
                               (i == 6) ? x[27:24] : \
                               (i == 7) ? x[31:28] : \
                             /*(i == 0)*/ 0

`define lut8(x, i, l) res``l; \
        wire [7:0]    res``l = (i == 0) ? x[ 7: 0] : \
                               (i == 1) ? x[15: 8] : \
                               (i == 2) ? x[23:16] : \
                               (i == 3) ? x[31:24] : \
                             /*(i == 0)*/ 0


localparam [5:0] FN_ROR   = 6'd32;
localparam [5:0] FN_ROL   = 6'd33;
localparam [5:0] FN_RORI  = 6'd34;
localparam [5:0] FN_ANDN  = 6'd35;
localparam [5:0] FN_ORN   = 6'd36;
localparam [5:0] FN_XNOR  = 6'd37;
localparam [5:0] FN_PACK  = 6'd38;
localparam [5:0] FN_PACKH = 6'd39;
localparam [5:0] FN_BREV8 = 6'd44;
localparam [5:0] FN_REV8  = 6'd45;
localparam [5:0] FN_ZIP   = 6'd46;
localparam [5:0] FN_UNZIP = 6'd47;
localparam [5:0] FN_XPERM8= 6'd48;
localparam [5:0] FN_XPERM4= 6'd49;

wire    ror_sel = ise_val && (ise_fn == FN_ROR);
wire    rol_sel = ise_val && (ise_fn == FN_ROL);
wire   rori_sel = ise_val && (ise_fn == FN_RORI);
wire   andn_sel = ise_val && (ise_fn == FN_ANDN);
wire    orn_sel = ise_val && (ise_fn == FN_ORN);
wire   xnor_sel = ise_val && (ise_fn == FN_XNOR);
wire   pack_sel = ise_val && (ise_fn == FN_PACK);
wire  packh_sel = ise_val && (ise_fn == FN_PACKH);
wire  brev8_sel = ise_val && (ise_fn == FN_BREV8);
wire   rev8_sel = ise_val && (ise_fn == FN_REV8);
wire    zip_sel = ise_val && (ise_fn == FN_ZIP);
wire  unzip_sel = ise_val && (ise_fn == FN_UNZIP);
wire xperm8_sel = ise_val && (ise_fn == FN_XPERM8);
wire xperm4_sel = ise_val && (ise_fn == FN_XPERM4);


wire [ 4:0] shamt  = ise_in2[4:0];
wire [31:0] wror   = `ror32(ise_in1, shamt, iror32);
wire [31:0] wrol   = `rol32(ise_in1, shamt, irol32);
wire [31:0] wandn  = ise_in1 & (~ise_in2); 
wire [31:0] worn   = ise_in1 | (~ise_in2); 
wire [31:0] wxnor  = ise_in1 ^ (~ise_in2); 
wire [31:0] wpack  = {       ise_in2[15:0], ise_in1[15:0]};
wire [31:0] wpackh = {16'd0, ise_in2[ 7:0], ise_in1[ 7:0]};

wire [ 7:0] brev8_0 = `rev(ise_in1[ 7: 0], 8, irev8_0)
wire [ 7:0] brev8_1 = `rev(ise_in1[15: 8], 8, irev8_1)
wire [ 7:0] brev8_2 = `rev(ise_in1[23:16], 8, irev8_2)
wire [ 7:0] brev8_3 = `rev(ise_in1[31:24], 8, irev8_3)
wire [31:0] wbrev8  = {brev8_3, brev8_2, brev8_1, brev8_0};

wire [31:0] wrev8 = {ise_in1[ 7: 0], ise_in1[15: 8], ise_in1[23:16], ise_in1[31:24]};

wire [31:0] wzip   = `zip32(  ise_in1, izip32)
wire [31:0] wunzip = `unzip32(ise_in1, iunzip32)

wire [ 7:0] wlut8_0 = `lut8(ise_in1, ise_in2[ 7: 0], ilut8_0);
wire [ 7:0] wlut8_1 = `lut8(ise_in1, ise_in2[15: 8], ilut8_1);
wire [ 7:0] wlut8_2 = `lut8(ise_in1, ise_in2[23:16], ilut8_2);
wire [ 7:0] wlut8_3 = `lut8(ise_in1, ise_in2[31:24], ilut8_3);
wire [31:0] wxperm8 = {wlut8_3, wlut8_2, wlut8_1, wlut8_0};

wire [ 3:0] wlut4_0 = `lut4(ise_in1, ise_in2[ 3: 0], ilut4_0);
wire [ 3:0] wlut4_1 = `lut4(ise_in1, ise_in2[ 7: 4], ilut4_1);
wire [ 3:0] wlut4_2 = `lut4(ise_in1, ise_in2[11: 8], ilut4_2);
wire [ 3:0] wlut4_3 = `lut4(ise_in1, ise_in2[15:12], ilut4_3);
wire [ 3:0] wlut4_4 = `lut4(ise_in1, ise_in2[19:16], ilut4_4);
wire [ 3:0] wlut4_5 = `lut4(ise_in1, ise_in2[23:20], ilut4_5);
wire [ 3:0] wlut4_6 = `lut4(ise_in1, ise_in2[27:24], ilut4_6);
wire [ 3:0] wlut4_7 = `lut4(ise_in1, ise_in2[31:28], ilut4_7);
wire [31:0] wxperm4 = {wlut4_7, wlut4_6, wlut4_5, wlut4_4, wlut4_3, wlut4_2, wlut4_1, wlut4_0};


wire [31:0] dout = {32{   ror_sel}} & wror   |
                   {32{   rol_sel}} & wrol   |
                   {32{  rori_sel}} & wror   |
                   {32{  andn_sel}} & wandn  |
                   {32{   orn_sel}} & worn   |
                   {32{  xnor_sel}} & wxnor  |
                   {32{  pack_sel}} & wpack  |
                   {32{ packh_sel}} & wpackh |
                   {32{ brev8_sel}} & wbrev8 |
                   {32{  rev8_sel}} & wrev8  |
                   {32{   zip_sel}} & wzip   |
                   {32{ unzip_sel}} & wunzip |
                   {32{xperm8_sel}} & wxperm8|
                   {32{xperm4_sel}} & wxperm4;

assign ise_oval = ise_val;
assign ise_out  = dout;

endmodule


