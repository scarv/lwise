#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a3~a6: cipher state
// t3~t6: key state
// t0, t1, t2: tmp registers
// a0, a1, a2: the address of plaintext, key, ciphertext, respectively 
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro GIFT_PROLOGUE
  addi sp, sp, -32
  sw   s0,  0(sp)
  sw   s1,  4(sp)
  sw   s2,  8(sp)
  sw   s3, 12(sp)
  sw   s4, 16(sp)
  sw   s5, 20(sp)
  sw   s6, 24(sp)
  sw   s7, 28(sp)
.endm

.macro GIFT_EPILOGUE
  lw   s0,  0(sp)
  lw   s1,  4(sp)
  lw   s2,  8(sp)
  lw   s3, 12(sp)
  lw   s4, 16(sp)
  lw   s5, 20(sp)
  lw   s6, 24(sp)
  lw   s7, 28(sp)
  addi sp, sp, 32 
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

.macro GIFT_SUBCELLS s0, s1, s2, s3, t0, t1
  and  \t0, \s0, \s2
  xor  \s1, \s1, \t0
  and  \t0, \s1, \s3
  xor  \t1, \s0, \t0
  or   \t0, \t1, \s1
  xor  \s2, \s2, \t0
  xor  \s3, \s3, \s2
  xor  \s1, \s1, \s3
  not  \s0, \s3
  and  \t0, \t1, \s1
  xor  \s2, \s2, \t0
  mv   \s3, \t1
.endm 

// PermBits

.macro GIFT_SWAPMOVE32 s0, mask, imm, t0, t1
  srli \t0, \s0, \imm
  xor  \t0, \s0, \t0
  and  \t0, \t0, \mask
  slli \t1, \t0, \imm
  xor  \t0, \t0, \t1
  xor  \s0, \t0, \s0
.endm

.macro GIFT_PERMBITS_STEP s0, t0, t1
  GIFT_SWAPMOVE32 \s0, s0,  3, \t0, \t1
  GIFT_SWAPMOVE32 \s0, s1,  6, \t0, \t1
  GIFT_SWAPMOVE32 \s0, s2, 12, \t0, \t1
  GIFT_SWAPMOVE32 \s0, s3, 24, \t0, \t1
.endm 

.macro GIFT_PERMBITS s0, s1, s2, s3, t0, t1
  GIFT_PERMBITS_STEP \s0, \t0, \t1 
  GIFT_PERMBITS_STEP \s1, \t0, \t1 
  GIFT_PERMBITS_STEP \s2, \t0, \t1 
  GIFT_PERMBITS_STEP \s3, \t0, \t1
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
  xor  \s3, \s3, a0
.endm  

// Key state update

.macro GIFT_KEYSTUPD k0, k1, k2, k3, t0, t1
  srli \t0, \k3, 12
  and  \t0, \t0, s4

  and  \t1, \k3, s5
  slli \t1, \t1, 4
  or   \t0, \t0, \t1
  
  srli \t1, \k3, 2
  and  \t1, \t1, s6
  or   \t0, \t0, \t1

  and  \t1, \k3, s7
  slli \t1, \t1, 14
  or   \t0, \t0, \t1

  mv   \k3, \k2
  mv   \k2, \k1
  mv   \k1, \k0
  mv   \k0, \t0
.endm


// operations in each round

.macro GIFT_ROUND s0, s1, s2, s3, k0, k1, k2, k3, rci, t0, t1
  GIFT_SUBCELLS \s0, \s1, \s2, \s3, \t0, \t1
  GIFT_PERMBITS \s0, \s1, \s2, \s3, \t0, \t1
  GIFT_ADDRDKEY \s1, \s2, \k1, \k3
  GIFT_ADDCONST \s3, \rci 
  GIFT_KEYSTUPD \k0, \k1, \k2, \k3, \t0, \t1
.endm


// GIFT-128

.section .text

.global giftb128

giftb128:
  GIFT_PROLOGUE
  GIFT_LDSTATE  a0, a3, a4, a5, a6
  GIFT_REVERSE  a3, a4, a5, a6
  GIFT_LDSTATE  a1, t3, t4, t5, t6
  GIFT_REVERSE  t3, t4, t5, t6
  not  a0, x0
  slli a0, a0, 31
  li   s0, 0x0A0A0A0A
  li   s1, 0x00CC00CC
  li   s2, 0x0000F0F0
  li   s3, 0x000000FF
  li   s4, 0x0000000F
  li   s5, 0x00000FFF
  li   s6, 0x3FFF0000
  li   s7, 0x00030000
  //  
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000001, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000003, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000007, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000000F, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000001F, t1, t2 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000003E, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000003D, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000003B, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000037, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000002F, t1, t2

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000001E, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000003C, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000039, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000033, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000027, t1, t2 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000000E, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000001D, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000003A, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000035, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000002B, t1, t2 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000016, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000002C, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000018, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000030, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000021, t1, t2 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000002, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000005, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000000B, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000017, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000002E, t1, t2 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000001C, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000038, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000031, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000023, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000006, t1, t2 

  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000000D, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000001B, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x00000036, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000002D, t1, t2
  GIFT_ROUND    a3, a4, a5, a6, t3, t4, t5, t6, 0x0000001A, t1, t2  
  //  
  GIFT_REVERSE  a3, a4, a5, a6
  GIFT_STSTATE  a2, a3, a4, a5, a6  
  GIFT_EPILOGUE
