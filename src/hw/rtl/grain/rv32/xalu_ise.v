//grain Instruction Set Extension
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

parameter [1:0] ISE_V  = 2'b10;

localparam [1:0] CUSTOM_0 = 2'b00;
localparam [1:0] CUSTOM_1 = 2'b01;
localparam [1:0] CUSTOM_2 = 2'b10;
localparam [1:0] CUSTOM_3 = 2'b11; 

wire [6:0] funct    = ise_imm;

//decode romulus_ise
wire        grain_ise_sel;
wire [31:0] grain_ise_rd;
generate 
    if (ISE_V[1] == 1'b1) begin : GRAIN_ISE_IMP
wire   op_extr   = (funct[6:5] == 2'b00     ) && (ise_fn[1:0] == CUSTOM_0);
wire   op_fln0   = (funct[6:0] == 7'b0000000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_fln2   = (funct[6:0] == 7'b0001000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_gnn0   = (funct[6:0] == 7'b0010000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_gnn1   = (funct[6:0] == 7'b0011000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_gnn2   = (funct[6:0] == 7'b0100000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_hnn0   = (funct[6:0] == 7'b0101000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_hnn1   = (funct[6:0] == 7'b0110000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_hnn2   = (funct[6:0] == 7'b0111000) && (ise_fn[1:0] == CUSTOM_1);
wire   op_hln0   = (funct[6:0] == 7'b1000000) && (ise_fn[1:0] == CUSTOM_1);

assign grain_ise_sel   = op_extr | op_fln0 | op_fln2 | 
                         op_gnn0 | op_gnn1 | op_gnn2 | 
                         op_hnn0 | op_hnn1 | op_hnn2 | op_hln0;
grain_ise grain_ise_ins(
    .rs1(     ise_in1   ),
    .rs2(     ise_in2   ),
    .rd (  grain_ise_rd ),
    .imm(   funct[4:0]  ),
    .op_extr( op_extr   ),
    .op_fln0( op_fln0   ),
    .op_fln2( op_fln2   ),
    .op_gnn0( op_gnn0   ),
    .op_gnn1( op_gnn1   ),
    .op_gnn2( op_gnn2   ),
    .op_hnn0( op_hnn0   ),
    .op_hnn1( op_hnn1   ),
    .op_hnn2( op_hnn2   ),
    .op_hln0( op_hln0   )
);
end else begin            : No_GRAIN_ISE
assign  grain_ise_sel =  1'b0;
assign  grain_ise_rd  = 32'd0;
    end
endgenerate

wire [31:0] dout = {32{grain_ise_sel}} & grain_ise_rd ;

assign ise_oval = ise_val && grain_ise_sel;
assign ise_out  = dout;

endmodule


