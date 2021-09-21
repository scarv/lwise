module gift-cofb_ise(
input  wire [31:0]  rs1,
input  wire [ 4:0]  imm,

input  wire         swapmove,
input  wire         keyupdate, 
input  wire         keyarrange,

output wire [31:0]  rd
);

wire keyarrange_0 = keyarrange && (imm = 0);  // swapmov : mask = 0x00550055 shamt =  9
wire keyarrange_1 = keyarrange && (imm = 1);  // swapmov : mask = 0x11111111 shamt =  3
wire keyarrange_2 = keyarrange && (imm = 2);  // swapmov : mask = 0x0000aaaa shamt = 15
wire keyarrange_3 = keyarrange && (imm = 3);  // swapmov : mask = 0x0a0a0a0a shamt =  3

// swapmove 0
wire [31:0] sm0_mask  = keyarrange_0 ?  32'h00550055:
                        keyarrange_1 ?  32'h11111111:
                        keyarrange_2 ?  32'h0000aaaa: 
                      /*keyarrange_3*/  32'h0a0a0a0a;

wire [31:0] rs1_rshf  = keyarrange_0 ?  { 9'd0, rs1[31: 9]}:
                        keyarrange_1 ?  { 3'd0, rs1[31: 3]}:
                        keyarrange_2 ?  {15'd0, rs1[31:15]}: 
                      /*keyarrange_3*/  { 3'd0, rs1[31: 3]};
 
wire [31:0] sm0_tem   = (rs1 ^ rs1_rshf) & sm0_mask; //x ^ (x >> n)) & mask;

wire [31:0] tem0_lshf = keyarrange_0 ?  {sm0_tem[22:0],  9'd0}:
                        keyarrange_1 ?  {sm0_tem[28:0],  3'd0}:
                        keyarrange_2 ?  {sm0_tem[16:0], 15'd0}: 
                      /*keyarrange_3*/  {sm0_tem[28:0],  3'd0};

wire [31:0] sm0 = rs1 ^ sm0_tem ^ tem0_lshf;

// swapmove 1
wire [31:0] sm1_mask  = keyarrange_0 ?  32'h00003333: // swapmov : mask = 0x00003333 shamt = 18
                        keyarrange_1 ?  32'h03030303: // swapmov : mask = 0x03030303 shamt =  6
                        keyarrange_2 ?  32'h00003333: // swapmov : mask = 0x00003333 shamt = 18 
                      /*keyarrange_3*/  32'h00cc00cc; // swapmov : mask = 0x00cc00cc shamt =  6 
wire [31:0] sm0_rshf  = (keyarrange_0 || keyarrange_2) ?  {18'd0, sm0[31:18]}:
                      /*(keyarrange_1 || keyarrange_3)*/  { 6'd0, sm0[31: 6]};
 
wire [31:0] sm1_tem   = (sm0 ^ sm0_rshf) & sm1_mask; //x ^ (x >> n)) & mask;
wire [31:0] tem1_lshf = (keyarrange_0 || keyarrange_2) ? {sm1_tem[13:0],18'd0}:
                      /*(keyarrange_1 || keyarrange_3)*/ {sm1_tem[25:0], 6'd0};

wire [31:0] sm1 = sm0 ^ sm1_tem ^ tem1_lshf;

// swapmove 2
wire [31:0] sm2_mask  = (keyarrange_0 || keyarrange_1) ? 32'h000f000f: // swapmov : mask = 0x000f000f shamt = 12
                      /*(keyarrange_2 || keyarrange_3)*/ 32'h0000f0f0; // swapmov : mask = 0x0000f0f0 shamt = 12
wire [31:0] sm1_rshf  = {12'd0, sm1[31:12]};                
 
wire [31:0] sm2_tem   = (sm1 ^ sm1_rshf) & sm2_mask; //x ^ (x >> n)) & mask;
wire [31:0] tem2_lshf = {sm2_tem[19:0],12'd0};

wire [31:0] sm2 = sm1 ^ sm2_tem ^ tem2_lshf;

wire swapmove_0   = swapmove   && (imm = 0);  // swapmov : mask = 0x00003333 shamt = 16
wire swapmove_1   = swapmove   && (imm = 1);  // swapmov : mask = 0x55554444 shamt =  1
wire swapmove_2   = swapmove   && (imm = 2);  // swapmov : mask = 0x55551100 shamt =  1

wire swapmove_3   = swapmove   && (imm = 3);  // swapmov : mask = 0x55555555 shamt =  1
wire swapmove_4   = swapmove   && (imm = 4);  // swapmov : mask = 0x00005555 shamt =  1
wire swapmove_5   = swapmove   && (imm = 5);  // swapmov : mask = 0x55550000 shamt =  1

// swapmove 3 MUX swapmov instr.

wire [31:0] sm3_in = swapmove ? rs1 : sm2;

wire [31:0] sm3_mask  = (~swapmove)  ? 32'h000000ff: 
                          swapmove_0 ? 32'h00003333: 
                          swapmove_1 ? 32'h55554444: 
                          swapmove_2 ? 32'h55551100: 
                          swapmove_3 ? 32'h55555555: 
                          swapmove_4 ? 32'h00005555: 
                        /*swapmove_5*/ 32'h55550000; 

wire [31:0] sm2_rshf  = (~swapmove)    ? {24'd0, sm3_in[31:24]}: 
                          swapmove_0   ? {16'd0, sm3_in[31:16]}:
                        /*swapmove_1-5*/ { 1'd0, sm3_in[31: 1]};                 
 
wire [31:0] sm3_tem   = (sm2 ^ sm2_rshf) & sm3_mask; //x ^ (x >> n)) & mask;
wire [31:0] tem3_lshf = (~swapmove)    ? {sm3_tem[ 7:0], 24'd0}: 
                          swapmove_0   ? {sm3_tem[15:0], 16'd0}:
                        /*swapmove_1-5*/ {sm3_tem[30:0],  1'd0};

wire [31:0] sm3 = sm3_in ^ sm3_tem ^ tem3_lshf;

wire [31:0]         tem =  {28'h0000000,rs1[16:12]}     | {16'h0000,rs1[11:0],4'h0};         //   ((x >> 12) & 0x0000000f) | ((x & 0x00000fff) <<  4);
wire [31:0] updated_key =  { 2'b00,rs1[31:18],16'h0000} | {rs1[17:16],30'd0} | tem;          // | ((x >>  2) & 0x3fff0000) | ((x & 0x00030000) << 14);

assign        rd  = {32{swapmove | keyarrange}} & sm3        |
                    {32{     keyupdate       }} & updated_key;
endmodule


