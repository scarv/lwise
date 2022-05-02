//gift-cofb Instruction Set Extension
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

//decode gift_ise_v2
wire        gift_ise_sel_v2;
wire [31:0] gift_ise_rd_v2;  
generate 
    if (ISE_V[1] == 1'b1) begin : GIFT_ISE_IMP_V2
wire   op_key_updstd    = (funct[6:0] == 7'b0100000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_key_reorg     = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_1);
wire   op_key_updfix    = (funct[6:5] == 2'b10     ) && (ise_fn[1:0] == CUSTOM_1);
wire   op_swapmove      = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori_n        = (funct[6:5] == 2'b01     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori_b        = (funct[6:5] == 2'b10     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori_h        = (funct[6:5] == 2'b11     ) && (ise_fn[1:0] == CUSTOM_0);

assign gift_ise_sel_v2  = op_swapmove | op_key_updstd | op_key_reorg | 
                          op_key_updfix | op_rori_n | op_rori_b | op_rori_h;

gift_ise_v2 gift_ise_v2_ins(
    .rs1(            ise_in1        ),
    .rs2(            ise_in2        ),
    .rd (            gift_ise_rd_v2 ),
    .imm(            funct[4:0]     ),
    .op_swapmove(    op_swapmove    ),
    .op_key_updstd(  op_key_updstd  ),
    .op_key_reorg(   op_key_reorg   ),
    .op_key_updfix(  op_key_updfix  ),
    .op_rori_n(      op_rori_n      ),
    .op_rori_b(      op_rori_b      ),
    .op_rori_h(      op_rori_h      )
);
    end else begin            : NO_GIFT_ISE_V2
assign  gift_ise_sel_v2 =  1'b0;
assign  gift_ise_rd_v2  = 32'd0;  
    end
endgenerate

//decode gift_v2_ise
wire        gift_ise_sel_v3;
wire [31:0] gift_ise_rd_v3;  
generate 
    if (ISE_V[2] == 1'b1) begin : GIFT_ISE_IMP_V3
wire op_key_updstd_v3  = (funct[6:0] == 7'b0100001) && (ise_fn[1:0] == CUSTOM_1);
wire op_permbits_step  = (funct[6:5] == 2'b11     ) && (ise_fn[1:0] == CUSTOM_1);

assign gift_ise_sel_v3 = op_key_updstd_v3 | op_permbits_step;
gift_ise_v3 gift_v3_ins( 
    .rs1(            ise_in1          ),
    .rs2(            ise_in2          ),
    .rd (            gift_ise_rd_v3   ),
    .imm(            funct[4:0]       ),
    .op_permbits_step(op_permbits_step),
    .op_key_updstd(   op_key_updstd_v3)
);
    end else begin            : NO_GIFT_ISE_V3
assign  gift_ise_sel_v3 =  1'b0;
assign  gift_ise_rd_v3  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{gift_ise_sel_v2}} & gift_ise_rd_v2 |
                   {32{gift_ise_sel_v3}} & gift_ise_rd_v3 ;

assign ise_oval = ise_val && (gift_ise_sel_v2 | gift_ise_sel_v3);
assign ise_out  = dout;

endmodule


