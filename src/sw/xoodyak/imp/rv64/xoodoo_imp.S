#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"

// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a1~a6: state
// t0: the fixed tmp register used in "roli"
// t1~t5: tmp registers used in XOODOO_ROUND
// a0: the address of state
// ----------------------------------------------------------------------------


// rotate left (immediate)

.macro roliw rd, rs, imm
#if (ENABLE_ZBKB_ZBKX)
  roriw \rd, \rs, 32-\imm
#else
  slliw  t0, \rs, \imm
  srliw \rd, \rs, 32-\imm
  xor   \rd, \rd, t0
#endif
.endm

// pack 

.macro blnd rd, lo, hi
#if (ENABLE_ZBKB_ZBKX)
  pack  \rd, \lo, \hi
#else
  slli  \hi, \hi, 32   
  and   \lo, \lo, t6
  xor   \rd, \lo, \hi   
#endif 
.endm


// prologue + epilogue 

.macro XOODOO_PROLOGUE
.endm

.macro XOODOO_EPILOGUE
  ret
.endm


// load state + store state  

.macro XOODOO_LDSTATE a00, a02, a10, a12, a20, a22
  // plane 0
  ld    \a00,  0(a0)
  ld    \a02,  8(a0)

  // plane 1
  ld    \a10, 16(a0)
  ld    \a12, 24(a0)

  // plane 2
  ld    \a20, 32(a0)
  ld    \a22, 40(a0)
.endm

.macro XOODOO_STSTATE a00, a02, a10, a12, a20, a22
  // plane 0
  sd    \a00,  0(a0)
  sd    \a02,  8(a0)

  // plane 1
  sd    \a10, 16(a0)
  sd    \a12, 24(a0)

  // plane 2
  sd    \a20, 32(a0)
  sd    \a22, 40(a0)
.endm


// operations in the permutation: theta + rho_west + iota + chi + rho_east

.macro XOODOO_THETA a00, a02, a10, a12, a20, a22, t00, t01, t02, t03, t04
  xor   \t00, \a02, \a12   // t00 = a03 ^ a13, a02 ^ a12 
  xor   \t00, \t00, \a22   // t00 = a03 ^ a13 ^ a23, a02 ^ a12 ^ a23
  xor   \t01, \a00, \a10   // t01 = a01 ^ a11, a00 ^ a10
  xor   \t01, \t01, \a20   // t01 = a01 ^ a11 ^ a21, a00 ^ a10 ^ a20 

  // sheet 0 and 1
  srli  \t02, \t00,   32   // t02 = a03 ^ a13 ^ a23
  roliw \t03, \t02,    5   // t03 = t02 <<< 5
  roliw \t02, \t02,   14   // t02 = t02 <<< 14
  xor   \t02, \t03, \t02   // t02 = t03 ^ t02

  roliw \t03, \t01,    5   // t03 = lo(t01) <<< 5
  roliw \t04, \t01,   14   // t04 = lo(t01) <<< 14
  xor   \t03, \t04, \t03   // t03 = t04 ^ t03 
  
  blnd  \t02, \t02, \t03   // t02 = t03, t02
  xor   \a00, \a00, \t02   // a00 = a00 ^ t02
  xor   \a10, \a10, \t02   // a10 = a10 ^ t02
  xor   \a20, \a20, \t02   // a20 = a20 ^ t02

  // sheet 2 and 3
  srli  \t02, \t01,   32   // t02 = a01 ^ a11 ^ a21
  roliw \t03, \t02,    5   // t03 = t02 <<< 5
  roliw \t02, \t02,   14   // t02 = t02 <<< 14
  xor   \t02, \t03, \t02   // t02 = t03 ^ t02

  roliw \t03, \t00,    5   // t03 = lo(t00) <<< 5
  roliw \t04, \t00,   14   // t04 = lo(t00) <<< 14
  xor   \t03, \t04, \t03   // t03 = t04 ^ t03 

  blnd  \t02, \t02, \t03   // t02 = t03, t02
  xor   \a02, \a02, \t02   // a02 = a02 ^ t02
  xor   \a12, \a12, \t02   // a12 = a12 ^ t02
  xor   \a22, \a22, \t02   // a22 = a22 ^ t02
.endm

.macro XOODOO_RHOWEST a10, a12, a20, a22, t00, t01
#if (ENABLE_ZBKB_ZBKX)
  rori  \t00, \a10,   32   // t00 = a10, a11
  rori  \t01, \a12,   32   // t01 = a12, a13
  pack  \a10, \t01, \a10   // a10 = a10, a13
  pack  \a12, \t00, \a12   // a12 = a12, a11
#else 
  srli  \t00, \a10,   32   // t00 = 0, a11
  srli  \t01, \a12,   32   // t01 = 0, a13
  slli  \a10, \a10,   32   // a10 = a10, 0
  xor   \a10, \a10, \t01   // a10 = a10, a13
  slli  \a12, \a12,   32   // a12 = a12, 0
  xor   \a12, \a12, \t00   // a12 = a12, a11
#endif 

  srli  \t00, \a20,   32   // t00 = a21
  roliw \t00, \t00,   11   // t00 = a21 <<< 11
  roliw \a20, \a20,   11   // a20 = a20 <<< 11
  blnd  \a20, \a20, \t00   // a20 = t00, a20

  srli  \t00, \a22,   32   // t00 = a23
  roliw \t00, \t00,   11   // t00 = a23 <<< 11
  roliw \a22, \a22,   11   // a22 = a22 <<< 11
  blnd  \a22, \a22, \t00   // a22 = t00, a22
.endm

.macro XOODOO_IOTA a00, rci
  xori \a00, \a00, \rci
.endm

# if (ENABLE_ZBKB_ZBKX)
// When ZBKB_ZBKX is enabled, we can use the "andn" instruction.
.macro XOODOO_CHI a00, a02, a10, a12, a20, a22, t00, t01, t02
  // sheet 0 and 1
  andn \t00, \a20, \a10    // t00 = a20 & ~a10
  andn \t01, \a00, \a20    // t01 = a00 & ~a20 
  andn \t02, \a10, \a00    // t02 = a10 & ~a00

  xor  \a00, \a00, \t00    // a00 = a00 ^ t00
  xor  \a10, \a10, \t01    // a10 = a10 ^ t01
  xor  \a20, \a20, \t02    // a20 = a20 ^ t02

  // sheet 2 and 3
  andn \t00, \a22, \a12    // t00 = a22 & ~a12
  andn \t01, \a02, \a22    // t01 = a02 & ~a22 
  andn \t02, \a12, \a02    // t02 = a12 & ~a02

  xor  \a02, \a02, \t00    // a02 = a02 ^ t00
  xor  \a12, \a12, \t01    // a12 = a12 ^ t01
  xor  \a22, \a22, \t02    // a22 = a22 ^ t02 
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

.macro XOODOO_CHI_2 a00, a02, a10, a12, a20, a22, t00
  XOODOO_CHI_2_STEP \a00, \a10, \a20, \t00
  XOODOO_CHI_2_STEP \a02, \a12, \a22, \t00
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

.macro XOODOO_CHI_4 a00, a02, a10, a12, a20, a22, t00
  XOODOO_CHI_4_STEP \a00, \a10, \a20, \t00
  XOODOO_CHI_4_STEP \a02, \a12, \a22, \t00
.endm

.macro XOODOO_MASKING a00, a02
  not  \a00, \a00 
  not  \a02, \a02
.endm 

#endif 

.macro XOODOO_RHOEAST a10, a12, a20, a22, t00, t01, t02
  srli  \t00, \a10,   32   // t00 = a11
  roliw \t00, \t00,    1   // t00 = a11 <<< 1
  roliw \a10, \a10,    1   // a10 = a10 <<< 1
  blnd  \a10, \a10, \t00   // a10 = t00, a10

  srli  \t00, \a12,   32   // t00 = a13
  roliw \t00, \t00,    1   // t00 = a13 <<< 1
  roliw \a12, \a12,    1   // a12 = a12 <<< 1
  blnd  \a12, \a12, \t00   // a12 = t00, a12

  srli  \t00, \a20,   32   // t00 = a21
  roliw \t00, \t00,    8   // t00 = a21 <<< 8
  roliw \t01, \a20,    8   // t01 = a20 <<< 8
  srli  \t02, \a22,   32   // t02 = a23 
  roliw \t02, \t02,    8   // t02 = a23 <<< 8
  roliw \a20, \a22,    8   // a20 = a22 <<< 8 
  blnd  \a20, \a20, \t02   // a20 = t02, a20
  blnd  \a22, \t01, \t00   // a22 = t00, t01
.endm


// operations in each round
// the difference between type-0 and type-1 is XOODOO_CHI (when ZBKB_ZBKX is disabled)

.macro XOODOO_ROUND_0 a00, a02, a10, a12, a20, a22, t00, t01, t02, t03, t04, rci
  XOODOO_THETA   \a00, \a02, \a10, \a12, \a20, \a22, \t00, \t01, \t02, \t03, \t04
  XOODOO_RHOWEST \a10, \a12, \a20, \a22, \t00, \t01
  XOODOO_IOTA    \a00, \rci
#if (ENABLE_ZBKB_ZBKX) 
  XOODOO_CHI     \a00, \a02, \a10, \a12, \a20, \a22, \t00, \t01, \t02
#else 
  XOODOO_CHI_4   \a00, \a02, \a10, \a12, \a20, \a22, \t00
#endif
  XOODOO_RHOEAST \a10, \a12, \a20, \a22, \t00, \t01, \t02
.endm

.macro XOODOO_ROUND_1 a00, a02, a10, a12, a20, a22, t00, t01, t02, t03, t04, rci
  XOODOO_THETA   \a00, \a02, \a10, \a12, \a20, \a22, \t00, \t01, \t02, \t03, \t04
  XOODOO_RHOWEST \a10, \a12, \a20, \a22, \t00, \t01
  XOODOO_IOTA    \a00, \rci
#if (ENABLE_ZBKB_ZBKX) 
  XOODOO_CHI     \a00, \a02, \a10, \a12, \a20, \a22, \t00, \t01, \t02
#else 
  XOODOO_CHI_2   \a00, \a02, \a10, \a12, \a20, \a22, \t00
#endif
  XOODOO_RHOEAST \a10, \a12, \a20, \a22, \t00, \t01, \t02
.endm


// Xoodoo permutation 

.section .text

.global Xoodoo_Permute_12rounds

Xoodoo_Permute_12rounds:
  XOODOO_PROLOGUE
  XOODOO_LDSTATE  a1, a2, a3, a4, a5, a6
#if !(ENABLE_ZBKB_ZBKX)
  not             t6, x0
  srli            t6, t6, 32
  XOODOO_MASKING  a1, a2
#endif
  //
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000058
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000038
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x00000000000003C0
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x00000000000000D0
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000120
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000014 
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000060
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x000000000000002C
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000380
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x00000000000000F0
  XOODOO_ROUND_0  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x00000000000001A0
  XOODOO_ROUND_1  a1, a2, a3, a4, a5, a6, t1, t2, t3, t4, t5, 0x0000000000000012
  // 
#if !(ENABLE_ZBKB_ZBKX)
  XOODOO_MASKING  a1, a2
#endif
  XOODOO_STSTATE  a1, a2, a3, a4, a5, a6
  XOODOO_EPILOGUE 
