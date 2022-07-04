module alzette_ise_v4 (
input  wire [31:0]  rs1,
input  wire [31:0]  rs2,

input  wire [ 2:0]  imm,
input  wire         op_x,
input  wire         op_enc,

output wire [31:0]  rd
);
parameter           DEC_E  = 1'b0;  //enable alzette decrypting instruction in variant 4
                                    //this isn't required in the LW Sparkle                         
wire [31:0] x = rs1; 
wire [31:0] y = rs2; 

reg  [31:0] c;
always @(*) begin
    case(imm[2:0])
            0  : c = 32'hB7E15162;
            1  : c = 32'hBF715880;
            2  : c = 32'h38B4DA56;
            3  : c = 32'h324E7738;
            4  : c = 32'hBB1185EB;
            5  : c = 32'h4F7C7B57;
            6  : c = 32'hCFBFA1C8;
            7  : c = 32'hC2B3293D;
		default: c = 32'hXXXXXXXX;
    endcase
end

//encryption
//quarter 0
wire [31:0] enc_add0_lhs =  x;
wire [31:0] enc_add0_rhs = {y[30:0],y[   31]};                 //         y>>>31
wire [31:0] enc_add0     =  enc_add0_lhs + enc_add0_rhs;       //x <- x + y>>>31
wire [31:0] enc_xor0_lhs =  y;
wire [31:0] enc_xor0_rhs = {enc_add0[23:0],enc_add0[31:24]};   //         x>>>24
wire [31:0] enc_xor0     =  enc_xor0_lhs ^ enc_xor0_rhs;       //y <- y ^ x>>>24
wire [31:0] enc_xor1_lhs =  enc_add0;
wire [31:0] enc_xor1_rhs =  c;
wire [31:0] enc_xor1     =  enc_xor1_lhs ^ enc_xor1_rhs;       //x <- x ^ c
//quarter 1
wire [31:0] enc_add1_lhs =  enc_xor1;
wire [31:0] enc_add1_rhs = {enc_xor0[16:0],enc_xor0[31:17]};   //         y>>>17
wire [31:0] enc_add1     =  enc_add1_lhs + enc_add1_rhs;       //x <- x + y>>>17
wire [31:0] enc_xor2_lhs =  enc_xor0;
wire [31:0] enc_xor2_rhs = {enc_add1[16:0],enc_add1[31:17]};   //         x>>>17
wire [31:0] enc_xor2     =  enc_xor2_lhs ^ enc_xor2_rhs;       //y <- y ^ x>>>17
wire [31:0] enc_xor3_lhs =  enc_add1;
wire [31:0] enc_xor3_rhs =  c;
wire [31:0] enc_xor3     =  enc_xor3_lhs ^ enc_xor3_rhs;       //x <- x ^ c
//quarter 2
wire [31:0] enc_add2_lhs =  enc_xor3;
wire [31:0] enc_add2_rhs =  enc_xor2;                          //         y>>>0
wire [31:0] enc_add2     =  enc_add2_lhs + enc_add2_rhs;       //x <- x + y>>>0
wire [31:0] enc_xor4_lhs =  enc_xor2;
wire [31:0] enc_xor4_rhs = {enc_add2[30:0],enc_add2[   31]};   //         x>>>31
wire [31:0] enc_xor4     =  enc_xor4_lhs ^ enc_xor4_rhs;       //y <- y ^ x>>>31
wire [31:0] enc_xor5_lhs = enc_add2;
wire [31:0] enc_xor5_rhs = c;
wire [31:0] enc_xor5     = enc_xor5_lhs ^ enc_xor5_rhs;        //x <- x ^ c
//quarter 3
wire [31:0] enc_add3_lhs =  enc_xor5;
wire [31:0] enc_add3_rhs = {enc_xor4[23:0],enc_xor4[31:24]};   //         y>>>24  
wire [31:0] enc_add3     =  enc_add3_lhs + enc_add3_rhs;       //x <- x + y>>>24
wire [31:0] enc_xor6_lhs =  enc_xor4;
wire [31:0] enc_xor6_rhs = {enc_add3[15:0],enc_add3[31:16]};   //         x>>>16  
wire [31:0] enc_xor6     =  enc_xor6_lhs ^ enc_xor6_rhs;       //y <- y ^ x>>>16
wire [31:0] enc_xor7_lhs =  enc_add3;
wire [31:0] enc_xor7_rhs =  c;
wire [31:0] enc_xor7     =  enc_xor7_lhs ^ enc_xor7_rhs;       //x <- x ^ c

generate
if (DEC_E    == 1'b1) begin : DEC_gen
//decryption
//quarter 0
wire [31:0] dec_xor0_lhs =  x;
wire [31:0] dec_xor0_rhs =  c;
wire [31:0] dec_xor0     =  dec_xor0_lhs ^ dec_xor0_rhs;       //x <- x ^ c
wire [31:0] dec_xor1_lhs =  y;
wire [31:0] dec_xor1_rhs = {dec_xor0[15:0],dec_xor0[31:16]};   //         x>>>16  
wire [31:0] dec_xor1     =  dec_xor1_lhs ^ dec_xor1_rhs;       //y <- y ^ x>>>16
wire [31:0] dec_add0_lhs =  dec_xor0;
wire [31:0] dec_add0_rhs = {dec_xor1[23:0],dec_xor1[31:24]};   //         y>>>24  
wire [31:0] dec_add0     =  dec_add0_lhs - dec_add0_rhs;       //x <- x + y>>>24 
//quarter 1
wire [31:0] dec_xor2_lhs =  dec_add0;
wire [31:0] dec_xor2_rhs =  c;
wire [31:0] dec_xor2     =  dec_xor2_lhs ^ dec_xor2_rhs;       //x <- x ^ c
wire [31:0] dec_xor3_lhs =  dec_xor1;
wire [31:0] dec_xor3_rhs = {dec_xor2[30:0],dec_xor2[   31]};   //         x>>>31  
wire [31:0] dec_xor3     =  dec_xor3_lhs ^ dec_xor3_rhs;       //y <- y ^ x>>>31
wire [31:0] dec_add1_lhs =  dec_xor2;
wire [31:0] dec_add1_rhs =  dec_xor3;                          //         y>>>0   
wire [31:0] dec_add1     =  dec_add1_lhs - dec_add1_rhs;       //x <- x + y>>>0  
//quarter 2
wire [31:0] dec_xor4_lhs =  dec_add1;
wire [31:0] dec_xor4_rhs =  c;
wire [31:0] dec_xor4     =  dec_xor4_lhs ^ dec_xor4_rhs;       //x <- x ^ c
wire [31:0] dec_xor5_lhs =  dec_xor3;
wire [31:0] dec_xor5_rhs = {dec_xor4[16:0],dec_xor4[31:17]};   //         x>>>17  
wire [31:0] dec_xor5     =  dec_xor5_lhs ^ dec_xor5_rhs;       //y <- y ^ x>>>17
wire [31:0] dec_add2_lhs =  dec_xor4;
wire [31:0] dec_add2_rhs = {dec_xor5[16:0],dec_xor5[31:17]};   //         y>>>17  
wire [31:0] dec_add2     =  dec_add2_lhs - dec_add2_rhs;       //x <- x + y>>>17
//quarter 3
wire [31:0] dec_xor6_lhs =  dec_add2;
wire [31:0] dec_xor6_rhs =  c;
wire [31:0] dec_xor6     =  dec_xor6_lhs ^ dec_xor6_rhs;       //x <- x ^ c
wire [31:0] dec_xor7_lhs =  dec_xor5;
wire [31:0] dec_xor7_rhs = {dec_xor6[23:0],dec_xor6[31:24]};   //         x>>>24  
wire [31:0] dec_xor7     =  dec_xor7_lhs ^ dec_xor7_rhs;       //y <- y ^ x>>>24
wire [31:0] dec_add3_lhs =  dec_xor6;
wire [31:0] dec_add3_rhs = {dec_xor7[30:0],dec_xor7[   31]};   //         y>>>31  
wire [31:0] dec_add3     =  dec_add3_lhs - dec_add3_rhs;       //x <- x + y>>>31

wire [31:0] rd_y   =  op_enc ? enc_xor6 : 
                   /* op_dec */dec_xor7 ;                   

wire [31:0] rd_x   =  op_enc ? enc_xor7 : 
                   /* op_dec */dec_add3 ;

assign      rd     =  op_x   ? rd_x     :
                   /* op_y  */ rd_y     ;
end else begin // ! DEC_gen
assign      rd     =  op_x   ? enc_xor7     :
                   /* op_y  */ enc_xor6     ;
end
endgenerate
endmodule
