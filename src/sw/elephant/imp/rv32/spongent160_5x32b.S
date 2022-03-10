#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a1-a5:  state
// t0-t4:  temp state
// t5, t6: temp registers
// a0:     the address of state
// a6, a7: LUT
// s0:     mask
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro SPONGENT_PROLOGUE
  addi sp, sp, -4
  sw   s0,  0(sp)
.endm

.macro SPONGENT_EPILOGUE
  lw   s0,  0(sp)
  addi sp, sp, 4 
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

// sBoxLayer

.macro SPONGENT_SBOX r0, s0, lut0, lut1, t0
  xperm4 \r0, \lut0,  \s0
  xor    \s0, \s0,     s0
  xperm4 \t0, \lut1,  \s0
  xor    \r0, \r0,    \t0
.endm

.macro SPONGENT_SBL r0, r1, r2, r3, r4, s0, s1, s2, s3, s4, lut0, lut1, t0
  SPONGENT_SBOX  \r0, \s0, \lut0, \lut1, \t0
  SPONGENT_SBOX  \r1, \s1, \lut0, \lut1, \t0
  SPONGENT_SBOX  \r2, \s2, \lut0, \lut1, \t0
  SPONGENT_SBOX  \r3, \s3, \lut0, \lut1, \t0
  SPONGENT_SBOX  \r4, \s4, \lut0, \lut1, \t0
.endm

// pLayer

// This step1 can be easily implemented with "unzip" and "rev8" instructions 
// from ZBKB.

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

// The "rev8" then makes the 32-bit state word as follows:
// bits[31:24] 28 24 20 16 12  8  4  0
// bits[23:16] 29 25 21 17 13  9  5  1
// bits[16: 8] 30 26 22 18 14 10  6  2 
// bits[ 7: 0] 31 27 23 19 15 11  7  3

#if (ELEPHANT_RV32_TYPE1)
.macro SPONGENT_PL_STEP1 s0, t0, t1
  unzip \s0, \s0 
  unzip \s0, \s0 
  rev8  \s0, \s0
.endm
#elif  (ELEPHANT_RV32_TYPE2)|(ELEPHANT_RV32_TYPE3)
.macro SPONGENT_PL_STEP1 s0, t0, t1
  elephant.pstep1 \s0, \s0
.endm
#endif

#if (ELEPHANT_RV32_TYPE1)
.macro SPONGENT_BSLLXOR r0, s0, s1, imm, t0
  andi \t0, \s1, 0xFF
  slli \t0, \t0, \imm
  xor  \r0, \s0, \t0 
.endm
#elif (ELEPHANT_RV32_TYPE2)
.macro SPONGENT_BSLLXOR r0, s0, s1, imm, t0
  elephant.bsllxor \r0, \s0, \s1, \imm
.endm
#endif 

.macro SPONGENT_PL r0, r1, r2, r3, r4, s0, s1, s2, s3, s4, t0, t1
  // step 1
  SPONGENT_PL_STEP1 \s0, \t0, \t1
  SPONGENT_PL_STEP1 \s1, \t0, \t1
  SPONGENT_PL_STEP1 \s2, \t0, \t1
  SPONGENT_PL_STEP1 \s3, \t0, \t1
  SPONGENT_PL_STEP1 \s4, \t0, \t1

  // step 2
#if (ELEPHANT_RV32_TYPE1)|(ELEPHANT_RV32_TYPE2)

  spongent_BSLLXOR \r3,  x0, \s0, 24, \t0
  spongent_BSLLXOR \r4,  x0, \s1, 0 , \t0 
  spongent_BSLLXOR \r4, \r4, \s2, 8 , \t0
  spongent_BSLLXOR \r4, \r4, \s3, 16, \t0
  spongent_BSLLXOR \r4, \r4, \s4, 24, \t0 

  srli \s0, \s0, 8
  srli \s1, \s1, 8
  srli \s2, \s2, 8
  srli \s3, \s3, 8
  srli \s4, \s4, 8

  spongent_BSLLXOR \r2,  x0, \s0, 16, \t0
  spongent_BSLLXOR \r2, \r2, \s1, 24, \t0 
  spongent_BSLLXOR \r3, \r3, \s2, 0 , \t0
  spongent_BSLLXOR \r3, \r3, \s3, 8 , \t0
  spongent_BSLLXOR \r3, \r3, \s4, 16, \t0

  srli \s0, \s0, 8
  srli \s1, \s1, 8
  srli \s2, \s2, 8
  srli \s3, \s3, 8
  srli \s4, \s4, 8

  spongent_BSLLXOR \r1,  x0, \s0, 8 , \t0
  spongent_BSLLXOR \r1, \r1, \s1, 16, \t0 
  spongent_BSLLXOR \r1, \r1, \s2, 24, \t0
  spongent_BSLLXOR \r2, \r2, \s3, 0 , \t0
  spongent_BSLLXOR \r2, \r2, \s4, 8 , \t0

  srli \s0, \s0, 8
  srli \s1, \s1, 8
  srli \s2, \s2, 8
  srli \s3, \s3, 8
  srli \s4, \s4, 8

  spongent_BSLLXOR \r0,  x0, \s0, 0 , \t0
  spongent_BSLLXOR \r0, \r0, \s1, 8 , \t0
  spongent_BSLLXOR \r0, \r0, \s2, 16, \t0
  spongent_BSLLXOR \r0, \r0, \s3, 24, \t0
  spongent_BSLLXOR \r1, \r1, \s4, 0 , \t0
#elif (ELEPHANT_RV32_TYPE3)

  elephant.pstep2.24 \r0,  x0, \s0, 0 
  elephant.pstep2.24 \r0, \r0, \s1, 8
  elephant.pstep2.24 \r0, \r0, \s2, 16
  elephant.pstep2.24 \r0, \r0, \s3, 24

  elephant.pstep2.24 \r1,  x0, \s4, 0 
  elephant.pstep2.16 \r1, \r1, \s0, 8
  elephant.pstep2.16 \r1, \r1, \s1, 16
  elephant.pstep2.16 \r1, \r1, \s2, 24

  elephant.pstep2.16 \r2,  x0, \s3, 0 
  elephant.pstep2.16 \r2, \r2, \s4, 8
  elephant.pstep2.8  \r2, \r2, \s0, 16
  elephant.pstep2.8  \r2, \r2, \s1, 24

  elephant.pstep2.8  \r3,  x0, \s2, 0 
  elephant.pstep2.8  \r3, \r3, \s3, 8
  elephant.pstep2.8  \r3, \r3, \s4, 16
  elephant.pstep2.0  \r3, \r3, \s0, 24

  elephant.pstep2.0  \r4,  x0, \s1, 0 
  elephant.pstep2.0  \r4, \r4, \s2, 8
  elephant.pstep2.0  \r4, \r4, \s3, 16
  elephant.pstep2.0  \r4, \r4, \s4, 24
#endif
.endm

// operations in each round

.macro SONPGENT_ROUND s0, s1, s2, s3, s4, r0, r1, r2, r3, r4, rci, icr, t0, t1, lut0, lut1
  SPONGENT_ADDRC \s0, \s4, \rci, \icr, \t0
  SPONGENT_SBL   \r0, \r1, \r2, \r3, \r4, \s0, \s1, \s2, \s3, \s4, \lut0, \lut1, \t0
  SPONGENT_PL    \s0, \s1, \s2, \s3, \s4, \r0, \r1, \r2, \r3, \r4, \t0, \t1
.endm

// Spongent-160

.section .text

.global Spongent160_5x32b

Spongent160_5x32b:
  SPONGENT_PROLOGUE
  SPONGENT_LDSTATE  a1, a2, a3, a4, a5 
  li a6, 0xF4120BDE
  li a7, 0x63C958A7
  li s0, 0x88888888
  //
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x75, 0xae, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x6a, 0x56, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x54, 0x2a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x29, 0x94, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x53, 0xca, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x27, 0xe4, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x4f, 0xf2, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x1f, 0xf8, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x3e, 0x7c, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x7d, 0xbe, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x7a, 0x5e, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x74, 0x2e, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x68, 0x16, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x50, 0x0a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x21, 0x84, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x43, 0xc2, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x07, 0xe0, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x0e, 0x70, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x1c, 0x38, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x38, 0x1c, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x71, 0x8e, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x62, 0x46, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x44, 0x22, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x09, 0x90, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x12, 0x48, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x24, 0x24, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x49, 0x92, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x13, 0xc8, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x26, 0x64, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x4d, 0xb2, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x1b, 0xd8, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x36, 0x6c, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x6d, 0xb6, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x5a, 0x5a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x35, 0xac, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x6b, 0xd6, t5, t6, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x56, 0x6a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x2d, 0xb4, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x5b, 0xda, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x37, 0xec, t5, t6, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x6f, 0xf6, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x5e, 0x7a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x3d, 0xbc, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x7b, 0xde, t5, t6, a6, a7 

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x76, 0x6e, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x6c, 0x36, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x58, 0x1a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x31, 0x8c, t5, t6, a6, a7 

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x63, 0xc6, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x46, 0x62, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x0d, 0xb0, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x1a, 0x58, t5, t6, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x34, 0x2c, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x69, 0x96, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x52, 0x4a, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x25, 0xa4, t5, t6, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x4b, 0xd2, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x17, 0xe8, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x2e, 0x74, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x5d, 0xba, t5, t6, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x3b, 0xdc, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x77, 0xee, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x6e, 0x76, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x5c, 0x3a, t5, t6, a6, a7  

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x39, 0x9c, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x73, 0xce, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x66, 0x66, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x4c, 0x32, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x19, 0x98, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x32, 0x4c, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x65, 0xa6, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x4a, 0x52, t5, t6, a6, a7

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x15, 0xa8, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x2a, 0x54, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x55, 0xaa, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x2b, 0xd4, t5, t6, a6, a7 

  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x57, 0xea, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x2f, 0xf4, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x5f, 0xfa, t5, t6, a6, a7
  SONPGENT_ROUND    a1, a2, a3, a4, a5, t0, t1, t2, t3, t4, 0x3f, 0xfc, t5, t6, a6, a7 
  //
  SPONGENT_STSTATE  a1, a2, a3, a4, a5
  SPONGENT_EPILOGUE
