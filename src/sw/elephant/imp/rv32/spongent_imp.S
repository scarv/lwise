#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"

// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a0:     the address of state
// a1-a5:  state
// a6-a7:  LUTs         for xperm-style SBox
// t0:     a fixed mask for xperm-style SBox
// t1:     temp register
// t2-t4:  masks for SWAPMPVE 
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro SPONGENT_PROLOGUE
.endm

.macro SPONGENT_EPILOGUE
  ret
.endm


// load state + store state

.macro SPONGENT_LDSTATE s0, s1, s2, s3, s4
  lw   \s0,  0(a0)
  lw   \s1,  4(a0)
  lw   \s2,  8(a0)
  lw   \s3, 12(a0)
  lw   \s4, 16(a0)
.endm

.macro SPONGENT_STSTATE s0, s1, s2, s3, s4
  sw   \s0,  0(a0)
  sw   \s1,  4(a0)
  sw   \s2,  8(a0)
  sw   \s3, 12(a0)
  sw   \s4, 16(a0)
.endm


// operations: add round constants + sBoxLayer + pLayer

// add round constants

.macro SPONGENT_ADDRC s0, s4, rci, icr, t0
  xori \s0, \s0, \rci
  li   \t0, \icr
  slli \t0, \t0, 24
  xor  \s4, \s4, \t0
.endm

// sBoxLayer (xperm-style SBox)

.macro SPONGENT_SBOX s0, lut0, lut1, t0
  xperm4 \t0, \lut0,  \s0
  xor    \s0, \s0,     t0
  xperm4 \s0, \lut1,  \s0
  xor    \s0, \s0,    \t0
.endm

.macro SPONGENT_SBL s0, s1, s2, s3, s4, lut0, lut1, t0
  SPONGENT_SBOX  \s0, \lut0, \lut1, \t0
  SPONGENT_SBOX  \s1, \lut0, \lut1, \t0
  SPONGENT_SBOX  \s2, \lut0, \lut1, \t0
  SPONGENT_SBOX  \s3, \lut0, \lut1, \t0
  SPONGENT_SBOX  \s4, \lut0, \lut1, \t0
.endm

// pLayer 
// Our pLayer implementation contains two steps:
// Step1: permute  the bits in the same  32-bit state word
// Step2: swapmove the bits in different 32-bit state words 

// Step1 can be easily implemented with "unzip" instruction from ZBKB.

// The 1st "unzip" permutes the 32-bit state word as follows: 
// bits[31:24] 31 29 27 25 23 21 19 17
// bits[23:16] 15 13 11  9  7  5  3  1
// bits[15: 8] 30 28 26 24 22 20 18 16 
// bits[ 7: 0] 14 12 10  8  6  4  2  0 

// The 2nd "unzip" permutes the 32-bit state word as follows:
// bits[31:24] 31 27 23 19 15 11  7  3
// bits[23:16] 30 26 22 18 14 10  6  2
// bits[15: 8] 29 25 21 17 13  9  5  1 
// bits[ 7: 0] 28 24 20 16 12  8  4  0 

.macro SPONGENT_PL_STEP1 s0
  unzip \s0, \s0 
  unzip \s0, \s0 
.endm

// Step2 is composed of series of swapmove and rori instructions. 

#if (ELEPHANT_RV32_TYPE1)
.macro SPONGENT_SWAPMOVE s0, s1, m0, imm, t0
  srli \t0, \s0, \imm
  xor  \t0, \t0, \s1
  and  \t0, \t0, \m0
  xor  \s1, \s1, \t0
  slli \t0, \t0, \imm
  xor  \s0, \s0, \t0
.endm
#endif 

.macro SPONGENT_PL s0, s1, s2, s3, s4, t0
  // step 1
  SPONGENT_PL_STEP1 \s0
  SPONGENT_PL_STEP1 \s1
  SPONGENT_PL_STEP1 \s2
  SPONGENT_PL_STEP1 \s3
  SPONGENT_PL_STEP1 \s4

  // step 2
#if   (ELEPHANT_RV32_TYPE1)

  SPONGENT_SWAPMOVE \s0, \s1, t2, 8 , \t0
  SPONGENT_SWAPMOVE \s0, \s2, t2, 16, \t0 
  SPONGENT_SWAPMOVE \s0, \s3, t2, 24, \t0
  SPONGENT_SWAPMOVE \s1, \s2, t3, 8 , \t0 
  SPONGENT_SWAPMOVE \s1, \s4, t2, 24, \t0
  SPONGENT_SWAPMOVE \s2, \s3, t3, 8 , \t0
  SPONGENT_SWAPMOVE \s2, \s4, t3, 16, \t0
  SPONGENT_SWAPMOVE \s3, \s4, t4, 8 , \t0
  rori \s1, \s1, 24
  rori \s2, \s2, 16
  rori \s3, \s3, 8
#elif (ELEPHANT_RV32_TYPE2)

  # 0. swapmove(x, y, 0x000000FF, 8)
  # 1. swapmove(x, y, 0x000000FF, 16)
  # 2. swapmove(x, y, 0x000000FF, 24)
  # 3. swapmove(x, y, 0x0000FF00, 8)
  # 4. swapmove(x, y, 0x000000FF, 24)   x = x >>> 24 
  # 3. swapmove(x, y, 0x0000FF00, 8)
  # 5. swapmove(x, y, 0x0000FF00, 16)   x = x >>> 16
  # 6. swapmove(x, y, 0x00FF0000, 8)    x = x >>> 8

  // Because we need two custom instructions to perform each SWAPMOVE, and the 
  // output of each custom instruction will overwrite an input, so we need to 
  // use some temp regiters to store the intermediate values.  

  elephant.pstep2.x   t2, \s0, \s1, 0    // t2 <- s0
  elephant.pstep2.y  \s1, \s0, \s1, 0    // s1 <- s1
  elephant.pstep2.x   t3,  t2, \s2, 1    // t3 <- s0
  elephant.pstep2.y  \s2,  t2, \s2, 1    // s2 <- s2
  elephant.pstep2.x  \s0,  t3, \s3, 2    // s0 <- s0
  elephant.pstep2.y  \s3,  t3, \s3, 2    // s3 <- s3
  elephant.pstep2.x   t2, \s1, \s2, 3    // t2 <- s1
  elephant.pstep2.y  \s2, \s1, \s2, 3    // s2 <- s2
  elephant.pstep2.x  \s1,  t2, \s4, 4    // s1 <- s1
  elephant.pstep2.y  \s4,  t2, \s4, 4    // s4 <- s4
  elephant.pstep2.x   t2, \s2, \s3, 3    // t2 <- s2
  elephant.pstep2.y   t3, \s2, \s3, 3    // t3 <- s3
  elephant.pstep2.x  \s2,  t2, \s4, 5    // s2 <- s2
  elephant.pstep2.y  \s4,  t2, \s4, 5    // s4 <- s4
  elephant.pstep2.x  \s3,  t3, \s4, 6    // s3 <- s3
  elephant.pstep2.y  \s4,  t3, \s4, 6    // s4 <- s4  
#endif
.endm

// operations in each round

.macro SONPGENT_ROUND s0, s1, s2, s3, s4, rci, icr, t0, lut0, lut1
  SPONGENT_ADDRC \s0, \s4, \rci, \icr, \t0
  SPONGENT_SBL   \s0, \s1, \s2, \s3, \s4, \lut0, \lut1, \t0
  SPONGENT_PL    \s0, \s1, \s2, \s3, \s4, \t0
.endm


// Spongent-160

.section .text

.global permutation

permutation:
  SPONGENT_PROLOGUE
  SPONGENT_LDSTATE  a1, a2, a3, a4, a5 
  li a6, 0xF4120BDE
  li a7, 0x63C958A7
  li t0, 0x88888888
#if (ELEPHANT_RV32_TYPE1)
  li t2, 0x000000FF
  li t3, 0x0000FF00
  li t4, 0x00FF0000
#endif
  //
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x75, 0xae, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x6a, 0x56, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x54, 0x2a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x29, 0x94, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x53, 0xca, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x27, 0xe4, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x4f, 0xf2, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x1f, 0xf8, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x3e, 0x7c, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x7d, 0xbe, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x7a, 0x5e, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x74, 0x2e, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x68, 0x16, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x50, 0x0a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x21, 0x84, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x43, 0xc2, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x07, 0xe0, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x0e, 0x70, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x1c, 0x38, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x38, 0x1c, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x71, 0x8e, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x62, 0x46, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x44, 0x22, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x09, 0x90, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x12, 0x48, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x24, 0x24, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x49, 0x92, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x13, 0xc8, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x26, 0x64, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x4d, 0xb2, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x1b, 0xd8, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x36, 0x6c, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x6d, 0xb6, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x5a, 0x5a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x35, 0xac, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x6b, 0xd6, t1, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x56, 0x6a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x2d, 0xb4, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x5b, 0xda, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x37, 0xec, t1, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x6f, 0xf6, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x5e, 0x7a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x3d, 0xbc, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x7b, 0xde, t1, a6, a7 

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x76, 0x6e, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x6c, 0x36, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x58, 0x1a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x31, 0x8c, t1, a6, a7 

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x63, 0xc6, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x46, 0x62, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x0d, 0xb0, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x1a, 0x58, t1, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x34, 0x2c, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x69, 0x96, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x52, 0x4a, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x25, 0xa4, t1, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x4b, 0xd2, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x17, 0xe8, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x2e, 0x74, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x5d, 0xba, t1, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x3b, 0xdc, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x77, 0xee, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x6e, 0x76, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x5c, 0x3a, t1, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x39, 0x9c, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x73, 0xce, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x66, 0x66, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x4c, 0x32, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x19, 0x98, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x32, 0x4c, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x65, 0xa6, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x4a, 0x52, t1, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x15, 0xa8, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x2a, 0x54, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x55, 0xaa, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x2b, 0xd4, t1, a6, a7 

  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x57, 0xea, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x2f, 0xf4, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x5f, 0xfa, t1, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, 0x3f, 0xfc, t1, a6, a7 
  //
  SPONGENT_STSTATE  a1, a2, a3, a4, a5
  SPONGENT_EPILOGUE