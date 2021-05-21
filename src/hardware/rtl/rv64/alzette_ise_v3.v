module alzette_ise_v3 (
input  wire [63:0]  rs1,
input  wire [63:0]  rs2,

input  wire [ 2:0]  funct,

output wire [63:0]  rd
);
                           
wire [31:0] y = rs1[63:32]; 
wire [31:0] x = rs1[31: 0]; 
wire [31:0] c = rs2[31: 0]; 

wire        op_enc   = ~funct[2];
wire [ 1:0] op_rot   = funct[1:0];
//encryption
wire [31:0] add0_lhs = x;
wire [31:0] add0_rhs = (op_rot==2'b00)? {y[30:0],y[   31]}:   //         y>>>31
                       (op_rot==2'b01)? {y[16:0],y[31:17]}:   //         y>>>17
                       (op_rot==2'b10)? {y[31:1],y[    0]}:   //         y>>>0
                      /*op_rot==2'b11)*/{y[23:0],y[31:24]};   //         y>>>24  
wire [31:0] add0     = add0_lhs + add0_rhs;                   //x <- x + y>>>op_rot

wire [31:0] xor0_lhs = y;
wire [31:0] xor0_rhs = (op_rot==2'b00)? {add0[23:0],add0[31:24]}:   //         x>>>24
                       (op_rot==2'b01)? {add0[16:0],add0[31:17]}:   //         x>>>17
                       (op_rot==2'b10)? {add0[30:0],add0[   31]}:   //         x>>>31
                      /*op_rot==2'b11)*/{add0[15:0],add0[31:16]};   //         x>>>16  
wire [31:0] xor0     = xor0_lhs ^ xor0_rhs;                         //y <- y ^ x>>>op_rot

wire [31:0] xor1_lhs = add0;
wire [31:0] xor1_rhs = c;
wire [31:0] xor1     = xor1_lhs ^ xor1_rhs;                         //x <- x ^ c

//decryption
wire [31:0] xor2_lhs = x;
wire [31:0] xor2_rhs = c;
wire [31:0] xor2     = xor2_lhs ^ xor2_rhs;                         //x <- x ^ c

wire [31:0] xor3_lhs = y;
wire [31:0] xor3_rhs = (op_rot==2'b00)? {xor2[23:0],xor2[31:24]}:   //         x>>>24
                       (op_rot==2'b01)? {xor2[16:0],xor2[31:17]}:   //         x>>>17
                       (op_rot==2'b10)? {xor2[30:0],xor2[   31]}:   //         x>>>31
                      /*op_rot==2'b11)*/{xor2[15:0],xor2[31:16]};   //         x>>>16  
wire [31:0] xor3     = xor3_lhs ^ xor3_rhs;                         //y <- y ^ x>>>op_rot 

wire [31:0] add1_lhs = xor2;
wire [31:0] add1_rhs = (op_rot==2'b00)? {xor3[30:0],xor3[   31]}:   //         y>>>31
                       (op_rot==2'b01)? {xor3[16:0],xor3[31:17]}:   //         y>>>17
                       (op_rot==2'b10)? {xor3[31:1],xor3[    0]}:   //         y>>>0
                      /*op_rot==2'b11)*/{xor3[23:0],xor3[31:24]};   //         y>>>24  
wire [31:0] add1     = add1_lhs - add1_rhs;                         //x <- x - y>>>op_rot


wire [31:0] rd_hi   = op_enc ? xor0 : 
                   /* op_dec */xor3 ;                   

wire [31:0] rd_lo   = op_enc ? xor1 : 
                   /* op_dec */add1 ;

assign      rd      = {rd_hi, rd_lo};

endmodule
