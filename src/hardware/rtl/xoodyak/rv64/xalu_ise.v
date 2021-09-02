//Alzette Instruction Set Extension
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

parameter [0:0] ISE_V  = 1'b1;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode rv64b_ise
wire        rv64b_sel;
wire [63:0] rv64b_rd;  
generate 
    if (ISE_V[0] == 1'b1) begin : RB64B_IMP
wire   op_roli   = (funct[6:5] == 2'b00)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_roliw  = (funct[6:5] == 2'b01)      && (ise_fn[1:0] == CUSTOM_0);
wire   op_andn   = (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_1);
assign rv64b_sel = op_roli | op_roliw | op_andn;
rv64b_ise rv64b_ins(
    .rs1(      cop_rs1  ),
    .rs2(      cop_rs2  ),
    .rd (      rv64b_rd ),
    .imm(     funct[4:0]),
    .op_roli(  op_roli  ),
    .op_roliw( op_roliw ),
    .op_andn(  op_andn  )
);
end else begin            : No_RB64B
assign  rv64b_sel =  1'b0;
assign  rv64b_rd  = 64'd0;  
    end
endgenerate

wire [63:0] dout = {64{ rv64b_sel }} & rv64b_rd ;

assign  ise_oval = ise_val && rv64b_sel;
assign  ise_out  = dout;

endmodule

