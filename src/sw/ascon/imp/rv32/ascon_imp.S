#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a2~a7, t2~t5: state
// t0, t1, t6: tmp registers used in ASCON_ROUND
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro ASCON_PROLOGUE
.endm

.macro ASCON_EPILOGUE
  ret
.endm


// load state + store state  

.macro ASCON_LDSTATE x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h
  lw   \x0l,  0(a0)
  lw   \x0h,  4(a0)

  lw   \x1l,  8(a0)
  lw   \x1h, 12(a0)

  lw   \x2l, 16(a0)
  lw   \x2h, 20(a0)

  lw   \x3l, 24(a0)
  lw   \x3h, 28(a0)

  lw   \x4l, 32(a0)
  lw   \x4h, 36(a0)
.endm

.macro ASCON_STSTATE x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h
  sw   \x0l,  0(a0)
  sw   \x0h,  4(a0)

  sw   \x1l,  8(a0)
  sw   \x1h, 12(a0)

  sw   \x2l, 16(a0)
  sw   \x2h, 20(a0)

  sw   \x3l, 24(a0)
  sw   \x3h, 28(a0)

  sw   \x4l, 32(a0)
  sw   \x4h, 36(a0)
.endm


// operations in the permutation: PC + PS + PL

// addition of constants

.macro ASCON_PC x2l, rci
  xori \x2l, \x2l, \rci
.endm

// sbox: x0 x1 x2 x3 x4 -> x3 x1 x2 x0 x4

.macro ASCON_PS x0, x1, x2, x3, x4, t0, t1, t2
#if (ENABLE_ZBKB_ZBKX)
// When ZBKB_ZBKX is enabled, we can use the "andn" and "orn" instruction.
  xor  \t2, \x1, \x2    // t2 = x1 ^ x2
  xor  \t0, \x0, \x4    // t0 = x0 ^ x4
  xor  \t1, \x3, \x4    // t1 = x3 ^ x4 

  orn  \x2, \x3, \x4    // x2 = x3 ^ ~x4
  xor  \x2, \x2, \t2    // x2 = x1 ^ x2 ^ (x3 ^ ~x4)

  andn \x4, \x1, \t0    // x4 = x1 & ~(x0 ^ x4)
  xor  \x4, \x4, \t1    // x4 = x3 ^ x4 ^ (x1 & ~(x0 ^ x4))

  or   \x0, \x0, \t1    // x0 = x0 | (x3 ^ x4)
  xor  \x3, \x1, \x3    // x3 = x1 ^ x3
  xor  \x0, \x0, \t2    // x0 = x1 ^ x2 ^ (x0 | (x3 ^ x4))

  or   \x3, \x3, \t2    // x3 = (x1 ^ x3) | (x1 ^ x2)
  xor  \t2, \t2, \t0    // t2 =  x0 ^ x4 ^ x1 ^ x2
  or   \t2, \t2, \x1    // t2 = x1 | (x0 ^ x4 ^ x1 ^ x2)

  xor  \x1, \t0, \x3    // x1 = x0 ^ x4 ^ ((x1 ^ x3) | (x1 ^ x2))
  xor  \x3, \t1, \t2    // x3 = x3 ^ x4 ^ (x1 | (x0 ^ x4 ^ x1 ^ x2))
#else
// When ZBKB_ZBKX is disabled, we use the optimized formulas based on the formulas 
// in [CJL+20], which save one tmp register compared to [CJL+20]. 
  xor  \t2, \x1, \x2    // t2 = x1 ^ x2
  xor  \t0, \x0, \x4    // t0 = x0 ^ x4
  xor  \t1, \x3, \x4    // t1 = x3 ^ x4 

  not  \x4, \x4         // x4 = ~x4
  or   \x2, \x3, \x4    // x2 = x3 ^ ~x4
  xor  \x2, \x2, \t2    // x2 = x1 ^ x2 ^ (x3 ^ ~x4)

  not  \x4, \t0         // x4 = ~(x0 ^ x4)
  and  \x4, \x1, \x4    // x4 = x1 & ~(x0 ^ x4)
  xor  \x4, \x4, \t1    // x4 = x3 ^ x4 ^ (x1 & ~(x0 ^ x4))

  or   \x0, \x0, \t1    // x0 = x0 | (x3 ^ x4)
  xor  \x3, \x1, \x3    // x3 = x1 ^ x3
  xor  \x0, \x0, \t2    // x0 = x1 ^ x2 ^ (x0 | (x3 ^ x4))

  or   \x3, \x3, \t2    // x3 = (x1 ^ x3) | (x1 ^ x2)
  xor  \t2, \t2, \t0    // t2 =  x0 ^ x4 ^ x1 ^ x2
  or   \t2, \t2, \x1    // t2 = x1 | (x0 ^ x4 ^ x1 ^ x2)

  xor  \x1, \t0, \x3    // x1 = x0 ^ x4 ^ ((x1 ^ x3) | (x1 ^ x2))
  xor  \x3, \t1, \t2    // x3 = x3 ^ x4 ^ (x1 | (x0 ^ x4 ^ x1 ^ x2))
#endif 
.endm 

// linear diffusion

#if (ASCON_RV32_TYPE1)
// 64-bit rotate right (immediate)

.macro ASCON_RORI64L dl, sl, sh, imm, t0
  srli \t0, \sl, \imm
  slli \dl, \sh, 32-\imm
  xor  \dl, \t0, \dl  
.endm 

.macro ASCON_RORI64H_0 dh, sl, sh, imm, t0
  slli \t0, \sl, 32-\imm
  srli \dh, \sh, \imm
  xor  \dh, \t0, \dh  
.endm a2, a3, a4, a5, a6, a7, t2, t3, t4, t

.macro ASCON_RORI64H_1 dh, sl, sh, imm, t0, t1
  slli \t0, \sl, 32-\imm
  xor  \sl, \sl, \t1 
  srli \t1, \sh, \imm
  xor  \dh, \t0, \t1  
.endm 

// 64-bit rotate left (immediate)

.macro ASCON_ROLI64L dl, sl, sh, imm, t0
  slli \t0, \sl, \imm
  srli \dl, \sh, 32-\imm
  xor  \dl, \t0, \dl 
.endm 

.macro ASCON_ROLI64H_0 dh, sl, sh, imm, t0
  srli \t0, \sl, 32-\imm
  slli \dh, \sh, \imm
  xor  \dh, \t0, \dh
.endm 

.macro ASCON_ROLI64H_1 dh, sl, sh, imm, t0, t1
  srli \t0, \sl, 32-\imm
  xor  \sl, \sl, \t1 
  slli \t1, \sh, \imm
  xor  \dh, \t0, \t1
.endm 

.macro ASCON_PL_STEP_0 xl, xh, imm0, imm1, t0, t1, t2 
  ASCON_RORI64L   \t1, \xl, \xh, \imm0, \t0 
  ASCON_RORI64L   \t2, \xl, \xh, \imm1, \t0 
  xor             \t1, \t1, \t2
  ASCON_RORI64H_0 \t2, \xl, \xh, \imm0, \t0
  ASCON_RORI64H_1 \t1, \xl, \xh, \imm1, \t0, \t1
  xor             \t1, \t2, \t1
  xor             \xh, \xh, \t1
.endm 

.macro ASCON_PL_STEP_1 xl, xh, imm0, imm1, t0, t1, t2 
  ASCON_ROLI64L   \t1, \xl, \xh, \imm0, \t0 
  ASCON_ROLI64L   \t2, \xl, \xh, \imm1, \t0 
  xor             \t1, \t1, \t2
  ASCON_ROLI64H_0 \t2, \xl, \xh, \imm0, \t0
  ASCON_ROLI64H_1 \t1, \xl, \xh, \imm1, \t0, \t1
  xor             \t1, \t2, \t1
  xor             \xh, \xh, \t1
.endm 

.macro ASCON_PL_STEP_2 xl, xh, imm0, imm1, t0, t1, t2 
  ASCON_RORI64L   \t1, \xl, \xh, \imm0, \t0 
  ASCON_ROLI64L   \t2, \xl, \xh, \imm1, \t0 
  xor             \t1, \t1, \t2
  ASCON_RORI64H_0 \t2, \xl, \xh, \imm0, \t0
  ASCON_ROLI64H_1 \t1, \xl, \xh, \imm1, \t0, \t1
  xor             \t1, \t2, \t1
  xor             \xh, \xh, \t1
.endm 

.macro ASCON_PL x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h, t0, t1, t2
  ASCON_PL_STEP_0 \x0l, \x0h, 19, 28, \t0, \t1, \t2
  ASCON_PL_STEP_1 \x1l, \x1h,  3, 25, \t0, \t1, \t2
  ASCON_PL_STEP_0 \x2l, \x2h,  1,  6, \t0, \t1, \t2
  ASCON_PL_STEP_0 \x3l, \x3h, 10, 17, \t0, \t1, \t2
  ASCON_PL_STEP_2 \x4l, \x4h,  7, 23, \t0, \t1, \t2
.endm
#elif (ASCON_RV32_TYPE2)
//  x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h -> 
//  t0l, t0h, x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h 

.macro ASCON_PL x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h, t0l, t0h, t2
  ascon.sigma.lo \t0l, \x0l, \x0h, 0
  ascon.sigma.hi \t0h, \x0l, \x0h, 0
  ascon.sigma.lo \x0l, \x1l, \x1h, 1
  ascon.sigma.hi \x0h, \x1l, \x1h, 1
  ascon.sigma.lo \x1l, \x2l, \x2h, 2
  ascon.sigma.hi \x1h, \x2l, \x2h, 2
  ascon.sigma.lo \x2l, \x3l, \x3h, 3
  ascon.sigma.hi \x2h, \x3l, \x3h, 3
  ascon.sigma.lo \x3l, \x4l, \x4h, 4
  ascon.sigma.hi \x3h, \x4l, \x4h, 4
.endm
#endif


// operations in each round 

.macro ASCON_ROUND x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h, rci, t0, t1, t2
  ASCON_PC \x2l, \rci
  ASCON_PS \x0l, \x1l, \x2l, \x3l, \x4l, \t0, \t1, \t2
  ASCON_PS \x0h, \x1h, \x2h, \x3h, \x4h, \t0, \t1, \t2
  ASCON_PL \x3l, \x3h, \x1l, \x1h, \x2l, \x2h, \x0l, \x0h, \x4l, \x4h, \t0, \t1, \t2
.endm 


// Ascon permutation 

.section .text

.global Ascon_Permute_6rounds

Ascon_Permute_6rounds:
  ASCON_PROLOGUE
  ASCON_LDSTATE a2, a3, a4, a5, a6, a7, t2, t3, t4, t5
  //
#if (ASCON_RV32_TYPE1)
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000096, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x00000087, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000078, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x00000069, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x0000005A, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x0000004B, t0, t1, t6 
#elif (ASCON_RV32_TYPE2)
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000096, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x00000087, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x00000078, a2, a3, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000069, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x0000005A, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x0000004B, a2, a3, t6 
#endif
  //
  ASCON_STSTATE a2, a3, a4, a5, a6, a7, t2, t3, t4, t5
  ASCON_EPILOGUE


.section .text

.global Ascon_Permute_12rounds

Ascon_Permute_12rounds:
  ASCON_PROLOGUE
  ASCON_LDSTATE a2, a3, a4, a5, a6, a7, t2, t3, t4, t5
  //
#if (ASCON_RV32_TYPE1)
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x000000F0, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x000000E1, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x000000D2, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x000000C3, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x000000B4, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x000000A5, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000096, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x00000087, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000078, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x00000069, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x0000005A, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x0000004B, t0, t1, t6 
#elif (ASCON_RV32_TYPE2)
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x000000F0, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x000000E1, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x000000D2, a2, a3, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x000000C3, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x000000B4, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x000000A5, a2, a3, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000096, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x00000087, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x00000078, a2, a3, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x00000069, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x0000005A, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x0000004B, a2, a3, t6 
#endif
  //
  ASCON_STSTATE a2, a3, a4, a5, a6, a7, t2, t3, t4, t5
  ASCON_EPILOGUE
    