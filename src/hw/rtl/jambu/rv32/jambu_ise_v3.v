module jambu_ise_v3 (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,

input  wire         op_fsr_27,
input  wire         op_fsr_21,
input  wire         op_fsr_15,
input  wire         op_fsr_06,

output wire [31:0]  rd
);

wire [ 4:0] shamt = imm[4:0]; 

//64-bit right rotation
wire [63:0] opr64 = {rs2, rs1};

wire [63:0] ror64_27 = {opr64[26: 0], opr64[63:27]};
wire [63:0] ror64_21 = {opr64[20: 0], opr64[63:21]};
wire [63:0] ror64_15 = {opr64[14: 0], opr64[63:15]};
wire [63:0] ror64_06 = {opr64[ 5: 0], opr64[63: 6]};

assign           rd  = {32{op_fsr_27}} & ror64_27[31: 0] |
                       {32{op_fsr_21}} & ror64_21[31: 0] |
                       {32{op_fsr_15}} & ror64_15[31: 0] |
                       {32{op_fsr_06}} & ror64_06[31: 0] ;
endmodule


