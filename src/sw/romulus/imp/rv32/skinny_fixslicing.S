#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (use caller-saved registers to save push/pop instructions)  
//
// a0-a3:            the address of out, in, rtk_1, rtk_23
// t0-t3:            state 
// t4:               temp register
// a4:               temp address of rtk_1 
// a1, a5-a7, t5-t6: masks 
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro SKINNY_PROLOGUE
.endm

.macro SKINNY_EPILOGUE
  ret 
.endm


// MixColumns computations 

.macro SKINNY_MIXCOL0 s0, t0
#if   (ROMULUS_RV32_TYPE1)
  rori \t0, \s0, 24
  and  \t0, \t0, t5
  rori \t0, \t0, 30
  xor  \s0, \s0, \t0
  rori \t0, \s0, 16
  and  \t0, \t0, t6
  rori \t0, \t0, 4
  xor  \s0, \s0, \t0
  rori \t0, \s0, 8
  and  \t0, \t0, t5
  rori \t0, \t0, 2
  xor  \s0, \s0, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.mixcolumns \s0, \s0, 0
#endif 
.endm

.macro SKINNY_MIXCOL1 s0, t0
#if   (ROMULUS_RV32_TYPE1)
  rori \t0, \s0, 16
  and  \t0, \t0, a7
  rori \t0, \t0, 30
  xor  \s0, \s0, \t0
  and  \t0, \s0, a6
  rori \t0, \t0, 28
  xor  \s0, \s0, \t0
  rori \t0, \s0, 16
  and  \t0, \t0, a7
  rori \t0, \t0, 2
  xor  \s0, \s0, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.mixcolumns \s0, \s0, 1
#endif
.endm

.macro SKINNY_MIXCOL2 s0, t0
#if   (ROMULUS_RV32_TYPE1)
  rori \t0, \s0, 8
  and  \t0, \t0, t6
  rori \t0, \t0, 6
  xor  \s0, \s0, \t0
  rori \t0, \s0, 16
  and  \t0, \t0, t5
  rori \t0, \t0, 28
  xor  \s0, \s0, \t0
  rori \t0, \s0, 24
  and  \t0, \t0, t6
  rori \t0, \t0, 2
  xor  \s0, \s0, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.mixcolumns \s0, \s0, 2
#endif
.endm

.macro SKINNY_MIXCOL3 s0, t0
#if   (ROMULUS_RV32_TYPE1)
  and  \t0, \s0, a6
  rori \t0, \t0, 30
  xor  \s0, \s0, \t0
  and  \t0, \s0, a7
  rori \t0, \t0, 4
  xor  \s0, \s0, \t0
  and  \t0, \s0, a6
  rori \t0, \t0, 26
  xor  \s0, \s0, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.mixcolumns \s0, \s0, 3
#endif
.endm

.macro SKINNY_MIXCOL s0, s1, s2, s3, t0, idx
  SKINNY_MIXCOL\idx \s0, \t0
  SKINNY_MIXCOL\idx \s1, \t0
  SKINNY_MIXCOL\idx \s2, \t0
  SKINNY_MIXCOL\idx \s3, \t0
.endm

// the quadruple-round routine

#if   (ROMULUS_RV32_TYPE1)
// swapmove 

.macro SKINNY_SPMV s0, s1, m0, imm, t0
  srli \t0, \s0, \imm
  xor  \t0, \t0, \s1
  and  \t0, \t0, \m0
  xor  \s1, \s1, \t0
  slli \t0, \t0, \imm
  xor  \s0, \s0, \t0
.endm 

// swapmove32

.macro SKINNY_SPMV32 s0, m0, imm, t0, t1
  srli \t0, \s0, \imm
  xor  \t0, \s0, \t0
  and  \t0, \t0, \m0
  slli \t1, \t0, \imm
  xor  \t0, \t0, \t1
  xor  \s0, \t0, \s0
.endm
#endif

// swap-only

.macro SKINNY_SWAP s0, s1, m0, t0
  xor  \t0, \s0, \s1
  and  \t0, \t0, \m0
  xor  \s1, \s1, \t0
  xor  \s0, \s0, \t0
.endm 


// SBox

.macro SKINNY_SBOX s0, s1, s2, s3, t0 
  or          \t0, \s0, \s1
  xnor        \s3, \s3, \t0
#if   (ROMULUS_RV32_TYPE1)
  SKINNY_SPMV \s2, \s1,  a1, 1, \t0
  SKINNY_SPMV \s3, \s2,  a1, 1, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.swapmove.x \t0, \s2, \s1, 0    // t0 <- s2
  romulus.swapmove.y \s1, \s2, \s1, 0    // s1 <- s1
  romulus.swapmove.y \s2, \s3, \t0, 0    // s2 <- s2 
  romulus.swapmove.x \s3, \s3, \t0, 0    // s3 <- s3
#endif 
  or          \t0, \s2, \s3
  xnor        \s1, \s1, \t0
#if   (ROMULUS_RV32_TYPE1)
  SKINNY_SPMV \s1, \s0,  a1, 1, \t0
  SKINNY_SPMV \s0, \s3,  a1, 1, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.swapmove.y \t0, \s1, \s0, 0    // t0 <- s0
  romulus.swapmove.x \s1, \s1, \s0, 0    // s1 <- s1
  romulus.swapmove.x \s0, \t0, \s3, 0    // s0 <- s0
  romulus.swapmove.y \s3, \t0, \s3, 0    // s3 <- s3 
#endif  
  or          \t0, \s0, \s1
  xnor        \s3, \s3, \t0
#if   (ROMULUS_RV32_TYPE1)
  SKINNY_SPMV \s2, \s1,  a1, 1, \t0
  SKINNY_SPMV \s3, \s2,  a1, 1, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.swapmove.x \t0, \s2, \s1, 0    // t0 <- s2
  romulus.swapmove.y \s1, \s2, \s1, 0    // s1 <- s1
  romulus.swapmove.y \s2, \s3, \t0, 0    // s2 <- s2 
  romulus.swapmove.x \s3, \s3, \t0, 0    // s3 <- s3
#endif 
  or          \t0, \s2, \s3
  xor         \s1, \s1, \t0
  SKINNY_SWAP \s3, \s0,  a1,    \t0
.endm


// add tweak keys

.macro SKINNY_RTK1 s0, s1, s2, s3, kaddr, imm, k1
  lw   \k1, \imm   (\kaddr)
  xor  \s0, \s0, \k1
  lw   \k1, \imm+4 (\kaddr)
  xor  \s1, \s1, \k1
  lw   \k1, \imm+8 (\kaddr)
  xor  \s2, \s2, \k1
  lw   \k1, \imm+12(\kaddr)
  xor  \s3, \s3, \k1       
.endm 

.macro SKINNY_RTK23 s0, s1, s2, s3, kaddr, imm, k23
  lw   \k23, \imm   (\kaddr)
  xor  \s0,  \s0, \k23
  lw   \k23, \imm+4 (\kaddr)
  xor  \s1,  \s1, \k23
  lw   \k23, \imm+8 (\kaddr)
  xor  \s2,  \s2, \k23
  lw   \k23, \imm+12(\kaddr)
  xor  \s3,  \s3, \k23    
.endm 

// quadruple-round 

.macro SKINNY_QUADROUND s0, s1, s2, s3, addr1, addr23, t0
  // round 0
  SKINNY_SBOX    \s0, \s1, \s2, \s3, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,   0, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23,  0, \t0
  SKINNY_MIXCOL  \s0, \s1, \s2, \s3, \t0, 0
  
  // round 1
  SKINNY_SBOX    \s2, \s3, \s0, \s1, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,  16, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23, 16, \t0
  SKINNY_MIXCOL  \s0, \s1, \s2, \s3, \t0, 1

  // round 2
  SKINNY_SBOX    \s0, \s1, \s2, \s3, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,  32, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23, 32, \t0
  SKINNY_MIXCOL  \s0, \s1, \s2, \s3, \t0, 2  

  // round 3
  SKINNY_SBOX    \s2, \s3, \s0, \s1, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,  48, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23, 48, \t0
  SKINNY_MIXCOL  \s0, \s1, \s2, \s3, \t0, 3
.endm


// packing and unpacking

.macro SKINNY_PACKING addr, s0, s1, s2, s3, t0, t1, m0, m1, m2, m3
  lw   \s0,  0(\addr)
  lw   \s1,  8(\addr)
  lw   \s2,  4(\addr)
  lw   \s3, 12(\addr)
#if   (ROMULUS_RV32_TYPE1)

  SKINNY_SPMV32 \s0, \m0, 3, \t0, \t1
  SKINNY_SPMV32 \s1, \m0, 3, \t0, \t1
  SKINNY_SPMV32 \s2, \m0, 3, \t0, \t1
  SKINNY_SPMV32 \s3, \m0, 3, \t0, \t1
  SKINNY_SPMV   \s2, \s0, \m1, 2, \t0
  SKINNY_SPMV   \s1, \s0, \m2, 4, \t0
  SKINNY_SPMV   \s3, \s0, \m3, 6, \t0
  SKINNY_SPMV   \s1, \s2, \m2, 2, \t0
  SKINNY_SPMV   \s3, \s2, \m3, 4, \t0
  SKINNY_SPMV   \s3, \s1, \m3, 2, \t0
#elif (ROMULUS_RV32_TYPE3)

  romulus.swapmove.x \s0, \s0, \s0, 7
  romulus.swapmove.x \s1, \s1, \s1, 7
  romulus.swapmove.x \s2, \s2, \s2, 7
  romulus.swapmove.x \s3, \s3, \s3, 7
  romulus.swapmove.y \t0, \s2, \s0, 1    // t0 <- s0
  romulus.swapmove.x \s2, \s2, \s0, 1    // s2 <- s2
  romulus.swapmove.y \t1, \s1, \t0, 2    // t1 <- s0
  romulus.swapmove.x \s1, \s1, \t0, 2    // s1 <- s1
  romulus.swapmove.y \s0, \s3, \t1, 3    // s0 <- s0
  romulus.swapmove.x \s3, \s3, \t1, 3    // s3 <- s3
  romulus.swapmove.y \t0, \s1, \s2, 4    // t0 <- s2
  romulus.swapmove.x \t1, \s1, \s2, 4    // t1 <- s1
  romulus.swapmove.y \s2, \s3, \t0, 5    // s2 <- s2
  romulus.swapmove.x \s3, \s3, \t0, 5    // s3 <- s3
  romulus.swapmove.y \s1, \s3, \t1, 6    // s1 <- s1
  romulus.swapmove.x \s3, \s3, \t1, 6    // s3 <- s3
#endif 
.endm

.macro SKINNY_UNPACKING addr, s0, s1, s2, s3, t0, t1, m0, m1, m2, m3
#if   (ROMULUS_RV32_TYPE1)

  SKINNY_SPMV   \s3, \s1, \m3, 2, \t0
  SKINNY_SPMV   \s3, \s2, \m3, 4, \t0
  SKINNY_SPMV   \s1, \s2, \m2, 2, \t0
  SKINNY_SPMV   \s3, \s0, \m3, 6, \t0
  SKINNY_SPMV   \s1, \s0, \m2, 4, \t0
  SKINNY_SPMV   \s2, \s0, \m1, 2, \t0
  SKINNY_SPMV32 \s0, \m0, 3, \t0, \t1
  SKINNY_SPMV32 \s1, \m0, 3, \t0, \t1
  SKINNY_SPMV32 \s2, \m0, 3, \t0, \t1
  SKINNY_SPMV32 \s3, \m0, 3, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)

  romulus.swapmove.y \t0, \s3, \s1, 6    // t0 <- s1
  romulus.swapmove.x \s3, \s3, \s1, 6    // s3 <- s3
  romulus.swapmove.y \t1, \s3, \s2, 5    // t1 <- s2
  romulus.swapmove.x \s3, \s3, \s2, 5    // s3 <- s3
  romulus.swapmove.y \s2, \t0, \t1, 4    // s2 <- s2
  romulus.swapmove.x \s1, \t0, \t1, 4    // s1 <- s1
  romulus.swapmove.y \t0, \s3, \s0, 3    // t0 <- s0
  romulus.swapmove.x \s3, \s3, \s0, 3    // s3 <- s3
  romulus.swapmove.y \t1, \s1, \t0, 2    // t1 <- s0
  romulus.swapmove.x \s1, \s1, \t0, 2    // s1 <- s1
  romulus.swapmove.y \s0, \s2, \t1, 1    // s0 <- s0
  romulus.swapmove.x \s2, \s2, \t1, 1    // s2 <- s2
  romulus.swapmove.x \s0, \s0, \s0, 7
  romulus.swapmove.x \s1, \s1, \s1, 7
  romulus.swapmove.x \s2, \s2, \s2, 7
  romulus.swapmove.x \s3, \s3, \s3, 7
#endif
  sw   \s0,  0(\addr)
  sw   \s1,  8(\addr)
  sw   \s2,  4(\addr)
  sw   \s3, 12(\addr)  
.endm


.section .text
  
.global skinny128_384_plus

skinny128_384_plus:
  SKINNY_PROLOGUE
#if   (ROMULUS_RV32_TYPE1) 
  li a5, 0x0a0a0a0a
  li a6, 0x03030303
  li a7, 0x30303030
  li t5, 0x0c0c0c0c
  li t6, 0xc0c0c0c0
#endif
  SKINNY_PACKING   a1, t0, t1, t2, t3, t4, a4, a5, a7, t5, a6
  li a1, 0x55555555
  //
  SKINNY_QUADROUND t0, t1, t2, t3, a2, a3, t4
  addi a4, a2, 64
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  addi a4, a2, 128
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  addi a4, a2, 192
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a2, a3, t4
  addi a4, a2, 64
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  addi a4, a2, 128
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  addi a4, a2, 192
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a2, a3, t4
  addi a4, a2, 64
  addi a3, a3, 64
  SKINNY_QUADROUND t0, t1, t2, t3, a4, a3, t4
  //
  SKINNY_UNPACKING a0, t0, t1, t2, t3, t4, a4, a5, a7, t5, a6
  SKINNY_EPILOGUE
  

// ----------------------------------------------------------------------------
// Key Precomputation Functions
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro RKEY_PROLOGUE
#if   (ROMULUS_RV32_TYPE1)
  addi sp, sp, -48
  sw   s2,   8(sp)
  sw   s3,  12(sp)
  sw   s4,  16(sp)
  sw   s5,  20(sp)
  sw   s6,  24(sp)
  sw   s7,  28(sp)
  sw   s8,  32(sp)
  sw   s9,  36(sp)
  sw   s10, 40(sp)
  sw   s11, 44(sp)
#elif  (ROMULUS_RV32_TYPE3)
  addi sp, sp, -8
#endif
  sw   s0,   0(sp)
  sw   s1,   4(sp)
.endm

.macro RKEY_EPILOGUE
  lw   s0,   0(sp)
  lw   s1,   4(sp)
#if   (ROMULUS_RV32_TYPE1)
  lw   s2,   8(sp)
  lw   s3,  12(sp)
  lw   s4,  16(sp)
  lw   s5,  20(sp)
  lw   s6,  24(sp)
  lw   s7,  28(sp)
  lw   s8,  32(sp)
  lw   s9,  36(sp)
  lw   s10, 40(sp)
  lw   s11, 44(sp)
  addi sp, sp, 48
#elif  (ROMULUS_RV32_TYPE3)
  addi sp, sp, 8
#endif  
  ret 
.endm


// load + store rkey

.macro SKINNY_LDRKEY addr, imm, k0, k1, k2, k3
  lw   \k0, \imm   (\addr)
  lw   \k1, \imm+4 (\addr)
  lw   \k2, \imm+8 (\addr)
  lw   \k3, \imm+12(\addr)
.endm 

.macro SKINNY_STRKEY addr, imm, k0, k1, k2, k3
  sw   \k0, \imm   (\addr)
  sw   \k1, \imm+4 (\addr)
  sw   \k2, \imm+8 (\addr)
  sw   \k3, \imm+12(\addr)
.endm 


// tk permutation 

.macro SKINNY_PERMTK2 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 14
  and  \t0, \t1, s6   // t0 = t1 & 0xcc00cc00
  andi \t1, \k0, 0xff // t1 = k0 & 0x000000ff
  slli \t1, \t1, 16
  or   \t0, \t0, \t1
  and  \t1, \k0, s2   // t1 = k0 & 0xcc000000
  srli \t1, \t1, 2
  or   \t0, \t0, \t1
  and  \t1, \k0, s3   // t1 = k0 & 0x0033cc00
  srli \t1, \t1, 8
  or   \t0, \t0, \t1
  and  \t1, \k0, s4   // t1 = k0 & 0x00cc0000
  srli \t1, \t1, 18
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 0 
#endif
.endm

.macro SKINNY_PERMTK4 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 22
  and  \t0, \t1, s7   // t0 = t1 & 0xcc0000cc
  rori \t1, \k0, 16  
  and  \t1, \t1, s8   // t1 = t1 & 0x3300cc00
  or   \t0, \t0, \t1
  rori \t1, \k0, 24
  and  \t1, \t1, s9   // t1 = t1 & 0x00cc3300
  or   \t0, \t0, \t1
  and  \t1, \k0, s5   // t1 = k0 & 0x00cc00cc
  srli \t1, \t1, 2
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 1 
#endif
.endm

.macro SKINNY_PERMTK6 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 6
  and  \t0, \t1, s10  // t0 = t1 & 0xcccc0000
  rori \t1, \k0, 24
  and  \t1, \t1, s11  // t1 = t1 & 0x330000cc
  or   \t0, \t0, \t1
  rori \t1, \k0, 10
  li a1, 0x00003333
  and  \t1, \t1, a1   // t1 = t1 & 0x00003333
  or   \t0, \t0, \t1
  andi \t1, \k0, 0xcc // t1 = k0 & 0x000000cc
  slli \t1, \t1, 14
  or   \t0, \t0, \t1
  li a1, 0x00003300
  and  \t1, \k0, a1   // t1 = k0 & 0x00003300
  slli \t1, \t1, 2
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 2 
#endif
.endm

.macro SKINNY_PERMTK8 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 24
  li a1, 0xcc000033
  and  \t0, \t1, a1   // t0 = t1 & 0xcc000033
  rori \t1, \k0, 8
  li a1, 0x33cc0000
  and  \t1, \t1, a1   // t1 = t1 & 0x33cc0000
  or   \t0, \t0, \t1 
  rori \t1, \k0, 26
  li a1, 0x00333300
  and  \t1, \t1, a1   // t1 = t1 & 0x00333300
  or   \t0, \t0, \t1
  and  \t1, \k0, a1   // t1 = k0 & 0x00333300
  srli \t1, \t1, 6
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 3
#endif
.endm

.macro SKINNY_PERMTK10 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 8
  li a1, 0xcc330000
  and  \t0, \t1, a1   // t0 = t1 & 0xcc330000
  rori \t1, \k0, 26
  li a1, 0x33000033
  and  \t1, \t1, a1   // t1 = t1 & 0x33000033
  or   \t0, \t0, \t1
  rori \t1, \k0, 22
  li a1, 0x00cccc00   
  and  \t1, \t1, a1   // t1 = t1 & 0x00cccc00
  or   \t0, \t0, \t1
  li a1, 0x00330000
  and  \t1, \k0, a1   // t1 = k0 & 0x00330000 
  srli \t1, \t1, 14
  or   \t0, \t0, \t1
  li a1, 0x0000cc00 
  and  \t1, \k0, a1   // t1 = k0 & 0x0000cc00
  srli \t1, \t1, 2
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 4
#endif       
.endm

.macro SKINNY_PERMTK12 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 8
  li a1, 0x0000cc33
  and  \t0, \t1, a1   // t0 = t1 & 0x0000cc33
  rori \t1, \k0, 30
  and  \t1, \t1, s5   // t1 = t1 & 0x00cc00cc
  or   \t0, \t0, \t1
  rori \t1, \k0, 10
  li a1, 0x33330000
  and  \t1, \t1, a1   // t1 = t1 & 0x33330000
  or   \t0, \t0, \t1
  rori \t1, \k0, 16
  li a1, 0xcc003300
  and  \t1, \t1, a1   // t1 = t1 & 0xcc003300
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 5
#endif  
.endm

.macro SKINNY_PERMTK14 r0, k0, t0, t1
#if   (ROMULUS_RV32_TYPE1)
  rori \t1, \k0, 24
  and  \t0, \t1, s3   // t0 = t1 & 0x0033cc00
  rori \t1, \k0, 14
  and  \t1, \t1, s4   // t1 = t1 & 0x00cc0000
  or   \t0, \t0, \t1
  rori \t1, \k0, 30
  and  \t1, \t1, s2   // t1 = t1 & 0xcc000000
  or   \t0, \t0, \t1
  rori \t1, \k0, 16
  andi \t1, \t1, 0xff // t1 = t1 & 0x000000ff
  or   \t0, \t0, \t1   
  rori \t1, \k0, 18
  li a1, 0x33003300
  and  \t1, \t1, a1   // t1 = t1 & 0x33003300
  or   \r0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.permtk \r0, \k0, 6
#endif
.endm

.macro SKINNY_PERMTK r0, r1, r2, r3, k0, k1, k2, k3, t0, t1, num
  SKINNY_PERMTK\num \r0, \k0, \t0, \t1
  SKINNY_PERMTK\num \r1, \k1, \t0, \t1
  SKINNY_PERMTK\num \r2, \k2, \t0, \t1
  SKINNY_PERMTK\num \r3, \k3, \t0, \t1
.endm


// a single round of the main loop of tk permutation 

.macro SKINNY_TKUPD0_STEP addr, imm0, r0, imm1, m0, t0, idx
#if   (ROMULUS_RV32_TYPE1)
  rori \t0, \r0, \imm1
  and  \t0, \t0, \m0
#elif (ROMULUS_RV32_TYPE3)
  romulus.tkupd.0 \t0, \r0, \idx
#endif
  sw   \t0, \imm0(\addr)
.endm

.macro SKINNY_TKUPD0 addr, imm0, r0, r1, r2, r3, imm1, m0, t0, idx
  SKINNY_TKUPD0_STEP \addr, \imm0,    \r0, \imm1, \m0, \t0, \idx
  SKINNY_TKUPD0_STEP \addr, \imm0+4,  \r1, \imm1, \m0, \t0, \idx
  SKINNY_TKUPD0_STEP \addr, \imm0+8,  \r2, \imm1, \m0, \t0, \idx
  SKINNY_TKUPD0_STEP \addr, \imm0+12, \r3, \imm1, \m0, \t0, \idx
.endm

.macro SKINNY_TKUPD1_STEP addr, imm0, r0, imm1, imm2, m0, m1, t0, t1, idx
#if   (ROMULUS_RV32_TYPE1)
  rori \t0, \r0, \imm1
  and  \t0, \t0, \m0
  rori \t1, \r0, \imm2
  and  \t1, \t1, \m1
  or   \t0, \t0, \t1
#elif (ROMULUS_RV32_TYPE3)
  romulus.tkupd.1 \t0, \r0, \idx
#endif
  sw   \t0, \imm0(\addr)
.endm

.macro SKINNY_TKUPD1 addr, imm0, r0, r1, r2, r3, imm1, imm2, m0, m1, t0, t1, idx
  SKINNY_TKUPD1_STEP \addr, \imm0,    \r0, \imm1, \imm2, \m0, \m1, \t0, \t1, \idx
  SKINNY_TKUPD1_STEP \addr, \imm0+4,  \r1, \imm1, \imm2, \m0, \m1, \t0, \t1, \idx
  SKINNY_TKUPD1_STEP \addr, \imm0+8,  \r2, \imm1, \imm2, \m0, \m1, \t0, \t1, \idx
  SKINNY_TKUPD1_STEP \addr, \imm0+12, \r3, \imm1, \imm2, \m0, \m1, \t0, \t1, \idx
.endm 

.macro SKINNY_PERMTK1_ROUND_EVN addr, k0, k1, k2, k3, r0, r1, r2, r3, t0, t1
  and  \r0, \k0, t4
  and  \r1, \k1, t4
  and  \r2, \k2, t4
  and  \r3, \k3, t4
  SKINNY_STRKEY  \addr,   0, \r2, \r3, \r0, \r1

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,   2
  SKINNY_TKUPD0  \addr,  16, \r0, \r1, \r2, \r3,  26,  t6, \t0,   0
  SKINNY_TKUPD1  \addr,  32, \r2, \r3, \r0, \r1,  28,  12,  a6,  t5, \t0, \t1, 0

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,   4
  SKINNY_TKUPD1  \addr,  48, \r0, \r1, \r2, \r3,  14,   6,  a7,  t5, \t0, \t1, 1
  SKINNY_TKUPD0  \addr,  64, \r2, \r3, \r0, \r1,  16,  t4, \t0,   1

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,   6
  SKINNY_TKUPD0  \addr,  80, \r0, \r1, \r2, \r3,  10,  t6, \t0,   2
  SKINNY_TKUPD1  \addr,  96, \r2, \r3, \r0, \r1,  12,  28,  a6,  t5, \t0, \t1, 2

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,   8
  SKINNY_TKUPD1  \addr, 112, \r0, \r1, \r2, \r3,  30,  22,  a7,  t5, \t0, \t1, 3
.endm

.macro SKINNY_PERMTK1_ROUND_ODD addr, k0, k1, k2, k3, r0, r1, r2, r3, t0, t1
  and  \r0, \r0, t4
  and  \r1, \r1, t4
  and  \r2, \r2, t4
  and  \r3, \r3, t4
  SKINNY_STRKEY  \addr,   0, \r2, \r3, \r0, \r1

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,  10
  SKINNY_TKUPD0  \addr,  16, \r0, \r1, \r2, \r3,  26,  t6, \t0,   0
  SKINNY_TKUPD1  \addr,  32, \r2, \r3, \r0, \r1,  28,  12,  a6,  t5, \t0, \t1, 0

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,  12
  SKINNY_TKUPD1  \addr,  48, \r0, \r1, \r2, \r3,  14,   6,  a7,  t5, \t0, \t1, 1
  SKINNY_TKUPD0  \addr,  64, \r2, \r3, \r0, \r1,  16,  t4, \t0,   1

  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \k0, \k1, \k2, \k3, \t0, \t1,  14
  SKINNY_TKUPD0  \addr,  80, \r0, \r1, \r2, \r3,  10,  t6, \t0,   2
  SKINNY_TKUPD1  \addr,  96, \r2, \r3, \r0, \r1,  12,  28,  a6,  t5, \t0, \t1, 2

  SKINNY_TKUPD1  \addr, 112, \k0, \k1, \k2, \k3,  30,  22,  a7,  t5, \t0, \t1, 3
.endm


// ----------------------------------------------------------------------------
// Register Allocation
// (use caller-saved registers to save push/pop instructions)  
//
// a0-a1:         the address of rtk1 and tk1, resp.
// a2-a5:         tk
// t0-t3:         rk
// s0-s1:         temp registers
// t4-t6, a6-a7:  masks 
// s2-s11:        masks in PermTK
// ----------------------------------------------------------------------------


.section .text
  
.global precompute_rtk1

precompute_rtk1:
  RKEY_PROLOGUE
#if   (ROMULUS_RV32_TYPE1)
  li t4,  0x0a0a0a0a
  li t5,  0x0c0c0c0c
  li t6,  0xc3c3c3c3
  li a6,  0x03030303
  li a7,  0x30303030
#endif 
  SKINNY_PACKING a1, a2, a3, a4, a5, s0, s1, t4, a7, t5, a6
  //
  li t4,  0xf0f0f0f0
#if   (ROMULUS_RV32_TYPE1)
  li s2,  0xcc000000   // a fixed mask used in PermTK2 and PermTK14
  li s3,  0x0033cc00   // a fixed mask used in PermTK2 and PermTK14
  li s4,  0x00cc0000   // a fixed mask used in PermTK2 and PermTK14
  li s5,  0x00cc00cc   // a fixed mask used in PermTK4 and PermTK12
  // 
  li s6,  0xcc00cc00   // a fixed mask used in PermTK2
  li s7,  0xcc0000cc   // a fixed mask used in PermTK4
  li s8,  0x3300cc00   // a fixed mask used in PermTK4
  li s9,  0x00cc3300   // a fixed mask used in PermTK4
  li s10, 0xcccc0000   // a fixed mask used in PermTK6
  li s11, 0x330000cc   // a fixed mask used in PermTK6
  // For the remaining masks, we use register a1 to serve as a temp mask.
#endif 
  //
  SKINNY_PERMTK1_ROUND_EVN  a0, a2, a3, a4, a5, t0, t1, t2, t3, s0, s1
  addi a0, a0, 128
  SKINNY_PERMTK1_ROUND_ODD  a0, a2, a3, a4, a5, t0, t1, t2, t3, s0, s1
  //
  RKEY_EPILOGUE


// ----------------------------------------------------------------------------
// Register Allocation
// (use caller-saved registers to save push/pop instructions)  
//
// a0-a2:         the address of rtk, tk2, and tk3, resp.
// a2-a5:         tk2 
// t0-t3:         tk3 (rk after lfsr)
// s0-s1:         temp registers 
// t4-t6, a6-a7:  masks
// s2-s11:        masks in PermTK
// a2:            the address of LUT (after lfsr)
// ----------------------------------------------------------------------------

// lfsr2: k0, k1, k2, k3 -> k1, k2, k3, k0

.macro SKINNY_LFSR2 k0, k1, k2, k3, t0, m0
#if   (ROMULUS_RV32_TYPE1)
  and  \t0, \k2, \m0
  xor  \t0, \t0, \k0
  and  \k0, \t0, \m0
  srli \k0, \k0, 1
  slli \t0, \t0, 1
  and  \t0, \t0, \m0
  or   \k0, \k0, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.lfsr2 \k0, \k0, \k2
#endif
.endm

// lfsr3: k0, k1, k2, k3 -> k3, k0, k1, k2

.macro SKINNY_LFSR3 k0, k1, k2, k3, t0, m0
#if   (ROMULUS_RV32_TYPE1) 
  and  \t0, \k1, \m0
  srli \t0, \t0, 1
  xor  \t0, \t0, \k3
  and  \k3, \t0, \m0
  srli \k3, \k3, 1
  slli \t0, \t0, 1
  and  \t0, \t0, \m0
  or   \k3, \k3, \t0
#elif (ROMULUS_RV32_TYPE3)
  romulus.lfsr3 \k3, \k3, \k1
#endif
.endm

.macro SKINNY_XORSW addr, imm, k20, k21, k22, k23, k30, k31, k32, k33, t0
  xor  \t0, \k20, \k30
  sw   \t0, \imm   (\addr)
  xor  \t0, \k21, \k31
  sw   \t0, \imm+4 (\addr)
  xor  \t0, \k22, \k32
  sw   \t0, \imm+8 (\addr)
  xor  \t0, \k23, \k33
  sw   \t0, \imm+12(\addr) 
.endm

.macro SKINNY_LFSR_TK23_STEP addr, imm, k20, k21, k22, k23, k30, k31, k32, k33, t0, m0
  SKINNY_LFSR2 \k20,  \k21, \k22, \k23, \t0, \m0
  SKINNY_LFSR3 \k30,  \k31, \k32, \k33, \t0, \m0
  SKINNY_XORSW \addr, \imm, \k21, \k22, \k23, \k20, \k33, \k30, \k31, \k32, \t0
.endm

.macro SKINNY_LFSR_TK23 addr, k20, k21, k22, k23, k30, k31, k32, k33, t0, m0
  SKINNY_XORSW          \addr,   0,    \k20, \k21, \k22, \k23, \k30, \k31, \k32, \k33, \t0
  .set imm, 16
  .rept 5
  SKINNY_LFSR_TK23_STEP \addr, imm,    \k20, \k21, \k22, \k23, \k30, \k31, \k32, \k33, \t0, \m0
  SKINNY_LFSR_TK23_STEP \addr, imm+32, \k21, \k22, \k23, \k20, \k33, \k30, \k31, \k32, \t0, \m0
  SKINNY_LFSR_TK23_STEP \addr, imm+64, \k22, \k23, \k20, \k21, \k32, \k33, \k30, \k31, \t0, \m0
  SKINNY_LFSR_TK23_STEP \addr, imm+96, \k23, \k20, \k21, \k22, \k31, \k32, \k33, \k30, \t0, \m0
  .set imm, imm + 128
  .endr
.endm

.macro SKINNY_PERMTK23_ROUND_EVN addr, r0, r1, r2, r3, t0, t1
  and  \r0, \r0, t4
  and  \r1, \r1, t4
  and  \r2, \r2, t4
  and  \r3, \r3, t4
  SKINNY_STRKEY  \addr,   0, \r2, \r3, \r0, \r1

  SKINNY_LDRKEY  \addr,  16, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,   2
  SKINNY_TKUPD0  \addr,  16, \r0, \r1, \r2, \r3,  26,  t6, \t0,   0
  SKINNY_TKUPD1  \addr,  32, \r2, \r3, \r0, \r1,  28,  12,  a6,  t5, \t0, \t1, 0

  SKINNY_LDRKEY  \addr,  48, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,   4
  SKINNY_TKUPD1  \addr,  48, \r0, \r1, \r2, \r3,  14,   6,  a7,  t5, \t0, \t1, 1
  SKINNY_TKUPD0  \addr,  64, \r2, \r3, \r0, \r1,  16,  t4, \t0,   1

  SKINNY_LDRKEY  \addr,  80, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,   6
  SKINNY_TKUPD0  \addr,  80, \r0, \r1, \r2, \r3,  10,  t6, \t0,   2
  SKINNY_TKUPD1  \addr,  96, \r2, \r3, \r0, \r1,  12,  28,  a6,  t5, \t0, \t1, 2

  SKINNY_LDRKEY  \addr, 112, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,   8
  SKINNY_TKUPD1  \addr, 112, \r0, \r1, \r2, \r3,  30,  22,  a7,  t5, \t0, \t1, 3
.endm

.macro SKINNY_PERMTK23_ROUND_ODD addr, r0, r1, r2, r3, t0, t1
  and  \r0, \r0, t4
  and  \r1, \r1, t4
  and  \r2, \r2, t4
  and  \r3, \r3, t4
  SKINNY_STRKEY  \addr,   0, \r2, \r3, \r0, \r1

  SKINNY_LDRKEY  \addr,  16, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,  10
  SKINNY_TKUPD0  \addr,  16, \r0, \r1, \r2, \r3,  26,  t6, \t0,   0
  SKINNY_TKUPD1  \addr,  32, \r2, \r3, \r0, \r1,  28,  12,  a6,  t5, \t0, \t1, 0

  SKINNY_LDRKEY  \addr,  48, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,  12
  SKINNY_TKUPD1  \addr,  48, \r0, \r1, \r2, \r3,  14,   6,  a7,  t5, \t0, \t1, 1
  SKINNY_TKUPD0  \addr,  64, \r2, \r3, \r0, \r1,  16,  t4, \t0,   1

  SKINNY_LDRKEY  \addr,  80, \r0, \r1, \r2, \r3
  SKINNY_PERMTK    \r0, \r1, \r2, \r3, \r0, \r1, \r2, \r3, \t0, \t1,  14
  SKINNY_TKUPD0  \addr,  80, \r0, \r1, \r2, \r3,  10,  t6, \t0,   2
  SKINNY_TKUPD1  \addr,  96, \r2, \r3, \r0, \r1,  12,  28,  a6,  t5, \t0, \t1, 2

  SKINNY_LDRKEY  \addr, 112, \r0, \r1, \r2, \r3
  SKINNY_TKUPD1  \addr, 112, \r0, \r1, \r2, \r3,  30,  22,  a7,  t5, \t0, \t1, 3
.endm


.macro SKINNY_ADDRC kaddr, caddr, r0, rc
  .set imm, 0
  .rept 160
  lw   \r0, imm(\kaddr)
  lw   \rc, imm(\caddr)
  xor  \r0, \r0, \rc
  sw   \r0, imm(\kaddr)
  .set imm, imm + 4
  .endr 
.endm


.section .text
  
.global precompute_rtk2_3

precompute_rtk2_3:
  RKEY_PROLOGUE
#if   (ROMULUS_RV32_TYPE1)
  li t4,  0x0a0a0a0a
  li t5,  0x0c0c0c0c
  li t6,  0xc3c3c3c3
  li a6,  0x03030303
  li a7,  0x30303030
#endif
  SKINNY_PACKING a2, t0, t1, t2, t3, s0, s1, t4, a7, t5, a6
  SKINNY_PACKING a1, a2, a3, a4, a5, s0, s1, t4, a7, t5, a6
  //
#if   (ROMULUS_RV32_TYPE1)
  li t4,  0xaaaaaaaa
#endif
  SKINNY_LFSR_TK23 a0, a2, a3, a4, a5, t0, t1, t2, t3, s0, t4
  //
  li t4,  0xf0f0f0f0
#if   (ROMULUS_RV32_TYPE1)
  li s2,  0xcc000000   // a fixed mask used in PermTK2 and PermTK14
  li s3,  0x0033cc00   // a fixed mask used in PermTK2 and PermTK14
  li s4,  0x00cc0000   // a fixed mask used in PermTK2 and PermTK14
  li s5,  0x00cc00cc   // a fixed mask used in PermTK4 and PermTK12
  // Other masks are not repeated, so we prioritize masks used in PermTK2/4/6/8.
  li s6,  0xcc00cc00   // a fixed mask used in PermTK2
  li s7,  0xcc0000cc   // a fixed mask used in PermTK4
  li s8,  0x3300cc00   // a fixed mask used in PermTK4
  li s9,  0x00cc3300   // a fixed mask used in PermTK4
  li s10, 0xcccc0000   // a fixed mask used in PermTK6
  li s11, 0x330000cc   // a fixed mask used in PermTK6
  // For the remaining masks, we use regster a1 to serve as a temp mask.
#endif
  // 
  SKINNY_LDRKEY    a0,  0, t0, t1, t2, t3
  la a2, RCONST32
  SKINNY_PERMTK23_ROUND_EVN  a0, t0, t1, t2, t3, s0, s1
  addi a0, a0, 128
  SKINNY_PERMTK23_ROUND_ODD  a0, t0, t1, t2, t3, s0, s1
  addi a0, a0, 128
  SKINNY_PERMTK23_ROUND_EVN  a0, t0, t1, t2, t3, s0, s1
  addi a0, a0, 128  
  SKINNY_PERMTK23_ROUND_ODD  a0, t0, t1, t2, t3, s0, s1
  addi a0, a0, 128
  SKINNY_PERMTK23_ROUND_EVN  a0, t0, t1, t2, t3, s0, s1
  // SKINNY_ADDRC can be integrated into ROUND to save some instructions
  la a2, RCONST32
  addi a0, a0, -512
  SKINNY_ADDRC a0, a2, t0, t1
  //
  RKEY_EPILOGUE

.section .data

.align 2

RCONST32:
.word 0x00000004, 0xffffffbf, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x10000100, 0xfffffeff, 0x44000000, 0xfbffffff, 0x00000000, 0x04000000
.word 0x00100000, 0x00100000, 0x00100001, 0xffefffff, 0x00440000, 0xffafffff
.word 0x00400000, 0x00400000, 0x01000000, 0x01000000, 0x01401000, 0xffbfffff
.word 0x01004000, 0xfefffbff, 0x00000400, 0x00000400, 0x00000010, 0x00000000
.word 0x00010410, 0xfffffbef, 0x00000054, 0xffffffaf, 0x00000000, 0x00000040
.word 0x00000100, 0x00000100, 0x10000140, 0xfffffeff, 0x44000000, 0xfffffeff
.word 0x04000000, 0x04000000, 0x00100000, 0x00100000, 0x04000001, 0xfbffffff
.word 0x00140000, 0xffafffff, 0x00400000, 0x00000000, 0x00000000, 0x00000000
.word 0x01401000, 0xfebfffff, 0x01004400, 0xfffffbff, 0x00000000, 0x00000400
.word 0x00000010, 0x00000010, 0x00010010, 0xffffffff, 0x00000004, 0xffffffaf
.word 0x00000040, 0x00000040, 0x00000100, 0x00000000, 0x10000140, 0xffffffbf
.word 0x40000100, 0xfbfffeff, 0x00000000, 0x04000000, 0x00100000, 0x00000000
.word 0x04100001, 0xffefffff, 0x00440000, 0xffefffff, 0x00000000, 0x00400000
.word 0x01000000, 0x01000000, 0x00401000, 0xffffffff, 0x00004000, 0xfeffffff 
.word 0x00000400, 0x00000000, 0x00000000, 0x00000000, 0x00010400, 0xfffffbff
.word 0x00000014, 0xffffffbf, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x10000100, 0xffffffff, 0x40000000, 0xfbffffff, 0x00000000, 0x04000000
.word 0x00100000, 0x00000000, 0x00100001, 0xffefffff, 0x00440000, 0xffafffff
.word 0x00000000, 0x00400000, 0x01000000, 0x01000000, 0x01401000, 0xffffffff
.word 0x00004000, 0xfeffffff, 0x00000400, 0x00000400, 0x00000010, 0x00000000
.word 0x00010400, 0xfffffbff, 0x00000014, 0xffffffaf, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x10000140, 0xfffffeff, 0x44000000, 0xffffffff
.word 0x00000000, 0x04000000, 0x00100000, 0x00100000, 0x00000001, 0xffefffff
.word 0x00440000, 0xffafffff, 0x00400000, 0x00000000, 0x00000000, 0x01000000
.word 0x01401000, 0xffbfffff, 0x01004000, 0xfffffbff, 0x00000400, 0x00000400
.word 0x00000010, 0x00000000, 0x00010010, 0xfffffbff
