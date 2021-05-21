module rv32ell_ise (
input  wire [31:0]  rs1,
input  wire         op_ell,

output wire [31:0]  rd
);

wire [15:0] tmp = rs1[31:16] ^ rs1[15:0];
wire [31:0] ell = {rs1[15:0] , tmp};

assign  rd  = {32{op_ell}} & ell; 
endmodule

