module rv64ell_ise (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,
input  wire         op_ell,
input  wire         op_ellrev,

output wire [63:0]  rd
);

wire [63:0] xrs    = rs1 ^ rs2;

wire [15:0] tmp_lo = xrs[31:16] ^ xrs[15:0];
wire [31:0] ell_lo = {xrs[15:0] , tmp_lo};

wire [31:0] xrs_hi = xrs[63:32];
wire [15:0] tmp_hi = xrs_hi[31:16] ^ xrs_hi[15:0];
wire [31:0] ell_hi = {xrs_hi[15:0] , tmp_hi};

assign  rd  = {64{op_ell}}    & {ell_hi, ell_lo} |
              {64{op_ellrev}} & {ell_lo, ell_hi} ; 
endmodule

