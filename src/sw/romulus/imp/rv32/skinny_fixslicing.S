#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
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


// the MixColumns computations 

.macro SKINNY_MIXCOL0_STEP s0, t0
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
.endm

.macro SKINNY_MIXCOL1_STEP s0, t0
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
.endm

.macro SKINNY_MIXCOL2_STEP s0, t0
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
.endm

.macro SKINNY_MIXCOL3_STEP s0, t0
  and  \t0, \s0, a6
  rori \t0, \t0, 30
  xor  \s0, \s0, \t0
  and  \t0, \s0, a7
  rori \t0, \t0, 4
  xor  \s0, \s0, \t0
  and  \t0, \s0, a6
  rori \t0, \t0, 26
  xor  \s0, \s0, \t0
.endm

.macro SKINNY_MIXCOL0 s0, s1, s2, s3, t0
  SKINNY_MIXCOL0_STEP \s0, \t0
  SKINNY_MIXCOL0_STEP \s1, \t0
  SKINNY_MIXCOL0_STEP \s2, \t0
  SKINNY_MIXCOL0_STEP \s3, \t0
.endm

.macro SKINNY_MIXCOL1 s0, s1, s2, s3, t0
  SKINNY_MIXCOL1_STEP \s0, \t0
  SKINNY_MIXCOL1_STEP \s1, \t0
  SKINNY_MIXCOL1_STEP \s2, \t0
  SKINNY_MIXCOL1_STEP \s3, \t0
.endm

.macro SKINNY_MIXCOL2 s0, s1, s2, s3, t0
  SKINNY_MIXCOL2_STEP \s0, \t0
  SKINNY_MIXCOL2_STEP \s1, \t0
  SKINNY_MIXCOL2_STEP \s2, \t0
  SKINNY_MIXCOL2_STEP \s3, \t0
.endm

.macro SKINNY_MIXCOL3 s0, s1, s2, s3, t0
  SKINNY_MIXCOL3_STEP \s0, \t0
  SKINNY_MIXCOL3_STEP \s1, \t0
  SKINNY_MIXCOL3_STEP \s2, \t0
  SKINNY_MIXCOL3_STEP \s3, \t0
.endm


// quadruple-round routine

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
  SKINNY_SPMV \s2, \s1,  a1, 1, \t0
  SKINNY_SPMV \s3, \s2,  a1, 1, \t0 
  or          \t0, \s2, \s3
  xnor        \s1, \s1, \t0
  SKINNY_SPMV \s1, \s0,  a1, 1, \t0
  SKINNY_SPMV \s0, \s3,  a1, 1, \t0 
  or          \t0, \s0, \s1
  xnor        \s3, \s3, \t0
  SKINNY_SPMV \s2, \s1,  a1, 1, \t0
  SKINNY_SPMV \s3, \s2,  a1, 1, \t0 
  or          \t0, \s2, \s3
  xor         \s1, \s1, \t0  
  SKINNY_SWAP \s3, \s0,  a1,    \t0 
.endm


// add keys

.macro SKINNY_RTK1 s0, s1, s2, s3, kaddr, imm, k1
  lw   \k1, \imm(\kaddr)
  xor  \s0, \s0, \k1
  lw   \k1, \imm+4(\kaddr)
  xor  \s1, \s1, \k1
  lw   \k1, \imm+8(\kaddr)
  xor  \s2, \s2, \k1
  lw   \k1, \imm+12(\kaddr)
  xor  \s3, \s3, \k1       
.endm 

.macro SKINNY_RTK23 s0, s1, s2, s3, kaddr, imm, k23
  lw   \k23, \imm(\kaddr)
  xor  \s0,  \s0, \k23
  lw   \k23, \imm+4(\kaddr)
  xor  \s1,  \s1, \k23
  lw   \k23, \imm+8(\kaddr)
  xor  \s2,  \s2, \k23
  lw   \k23, \imm+12(\kaddr)
  xor  \s3,  \s3, \k23    
.endm 

// the quadruple-round routine

.macro SKINNY_QUADROUND s0, s1, s2, s3, addr1, addr23, t0
  // round 0
  SKINNY_SBOX    \s0, \s1, \s2, \s3, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,   0, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23,  0, \t0
  SKINNY_MIXCOL0 \s0, \s1, \s2, \s3, \t0
  
  // round 1
  SKINNY_SBOX    \s2, \s3, \s0, \s1, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,  16, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23, 16, \t0
  SKINNY_MIXCOL1 \s0, \s1, \s2, \s3, \t0

  // round 2
  SKINNY_SBOX    \s0, \s1, \s2, \s3, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,  32, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23, 32, \t0
  SKINNY_MIXCOL2 \s0, \s1, \s2, \s3, \t0  

  // round 3
  SKINNY_SBOX    \s2, \s3, \s0, \s1, \t0
  SKINNY_RTK1    \s0, \s1, \s2, \s3, \addr1,  48, \t0
  SKINNY_RTK23   \s0, \s1, \s2, \s3, \addr23, 48, \t0
  SKINNY_MIXCOL3 \s0, \s1, \s2, \s3, \t0
.endm


// packing and unpacking

.macro SKINNY_PACKING addr, s0, s1, s2, s3, t0, t1
  lw   \s0,  0(\addr)
  lw   \s1,  8(\addr)
  lw   \s2,  4(\addr)
  lw   \s3, 12(\addr)
  SKINNY_SPMV32 \s0, a5, 3, \t0, \t1
  SKINNY_SPMV32 \s1, a5, 3, \t0, \t1
  SKINNY_SPMV32 \s2, a5, 3, \t0, \t1
  SKINNY_SPMV32 \s3, a5, 3, \t0, \t1
  SKINNY_SPMV   \s2, \s0, a7, 2, \t0
  SKINNY_SPMV   \s1, \s0, t5, 4, \t0
  SKINNY_SPMV   \s3, \s0, a6, 6, \t0
  SKINNY_SPMV   \s1, \s2, t5, 2, \t0
  SKINNY_SPMV   \s3, \s2, a6, 4, \t0
  SKINNY_SPMV   \s3, \s1, a6, 2, \t0
.endm

.macro SKINNY_UNPACKING addr, s0, s1, s2, s3, t0, t1
  SKINNY_SPMV   \s3, \s1, a6, 2, \t0
  SKINNY_SPMV   \s3, \s2, a6, 4, \t0
  SKINNY_SPMV   \s1, \s2, t5, 2, \t0
  SKINNY_SPMV   \s3, \s0, a6, 6, \t0
  SKINNY_SPMV   \s1, \s0, t5, 4, \t0
  SKINNY_SPMV   \s2, \s0, a7, 2, \t0
  SKINNY_SPMV32 \s0, a5, 3, \t0, \t1
  SKINNY_SPMV32 \s1, a5, 3, \t0, \t1
  SKINNY_SPMV32 \s2, a5, 3, \t0, \t1
  SKINNY_SPMV32 \s3, a5, 3, \t0, \t1
  sw   \s0,  0(\addr)
  sw   \s1,  8(\addr)
  sw   \s2,  4(\addr)
  sw   \s3, 12(\addr)  
.endm


.section .text
  
.global skinny128_384_plus

skinny128_384_plus:
  SKINNY_PROLOGUE 
  li a5, 0x0a0a0a0a
  li a6, 0x03030303
  li a7, 0x30303030
  li t5, 0x0c0c0c0c
  li t6, 0xc0c0c0c0
  SKINNY_PACKING   a1, t0, t1, t2, t3, t4, a4
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
  SKINNY_UNPACKING a0, t0, t1, t2, t3, t4, a4
  SKINNY_EPILOGUE
  