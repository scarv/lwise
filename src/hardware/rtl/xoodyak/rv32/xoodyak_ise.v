module xoodyak_ise(
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,

input  wire         op_xorrol,

output wire [31:0]  rd
);

//rotation 
wire [63:0] xr0 = { rs1[26:0], rs1[31:27] };
wire [31:0] yr1 = { rs2[17:0], rs2[31:18] };


wire [31:0] res = xr0 ^ yr1;

assign        rd  = {32{op_xorrol}} & res[   31: 0];
endmodule


