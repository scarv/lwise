#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// s0, a1-a7:    state
// t0-t4, s1-s3: temp state 
// t5, t6:       temp state
// s4, s5:       masks
// a0:           the address of state
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro SPONGENT_PROLOGUE
  addi sp, sp, -24
  sw   s0,  0(sp)
  sw   s1,  4(sp)
  sw   s2,  8(sp)
  sw   s3, 12(sp)
  sw   s4, 16(sp)
  sw   s5, 20(sp)
.endm

.macro SPONGENT_EPILOGUE
  lw   s0,  0(sp)
  lw   s1,  4(sp)
  lw   s2,  8(sp)
  lw   s3, 12(sp)
  lw   s4, 16(sp)
  lw   s5, 20(sp)
  addi sp, sp, 24 
  ret
.endm


// load state + store state: four 40-bit slices

.macro SPONGENT_LDSTATE s0, s1, s2, s3, s4, s5, s6, s7
  lw   \s0,  0(a0)
  lb   \s1,  4(a0)
  lw   \s2,  5(a0)
  lb   \s3,  9(a0)
  lw   \s4, 10(a0)
  lb   \s5, 14(a0)
  lw   \s6, 15(a0)
  lb   \s7, 19(a0)
.endm

.macro SPONGENT_STSTATE s0, s1, s2, s3, s4, s5, s6, s7
  sw   \s0,  0(a0)
  sb   \s1,  4(a0)
  sw   \s2,  5(a0)
  sb   \s3,  9(a0)
  sw   \s4, 10(a0)
  sb   \s5, 14(a0)
  sw   \s6, 15(a0)
  sb   \s7, 19(a0)  
.endm


// operations: add round constants + sBoxLayer + pLayer

// add round constants

.macro SPONGENT_ADDRC s0, s7, rci, icr
  xori \s0, \s0, \rci
  xori \s7, \s7, \icr
.endm

// sBoxLayer (bitsliced) x0 x1 x2 x3 -> y0 y1 y2 y3
// Our formulas in the generic C code: 
// y0 = x0 + x1 + x3 + x1x2 
// y1 = x0 + x0x3 + x1x2 + x1x3 + x2x3 + x1x2x3 + 1
// y2 = x1 + x2 + x0x3 + x1x2x3 + 1
// y3 = x2 + x3 + x0x1 + x0x3 + x1x3 + x0x1x3 + x0x2x3 + 1

// But here we use the formulas from:
// https://github.com/usubalang/usuba/blob/master/data/sboxes/spongent.ua
// Both sets of formulas have 31 bitwise logical operations but the latter 
// allows us to use "andn" instruction to further save 2 instructions. 

.macro SPONGENT_SBOX y0, y1, y2, y3, x0, x1, x2, x3, t0, t1, t2, t3
  xor  \y3, \x3, \x1    // y3 = x3 ^ x1        
  xor  \y2, \x2, \x1    // y2 = x2 ^ x1
  and  \t0, \y3, \y2    // t0 = y3 & y2
  xor  \y1, \x3, \x2    // y1 = x3 ^ x2
  xor  \y1, \y1, \x0    // y1 = x3 ^ x2 ^ x0
  xor  \y1, \y1, \t0    // y1 = x3 ^ x2 ^ x0 ^ t0
  not  \y1, \y1         // y1 = ~(x3 ^ x2 ^ x0 ^ t0)
  andn \t1, \y1, \x3    // t1 = y1 & ~x3
  xor  \y0, \x2, \t1    // y0 = x2 ^ t1
  xor  \t2, \y0, \x1    // t2 = y0 ^ x1
  xor  \t2, \t2, \x0    // t2 = y0 ^ x1 ^ x0
  xor  \t2, \t2, \t0    // t2 = y0 ^ x1 ^ x0 ^ t0
  and  \t2, \t2, \y0    // t2 = (y0 ^ x1 ^ x0 ^t0) & y0
  xor  \t3, \x1, \t0    // t3 = x1 ^ t0
  xor  \y0, \x2, \t0    // y0 = x2 ^ t0
  andn \t3, \t3, \y0    // t3 = (x1 ^ t0) & ~(x2 ^ t0) 

  xor  \y0, \x3, \x0    // y0 = x3 ^ x0
  xor  \y0, \y0, \t0    // y0 = x3 ^ x0 ^ t0
  xor  \y0, \y0, \t3    // y0 = x3 ^ x0 ^ t0 ^ t3

  xor  \y1, \x3, \x2    // y1 = x3 ^ x2
  xor  \y1, \y1, \x1    // y1 = x3 ^ x2 ^ x1
  xor  \y1, \y1, \t1    // y1 = x3 ^ x2 ^ x1 ^ t1

  xor  \y2, \x3, \x1    // y2 = x3 ^ x1
  xor  \y2, \y2, \x0    // y2 = x3 ^ x1 ^ x0
  xor  \y2, \y2, \t0    // y2 = x3 ^ x1 ^ x0 ^ t0
  xor  \y2, \y2, \t1    // y2 = x3 ^ x1 ^ x0 ^ t0 ^ t1

  xor  \y3, \x2, \x1    // y3 = x2 ^ x1
  xor  \y3, \y3, \x0    // y3 = x2 ^ x1 ^ x0
  xor  \y3, \y3, \t2    // y3 = x2 ^ x1 ^ x0 ^ t2
.endm

// pLayer

#if (ELEPHANT_RV32_TYPE1)
.macro BUP r0, s0, t0, imm0, imm1 
  slli \r0, \s0, \imm0  
  slli \t0,  s5, \imm1
  and  \r0, \r0, \t0
.endm

.macro SONPGENT_PL_STEP00 r0, s1, s3, s5, t0, t1, imm0, imm1, imm2
  BUP  \r0, \s1, \t0, \imm0,    8
  BUP  \t1, \s1, \t0, \imm0-3,  9
  xor  \r0, \r0, \t1
  BUP  \t1, \s3, \t0, \imm1,   18
  xor  \r0, \r0, \t1
  BUP  \t1, \s3, \t0, \imm1-3, 19
  xor  \r0, \r0, \t1
  BUP  \t1, \s5, \t0, \imm2,   28
  xor  \r0, \r0, \t1
  BUP  \t1, \s5, \t0, \imm2-3, 29
  xor  \r0, \r0, \t1
.endm

.macro SONPGENT_PL_STEP01 r1, s7, t0, t1, imm
  BUP  \r1, \s7, \t0, \imm,     6      
  BUP  \t1, \s7, \t0, \imm-3,   7       
  xor  \r1, \r1, \t1
.endm
#elif (ELEPHANT_RV32_TYPE2)

.macro BUP r0, s0, pos, imm
  elephant.bup \r0, \s0, \pos, \imm
.endm

.macro SONPGENT_PL_STEP00 r0, s1, s3, s5, pos, t0
  BUP  \r0, \s1, \pos, 8
  BUP  \t0, \s3, \pos, 18
  xor  \r0, \r0, \t0
  BUP  \t0, \s5, \pos, 28
  xor  \r0, \r0, \t0
.endm

.macro SONPGENT_PL_STEP01 r1, s7, pos, t0 
  BUP  \r1, \s7, \pos, 6           
.endm

.macro SONPGENT_PL_STEP02 r0, s1, s3, s5, pos, t0
  BUP  \t0, \s1, \pos, 9
  xor  \r0, \r0, \t0
  BUP  \t0, \s3, \pos, 19
  xor  \r0, \r0, \t0
  BUP  \t0, \s5, \pos, 29
  xor  \r0, \r0, \t0
.endm

.macro SONPGENT_PL_STEP03 r1, s7, pos, t0
  BUP  \t0, \s7, \pos, 7
  xor  \r1, \r1, \t0           
.endm
#elif (ELEPHANT_RV32_TYPE3)

.macro BUPD r0, s0, pos, imm
  elephant.bupd \r0, \s0, \pos, \imm
.endm

.macro SONPGENT_PL_STEP00 r0, s1, s3, s5, pos, t0
  BUPD \r0, \s1, \pos, 8
  BUPD \t0, \s3, \pos, 18
  xor  \r0, \r0, \t0
  BUPD \t0, \s5, \pos, 28
  xor  \r0, \r0, \t0
.endm

.macro SONPGENT_PL_STEP01 r1, s7, pos, t0 
  BUPD \r1, \s7, \pos, 6           
.endm
#endif 

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

.macro SPONGENT_PL r0, r1, r2, r3, r4, r5, r6, r7, s0, s1, s2, s3, s4, s5, s6, s7, t0, t1
  // There are three steps in the pLayer. See details in the generic C code:
  // ../generic/spongent_imp.c 

  // step 0
#if   (ELEPHANT_RV32_TYPE1)

  SONPGENT_PL_STEP00 \r0, \s1, \s3, \s5, \t0, \t1, 8, 18, 28
  SONPGENT_PL_STEP00 \r2, \s1, \s3, \s5, \t0, \t1, 7, 17, 27
  SONPGENT_PL_STEP00 \r4, \s1, \s3, \s5, \t0, \t1, 6, 16, 26 
  SONPGENT_PL_STEP00 \r6, \s1, \s3, \s5, \t0, \t1, 5, 15, 25

  SONPGENT_PL_STEP01 \r1, \s7, \t0, \t1, 6
  SONPGENT_PL_STEP01 \r3, \s7, \t0, \t1, 5
  SONPGENT_PL_STEP01 \r5, \s7, \t0, \t1, 4
  SONPGENT_PL_STEP01 \r7, \s7, \t0, \t1, 3
#elif (ELEPHANT_RV32_TYPE2)|(ELEPHANT_RV32_TYPE3)

  SONPGENT_PL_STEP00 \r0, \s1, \s3, \s5,  x0, \t0
  SONPGENT_PL_STEP01 \r1, \s7,            x0, \t0
  addi \t1,  x0, 1
  SONPGENT_PL_STEP00 \r2, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP01 \r3, \s7,           \t1, \t0
  addi \t1, \t1, 1
  SONPGENT_PL_STEP00 \r4, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP01 \r5, \s7,           \t1, \t0
  addi \t1, \t1, 1
  SONPGENT_PL_STEP00 \r6, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP01 \r7, \s7,           \t1, \t0
  addi \t1, \t1, 1
#if (ELEPHANT_RV32_TYPE2)
  SONPGENT_PL_STEP02 \r0, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP03 \r1, \s7,           \t1, \t0
  addi \t1, \t1, 1
  SONPGENT_PL_STEP02 \r2, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP03 \r3, \s7,           \t1, \t0
  addi \t1, \t1, 1
  SONPGENT_PL_STEP02 \r4, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP03 \r5, \s7,           \t1, \t0
  addi \t1, \t1, 1
  SONPGENT_PL_STEP02 \r6, \s1, \s3, \s5, \t1, \t0
  SONPGENT_PL_STEP03 \r7, \s7,           \t1, \t0
#endif
#endif 

  // step 1
  SPONGENT_PL_STEP1 \s0, \t0, \t1
  SPONGENT_PL_STEP1 \s2, \t0, \t1
  SPONGENT_PL_STEP1 \s4, \t0, \t1
  SPONGENT_PL_STEP1 \s6, \t0, \t1

  // step 2
#if (ELEPHANT_RV32_TYPE1)|(ELEPHANT_RV32_TYPE2)

  SPONGENT_BSLLXOR \r6, \r6, \s0,  0, \t0
  srli \s0, \s0, 8
  SPONGENT_BSLLXOR \r4, \r4, \s0,  0, \t0
  srli \s0, \s0, 8
  SPONGENT_BSLLXOR \r2, \r2, \s0,  0, \t0
  srli \s0, \s0, 8
  SPONGENT_BSLLXOR \r0, \r0, \s0,  0, \t0

  SPONGENT_BSLLXOR \r6, \r6, \s2, 10, \t0
  srli \s2, \s2, 8
  SPONGENT_BSLLXOR \r4, \r4, \s2, 10, \t0
  srli \s2, \s2, 8
  SPONGENT_BSLLXOR \r2, \r2, \s2, 10, \t0
  srli \s2, \s2, 8
  SPONGENT_BSLLXOR \r0, \r0, \s2, 10, \t0

  SPONGENT_BSLLXOR \r6, \r6, \s4, 20, \t0
  srli \s4, \s4, 8
  SPONGENT_BSLLXOR \r4, \r4, \s4, 20, \t0
  srli \s4, \s4, 8
  SPONGENT_BSLLXOR \r2, \r2, \s4, 20, \t0
  srli \s4, \s4, 8
  SPONGENT_BSLLXOR \r0, \r0, \s4, 20, \t0

  and  \t1, \s6, s4
  SPONGENT_BSLLXOR \r6, \r6, \s6, 30, \t0
  srli \s6, \s6, 8
  SPONGENT_BSLLXOR \r4, \r4, \s6, 30, \t0
  srli \s6, \s6, 8
  SPONGENT_BSLLXOR \r2, \r2, \s6, 30, \t0
  srli \s6, \s6, 8
  SPONGENT_BSLLXOR \r0, \r0, \s6, 30, \t0  

  srli \t1, \t1, 2
  SPONGENT_BSLLXOR \r7, \r7, \t1,  0, \t0
  srli \t1, \t1, 8
  SPONGENT_BSLLXOR \r5, \r5, \t1,  0, \t0
  srli \t1, \t1, 8
  SPONGENT_BSLLXOR \r3, \r3, \t1,  0, \t0
  srli \t1, \t1, 8
  SPONGENT_BSLLXOR \r1, \r1, \t1,  0, \t0
#elif (ELEPHANT_RV32_TYPE3)

  elephant.pstep2.24 \r0, \r0, \s0, 0 
  elephant.pstep2.16 \r2, \r2, \s0, 0 
  elephant.pstep2.8  \r4, \r4, \s0, 0 
  elephant.pstep2.0  \r6, \r6, \s0, 0

  elephant.pstep2.24 \r0, \r0, \s2, 10 
  elephant.pstep2.16 \r2, \r2, \s2, 10 
  elephant.pstep2.8  \r4, \r4, \s2, 10 
  elephant.pstep2.0  \r6, \r6, \s2, 10

  elephant.pstep2.24 \r0, \r0, \s4, 20 
  elephant.pstep2.16 \r2, \r2, \s4, 20 
  elephant.pstep2.8  \r4, \r4, \s4, 20 
  elephant.pstep2.0  \r6, \r6, \s4, 20

  elephant.pstep2.24 \r0, \r0, \s6, 30 
  elephant.pstep2.16 \r2, \r2, \s6, 30 
  elephant.pstep2.8  \r4, \r4, \s6, 30 
  elephant.pstep2.0  \r6, \r6, \s6, 30

  srli \s6, \s6, 2
  and  \s6, \s6, s4
  elephant.pstep2.24 \r1, \r1, \s6, 0 
  elephant.pstep2.16 \r3, \r3, \s6, 0 
  elephant.pstep2.8  \r5, \r5, \s6, 0 
  elephant.pstep2.0  \r7, \r7, \s6, 0
#endif
.endm


// operations in each round

.macro SONPGENT_ROUND s0, s1, s2, s3, s4, s5, s6, s7, r0, r1, r2, r3, r4, r5, r6, r7, rci, icr, t0, t1
  SPONGENT_ADDRC \s0, \s7, \rci, \icr
  SPONGENT_PL    \r0, \r1, \r2, \r3, \r4, \r5, \r6, \r7, \s0, \s1, \s2, \s3, \s4, \s5, \s6, \s7, \t0, \t1
  SPONGENT_SBOX  \s0, \s2, \s4, \s6, \r0, \r2, \r4, \r6, \s1, \s3, \s5, \s7
  SPONGENT_SBOX  \s1, \s3, \s5, \s7, \r1, \r3, \r5, \r7, \r0, \r2, \r4, \r6
.endm


// Spongent-160

.section .text

.global Spongent160_4x40b

Spongent160_4x40b:
  SPONGENT_PROLOGUE
  SPONGENT_LDSTATE  s0, a1, a2, a3, a4, a5, a6, a7
#if   (ELEPHANT_RV32_TYPE1)|(ELEPHANT_RV32_TYPE2)
  li s4, 0xFCFCFCFC
#elif (ELEPHANT_RV32_TYPE3)
  li s4, 0x3F3F3F3F
#endif 
#if   (ELEPHANT_RV32_TYPE1)
  li s5, 1
#endif
  //
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x75, 0xae, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x6a, 0x56, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x54, 0x2a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x29, 0x94, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x53, 0xca, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x27, 0xe4, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x4f, 0xf2, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x1f, 0xf8, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x3e, 0x7c, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x7d, 0xbe, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x7a, 0x5e, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x74, 0x2e, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x68, 0x16, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x50, 0x0a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x21, 0x84, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x43, 0xc2, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x07, 0xe0, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x0e, 0x70, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x1c, 0x38, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x38, 0x1c, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x71, 0x8e, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x62, 0x46, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x44, 0x22, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x09, 0x90, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x12, 0x48, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x24, 0x24, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x49, 0x92, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x13, 0xc8, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x26, 0x64, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x4d, 0xb2, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x1b, 0xd8, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x36, 0x6c, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x6d, 0xb6, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x5a, 0x5a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x35, 0xac, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x6b, 0xd6, t5, t6  

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x56, 0x6a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x2d, 0xb4, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x5b, 0xda, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x37, 0xec, t5, t6  

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x6f, 0xf6, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x5e, 0x7a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x3d, 0xbc, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x7b, 0xde, t5, t6 

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x76, 0x6e, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x6c, 0x36, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x58, 0x1a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x31, 0x8c, t5, t6 

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x63, 0xc6, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x46, 0x62, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x0d, 0xb0, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x1a, 0x58, t5, t6  

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x34, 0x2c, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x69, 0x96, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x52, 0x4a, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x25, 0xa4, t5, t6  

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x4b, 0xd2, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x17, 0xe8, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x2e, 0x74, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x5d, 0xba, t5, t6  

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x3b, 0xdc, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x77, 0xee, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x6e, 0x76, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x5c, 0x3a, t5, t6  

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x39, 0x9c, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x73, 0xce, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x66, 0x66, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x4c, 0x32, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x19, 0x98, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x32, 0x4c, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x65, 0xa6, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x4a, 0x52, t5, t6

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x15, 0xa8, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x2a, 0x54, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x55, 0xaa, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x2b, 0xd4, t5, t6 

  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x57, 0xea, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x2f, 0xf4, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x5f, 0xfa, t5, t6
  SONPGENT_ROUND    s0, a1, a2, a3, a4, a5, a6, a7, t0, t1, t2, t3, t4, s1, s2, s3, 0x3f, 0xfc, t5, t6   
  //
  SPONGENT_STSTATE  s0, a1, a2, a3, a4, a5, a6, a7
  SPONGENT_EPILOGUE
