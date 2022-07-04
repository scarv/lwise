#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (use caller-saved registers to save push/pop instructions)  
//
// a0:           the address of state
// a2-a7, t2-t5: state
// t0-t1, t6:    temp registers
// 
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro ISAP_PROLOGUE
.endm

.macro ISAP_EPILOGUE
  ret
.endm


// load state + store state  
.macro LU32_BIG  xh, ptr
  lw \xh, \ptr
  rev8 \xh, \xh
.endm

.macro SU32_BIG xh, ptr
  rev8 \xh, \xh
  sw   \xh, \ptr
.endm

#if (ISAP_RV32_TYPE1)
// 64-bit rotate right (immediate)

.macro ISAP_RORI64L dl, sl, sh, imm, t0
  srli \t0, \sl, \imm
  slli \dl, \sh, 32-\imm
  xor  \dl, \t0, \dl  
.endm 

.macro ISAP_RORI64H_0 dh, sl, sh, imm, t0
  slli \t0, \sl, 32-\imm
  srli \dh, \sh, \imm
  xor  \dh, \t0, \dh  
.endm 

.macro ISAP_RORI64H_1 dh, sl, sh, imm, t0, t1
  slli \t0, \sl, 32-\imm
  xor  \sl, \sl, \t1 
  srli \t1, \sh, \imm
  xor  \dh, \t0, \t1  
.endm 

// 64-bit rotate left (immediate)

.macro ISAP_ROLI64L dl, sl, sh, imm, t0
  slli \t0, \sl, \imm
  srli \dl, \sh, 32-\imm
  xor  \dl, \t0, \dl 
.endm 

.macro ISAP_ROLI64H_0 dh, sl, sh, imm, t0
  srli \t0, \sl, 32-\imm
  slli \dh, \sh, \imm
  xor  \dh, \t0, \dh
.endm 

.macro ISAP_ROLI64H_1 dh, sl, sh, imm, t0, t1
  srli \t0, \sl, 32-\imm
  xor  \sl, \sl, \t1 
  slli \t1, \sh, \imm
  xor  \dh, \t0, \t1
.endm 
#endif 

.macro ISAP_LDSTATE x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h
  LU32_BIG   \x0h,  0(a0)
  LU32_BIG   \x0l,  4(a0)
  LU32_BIG   \x1h,  8(a0)
  LU32_BIG   \x1l, 12(a0)
  LU32_BIG   \x2h, 16(a0)
  LU32_BIG   \x2l, 20(a0)
  LU32_BIG   \x3h, 24(a0)
  LU32_BIG   \x3l, 28(a0)
  LU32_BIG   \x4h, 32(a0)
  LU32_BIG   \x4l, 36(a0)
.endm

.macro ISAP_STSTATE x0l, x0h, x1l, x1h, x2l, x2h, x3l, x3h, x4l, x4h
  SU32_BIG   \x0h,  0(a0)
  SU32_BIG   \x0l,  4(a0)
  SU32_BIG   \x1h,  8(a0)
  SU32_BIG   \x1l, 12(a0)
  SU32_BIG   \x2h, 16(a0)
  SU32_BIG   \x2l, 20(a0)
  SU32_BIG   \x3h, 24(a0)
  SU32_BIG   \x3l, 28(a0)
  SU32_BIG   \x4h, 32(a0)
  SU32_BIG   \x4l, 36(a0)
.endm


// layers: PC + PS + PL

// PC: addition of constants

.macro ASCON_PC x2l, rci
  xori \x2l, \x2l, \rci
.endm

// PS: SBox x0 x1 x2 x3 x4 -> x3 x1 x2 x0 x4

.macro ASCON_PS x0, x1, x2, x3, x4, t0, t1, t2, t3
  xor  \t2, \x1, \x2    // t2 = x1 ^ x2
  xor  \t0, \x0, \x4    // t0 = x0 ^ x4
  xor  \t1, \x3, \x4    // t1 = x3 ^ x4 

  orn  \x2, \x3, \x4    // x2 = x3 | ~x4
  xor  \x2, \x2, \t2    // x2 = x1 ^ x2 ^ (x3 | ~x4)

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
.endm 

// PL: linear diffusion

#if (ISAP_RV32_TYPE1)

.macro ASCON_PL_STEP_0 xl, xh, imm0, imm1, t0, t1, t2 
  ISAP_RORI64L   \t1, \xl, \xh, \imm0, \t0 
  ISAP_RORI64L   \t2, \xl, \xh, \imm1, \t0 
  xor             \t1, \t1, \t2
  ISAP_RORI64H_0 \t2, \xl, \xh, \imm0, \t0
  ISAP_RORI64H_1 \t1, \xl, \xh, \imm1, \t0, \t1
  xor             \t1, \t2, \t1
  xor             \xh, \xh, \t1
.endm 

.macro ASCON_PL_STEP_1 xl, xh, imm0, imm1, t0, t1, t2 
  ISAP_ROLI64L   \t1, \xl, \xh, \imm0, \t0 
  ISAP_ROLI64L   \t2, \xl, \xh, \imm1, \t0 
  xor             \t1, \t1, \t2
  ISAP_ROLI64H_0 \t2, \xl, \xh, \imm0, \t0
  ISAP_ROLI64H_1 \t1, \xl, \xh, \imm1, \t0, \t1
  xor             \t1, \t2, \t1
  xor             \xh, \xh, \t1
.endm 

.macro ASCON_PL_STEP_2 xl, xh, imm0, imm1, t0, t1, t2 
  ISAP_RORI64L   \t1, \xl, \xh, \imm0, \t0 
  ISAP_ROLI64L   \t2, \xl, \xh, \imm1, \t0 
  xor             \t1, \t1, \t2
  ISAP_RORI64H_0 \t2, \xl, \xh, \imm0, \t0
  ISAP_ROLI64H_1 \t1, \xl, \xh, \imm1, \t0, \t1
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

#elif (ISAP_RV32_TYPE2)
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

.global Ascon_Permute_Nrounds

Ascon_Permute_Nrounds:
  ISAP_PROLOGUE
  ISAP_LDSTATE a2, a3, a4, a5, a6, a7, t2, t3, t4, t5
  //
#if (ISAP_RV32_TYPE1)
  li t0, 1
  bne a1, t0, N12
N1:
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x4B, t0, t1, t6 
  ISAP_STSTATE t2, t3, a4, a5, a6, a7, a2, a3, t4, t5
  j EPILOGUE
N12:
  li t0, 6
  beq a1, t0, N6
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0xF0, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0xE1, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0xD2, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0xC3, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0xB4, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0xA5, t0, t1, t6 
N6:
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x96, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x87, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x78, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x69, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x5A, t0, t1, t6 
  ASCON_ROUND   t2, t3, a4, a5, a6, a7, a2, a3, t4, t5, 0x4B, t0, t1, t6 
  
#elif (ISAP_RV32_TYPE2)
  li t0, 1
  bne a1, t0, N12
N1:
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x4B, t0, t1, t6 
  ISAP_STSTATE t0, t1, t2, t3, a4, a5, a6, a7, a2, a3
  j EPILOGUE
N12:
  li t0, 6
  beq a1, t0, N6
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0xF0, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0xE1, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0xD2, a2, a3, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0xC3, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0xB4, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0xA5, a2, a3, t6 
N6:
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x96, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x87, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x78, a2, a3, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, a7, t2, t3, t4, t5, 0x69, t0, t1, t6 
  ASCON_ROUND   t0, t1, t2, t3, a4, a5, a6, a7, a2, a3, 0x5A, t4, t5, t6 
  ASCON_ROUND   t4, t5, a6, a7, t2, t3, a4, a5, t0, t1, 0x4B, a2, a3, t6 
#endif

  ISAP_STSTATE a2, a3, a4, a5, a6, a7, t2, t3, t4, t5
  //

EPILOGUE:
  ISAP_EPILOGUE
