//Jambu Instruction Set Extension
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
input  [63:0]   ise_in1;
input  [63:0]   ise_in2;
input           ise_val;
output          ise_oval;
output [63:0]   ise_out; 

parameter [1:0] ISE_V  = 2'b11;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode rv64b_ise
wire        rv64b_sel;
wire [63:0] rv64b_rd;  
generate 
    if (ISE_V[0] == 1'b1) begin : RB64B
wire   op_roriw  = (funct[6:5] == 2'b01)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_rori   = (funct[6:5] == 2'b00)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_xnor   = (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_2);
wire   op_pack   = (funct[6:0] == 7'b0000001) && (ise_fn[1:0] == CUSTOM_2);
wire   op_packu  = (funct[6:0] == 7'b0000010) && (ise_fn[1:0] == CUSTOM_2);

assign rv64b_sel = op_roriw | op_rori | op_xnor | op_pack | op_packu;
rv64b_ise rv64b_ins(
    .rs1(      ise_in1  ),
    .rs2(      ise_in2  ),
    .rd (      rv64b_rd ),
    .imm(     funct[4:0]),
    .op_roriw( op_roriw ),
    .op_rori(  op_rori  ),
    .op_xnor(  op_xnor  ),
    .op_pack(  op_pack  ),
    .op_packu( op_packu )
);
end else begin            : No_RB64B
assign  rv64b_sel =  1'b0; 
assign  rv64b_rd  = 64'd0;  
    end
endgenerate

//decode jambu_ise
wire        jambu_ise_sel;
wire [63:0] jambu_ise_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : JAMBU_ISE_IMP
wire   op_block_0    = (funct[6:0] == 7'b0100000) && (ise_fn[1:0] == CUSTOM_3);
wire   op_block_1    = (funct[6:0] == 7'b0100001) && (ise_fn[1:0] == CUSTOM_3);
wire   op_block_2    = (funct[6:0] == 7'b0100010) && (ise_fn[1:0] == CUSTOM_3);
wire   op_block_3    = (funct[6:0] == 7'b0100011) && (ise_fn[1:0] == CUSTOM_3);
assign jambu_ise_sel = op_block_0 | op_block_1 | op_block_2 | op_block_3;

jambu_ise jambu_ise_ins2(
    .rs1(        ise_in1      ),
    .rs2(        ise_in2      ),
    .rd (        jambu_ise_rd ),
    .op_block_0( op_block_0   ),
    .op_block_1( op_block_1   ),
    .op_block_2( op_block_2   ),
    .op_block_3( op_block_3   )
);
end else begin                  : No_JAMBU_ISE
assign  jambu_ise_sel =  1'b0;
assign  jambu_ise_rd  = 64'd0;  
    end
endgenerate

wire [63:0] dout = {64{     rv64b_sel }} &     rv64b_rd |
                   {64{ jambu_ise_sel }} & jambu_ise_rd ;

assign  ise_oval = ise_val && (rv64b_sel | jambu_ise_sel);
assign  ise_out  = dout;

endmodule

