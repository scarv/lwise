module rv32ell_ise (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,
input  wire         op_ell,

output wire [31:0]  rd
);
wire [31:0] xrs = rs1 ^ rs2;
wire [15:0] tmp = xrs[31:16] ^ xrs[15:0];
wire [31:0] ell = {xrs[15:0] , tmp};

assign  rd  = {32{op_ell}} & ell; 
endmodule

