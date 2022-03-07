#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a3~a6: cipher state
// t2~t6: key state
// t1: tmp register
// t0, s0~s3: masks
// a0, a1, a2: the address of plaintext, key, ciphertext, respectively 
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro GIFT_PROLOGUE
  addi sp, sp, -16
  sw   s0,  0(sp)
  sw   s1,  4(sp)
  sw   s2,  8(sp)
  sw   s3, 12(sp)
.endm

.macro GIFT_EPILOGUE
  lw   s0,  0(sp)
  lw   s1,  4(sp)
  lw   s2,  8(sp)
  lw   s3, 12(sp)
  addi sp, sp, 16 
  ret
.endm


// load state (cipher, key) + store state (cipher)  

.macro GIFT_LDSTATE addr, s0, s1, s2, s3
  lw   \s0,  0(\addr)
  lw   \s1,  4(\addr)
  lw   \s2,  8(\addr)
  lw   \s3, 12(\addr)
.endm

.macro GIFT_STSTATE addr, s0, s1, s2, s3
  sw   \s0,  0(\addr)
  sw   \s1,  4(\addr)
  sw   \s2,  8(\addr)
  sw   \s3, 12(\addr)
.endm


// byte-reverse for the state (cipher, key)
// byte3, byte2, byte1, byte0 -> byte0, byte1, byte2, byte3

.macro GIFT_REVERSE s0, s1, s2, s3 
  rev8 \s0, \s0
  rev8 \s1, \s1
  rev8 \s2, \s2
  rev8 \s3, \s3
.endm


// operations: SubCells + PermBits + AddRoundKey + Add round constant + Key state update 

// SubCells

.macro GIFT_SUBCELLS s0, s1, s2, s3, t0
  and  \t0, \s2, \s0
  xor  \s1, \s1, \t0
  and  \t0, \s1, \s3
  xor  \s0, \t0, \s0
  or   \t0, \s0, \s1
  xor  \s2, \t0, \s2
  xor  \s3, \s3, \s2
  xor  \s1, \s1, \s3
  and  \t0, \s0, \s1
  xor  \s2, \s2, \t0
  not  \s3, \s3
.endm 

// PermBits
// The costly permutation operation can be easily optimized by "unzip" and "rev8" 
// instructions from ZBKB.
// NOTE: "unzip" is only available on rv32.

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

// The resulting 32-bit state word is the same one needed by s3 (Table 2.2 in 
// the GIFT-COFB spec).
// For s0, s1, s2, just rotating the resulting state word to right with the 
// corresponding offset.

.macro GIFT_PERMBITS_STEP s0
  unzip \s0, \s0
  unzip \s0, \s0 
  rev8  \s0, \s0
.endm

.macro GIFT_PERMBITS s0, s1, s2, s3
  GIFT_PERMBITS_STEP \s0
  GIFT_PERMBITS_STEP \s1
  GIFT_PERMBITS_STEP \s2
  GIFT_PERMBITS_STEP \s3
  rori \s0, \s0,  24 
  rori \s1, \s1,  16 
  rori \s2, \s2,   8 
.endm

// AddRoundKey

.macro GIFT_ADDRDKEY s1, s2, k1, k3 
  xor  \s2, \s2, \k1
  xor  \s1, \s1, \k3
.endm

// Add round constant 

.macro GIFT_ADDCONST s3, rci
  xori \s3, \s3, \rci
  xor  \s3, \s3, t0
.endm  

// Key state update
// could be accelerated by "pack" and "rori" instructions as shown in the 
// following comments. There are some issues when using "pack" instruction, which
// needs to be fixed.

.macro GIFT_KEYSTUPD k3, k4, t0
  srli \k4, \k3, 12
  and  \k4, \k4, s0

  and  \t0, \k3, s1
  slli \t0, \t0, 4
  or   \k4, \k4, \t0
  
  srli \t0, \k3, 2
  and  \t0, \t0, s2
  or   \k4, \k4, \t0

  and  \t0, \k3, s3
  slli \t0, \t0, 14
  or   \k4, \k4, \t0
.endm

# .macro GIFT_KEYSTUPD k3, k4, t0
#   pack \t0, \k3, \k3
#   rori \k4, \k3, 16
#   pack \k4, \k4, \k4
#   rori \t0, \t0, 12
#   rori \k4, \k4,  2
#   pack \k4, \t0, \k4 

#   # mv   \t0, \k3
#   # pack \t0, \t0, \t0
#   # rori a1, \k3, 16
#   # pack a1, a1, a1
#   # rori \t0, \t0, 12
#   # rori a1, a1,  2
#   # pack \t0, \t0, a1
#   # mv   \k4, \t0 
# .endm


// operations in each round

.macro GIFT_ROUND s0, s1, s2, s3, k0, k1, k2, k3, k4, rci, t0
  GIFT_SUBCELLS \s0, \s1, \s2, \s3, \t0
  GIFT_PERMBITS \s3, \s1, \s2, \s0
  GIFT_ADDRDKEY \s1, \s2, \k1, \k3
  GIFT_ADDCONST \s0, \rci 
  GIFT_KEYSTUPD \k3, \k4, \t0
.endm


// GIFT-128

.section .text

.global giftb128_bitslicing

giftb128_bitslicing:
  GIFT_PROLOGUE
  GIFT_LDSTATE  a0, a3, a4, a5, a6
  GIFT_REVERSE  a3, a4, a5, a6
  GIFT_LDSTATE  a1, t3, t4, t5, t6
  GIFT_REVERSE  t3, t4, t5, t6
  li   s0, 0x0000000F
  li   s1, 0x00000FFF
  li   s2, 0x3FFF0000
  li   s3, 0x00030000
  slli t0, s0, 31
  //  
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x00000001, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x00000003, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x00000007, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x0000000F, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x0000001F, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x0000003E, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x0000003D, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x0000003B, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x00000037, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x0000002F, t1

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x0000001E, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x0000003C, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x00000039, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x00000033, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x00000027, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x0000000E, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x0000001D, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x0000003A, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x00000035, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x0000002B, t1 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x00000016, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x0000002C, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x00000018, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x00000030, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x00000021, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x00000002, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x00000005, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x0000000B, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x00000017, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x0000002E, t1 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x0000001C, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x00000038, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x00000031, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x00000023, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x00000006, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x0000000D, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x0000001B, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x00000036, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x0000002D, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x0000001A, t1  
  //  
  GIFT_REVERSE  a3, a4, a5, a6
  GIFT_STSTATE  a2, a3, a4, a5, a6  
  GIFT_EPILOGUE
