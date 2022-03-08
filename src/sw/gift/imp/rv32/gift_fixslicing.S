#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a3~a6: cipher state
// t0, t1: tmp registers
// t2~t6, s0~s5: masks
// ----------------------------------------------------------------------------


// prologue + epilogue 

.macro GIFT_PROLOGUE
  addi sp, sp, -24
  sw   s0,  0(sp)
  sw   s1,  4(sp)
  sw   s2,  8(sp)
  sw   s3, 12(sp)
  sw   s4, 16(sp)
  sw   s5, 20(sp)
.endm

.macro GIFT_EPILOGUE
  lw   s0,  0(sp)
  lw   s1,  4(sp)
  lw   s2,  8(sp)
  lw   s3, 12(sp)
  lw   s4, 16(sp)
  lw   s5, 20(sp)
  addi sp, sp, 24 
  ret
.endm


// load state + store state 

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


// SBox

.macro GIFT_SBOX s0, s1, s2, s3, t0
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

// swapmove32

.macro GIFT_SPMV s0, m0, imm, t0, t1
# # if (GIFT_RV32_TYPE2)
#   gift.swapmove \s0, \m0, \imm
# #else
  srli \t0, \s0, \imm
  xor  \t0, \s0, \t0
  and  \t0, \t0, \m0
  slli \t1, \t0, \imm
  xor  \t0, \t0, \t1
  xor  \s0, \t0, \s0
# #endif 
.endm


// nibble-wise rotation to the right

.macro GIFT_NROR s0, m0, m1, imm0, imm1, t0
#if (GIFT_RV32_TYPE2)
  gift.rori.n \s0, \s0, \imm0
#else 
  srli \t0, \s0, \imm0
  and  \t0, \t0, \m0
  and  \s0, \s0, \m1
  slli \s0, \s0, \imm1
  or   \s0, \s0, \t0
#endif 
.endm

// nibble-wise rotation to the right

.macro GIFT_BROR s0, m0, m1, imm0, imm1, t0
#if (GIFT_RV32_TYPE2)
  gift.rori.b \s0, \s0, \imm0
#else 
  srli \t0, \s0, \imm0
  and  \t0, \t0, \m0
  and  \s0, \s0, \m1
  slli \s0, \s0, \imm1
  or   \s0, \s0, \t0
#endif 
.endm

// half-word-wise rotation to the right

.macro GIFT_HROR s0, m0, m1, imm0, imm1, t0
#if (GIFT_RV32_TYPE2)
  gift.rori.h \s0, \s0, \imm0
#else 
  srli \t0, \s0, \imm0
  and  \t0, \t0, \m0
  and  \s0, \s0, \m1
  slli \s0, \s0, \imm1
  or   \s0, \s0, \t0
#endif 
.endm

// byte3, byte2, byte1, byte0 -> byte2, byte3, byte0, byte1

.macro GIFT_REV16 s0
  rev8 \s0, \s0           // s0 = byte0, byte1, byte2, byte3
  rori \s0, \s0, 16       // s0 = byte2, byte3, byte0, byte1
.endm

// the 1st round in a quintuple-round routine

.macro GIFT_ROUND0 s0, s1, s2, s3, rci, t0
  GIFT_SBOX \s0, \s1, \s2, \s3, \t0
  GIFT_NROR \s3, t4, t2, 1, 3, \t0
  GIFT_NROR \s1, t3, t3, 2, 2, \t0
  GIFT_NROR \s2, t2, t4, 3, 1, \t0
  lw        \t0, 0(a1)
  xor       \s1, \s1, \t0
  lw        \t0, 4(a1)
  xor       \s2, \s2, \t0  
  li        \t0, \rci
  xor       \s0, \s0, \t0
.endm

// the 2nd round in a quintuple-round routine

.macro GIFT_ROUND1 s0, s1, s2, s3, rci, t0
  GIFT_SBOX \s0, \s1, \s2, \s3, \t0
  GIFT_HROR \s3, t5, t6,  4, 12, \t0
#if (GIFT_RV32_TYPE2) 
  GIFT_HROR \s1, t5, t6,  8,  8, \t0
#else 
  GIFT_REV16 \s1
#endif  
  GIFT_HROR \s2, t6, t5, 12,  4, \t0
  lw        \t0,  8(a1)
  xor       \s1, \s1, \t0
  lw        \t0, 12(a1)
  xor       \s2, \s2, \t0  
  li        \t0, \rci
  xor       \s0, \s0, \t0
.endm

// the 3rd round in a quintuple-round routine

.macro GIFT_ROUND2 s0, s1, s2, s3, rci, t0, t1
  GIFT_SBOX \s0, \s1, \s2, \s3, \t0
  rori      \s3, \s3, 16
  rori      \s2, \s2, 16
  GIFT_SPMV \s1, s0, 1, \t0, \t1
  GIFT_SPMV \s2, s1, 1, \t0, \t1
  GIFT_SPMV \s3, s2, 1, \t0, \t1
  lw        \t0, 16(a1)
  xor       \s1, \s1, \t0
  lw        \t0, 20(a1)
  xor       \s2, \s2, \t0  
  li        \t0, \rci
  xor       \s0, \s0, \t0
.endm

// the 4th round in a quintuple-round routine

.macro GIFT_ROUND3 s0, s1, s2, s3, rci, t0
  GIFT_SBOX \s0, \s1, \s2, \s3, \t0 
  GIFT_BROR \s3, s3, s5, 6, 2, \t0
  GIFT_BROR \s1, s4, s4, 4, 4, \t0
  GIFT_BROR \s2, s5, s3, 2, 6, \t0
  lw        \t0, 24(a1)
  xor       \s1, \s1, \t0
  lw        \t0, 28(a1)
  xor       \s2, \s2, \t0  
  li        \t0, \rci
  xor       \s0, \s0, \t0  
.endm

// the 5th round in a quintuple-round routine

.macro GIFT_ROUND4 s0, s1, s2, s3, rci, t0
  GIFT_SBOX \s0, \s1, \s2, \s3, \t0
  rori      \s3, \s3, 24
  rori      \s1, \s1, 16
  rori      \s2, \s2,  8
  lw        \t0, 32(a1)
  xor       \s1, \s1, \t0
  lw        \t0, 36(a1)
  xor       \s2, \s2, \t0  
  li        \t0, \rci
  xor       \s0, \s0, \t0    
.endm


// GIFT-128

.section .text

.global giftb128_fixslicing

giftb128_fixslicing:
  GIFT_PROLOGUE
  GIFT_LDSTATE  a0, a3, a4, a5, a6
  GIFT_REVERSE  a3, a4, a5, a6
  //
  li t2, 0x11111111
  li t3, 0x33333333
  li t4, 0x77777777
  li t5, 0x0fff0fff
  li t6, 0x000f000f
  li s0, 0x55555555
  li s1, 0x00005555
  li s2, 0x55550000
  li s3, 0x03030303
  li s4, 0x0f0f0f0f
  li s5, 0x3f3f3f3f
  //
  GIFT_ROUND0   a3, a4, a5, a6, 0x10000008, t1
  GIFT_ROUND1   a6, a4, a5, a3, 0x80018000, t1
  GIFT_ROUND2   a3, a4, a5, a6, 0x54000002, t1, t0
  GIFT_ROUND3   a6, a4, a5, a3, 0x01010181, t1
  GIFT_ROUND4   a3, a4, a5, a6, 0x8000001f, t1
  addi a1, a1, 40

  GIFT_ROUND0   a6, a4, a5, a3, 0x10888880, t1 
  GIFT_ROUND1   a3, a4, a5, a6, 0x6001e000, t1
  GIFT_ROUND2   a6, a4, a5, a3, 0x51500002, t1, t0 
  GIFT_ROUND3   a3, a4, a5, a6, 0x03030180, t1
  GIFT_ROUND4   a6, a4, a5, a3, 0x8000002f, t1
  addi a1, a1, 40

  GIFT_ROUND0   a3, a4, a5, a6, 0x10088880, t1
  GIFT_ROUND1   a6, a4, a5, a3, 0x60016000, t1
  GIFT_ROUND2   a3, a4, a5, a6, 0x41500002, t1, t0
  GIFT_ROUND3   a6, a4, a5, a3, 0x03030080, t1
  GIFT_ROUND4   a3, a4, a5, a6, 0x80000027, t1
  addi a1, a1, 40

  GIFT_ROUND0   a6, a4, a5, a3, 0x10008880, t1 
  GIFT_ROUND1   a3, a4, a5, a6, 0x4001e000, t1
  GIFT_ROUND2   a6, a4, a5, a3, 0x11500002, t1, t0 
  GIFT_ROUND3   a3, a4, a5, a6, 0x03020180, t1
  GIFT_ROUND4   a6, a4, a5, a3, 0x8000002b, t1
  addi a1, a1, 40

  GIFT_ROUND0   a3, a4, a5, a6, 0x10080880, t1
  GIFT_ROUND1   a6, a4, a5, a3, 0x60014000, t1
  GIFT_ROUND2   a3, a4, a5, a6, 0x01400002, t1, t0
  GIFT_ROUND3   a6, a4, a5, a3, 0x02020080, t1
  GIFT_ROUND4   a3, a4, a5, a6, 0x80000021, t1
  addi a1, a1, 40

  GIFT_ROUND0   a6, a4, a5, a3, 0x10000080, t1 
  GIFT_ROUND1   a3, a4, a5, a6, 0x0001c000, t1
  GIFT_ROUND2   a6, a4, a5, a3, 0x51000002, t1, t0 
  GIFT_ROUND3   a3, a4, a5, a6, 0x03010180, t1
  GIFT_ROUND4   a6, a4, a5, a3, 0x8000002e, t1
  addi a1, a1, 40

  GIFT_ROUND0   a3, a4, a5, a6, 0x10088800, t1
  GIFT_ROUND1   a6, a4, a5, a3, 0x60012000, t1
  GIFT_ROUND2   a3, a4, a5, a6, 0x40500002, t1, t0
  GIFT_ROUND3   a6, a4, a5, a3, 0x01030080, t1
  GIFT_ROUND4   a3, a4, a5, a6, 0x80000006, t1 
  addi a1, a1, 40

  GIFT_ROUND0   a6, a4, a5, a3, 0x10008808, t1 
  GIFT_ROUND1   a3, a4, a5, a6, 0xc001a000, t1
  GIFT_ROUND2   a6, a4, a5, a3, 0x14500002, t1, t0 
  GIFT_ROUND3   a3, a4, a5, a6, 0x01020181, t1
  GIFT_ROUND4   a6, a4, a5, a3, 0x8000001a, t1

  //
  GIFT_REVERSE  a3, a4, a5, a6
  GIFT_STSTATE  a2, a3, a4, a5, a6
  GIFT_EPILOGUE 


// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a3~a6: cipher state
// t5, t6: tmp registers
// t0~t4, s0~s3: masks
// ----------------------------------------------------------------------------

.macro RKEY_PROLOGUE
  addi sp, sp, -8
  sw   s0,  0(sp)
  sw   s1,  4(sp)
.endm

.macro RKEY_EPILOGUE
  lw   s0,  0(sp)
  lw   s1,  4(sp)
  addi sp, sp, 8
  ret
.endm

.macro GIFT_KUPD k1, k0, t0, t1
#if (GIFT_RV32_TYPE2)
  gift.key.updstd \k0, \k0
#else
  srli \t0, \k0, 12
  and  \t0, \t0, t0

  and  \t1, \k0, t1
  slli \t1, \t1, 4
  or   \t0, \t0, \t1
  
  srli \t1, \k0, 2
  and  \t1, \t1, t2
  or   \t0, \t0, \t1

  and  \k0, \k0, t3
  slli \k0, \k0, 14
  or   \k0, \k0, \t0
#endif

  sw   \k1, 0(a0)
  sw   \k0, 4(a0)
  addi a0, a0, 8
.endm

.macro GIFT_KARR0 k0, t0, t1
#if (GIFT_RV32_TYPE2)
  gift.key.reorg \k0, \k0, 0
#else
  GIFT_SPMV \k0, t0,  9, \t0, \t1
  GIFT_SPMV \k0, t1, 12, \t0, \t1
  GIFT_SPMV \k0, t2, 18, \t0, \t1
  GIFT_SPMV \k0, t3, 24, \t0, \t1
#endif
.endm

.macro GIFT_KARR1 k0, t0, t1
#if (GIFT_RV32_TYPE2)
  gift.key.reorg \k0, \k0, 1
#else
  GIFT_SPMV \k0, t0,  3, \t0, \t1
  GIFT_SPMV \k0, t1,  6, \t0, \t1
  GIFT_SPMV \k0, t2, 12, \t0, \t1
  GIFT_SPMV \k0, t3, 24, \t0, \t1
#endif
.endm

.macro GIFT_KARR2 k0, t0, t1
#if (GIFT_RV32_TYPE2)
  gift.key.reorg \k0, \k0, 2
#else
  GIFT_SPMV \k0, t0, 15, \t0, \t1
  GIFT_SPMV \k0, t1, 18, \t0, \t1
  GIFT_SPMV \k0, t2, 12, \t0, \t1
  GIFT_SPMV \k0, t3, 24, \t0, \t1
#endif
.endm

.macro GIFT_KARR3 k0, t0, t1
#if (GIFT_RV32_TYPE2)
  gift.key.reorg \k0, \k0, 3
#else
  GIFT_SPMV \k0, t0,  3, \t0, \t1
  GIFT_SPMV \k0, t1,  6, \t0, \t1
  GIFT_SPMV \k0, t2, 12, \t0, \t1
  GIFT_SPMV \k0, t3, 24, \t0, \t1
#endif
.endm

.macro GIFT_KTPL0 k0, m0, m1, t0
  and  \t0, \k0, \m0
  and  \k0, \k0, \m1
  rori \t0, \t0, 24
  rori \k0, \k0, 16
  or   \k0, \k0, \t0
.endm

.macro GIFT_KDBL1 k0, m0, m1, m2, t0, t1, imm
# #if (GIFT_RV32_TYPE2)
#   gift.key.updfix \k0, \k0, 2
# #else
  srli \t0, \k0, 4
  and  \t0, \t0, \m0
  and  \t1, \k0, \m0
  slli \t1, \t1, 4
  or   \t0, \t0, \t1
  srli \t1, \k0, 6
  and  \t1, \t1, \m1
  or   \t0, \t0, \t1
  and  \t1, \k0, \m2
  slli \t1, \t1, 2
  or   \k0, \t0, \t1
# # endif
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KTPL1 k0, m0, m1, m2, m3, t0, t1, imm
  srli \t0, \k0, 6
  and  \t0, \t0, \m0
  and  \t1, \k0, \m1
  slli \t1, \t1, 2
  or   \t0, \t0, \t1
  srli \t1, \k0, 5
  and  \t1, \t1, \m2
  or   \t0, \t0, \t1
  and  \t1, \k0, \m3
  slli \t1, \t1, 3
  or   \k0, \t0, \t1
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KDBL2 k0, m0, m1, t0, imm
# #if (GIFT_RV32_TYPE2)
#   gift.key.updfix \k0, \k0, 4
# #else
  and  \t0, \k0, \m0
  and  \k0, \k0, \m1
  rori \t0, \t0, 24
  rori \k0, \k0, 16
  or   \k0, \k0, \t0
# # endif
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KTPL2 k0, m0, m1, t0, imm
  and  \t0, \k0, \m0
  and  \k0, \k0, \m1
  rori \t0, \t0, 24
  rori \k0, \k0, 20
  or   \k0, \k0, \t0
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KDBL3 k0, m0, m1, m2, t0, t1, imm
  srli \t0, \k0, 2
  and  \t0, \t0, \m0
  and  \t1, \k0, \m0
  slli \t1, \t1, 2
  or   \t0, \t0, \t1
  srli \t1, \k0, 1
  and  \t1, \t1, \m1
  or   \t0, \t0, \t1
  and  \t1, \k0, \m2
  slli \t1, \t1, 3
  or   \k0, \t0, \t1
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KTPL3 k0, m0, m1, m2, m3, m4, m5, t0, t1, imm
  srli \t0, \k0, 18
  and  \t0, \t0, \m0
  and  \t1, \k0, \m1
  slli \t1, \t1, 3
  or   \t0, \t0, \t1  
  srli \t1, \k0, 14
  and  \t1, \t1, \m2
  or   \t0, \t0, \t1
  and  \t1, \k0, \m3
  slli \t1, \t1, 15
  or   \t0, \t0, \t1  
  srli \t1, \k0, 1
  and  \t1, \t1, \m4
  or   \t0, \t0, \t1
  and  \t1, \k0, \m5
  slli \t1, \t1, 19
  or   \k0, \t0, \t1
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KDBL4 k0, m0, m1, m2, t0, t1, imm
  srli \t0, \k0, 4
  and  \t0, \t0, \m0
  and  \t1, \k0, \m1
  slli \t1, \t1, 12
  or   \t0, \t0, \t1
  srli \t1, \k0, 8
  and  \t1, \t1, \m2
  or   \t0, \t0, \t1
  and  \t1, \k0, \m2
  slli \t1, \t1, 8
  or   \k0, \t0, \t1
  sw   \k0, \imm(a0)
.endm

.macro GIFT_KTPL4 k0, m0, m1, m2, m3, t0, t1, imm
  srli \t0, \k0, 6
  and  \t0, \t0, \m0
  and  \t1, \k0, \m1
  slli \t1, \t1, 10
  or   \t0, \t0, \t1
  srli \t1, \k0, 4
  and  \t1, \t1, \m2
  or   \t0, \t0, \t1
  and  \t1, \k0, \m3
  slli \t1, \t1, 12
  or   \k0, \t0, \t1 
  sw   \k0, \imm(a0) 
.endm


// key pre-computation

.section .text

.global precompute_rkeys

precompute_rkeys:
  RKEY_PROLOGUE
  // classical initialization
  GIFT_LDSTATE  a1, a4, a5, a6, a7
  GIFT_REVERSE  a4, a5, a6, a7
  GIFT_STSTATE  a0, a7, a5, a6, a4
  addi  a0, a0, 16
  // classical keyschedule
  li   t0, 0x0000000F
  li   t1, 0x00000FFF
  li   t2, 0x3FFF0000
  li   t3, 0x00030000
  GIFT_KUPD  a5, a7, t5, t6    
  GIFT_KUPD  a4, a6, t5, t6
  GIFT_KUPD  a7, a5, t5, t6
  GIFT_KUPD  a6, a4, t5, t6
  GIFT_KUPD  a5, a7, t5, t6
  GIFT_KUPD  a4, a6, t5, t6
  GIFT_KUPD  a7, a5, t5, t6
  GIFT_KUPD  a6, a4, t5, t6
  addi a0, a0, -80
  // 1st for-loop
  li   t0, 0x00550055
  li   t1, 0x000f000f
  li   t2, 0x00003333
  li   t3, 0x000000ff
  lw   a4,  0(a0)
  lw   a5,  4(a0)
  GIFT_KARR0 a4, t5, t6
  GIFT_KARR0 a5, t5, t6
  sw   a4,  0(a0)
  sw   a5,  4(a0)
  lw   a4, 40(a0)
  lw   a5, 44(a0)
  GIFT_KARR0 a4, t5, t6
  GIFT_KARR0 a5, t5, t6
  sw   a4, 40(a0)
  sw   a5, 44(a0)

  li   t0, 0x11111111
  li   t1, 0x03030303
  li   t2, 0x000f000f
  # li   t3, 0x000000ff 
  lw   a4,  8(a0)
  lw   a5, 12(a0)
  GIFT_KARR1 a4, t5, t6
  GIFT_KARR1 a5, t5, t6
  sw   a4,  8(a0)
  sw   a5, 12(a0)
  lw   a4, 48(a0)
  lw   a5, 52(a0)
  GIFT_KARR1 a4, t5, t6
  GIFT_KARR1 a5, t5, t6
  sw   a4, 48(a0)
  sw   a5, 52(a0)
  
  li   t0, 0x0000aaaa
  li   t1, 0x00003333
  li   t2, 0x0000f0f0
  # li   t3, 0x000000ff
  lw   a4, 16(a0)
  lw   a5, 20(a0)
  GIFT_KARR2 a4, t5, t6
  GIFT_KARR2 a5, t5, t6
  sw   a4, 16(a0)
  sw   a5, 20(a0)
  lw   a4, 56(a0)
  lw   a5, 60(a0)
  GIFT_KARR2 a4, t5, t6
  GIFT_KARR2 a5, t5, t6
  sw   a4, 56(a0)
  sw   a5, 60(a0)

  li   t0, 0x0a0a0a0a
  li   t1, 0x00cc00cc
  # li   t2, 0x0000f0f0
  # li   t3, 0x000000ff
  lw   a4, 24(a0)
  lw   a5, 28(a0)
  GIFT_KARR3 a4, t5, t6
  GIFT_KARR3 a5, t5, t6
  sw   a4, 24(a0)
  sw   a5, 28(a0)
  lw   a4, 64(a0)
  lw   a5, 68(a0)
  GIFT_KARR3 a4, t5, t6
  GIFT_KARR3 a5, t5, t6
  sw   a4, 64(a0)
  sw   a5, 68(a0)
  // 2nd for-loop
  li   t0, 0x00003333
  li   t1, 0x55554444
  li   t2, 0x55551100
  li   t3, 0x33333333
  li   t4, 0xcccccccc
  lw   a4, 0(a0)
  lw   a5, 4(a0)
# #if (GIFT_RV32_TYPE2)  
#   gift.key.updfix a5, a5, 0
#   gift.key.updfix a4, a4, 1
# #else  
  GIFT_SPMV  a5, t0, 16, t5, t6
  GIFT_SPMV  a5, t1,  1, t5, t6
  GIFT_KTPL0 a4, t3, t4, t5
  GIFT_SPMV  a4, t2,  1, t5, t6
# #endif
  sw   a5, 80(a0)
  sw   a4, 84(a0)
# #if (GIFT_RV32_TYPE2)  
#   gift.key.updfix a4, a4, 0
#   gift.key.updfix a5, a5, 1
# #else 
  GIFT_SPMV  a4, t0, 16, t5, t6
  GIFT_SPMV  a4, t1,  1, t5, t6
  GIFT_KTPL0 a5, t3, t4, t5
  GIFT_SPMV  a5, t2,  1, t5, t6
# #endif
  sw   a4, 160(a0)
  sw   a5, 164(a0)
# #if (GIFT_RV32_TYPE2)  
#   gift.key.updfix a5, a5, 0
#   gift.key.updfix a4, a4, 1
# #else  
  GIFT_SPMV  a5, t0, 16, t5, t6
  GIFT_SPMV  a5, t1,  1, t5, t6
  GIFT_KTPL0 a4, t3, t4, t5
  GIFT_SPMV  a4, t2,  1, t5, t6
# #endif  
  sw   a5, 240(a0)
  sw   a4, 244(a0)
  lw   a4, 40(a0)
  lw   a5, 44(a0)
  GIFT_SPMV  a5, t0, 16, t5, t6
  GIFT_SPMV  a5, t1,  1, t5, t6
  GIFT_KTPL0 a4, t3, t4, t5
  GIFT_SPMV  a4, t2,  1, t5, t6
  sw   a5, 120(a0)
  sw   a4, 124(a0)
  GIFT_SPMV  a4, t0, 16, t5, t6
  GIFT_SPMV  a4, t1,  1, t5, t6
  GIFT_KTPL0 a5, t3, t4, t5
  GIFT_SPMV  a5, t2,  1, t5, t6
  sw   a4, 200(a0)
  sw   a5, 204(a0)
  GIFT_SPMV  a5, t0, 16, t5, t6
  GIFT_SPMV  a5, t1,  1, t5, t6
  GIFT_KTPL0 a4, t3, t4, t5
  GIFT_SPMV  a4, t2,  1, t5, t6
  sw   a5, 280(a0)
  sw   a4, 284(a0)

  li   t0, 0x0f000f00
  li   t1, 0x00030003
  li   t2, 0x003f003f
  li   s0, 0x03000300
  li   s1, 0x3f003f00
  li   a7, 0x00070007
  li   a3, 0x001f001f
  lw   a4,  8(a0)
  lw   a5, 12(a0)
  GIFT_KTPL1 a4, s0, s1, a7, a3, t5, t6, 92
  GIFT_KDBL1 a5, t0, t1, t2,     t5, t6, 88
  GIFT_KTPL1 a5, s0, s1, a7, a3, t5, t6, 172
  GIFT_KDBL1 a4, t0, t1, t2,     t5, t6, 168
  GIFT_KTPL1 a4, s0, s1, a7, a3, t5, t6, 252
  GIFT_KDBL1 a5, t0, t1, t2,     t5, t6, 248
  lw   a4, 48(a0)
  lw   a5, 52(a0)
  GIFT_KTPL1 a4, s0, s1, a7, a3, t5, t6, 132
  GIFT_KDBL1 a5, t0, t1, t2,     t5, t6, 128
  GIFT_KTPL1 a5, s0, s1, a7, a3, t5, t6, 212
  GIFT_KDBL1 a4, t0, t1, t2,     t5, t6, 208
  GIFT_KTPL1 a4, s0, s1, a7, a3, t5, t6, 292
  GIFT_KDBL1 a5, t0, t1, t2,     t5, t6, 288

  li   t0, 0xaaaaaaaa
  li   t1, 0x55555555
  lw   a4, 16(a0)
  lw   a5, 20(a0)
  GIFT_KTPL2 a4, t1, t0, t5, 100
  GIFT_KDBL2 a5, t0, t1, t5, 96
  GIFT_KTPL2 a5, t1, t0, t5, 180
  GIFT_KDBL2 a4, t0, t1, t5, 176
  GIFT_KTPL2 a4, t1, t0, t5, 260
  GIFT_KDBL2 a5, t0, t1, t5, 256
  lw   a4, 56(a0)
  lw   a5, 60(a0)
  GIFT_KTPL2 a4, t1, t0, t5, 140
  GIFT_KDBL2 a5, t0, t1, t5, 136
  GIFT_KTPL2 a5, t1, t0, t5, 220
  GIFT_KDBL2 a4, t0, t1, t5, 216
  GIFT_KTPL2 a4, t1, t0, t5, 300
  GIFT_KDBL2 a5, t0, t1, t5, 296

  li   t0, 0x03030303
  li   t1, 0x70707070
  li   t2, 0x10101010
  li   s0, 0x00003030
  li   s1, 0x01010101
  li   a7, 0x0000c0c0
  li   a3, 0x0000e0e0
  li   t3, 0x07070707
  li   t4, 0x00001010
  lw   a4, 24(a0)
  lw   a5, 28(a0)
  GIFT_KTPL3 a4, s0, s1, a7, a3, t3, t4, t5, t6, 108
  GIFT_KDBL3 a5, t0, t1, t2,             t5, t6, 104
  GIFT_KTPL3 a5, s0, s1, a7, a3, t3, t4, t5, t6, 188
  GIFT_KDBL3 a4, t0, t1, t2,             t5, t6, 184
  GIFT_KTPL3 a4, s0, s1, a7, a3, t3, t4, t5, t6, 268
  GIFT_KDBL3 a5, t0, t1, t2,             t5, t6, 264
  lw   a4, 64(a0)
  lw   a5, 68(a0)
  GIFT_KTPL3 a4, s0, s1, a7, a3, t3, t4, t5, t6, 148
  GIFT_KDBL3 a5, t0, t1, t2,             t5, t6, 144
  GIFT_KTPL3 a5, s0, s1, a7, a3, t3, t4, t5, t6, 228
  GIFT_KDBL3 a4, t0, t1, t2,             t5, t6, 224
  GIFT_KTPL3 a4, s0, s1, a7, a3, t3, t4, t5, t6, 308
  GIFT_KDBL3 a5, t0, t1, t2,             t5, t6, 304

  li    t0, 0x0fff0000
  li    t1, 0x000f0000
  li    t2, 0x000000ff
  li    s0, 0x03ff0000
  li    s1, 0x003f0000
  li    a7, 0x00000fff
  li    a3, 0x0000000f
  lw   a4, 32(a0)
  lw   a5, 36(a0)
  GIFT_KTPL4 a4, s0, s1, a7, a3, t5, t6, 116
  GIFT_KDBL4 a5, t0, t1, t2,     t5, t6, 112
  GIFT_KTPL4 a5, s0, s1, a7, a3, t5, t6, 196
  GIFT_KDBL4 a4, t0, t1, t2,     t5, t6, 192
  GIFT_KTPL4 a4, s0, s1, a7, a3, t5, t6, 276
  GIFT_KDBL4 a5, t0, t1, t2,     t5, t6, 272
  lw   a4, 72(a0)
  lw   a5, 76(a0)
  GIFT_KTPL4 a4, s0, s1, a7, a3, t5, t6, 156
  GIFT_KDBL4 a5, t0, t1, t2,     t5, t6, 152
  GIFT_KTPL4 a5, s0, s1, a7, a3, t5, t6, 236
  GIFT_KDBL4 a4, t0, t1, t2,     t5, t6, 232
  GIFT_KTPL4 a4, s0, s1, a7, a3, t5, t6, 316
  GIFT_KDBL4 a5, t0, t1, t2,     t5, t6, 312
  //
  RKEY_EPILOGUE
