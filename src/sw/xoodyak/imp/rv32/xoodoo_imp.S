#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (use caller-saved registers to save push/pop instructions)  
//
// a0:                  the address of state
// a1-a7, t0-t3, s0:    state  
// t4-t6:               temp registers 
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro XOODOO_PROLOGUE
  addi sp, sp, -4
  sw   s0, 0(sp)
.endm

.macro XOODOO_EPILOGUE
  lw   s0, 0(sp)
  addi sp, sp, 4
  ret
.endm


// load state + store state  

.macro XOODOO_LDSTATE a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23
  // plane 0
  lw   \a00,  0(a0)
  lw   \a01,  4(a0)
  lw   \a02,  8(a0)
  lw   \a03, 12(a0)
  // plane 1
  lw   \a10, 16(a0)
  lw   \a11, 20(a0)
  lw   \a12, 24(a0)
  lw   \a13, 28(a0)
  // plane 2
  lw   \a20, 32(a0)
  lw   \a21, 36(a0)
  lw   \a22, 40(a0)
  lw   \a23, 44(a0)
.endm

.macro XOODOO_STSTATE a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23
  // plane 0
  sw   \a00,  0(a0)
  sw   \a01,  4(a0)
  sw   \a02,  8(a0)
  sw   \a03, 12(a0)
  // plane 1
  sw   \a10, 16(a0)
  sw   \a11, 20(a0)
  sw   \a12, 24(a0)
  sw   \a13, 28(a0)
  // plane 2
  sw   \a20, 32(a0)
  sw   \a21, 36(a0)
  sw   \a22, 40(a0)
  sw   \a23, 44(a0) 
.endm


// layers: theta + rho_west + iota + chi + rho_east

// rotate left (immediate)

.macro roli rd, rs, imm
  rori \rd, \rs, 32-\imm
.endm

.macro XOODOO_XORROL t00, t01
#if   (XOODYAK_RV32_TYPE1)
  roli \t01, \t00, 5
  roli \t00, \t00, 14
  xor  \t00, \t00, \t01
#elif (XOODYAK_RV32_TYPE2)
  xoodyak.xorrol \t00, \t00, \t00
#endif
.endm

.macro XOODOO_THETA a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02
  xor  \t00, \a03, \a13     // t00 = a03 ^ a13
  xor  \t00, \t00, \a23     // t00 = a03 ^ a13 ^ a23

  // sheet 0
  xor  \t01, \a00, \a10     // t01 = a00 ^ a10
  xor  \t01, \t01, \a20     // t01 = a00 ^ a10 ^ a20
  XOODOO_XORROL \t00, \t02
  xor  \a00, \a00, \t00     // a00 = a00 ^ t00
  xor  \a10, \a10, \t00     // a10 = a10 ^ t00
  xor  \a20, \a20, \t00     // a20 = a20 ^ t00 

  // sheet 1
  xor  \t00, \a01, \a11     // t00 = a01 ^ a11
  xor  \t00, \t00, \a21     // t00 = a01 ^ a11 ^ a21
  XOODOO_XORROL \t01, \t02
  xor  \a01, \a01, \t01     // a01 = a01 ^ t01
  xor  \a11, \a11, \t01     // a11 = a11 ^ t01
  xor  \a21, \a21, \t01     // a21 = a21 ^ t01 

  // sheet 2 
  xor  \t01, \a02, \a12     // t01 = a02 ^ a12
  xor  \t01, \t01, \a22     // t01 = a02 ^ a12 ^ a22
  XOODOO_XORROL \t00, \t02
  xor  \a02, \a02, \t00     // a02 = a02 ^ t00
  xor  \a12, \a12, \t00     // a12 = a12 ^ t00
  xor  \a22, \a22, \t00     // a22 = a22 ^ t00       

  // sheet 3 
  XOODOO_XORROL \t01, \t02
  xor  \a03, \a03, \t01     // a03 = a03 ^ t01
  xor  \a13, \a13, \t01     // a13 = a13 ^ t01
  xor  \a23, \a23, \t01     // a23 = a23 ^ t01 
.endm

.macro XOODOO_RHOWEST a10, a11, a12, a13, a20, a21, a22, a23
  // a10, a11, a12, a13, a14 -> a13, a10, a11, a12
  roli \a20, \a20, 11
  roli \a21, \a21, 11
  roli \a22, \a22, 11
  roli \a23, \a23, 11
.endm

.macro XOODOO_IOTA a00, rci
  xori \a00, \a00, \rci
.endm

.macro XOODOO_CHI a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02
  // sheet 0
  andn \t00, \a20, \a10     // t00 = a20 & ~a10
  andn \t01, \a00, \a20     // t01 = a00 & ~a20 
  andn \t02, \a10, \a00     // t02 = a10 & ~a00
  xor  \a00, \a00, \t00     // a00 = a00 ^ t00
  xor  \a10, \a10, \t01     // a10 = a10 ^ t01
  xor  \a20, \a20, \t02     // a20 = a20 ^ t02

  // sheet 1
  andn \t00, \a21, \a11     // t00 = a21 & ~a11
  andn \t01, \a01, \a21     // t01 = a01 & ~a21 
  andn \t02, \a11, \a01     // t02 = a11 & ~a01
  xor  \a01, \a01, \t00     // a01 = a01 ^ t00
  xor  \a11, \a11, \t01     // a11 = a11 ^ t01
  xor  \a21, \a21, \t02     // a21 = a21 ^ t02  

  // sheet 2 
  andn \t00, \a22, \a12     // t00 = a22 & ~a12
  andn \t01, \a02, \a22     // t01 = a02 & ~a22 
  andn \t02, \a12, \a02     // t02 = a12 & ~a02
  xor  \a02, \a02, \t00     // a02 = a02 ^ t00
  xor  \a12, \a12, \t01     // a12 = a12 ^ t01
  xor  \a22, \a22, \t02     // a22 = a22 ^ t02 

  // sheet 3 
  andn \t00, \a23, \a13     // t00 = a23 & ~a13
  andn \t01, \a03, \a23     // t01 = a03 & ~a23
  andn \t02, \a13, \a03     // t02 = a13 & ~a03
  xor  \a03, \a03, \t00     // a03 = a03 ^ t00
  xor  \a13, \a13, \t01     // a13 = a13 ^ t01
  xor  \a23, \a23, \t02     // a23 = a23 ^ t02    
.endm 

.macro XOODOO_RHOEAST a10, a11, a12, a13, a20, a21, a22, a23
  roli \a10, \a10, 1
  roli \a11, \a11, 1
  roli \a12, \a12, 1 
  roli \a13, \a13, 1
  // a20, a21, a22, a23 -> a22, a23, a20, a21
  roli \a20, \a20, 8
  roli \a21, \a21, 8
  roli \a22, \a22, 8
  roli \a23, \a23, 8
.endm

// operations in each round

.macro XOODOO_ROUND a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02, rci
  XOODOO_THETA   \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00, \t01, \t02
  XOODOO_RHOWEST \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23
  XOODOO_IOTA    \a00, \rci 
  XOODOO_CHI     \a00, \a01, \a02, \a03, \a13, \a10, \a11, \a12, \a20, \a21, \a22, \a23, \t00, \t01, \t02
  XOODOO_RHOEAST \a13, \a10, \a11, \a12, \a20, \a21, \a22, \a23
.endm 


// Xoodoo permutation 

.section .text

.global Xoodoo_Permute_12rounds

Xoodoo_Permute_12rounds:
  XOODOO_PROLOGUE
  XOODOO_LDSTATE  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, t0
  //
  XOODOO_ROUND  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, t0, t4, t5, t6, 0x058
  XOODOO_ROUND  a1, a2, a3, a4, t1, a5, a6, a7, s0, t0, t2, t3, t4, t5, t6, 0x038
  XOODOO_ROUND  a1, a2, a3, a4, a7, t1, a5, a6, t2, t3, s0, t0, t4, t5, t6, 0x3C0
  XOODOO_ROUND  a1, a2, a3, a4, a6, a7, t1, a5, s0, t0, t2, t3, t4, t5, t6, 0x0D0
  XOODOO_ROUND  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, t0, t4, t5, t6, 0x120
  XOODOO_ROUND  a1, a2, a3, a4, t1, a5, a6, a7, s0, t0, t2, t3, t4, t5, t6, 0x014  
  XOODOO_ROUND  a1, a2, a3, a4, a7, t1, a5, a6, t2, t3, s0, t0, t4, t5, t6, 0x060
  XOODOO_ROUND  a1, a2, a3, a4, a6, a7, t1, a5, s0, t0, t2, t3, t4, t5, t6, 0x02C
  XOODOO_ROUND  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, t0, t4, t5, t6, 0x380
  XOODOO_ROUND  a1, a2, a3, a4, t1, a5, a6, a7, s0, t0, t2, t3, t4, t5, t6, 0x0F0
  XOODOO_ROUND  a1, a2, a3, a4, a7, t1, a5, a6, t2, t3, s0, t0, t4, t5, t6, 0x1A0
  XOODOO_ROUND  a1, a2, a3, a4, a6, a7, t1, a5, s0, t0, t2, t3, t4, t5, t6, 0x012
  //
  XOODOO_STSTATE  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, t0
  XOODOO_EPILOGUE 
