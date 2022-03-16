//Co-processor interface for Jambu ISE
module cop_ise (
    cop_clk,
    cop_rst,
    cop_valid,
    cop_rdywr,
    cop_ready,
    cop_wait,
    cop_wr,
    cop_insn,   
    cop_rs1,   
    cop_rs2,           
    cop_rd    );
input           cop_clk, cop_rst;
input           cop_valid;
input 	        cop_rdywr;
output          cop_ready; 
output          cop_wait;
output          cop_wr;
input  [31:0]   cop_insn;
input  [31:0]   cop_rs1;
input  [31:0]   cop_rs2;
output [31:0]   cop_rd;  

parameter [2:0] ISE_V  = 3'b111;

localparam [6:0] CUSTOM_0 = 7'b0001011;
localparam [6:0] CUSTOM_1 = 7'b0101011;
localparam [6:0] CUSTOM_2 = 7'b1011011;
localparam [6:0] CUSTOM_3 = 7'b1111011; 

assign     cop_wait = 1'b0;
wire [6:0] funct    = cop_insn[31:25];

//decode jambu_ise_v2
wire        jambu_ise_v2_sel;
wire [31:0] jambu_ise_v2_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : JAMBU_ISE_V2_IMP
wire   op_fsri            = (funct[6:5] == 2'b00) && (cop_insn[6:0] == CUSTOM_1);
assign jambu_ise_v2_sel   = op_fsri;

jambu_ise_v2 jambu_ise_v2_ins(
    .rs1(     ise_in1      ),
    .rs2(     ise_in2      ),
    .rd (     jambu_ise_v2_rd ),
    .imm(     funct[4:0]   ),
    .op_fsri( op_fsri    )
);
end else begin            : No_JAMBU_ISE_V2
assign  jambu_ise_v2_sel =  1'b0;
assign  jambu_ise_v2_rd  = 32'd0;  
    end
endgenerate

//decode jambu_ise_v3
wire        jambu_ise_v3_sel;
wire [31:0] jambu_ise_v3_rd;  
generate 
    if (ISE_V[1] == 1'b1) begin : JAMBU_ISE_V3_IMP
wire   op_fsr_27         = (funct[6:0] == 7'b0000011) && (cop_insn[6:0] == CUSTOM_3);
wire   op_fsr_21         = (funct[6:0] == 7'b0000010) && (cop_insn[6:0] == CUSTOM_3);
wire   op_fsr_15         = (funct[6:0] == 7'b0000000) && (cop_insn[6:0] == CUSTOM_3);
wire   op_fsr_06         = (funct[6:0] == 7'b0000001) && (cop_insn[6:0] == CUSTOM_3);
assign jambu_ise_v3_sel  = op_fsr_27 | op_fsr_21 | op_fsr_15 | op_fsr_06;

jambu_ise_v3 jambu_ise_v3_ins(
    .rs1(       ise_in1         ),
    .rs2(       ise_in2         ),
    .rd (       jambu_ise_v3_rd ),
    .op_fsr_27( op_fsr_27       ),
    .op_fsr_21( op_fsr_21       ),
    .op_fsr_15( op_fsr_15       ),
    .op_fsr_06( op_fsr_06       )
);
end else begin            : No_JAMBU_ISE_V3
assign  jambu_ise_v3_sel =  1'b0;
assign  jambu_ise_v3_rd  = 32'd0;  
    end
endgenerate

wire [31:0] dout = {32{jambu_ise_v2_sel}} & jambu_ise_v2_rd |
                   {32{jambu_ise_v3_sel}} & jambu_ise_v3_rd ;

wire   stallResp = cop_wr && (~cop_rdywr);
assign cop_ready = ~stallResp;

assign cop_wr = cop_valid && (jambu_ise_v2_sel | jambu_ise_v3_sel);
assign cop_rd = dout;

endmodule


