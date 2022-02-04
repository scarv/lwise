#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a1~a7, t1~t3, s0~s1: state  
// t0: the fixed tmp register used in "roli"
// t4~t6: tmp registers used in XOODOO_ROUND
// a0: the address of state
// ----------------------------------------------------------------------------


// rotate left (immediate)

.macro roli rd, rs, imm
#if (ENABLE_ZBKB_ZBKX)
  rori \rd, \rs, 32-\imm
#else
  slli  t0, \rs, \imm
  srli \rd, \rs, 32-\imm
  xor  \rd, \rd, t0
#endif
.endm


// prologue + epilogue 

.macro XOODOO_PROLOGUE
  addi sp,  sp, -8
  sw   s0,  0(sp)
  sw   s1,  4(sp)
.endm

.macro XOODOO_EPILOGUE
  lw   s0,   0(sp)
  lw   s1,   4(sp)
  addi sp,  sp, 8
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


// operations in the permutation: theta + rho_west + iota + chi + rho_east

.macro XOODOO_THETA a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02
  xor  \t00, \a03, \a13   // t00 = a03 ^ a13
  xor  \t00, \t00, \a23   // t00 = a03 ^ a13 ^ a23

  // sheet 0
  xor  \t01, \a00, \a10   // t01 = a00 ^ a10
  xor  \t01, \t01, \a20   // t01 = a00 ^ a10 ^ a20

#if (XOODYAK_RV32_TYPE1)
  roli \t02, \t00,    5   // t02 = t00 <<< 5
  roli \t00, \t00,   14   // t00 = t00 <<< 14
  xor  \t00, \t02, \t00   // t00 = t00 ^ t02
#elif (XOODYAK_RV32_TYPE2)
  xoodyak.xorrol \t00, \t00, \t00
#endif

  xor  \a00, \a00, \t00   // a00 = a00 ^ t00
  xor  \a10, \a10, \t00   // a10 = a10 ^ t00
  xor  \a20, \a20, \t00   // a20 = a20 ^ t00 

  // sheet 1
  xor  \t00, \a01, \a11   // t00 = a01 ^ a11
  xor  \t00, \t00, \a21   // t00 = a01 ^ a11 ^ a21

#if (XOODYAK_RV32_TYPE1)
  roli \t02, \t01,    5   // t02 = t01 <<< 5
  roli \t01, \t01,   14   // t01 = t01 <<< 14
  xor  \t01, \t02, \t01   // t01 = t01 ^ t02
#elif (XOODYAK_RV32_TYPE2)
  xoodyak.xorrol \t01, \t01, \t01
#endif

  xor  \a01, \a01, \t01   // a01 = a01 ^ t01
  xor  \a11, \a11, \t01   // a11 = a11 ^ t01
  xor  \a21, \a21, \t01   // a21 = a21 ^ t01 

  // sheet 2 
  xor  \t01, \a02, \a12   // t01 = a02 ^ a12
  xor  \t01, \t01, \a22   // t01 = a02 ^ a12 ^ a22

#if (XOODYAK_RV32_TYPE1)
  roli \t02, \t00,    5   // t02 = t00 <<< 5
  roli \t00, \t00,   14   // t00 = t00 <<< 14
  xor  \t00, \t02, \t00   // t00 = t00 ^ t02
#elif (XOODYAK_RV32_TYPE2)
  xoodyak.xorrol \t00, \t00, \t00
#endif

  xor  \a02, \a02, \t00   // a02 = a02 ^ t00
  xor  \a12, \a12, \t00   // a12 = a12 ^ t00
  xor  \a22, \a22, \t00   // a22 = a22 ^ t00       

  // sheet 3 
#if (XOODYAK_RV32_TYPE1)
  roli \t02, \t01,    5   // t02 = t01 <<< 5
  roli \t01, \t01,   14   // t01 = t01 <<< 14
  xor  \t01, \t02, \t01   // t01 = t01 ^ t02
#elif (XOODYAK_RV32_TYPE2)
  xoodyak.xorrol \t01, \t01, \t01
#endif

  xor  \a03, \a03, \t01   // a03 = a03 ^ t01
  xor  \a13, \a13, \t01   // a13 = a13 ^ t01
  xor  \a23, \a23, \t01   // a23 = a23 ^ t01 
.endm

.macro XOODOO_RHOWEST a10, a11, a12, a13, a20, a21, a22, a23, t00
  mv   \t00, \a10
  mv   \a10, \a13
  mv   \a13, \a12
  mv   \a12, \a11
  mv   \a11, \t00

  roli \a20, \a20, 11
  roli \a21, \a21, 11
  roli \a22, \a22, 11
  roli \a23, \a23, 11
.endm

.macro XOODOO_IOTA a00, rci
  xori \a00, \a00, \rci
.endm

#if (ENABLE_ZBKB_ZBKX)
// When ZBKB_ZBKX is enabled, we can use the "andn" instruction.
.macro XOODOO_CHI a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02
  // sheet 0
  andn \t00, \a20, \a10   // t00 = a20 & ~a10
  andn \t01, \a00, \a20   // t01 = a00 & ~a20 
  andn \t02, \a10, \a00   // t02 = a10 & ~a00

  xor  \a00, \a00, \t00   // a00 = a00 ^ t00
  xor  \a10, \a10, \t01   // a10 = a10 ^ t01
  xor  \a20, \a20, \t02   // a20 = a20 ^ t02

  // sheet 1
  andn \t00, \a21, \a11   // t00 = a21 & ~a11
  andn \t01, \a01, \a21   // t01 = a01 & ~a21 
  andn \t02, \a11, \a01   // t02 = a11 & ~a01

  xor  \a01, \a01, \t00   // a01 = a01 ^ t00
  xor  \a11, \a11, \t01   // a11 = a11 ^ t01
  xor  \a21, \a21, \t02   // a21 = a21 ^ t02  

  // sheet 2 
  andn \t00, \a22, \a12   // t00 = a22 & ~a12
  andn \t01, \a02, \a22   // t01 = a02 & ~a22 
  andn \t02, \a12, \a02   // t02 = a12 & ~a02

  xor  \a02, \a02, \t00   // a02 = a02 ^ t00
  xor  \a12, \a12, \t01   // a12 = a12 ^ t01
  xor  \a22, \a22, \t02   // a22 = a22 ^ t02 

  // sheet 3 
  andn \t00, \a23, \a13   // t00 = a23 & ~a13
  andn \t01, \a03, \a23   // t01 = a03 & ~a23
  andn \t02, \a13, \a03   // t02 = a13 & ~a03

  xor  \a03, \a03, \t00   // a03 = a03 ^ t00
  xor  \a13, \a13, \t01   // a13 = a13 ^ t01
  xor  \a23, \a23, \t02   // a23 = a23 ^ t02    
.endm 

#else
// When ZBKB_ZBKX is disabled, we use the method described in [CJL+20].
.macro XOODOO_CHI_2_STEP a00, a10, a20, t00
  and  \t00, \a10, \a20   // t00 = a10 & a20
  xor  \a00, \a00, \t00   // a00 = a00 ^ t00
  or   \t00, \a20, \a00   // t00 = a20 | a00
  xor  \a10, \a10, \t00   // a10 = a10 ^ t00
  and  \t00, \a00, \a10   // t00 = a00 & a10
  xor  \a20, \a20, \t00   // a20 = a20 ^ t00
.endm 

.macro XOODOO_CHI_2 a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00
  XOODOO_CHI_2_STEP \a00, \a10, \a20, \t00
  XOODOO_CHI_2_STEP \a01, \a11, \a21, \t00
  XOODOO_CHI_2_STEP \a02, \a12, \a22, \t00
  XOODOO_CHI_2_STEP \a03, \a13, \a23, \t00
.endm

.macro XOODOO_CHI_4_STEP a00, a10, a20, t00
  xori \t00, \a10, -1     // t00 = ~a10
  and  \t00, \t00, \a20   // t00 = t00 & a20
  xor  \a00, \a00, \t00   // a00 = a00 ^ t00
  or   \t00, \a20, \a00   // t00 = a20 | a00
  xor  \a10, \a10, \t00   // a10 = a10 ^ t00
  xori \t00, \a10, -1     // t00 = ~a10
  and  \t00, \a00, \t00   // t00 = a00 & t00
  xor  \a20, \a20, \t00   // a20 = a20 ^ t00 
.endm 

.macro XOODOO_CHI_4 a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00
  XOODOO_CHI_4_STEP \a00, \a10, \a20, \t00
  XOODOO_CHI_4_STEP \a01, \a11, \a21, \t00
  XOODOO_CHI_4_STEP \a02, \a12, \a22, \t00
  XOODOO_CHI_4_STEP \a03, \a13, \a23, \t00
.endm

.macro XOODOO_MASKING a00, a01, a02, a03
  not  \a00, \a00 
  not  \a01, \a01
  not  \a02, \a02
  not  \a03, \a03
.endm 

#endif

.macro XOODOO_RHOEAST a10, a11, a12, a13, a20, a21, a22, a23, t00
  roli \a10, \a10, 1
  roli \a11, \a11, 1
  roli \a12, \a12, 1 
  roli \a13, \a13, 1

  roli \t00, \a20, 8
  roli \a20, \a22, 8
  mv   \a22, \t00
  roli \t00, \a21, 8
  roli \a21, \a23, 8
  mv   \a23, \t00
.endm


// operations in each round
// the difference between type-0 and type-1 is XOODOO_CHI (when ZBKB_ZBKX is disabled)

.macro XOODOO_ROUND_0 a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02, rci
  XOODOO_THETA   \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00, \t01, \t02
  XOODOO_RHOWEST \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00
  XOODOO_IOTA    \a00, \rci
#if (ENABLE_ZBKB_ZBKX)  
  XOODOO_CHI     \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00, \t01, \t02
#else 
  XOODOO_CHI_4   \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00
#endif
  XOODOO_RHOEAST \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00
.endm 

.macro XOODOO_ROUND_1 a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, t00, t01, t02, rci
  XOODOO_THETA   \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00, \t01, \t02
  XOODOO_RHOWEST \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00
  XOODOO_IOTA    \a00, \rci
#if (ENABLE_ZBKB_ZBKX)  
  XOODOO_CHI     \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00, \t01, \t02
#else 
  XOODOO_CHI_2   \a00, \a01, \a02, \a03, \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00
#endif
  XOODOO_RHOEAST \a10, \a11, \a12, \a13, \a20, \a21, \a22, \a23, \t00
.endm 


// Xoodoo permutation 

.section .text

.global Xoodoo_Permute_12rounds

Xoodoo_Permute_12rounds:
  XOODOO_PROLOGUE
  XOODOO_LDSTATE  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1
#if !(ENABLE_ZBKB_ZBKX)
  XOODOO_MASKING  a1, a2, a3, a4
#endif
  //
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000058
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000038
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x000003C0
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x000000D0
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000120
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000014  
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000060
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x0000002C
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000380
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x000000F0
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x000001A0
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1, t4, t5, t6, 0x00000012
  //
#if !(ENABLE_ZBKB_ZBKX)
  XOODOO_MASKING  a1, a2, a3, a4
#endif
  XOODOO_STSTATE  a1, a2, a3, a4, a5, a6, a7, t1, t2, t3, s0, s1
  XOODOO_EPILOGUE 
