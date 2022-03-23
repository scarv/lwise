//elephant Instruction Set Extension
module xalu_ise (
    ise_clk,
    ise_rst,
    ise_fn,
    ise_imm,   
    ise_in1,   
    ise_in2,  
    ise_val,
    ise_oval,         
    ise_out    );
input           ise_clk, ise_rst;
input  [ 5:0]   ise_fn;
input  [ 6:0]   ise_imm;
input  [31:0]   ise_in1;
input  [31:0]   ise_in2;
input           ise_val; 
output          ise_oval;
output [31:0]   ise_out;  

parameter [2:0] ISE_V  = 3'b111;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

wire   op_pstep1   = (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_1);

//decode elephant_ise_v2
wire        elephant_ise_sel_v2;
wire [31:0] elephant_ise_rd_v2;  
generate 
    if (ISE_V[1] == 1'b1) begin : ELEPHANT_ISE_V2_IMP
wire   op_bsllxor  = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_bup      = (funct[6:5] == 2'b10     ) && (ise_fn[1:0] == CUSTOM_0);

assign elephant_ise_sel_v2  = op_bsllxor | op_bup | op_pstep1 ;

elephant_ise_v2 elephant_ise_v2_ins(
    .rs1(            ise_in1            ),
    .rs2(            ise_in2            ),
    .rd (            elephant_ise_rd_v2 ),
    .imm(            funct[4:0]         ),
    .op_bsllxor(     op_bsllxor         ),
    .op_bup(         op_bup             ),
    .op_pstep1(      op_pstep1          )
);
end else begin            : No_ELEPHANT_ISE_V2
assign  elephant_ise_sel_v2 =  1'b0;
assign  elephant_ise_rd_v2  = 32'd0;  
    end
endgenerate

//decode elephant_ise_v3
wire        elephant_ise_sel_v3;
wire [31:0] elephant_ise_rd_v3;  
generate 
    if (ISE_V[2] == 1'b1) begin : ELEPHANT_ISE_V3_IMP
wire   op_pstep2_0  = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_2);
wire   op_pstep2_8  = (funct[6:5] == 2'b01     ) && (ise_fn[1:0] == CUSTOM_2);
wire   op_pstep2_16 = (funct[6:5] == 2'b10     ) && (ise_fn[1:0] == CUSTOM_2);
wire   op_pstep2_24 = (funct[6:5] == 2'b11     ) && (ise_fn[1:0] == CUSTOM_2);
wire   op_bupd      = (funct[6:5] == 2'b11     ) && (ise_fn[1:0] == CUSTOM_0);

assign elephant_ise_sel_v3  = op_pstep2_0 | op_pstep2_8 | op_pstep2_16 | op_pstep2_24 | op_pstep1 | op_bupd ;

elephant_ise_v3 elephant_ise_v3_ins(
    .rs1(            ise_in1            ),
    .rs2(            ise_in2            ),
    .rd (            elephant_ise_rd_v3 ),
    .imm(            funct[4:0]         ),
    .op_pstep2_0(    op_pstep2_0        ),
    .op_pstep2_8(    op_pstep2_8        ),
    .op_pstep2_16(   op_pstep2_16       ),
    .op_pstep2_24(   op_pstep2_24       ),
    .op_pstep1(      op_pstep1          ),
    .op_bupd(        op_bupd            )
);
end else begin            : No_ELEPHANT_ISE_V3
assign  elephant_ise_sel_v3 =  1'b0;
assign  elephant_ise_rd_v3  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{elephant_ise_sel_v2}} & elephant_ise_rd_v2 |
                   {32{elephant_ise_sel_v3}} & elephant_ise_rd_v3 ;

assign ise_oval = ise_val && (elephant_ise_sel_v2 || elephant_ise_sel_v3);
assign ise_out  = dout;

endmodule


