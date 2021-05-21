module alzette_ise_v3 (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,

input  wire         op_addror_31,
input  wire         op_addror_24,
input  wire         op_addror_17,

input  wire         op_subror_31,
input  wire         op_subror_24,
input  wire         op_subror_17,

input  wire         op_xorror_31,
input  wire         op_xorror_24,
input  wire         op_xorror_17,
input  wire         op_xorror_16,

output wire [31:0]  rd
);

wire op_rori31 = op_addror_31 | op_subror_31 | op_xorror_31;
wire op_rori24 = op_addror_24 | op_subror_24 | op_xorror_24;
wire op_rori17 = op_addror_17 | op_subror_17 | op_xorror_17;
wire op_rori16 =                               op_xorror_16;

wire op_add = op_addror_31 | op_addror_24 | op_addror_17;
wire op_sub = op_subror_31 | op_subror_24 | op_subror_17;

wire [31:0] rs2_rori = {32{op_rori31}} & {rs2[30:0],rs2[   31]} |   //rs2>>>31
                       {32{op_rori24}} & {rs2[23:0],rs2[31:24]} |   //rs2>>>24
                       {32{op_rori17}} & {rs2[16:0],rs2[31:17]} |   //rs2>>>17 
                       {32{op_rori16}} & {rs2[15:0],rs2[31:16]} ;   //rs2>>>16 

wire [31:0] addrori  = rs1 + rs2_rori;   //rs1 + rs2>>>op_rot
wire [31:0] subrori  = rs1 - rs2_rori;   //rs1 - rs2>>>op_rot
wire [31:0] xorrori  = rs1 ^ rs2_rori;   //rs1 ^ rs2>>>op_rot

assign           rd  = op_add ? addrori : 
                       op_sub ? subrori :
                    /* op_xor */xorrori ; 
endmodule
