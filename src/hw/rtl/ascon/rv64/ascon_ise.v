module ascon_ise (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,

input  wire [ 4:0]  imm,
input  wire         op_sigma,

output wire [63:0]  rd
);

//rotation amount look-up
reg [5:0] ramt0;
always @(*) begin
    case(imm)
            0  : ramt0 = 5'd19;
            1  : ramt0 = 5'd61;
            2  : ramt0 = 5'd01;
            3  : ramt0 = 5'd10;
            4  : ramt0 = 5'd07;
		default: ramt0 = 5'hXX;
    endcase
end

reg [5:0] ramt1;
always @(*) begin
    case(imm)
            0  : ramt1 = 5'd28;
            1  : ramt1 = 5'd39;
            2  : ramt1 = 5'd06;
            3  : ramt1 = 5'd17;
            4  : ramt1 = 5'd41;
		default: ramt1 = 5'hXX;
    endcase
end
 
wire [63:0] xr0, xr1;
rot64 xrot0 (.datin(rs1), .shamt(ramt0), .datout(xr0));
rot64 xrot1 (.datin(rs1), .shamt(ramt1), .datout(xr1));

wire [63:0] res = rs1 ^ xr0 ^ xr1;

assign      rd  = {64{op_sigma}} & res;

endmodule

module rot64(
input  wire [63:0]  datin,
input  wire [ 5:0]  shamt,
output wire [63:0]  datout
);

wire [63:0]    l0 =  datin;
wire [63:0]    l1 = {64{ shamt[0]}} & { l0[   0],  l0[63: 1]} |
                    {64{!shamt[0]}} &   l0[63:0];
wire [63:0]    l2 = {64{ shamt[1]}} & { l1[ 1:0],  l1[63: 2]} |
                    {64{!shamt[1]}} &   l1[63:0];
wire [63:0]    l4 = {64{ shamt[2]}} & { l2[ 3:0],  l2[63: 4]} |
                    {64{!shamt[2]}} &   l2[63:0];
wire [63:0]    l8 = {64{ shamt[3]}} & { l4[ 7:0],  l4[63: 8]} |
                    {64{!shamt[3]}} &   l4[63:0];
wire [63:0]   l16 = {64{ shamt[4]}} & { l8[15:0],  l8[63:16]} |
                    {64{!shamt[4]}} &   l8[63:0];
wire [63:0]   l32 = {64{ shamt[5]}} & {l16[31:0], l16[63:32]} |
                    {64{!shamt[5]}} &  l16[63:0];
assign datout = l32;
endmodule
