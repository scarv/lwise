module rv64ell_ise (
input  wire [63:0]  rs1,
input  wire         op_ell,
input  wire         op_ellrev,

output wire [63:0]  rd
);

wire [15:0] tmp_lo = rs1[31:16] ^ rs1[15:0];
wire [31:0] ell_lo = {rs1[15:0] , tmp_lo};

wire [31:0] rs1_hi = rs1[63:32];
wire [15:0] tmp_hi = rs1_hi[31:16] ^ rs1_hi[15:0];
wire [31:0] ell_hi = {rs1_hi[15:0] , tmp_hi};

assign  rd  = {64{op_ell}}    & {ell_hi, ell_lo} |
              {64{op_ellrev}} & {ell_lo, ell_hi} ; 
endmodule

