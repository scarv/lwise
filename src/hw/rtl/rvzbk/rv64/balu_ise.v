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
input  [63:0]   ise_in1;
input  [63:0]   ise_in2;
input           ise_val; 
output          ise_oval;
output [63:0]   ise_out;  

`define ror64(x,  imm,  l)  ({64{imm[5]}} & {l16``l[31:0],l16``l[63:32]}) | ({64{!imm[5]}} &l16``l[63:0]); \
        wire [63:0] l16``l= ({64{imm[4]}} & { l8``l[15:0], l8``l[63:16]}) | ({64{!imm[4]}} & l8``l[63:0]); \
        wire [63:0] l8``l = ({64{imm[3]}} & { l4``l[ 7:0], l4``l[63: 8]}) | ({64{!imm[3]}} & l4``l[63:0]); \
        wire [63:0] l4``l = ({64{imm[2]}} & { l2``l[ 3:0], l2``l[63: 4]}) | ({64{!imm[2]}} & l2``l[63:0]); \
        wire [63:0] l2``l = ({64{imm[1]}} & { l1``l[ 1:0], l1``l[63: 2]}) | ({64{!imm[1]}} & l1``l[63:0]); \
        wire [63:0] l1``l = ({64{imm[0]}} & { l0``l[   0], l0``l[63: 1]}) | ({64{!imm[0]}} & l0``l[63:0]); \
        wire [63:0] l0``l = x  

`define rol64(x,  imm,  l)  ({64{imm[5]}} & {l16``l[31:0],l16``l[63:32]}) | ({64{!imm[5]}} &l16``l[63:0]); \
        wire [63:0] l16``l= ({64{imm[4]}} & { l8``l[47:0], l8``l[63:48]}) | ({64{!imm[4]}} & l8``l[63:0]); \
        wire [63:0] l8``l = ({64{imm[3]}} & { l4``l[55:0], l4``l[63:56]}) | ({64{!imm[3]}} & l4``l[63:0]); \
        wire [63:0] l4``l = ({64{imm[2]}} & { l2``l[59:0], l2``l[63:60]}) | ({64{!imm[2]}} & l2``l[63:0]); \
        wire [63:0] l2``l = ({64{imm[1]}} & { l1``l[61:0], l1``l[63:62]}) | ({64{!imm[1]}} & l1``l[63:0]); \
        wire [63:0] l1``l = ({64{imm[0]}} & { l0``l[62:0], l0``l[63   ]}) | ({64{!imm[0]}} & l0``l[63:0]); \
        wire [63:0] l0``l = x  

localparam [5:0] FN_ROR   = 6'd32;
localparam [5:0] FN_ROL   = 6'd33;
localparam [5:0] FN_RORI  = 6'd34;
localparam [5:0] FN_ANDN  = 6'd35;
localparam [5:0] FN_ORN   = 6'd36;
localparam [5:0] FN_XNOR  = 6'd37;
localparam [5:0] FN_PACK  = 6'd38;
localparam [5:0] FN_PACKH = 6'd39;
localparam [5:0] FN_RORW  = 6'd40;
localparam [5:0] FN_ROLW  = 6'd41;
localparam [5:0] FN_RORIW = 6'd42;
localparam [5:0] FN_PACKW = 6'd43;

wire   ror_sel = ise_val && (ise_fn == FN_ROR);
wire   rol_sel = ise_val && (ise_fn == FN_ROL);
wire  rori_sel = ise_val && (ise_fn == FN_RORI);
wire  andn_sel = ise_val && (ise_fn == FN_ANDN);
wire   orn_sel = ise_val && (ise_fn == FN_ORN);
wire  xnor_sel = ise_val && (ise_fn == FN_XNOR);
wire  pack_sel = ise_val && (ise_fn == FN_PACK);
wire packh_sel = ise_val && (ise_fn == FN_PACKH);
wire  rorw_sel = ise_val && (ise_fn == FN_RORW);
wire  rolw_sel = ise_val && (ise_fn == FN_ROLW);
wire roriw_sel = ise_val && (ise_fn == FN_RORIW);
wire packw_sel = ise_val && (ise_fn == FN_PACKW);

wire      roxw = rorw_sel | rolw_sel | roriw_sel;

wire [ 5:0] shamt  = roxw? {        1'b0 , ise_in2[ 4:0]} : ise_in2[5:0];
wire [63:0] win1   = roxw? {ise_in1[31:0], ise_in1[31:0]} : ise_in1;

wire [63:0] wror   = `ror64(win1, shamt, iror64);
wire [63:0] wrol   = `rol64(win1, shamt, irol64);
wire [63:0] wandn  = ise_in1 & (~ise_in2); 
wire [63:0] worn   = ise_in1 | (~ise_in2); 
wire [63:0] wxnor  = ise_in1 ^ (~ise_in2); 
wire [63:0] wpack  = {       ise_in2[31:0], ise_in1[31:0]};
wire [63:0] wpackw = {32'd0, ise_in2[15:0], ise_in1[15:0]};
wire [63:0] wpackh = {48'd0, ise_in2[ 7:0], ise_in1[ 7:0]};

wire [63:0] dout = {64{  ror_sel}} & wror  | 
                   {64{  rol_sel}} & wrol  |
                   {64{ rori_sel}} & wror  |
                   {64{ rorw_sel}} & {32'd0, wror[31:0]} |
                   {64{ rolw_sel}} & {32'd0, wrol[31:0]} |
                   {64{roriw_sel}} & {32'd0, wror[31:0]} |
                   {64{ andn_sel}} & wandn |
                   {64{  orn_sel}} & worn  |
                   {64{ xnor_sel}} & wxnor |
                   {64{ pack_sel}} & wpack |
                   {64{packw_sel}} & wpackw|
                   {64{packh_sel}} & wpackh;

assign ise_oval = ise_val;
assign ise_out  = dout;

endmodule


