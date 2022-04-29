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

parameter [1:0] ISE_V  = 2'b11;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode elephant_ise
wire        elephant_ise_sel;
wire [31:0] elephant_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : ELEPHANT_ISE_IMP
wire   op_pstep_x = ( funct[6:3] == 4'b0000 ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_pstep_y = ( funct[6:3] == 4'b0001 ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_sstep   = ( funct[6:3] == 4'b0010 ) && (ise_fn[1:0] == CUSTOM_0);


assign elephant_ise_sel  = op_pstep_x | op_pstep_y | op_sstep;

elephant_ise elephant_ise_v2_ins(
    .rs1(            ise_in1         ),
    .rs2(            ise_in2         ),
    .rd (            elephant_ise_rd ),
    .imm(            funct[2:0]      ),
    .op_pstep_x(    op_pstep_x     ),
    .op_pstep_y(    op_pstep_y     ),
    .op_sstep  (    op_sstep       )
);
end else begin            : No_ELEPHANT_ISE
assign  elephant_ise_sel =  1'b0;
assign  elephant_ise_rd  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{elephant_ise_sel}} & elephant_ise_rd;

assign ise_oval = ise_val && elephant_ise_sel;
assign ise_out  = dout;

endmodule


