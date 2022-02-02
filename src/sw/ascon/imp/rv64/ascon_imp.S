#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"

// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a2~a6: state
// t0, t1, t6: tmp registers used in ASCON_ROUND
// ----------------------------------------------------------------------------

// prologue + epilogue 

.macro ASCON_PROLOGUE
.endm

.macro ASCON_EPILOGUE
  ret
.endm


// load state + store state  

.macro ASCON_LDSTATE x0, x1, x2, x3, x4
  ld   \x0,  0(a0)
  ld   \x1,  8(a0)
  ld   \x2, 16(a0)
  ld   \x3, 24(a0)
  ld   \x4, 32(a0)
.endm

.macro ASCON_STSTATE x0, x1, x2, x3, x4
  sd   \x0,  0(a0)
  sd   \x1,  8(a0)
  sd   \x2, 16(a0)
  sd   \x3, 24(a0)
  sd   \x4, 32(a0)
.endm


// operations in the permutation: PC + PS + PL

// addition of constants

.macro ASCON_PC x2, rci
  xori \x2, \x2, \rci
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

#if (ASCON_RV64_TYPE1)
.macro ASCON_PL_STEP x0, imm0, imm1, t0
  rori \t0, \x0, \imm0
  xor  \t0, \x0, \t0
  rori \x0, \x0, \imm1
  xor  \x0, \t0, \x0
.endm

.macro ASCON_PL x0, x1, x2, x3, x4, t0
  ASCON_PL_STEP \x0, 19, 28, \t0
  ASCON_PL_STEP \x1, 61, 39, \t0
  ASCON_PL_STEP \x2,  1,  6, \t0
  ASCON_PL_STEP \x3, 10, 17, \t0
  ASCON_PL_STEP \x4,  7, 41, \t0
.endm
#elif (ASCON_RV64_TYPE2)
.macro ASCON_PL x0, x1, x2, x3, x4, t0
  ascon.sigma \x0, \x0, 0
  ascon.sigma \x1, \x1, 1
  ascon.sigma \x2, \x2, 2
  ascon.sigma \x3, \x3, 3
  ascon.sigma \x4, \x4, 4
.endm
#endif


// operations in each round 

.macro ASCON_ROUND x0, x1, x2, x3, x4, rci, t0, t1, t2
  ASCON_PC \x2, \rci
  ASCON_PS \x0, \x1, \x2, \x3, \x4, \t0, \t1, \t2
  ASCON_PL \x3, \x1, \x2, \x0, \x4, \t0
.endm 


// Ascon permutation 

.section .text

.global Ascon_Permute_6rounds

Ascon_Permute_6rounds:
  ASCON_PROLOGUE
  ASCON_LDSTATE a2, a3, a4, a5, a6
  //
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x0000000000000096, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x0000000000000087, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x0000000000000078, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x0000000000000069, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x000000000000005A, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x000000000000004B, t0, t1, t6 
  //
  ASCON_STSTATE a2, a3, a4, a5, a6
  ASCON_EPILOGUE


.section .text

.global Ascon_Permute_12rounds

Ascon_Permute_12rounds:
  ASCON_PROLOGUE
  ASCON_LDSTATE a2, a3, a4, a5, a6
  //
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x00000000000000F0, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x00000000000000E1, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x00000000000000D2, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x00000000000000C3, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x00000000000000B4, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x00000000000000A5, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x0000000000000096, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x0000000000000087, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x0000000000000078, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x0000000000000069, t0, t1, t6 
  ASCON_ROUND   a2, a3, a4, a5, a6, 0x000000000000005A, t0, t1, t6 
  ASCON_ROUND   a5, a3, a4, a2, a6, 0x000000000000004B, t0, t1, t6 
  //
  ASCON_STSTATE a2, a3, a4, a5, a6
  ASCON_EPILOGUE
