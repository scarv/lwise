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
input  [ 4:0]   ise_fn;
input  [ 6:0]   ise_imm;
input  [31:0]   ise_in1;
input  [31:0]   ise_in2;
input           ise_val; 
output          ise_oval;
output [31:0]   ise_out;  

parameter [1:0] ISE_V  = 2'b11;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode gift_cofb_ise
wire        gift_cofb_ise_sel;
wire [31:0] gift_cofb_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : GIFT_COFB_ISE_IMP
wire   op_swapmove         = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_keyupdate        = (funct[6:0] == 7'b0100000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_keyarrange       = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_1);
wire   op_fskeyupdate      = (funct[6:5] == 2'b10     ) && (ise_fn[1:0] == CUSTOM_1);
wire   op_rori_n           = (funct[6:5] == 2'b01     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori_b           = (funct[6:5] == 2'b10     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori_h           = (funct[6:5] == 2'b11     ) && (ise_fn[1:0] == CUSTOM_0);

assign gift_cofb_ise_sel   = op_swapmove | op_keyupdate | op_keyarrange | 
                             op_fskeyupdate | op_rori_n | op_rori_b | op_rori_h;

gift_ise gift_ise_ins(
    .rs1(            ise_in1          ),
    .rs2(            ise_in2          ),
    .rd (            gift_cofb_ise_rd ),
    .imm(            funct[4:0]       ),
    .op_swapmove(    op_swapmove      ),
    .op_keyupdate(   op_keyupdate     ),
    .op_keyarrange(  op_keyarrange    ),
    .op_fskeyupdate( op_fskeyupdate   ),
    .op_rori_n(      op_rori_n        ),
    .op_rori_b(      op_rori_b        ),
    .op_rori_h(      op_rori_h        )
);
end else begin            : No_GIFT_COFB_ISE
assign  gift_cofb_ise_sel =  1'b0;
assign  gift_cofb_ise_rd  = 32'd0;  
    end
endgenerate


wire [31:0] dout = {32{gift_cofb_ise_sel}} & gift_cofb_ise_rd ;

assign ise_oval = ise_val && gift_cofb_ise_sel;
assign ise_out  = dout;

endmodule

