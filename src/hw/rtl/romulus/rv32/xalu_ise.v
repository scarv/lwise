//romulus Instruction Set Extension
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

parameter [2:0] ISE_V  = 3'b110;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode romulus_ise_v2
wire        romulus_ise_sel_v2;
wire [31:0] romulus_ise_rd_v2;
generate 
    if (ISE_V[1] == 1'b1) begin : ROMULUS_ISE_IMP_V2
wire   op_rstep    = (funct[6:3] == 4'b0000) && (ise_fn[1:0] == CUSTOM_2);
wire   op_rc_upd   = (funct[6:3] == 4'b0000) && (ise_fn[1:0] == CUSTOM_0);
wire   op_tk_upd_0 = (funct[6:3] == 4'b0001) && (ise_fn[1:0] == CUSTOM_1);
wire   op_tk_upd_1 = (funct[6:3] == 4'b0010) && (ise_fn[1:0] == CUSTOM_1);
wire   op_rc_use_0 = (funct[6:3] == 4'b0010) && (ise_fn[1:0] == CUSTOM_0);
wire   op_rc_use_1 = (funct[6:3] == 4'b0011) && (ise_fn[1:0] == CUSTOM_0);
assign romulus_ise_sel_v2   = op_rstep | op_rc_upd | op_tk_upd_0 | op_tk_upd_1 | op_rc_use_0 | op_rc_use_1;

romulus_ise_v2 romulus_ise_v2_ins(
    .rs1(         ise_in1     ),
    .rs2(         ise_in2     ),
    .rd (   romulus_ise_rd_v2 ),
    .imm(         funct[2:0]  ),
    .op_rstep(    op_rstep    ),
    .op_rc_upd(   op_rc_upd   ),
    .op_rc_use_0( op_rc_use_0 ),
    .op_rc_use_1( op_rc_use_1 ),
    .op_tk_upd_0( op_tk_upd_0 ),
    .op_tk_upd_1( op_tk_upd_1 )
);
end else begin            : No_ROMULUS_ISE_V2
assign  romulus_ise_sel_v2 =  1'b0;
assign  romulus_ise_rd_v2  = 32'd0;
    end
endgenerate

//decode romulus_ise_v3
wire        romulus_ise_sel_v3;
wire [31:0] romulus_ise_rd_v3;
generate 
    if (ISE_V[2] == 1'b1) begin : ROMULUS_ISE_IMP_V3
wire   op_mixcolumns = (funct[6:3] == 4'b0000  )  && (ise_fn[1:0] == CUSTOM_3);
wire   op_swapmove_x = (funct[6:3] == 4'b0001  )  && (ise_fn[1:0] == CUSTOM_3);
wire   op_swapmove_y = (funct[6:3] == 4'b0010  )  && (ise_fn[1:0] == CUSTOM_3);
wire   op_permtk     = (funct[6:3] == 4'b0100  )  && (ise_fn[1:0] == CUSTOM_1);
wire   op_tkupd_0    = (funct[6:3] == 4'b0101  )  && (ise_fn[1:0] == CUSTOM_1);
wire   op_tkupd_1    = (funct[6:3] == 4'b0110  )  && (ise_fn[1:0] == CUSTOM_1);
wire   op_lfsr2      = (funct[6:0] == 7'b0100000) && (ise_fn[1:0] == CUSTOM_0);
wire   op_lfsr3      = (funct[6:0] == 7'b0101000) && (ise_fn[1:0] == CUSTOM_0);

assign romulus_ise_sel_v3 = op_mixcolumns | op_swapmove_x | op_swapmove_y | 
                            op_permtk | op_tkupd_0 | op_tkupd_1 | op_lfsr2 | op_lfsr3;

romulus_ise_v3 romulus_ise_v3_ins(
    .rs1(           ise_in1       ),
    .rs2(           ise_in2       ),
    .rd (      romulus_ise_rd_v3  ),
    .imm(           funct[2:0]    ),
    .op_mixcolumns( op_mixcolumns ),
    .op_swapmove_x( op_swapmove_x ),
    .op_swapmove_y( op_swapmove_y ),
    .op_permtk (    op_permtk     ),
    .op_tkupd_0(    op_tkupd_0    ),
    .op_tkupd_1(    op_tkupd_1    ),
    .op_lfsr2(      op_lfsr2      ),
    .op_lfsr3(      op_lfsr3      )
);
end else begin            : No_ROMULUS_ISE_V3
assign  romulus_ise_sel_v3 =  1'b0;
assign  romulus_ise_rd_v3  = 32'd0;
    end
endgenerate

wire [31:0] dout = {32{romulus_ise_sel_v2}} & romulus_ise_rd_v2 |
                   {32{romulus_ise_sel_v3}} & romulus_ise_rd_v3 ;

assign ise_oval = ise_val && (romulus_ise_sel_v2 | romulus_ise_sel_v3);
assign ise_out  = dout;

endmodule


