#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (use caller-saved registers to save push/pop instructions)  
//
// a0, a1, a2: the address of plaintext, key, ciphertext resp.
// a3-a6:      cipher state 
// t2-t6:      key state
// t1:         temp register
// t0:         constant
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro GIFT_PROLOGUE
.endm

.macro GIFT_EPILOGUE
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
// byte3 || byte2 || byte1 || byte0 -> 
// byte0 || byte1 || byte2 || byte3

.macro GIFT_REVERSE s0, s1, s2, s3 
  rev8 \s0, \s0
  rev8 \s1, \s1
  rev8 \s2, \s2
  rev8 \s3, \s3
.endm


// layers: SubCells + PermBits + AddRoundKey + Add round constant + Key state update 

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
// The costly PermBits layer can be easily implemented with "unzip" and "rev8" 
// instructions from ZBKB. Also note that "unzip" is only available on rv32.

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

// The resulting 32-bit state slice is the same one needed by s3 (Table 2.2 in 
// the GIFT-COFB spec).
// For s0, s1, s2, just rotate the resulting state slice to right with the 
// corresponding offset.

#if   (GIFT_RV32_TYPE1)
.macro GIFT_PERMBITS_STEP s0
  unzip \s0, \s0
  unzip \s0, \s0 
  rev8  \s0, \s0
.endm
#endif

.macro GIFT_PERMBITS s0, s1, s2, s3
#if   (GIFT_RV32_TYPE1)
  GIFT_PERMBITS_STEP \s0
  GIFT_PERMBITS_STEP \s1
  GIFT_PERMBITS_STEP \s2
  GIFT_PERMBITS_STEP \s3
  rori \s0, \s0,  24 
  rori \s1, \s1,  16 
  rori \s2, \s2,   8 
#elif  (GIFT_RV32_TYPE3)
  gift.permbits.step \s0, \s0, 24
  gift.permbits.step \s1, \s1, 16
  gift.permbits.step \s2, \s2,  8
  gift.permbits.step \s3, \s3,  0
#endif
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
// This halfword-wise rotation can be optimized with "pack" and "rori". 

.macro GIFT_KEYSTUPD k3, k4, t0
#if   (GIFT_RV32_TYPE3)
  gift.key.updstd \k4, \k3 
#elif (GIFT_RV32_TYPE1)         // k3 = W6        || W7
  pack \t0, \k3, \k3            // t0 = W7        || W7
  rori \k4, \k3, 16             // k4 = W7        || W6
  pack \k4, \k4, \k4            // k4 = W6        || W6
  rori \t0, \t0, 12             // t0 = W7 >>> 12 || W7 >>> 12 
  rori \k4, \k4,  2             // k4 = W6 >>> 2  || W6 >>> 2 
  pack \k4, \t0, \k4            // k4 = W6 >>> 2  || W7 >>> 12
#endif 
.endm

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
  li t0, 0x80000000
  //  
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x01, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x03, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x07, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x0F, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x1F, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x3E, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x3D, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x3B, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x37, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x2F, t1

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x1E, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x3C, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x39, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x33, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x27, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x0E, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x1D, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x3A, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x35, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x2B, t1 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x16, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x2C, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x18, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x30, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x21, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x02, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x05, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x0B, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x17, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x2E, t1 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, t2, 0x1C, t1
  GIFT_ROUND    a6, a4, a5, a3, t2, t3, t4, t5, t6, 0x38, t1
  GIFT_ROUND    a3, a4, a5, a6, t6, t2, t3, t4, t5, 0x31, t1
  GIFT_ROUND    a6, a4, a5, a3, t5, t6, t2, t3, t4, 0x23, t1
  GIFT_ROUND    a3, a4, a5, a6, t4, t5, t6, t2, t3, 0x06, t1 

  GIFT_ROUND    a6, a4, a5, a3, t3, t4, t5, t6, t2, 0x0D, t1
  GIFT_ROUND    a3, a4, a5, a6, t2, t3, t4, t5, t6, 0x1B, t1
  GIFT_ROUND    a6, a4, a5, a3, t6, t2, t3, t4, t5, 0x36, t1
  GIFT_ROUND    a3, a4, a5, a6, t5, t6, t2, t3, t4, 0x2D, t1
  GIFT_ROUND    a6, a4, a5, a3, t4, t5, t6, t2, t3, 0x1A, t1  
  //  
  GIFT_REVERSE  a3, a4, a5, a6
  GIFT_STSTATE  a2, a3, a4, a5, a6  
  GIFT_EPILOGUE
