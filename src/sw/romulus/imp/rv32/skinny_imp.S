// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================	
	
#include "zbkb.h"
#include "zbkx.h"
#include  "ise.h"

// ----------------------------------------------------------------------------	
// register allocation

// a0  => uint8_t* m
// a1  => uint8_t* k
// a2  => i
// a3  => n
// a4  => rc
// a5  => 
// a6  => 
// a7  => 

// t0  => s_0
// t1  => s_1
// t2  => s_2
// t3  => s_3
// t4  => 
// t5  => 
// t6  =>

// s0  => tk1_0
// s1  => tk1_1
// s2  => tk1_2
// s3  => tk1_3
// s4  => tk2_0
// s5  => tk2_1
// s6  => tk2_2
// s7  => tk2_3
// s8  => tk3_0
// s9  => tk3_1
// s10 => tk3_2
// s11 => tk3_3

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => prologue

.macro SKINNY_PROLOGUE
                          addi                 sp,  sp, -48     // adjust SP
                          sw                   s0,        0(sp) // push s0
                          sw                   s1,        4(sp) // push s1
                          sw                   s2,        8(sp) // push s2
                          sw                   s3,       12(sp) // push s3
                          sw                   s4,       16(sp) // push s4
                          sw                   s5,       20(sp) // push s5
                          sw                   s6,       24(sp) // push s6
                          sw                   s7,       28(sp) // push s7
                          sw                   s8,       32(sp) // push s8
                          sw                   s9,       36(sp) // push s9
                          sw                   s10,      40(sp) // push s10
                          sw                   s11,      44(sp) // push s11

#if !( ROMULUS_UNROLL )
                          li                   a2,        0     // i     =  0
                          li                   a3,       40     // n     = 40
#endif
                          li                   a4,        0     // rc    =  0

                          lw                   t0,        0(a0) // s_0   = MEM[ a0 +  0 ]
                          lw                   t1,        4(a0) // s_1   = MEM[ a0 +  8 ]
                          lw                   t2,        8(a0) // s_2   = MEM[ a0 +  8 ]
                          lw                   t3,       12(a0) // s_3   = MEM[ a0 +  8 ]

                          lw                   s0,        0(a1) // tk1_0 = MEM[ a1 +  0 ]
                          lw                   s1,        4(a1) // tk1_1 = MEM[ a1 +  4 ]
                          lw                   s2,        8(a1) // tk1_2 = MEM[ a1 +  8 ]
                          lw                   s3,       12(a1) // tk1_3 = MEM[ a1 + 12 ]
                          lw                   s4,       16(a1) // tk2_0 = MEM[ a1 + 16 ]
                          lw                   s5,       20(a1) // tk2_1 = MEM[ a1 + 20 ]
                          lw                   s6,       24(a1) // tk2_2 = MEM[ a1 + 24 ]
                          lw                   s7,       28(a1) // tk2_3 = MEM[ a1 + 28 ]
                          lw                   s8,       32(a1) // tk3_0 = MEM[ a1 + 32 ]
                          lw                   s9,       36(a1) // tk3_1 = MEM[ a1 + 36 ]
                          lw                   s10,      40(a1) // tk3_2 = MEM[ a1 + 40 ]
                          lw                   s11,      44(a1) // tk3_3 = MEM[ a1 + 44 ]
.endm

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => epilogue

.macro SKINNY_EPILOGUE
                          sw                   t0,        0(a0) // MEM[ a0 +  0 ] = s_0
                          sw                   t1,        4(a0) // MEM[ a0 +  4 ] = s_1
                          sw                   t2,        8(a0) // MEM[ a0 +  8 ] = s_2
                          sw                   t3,       12(a0) // MEM[ a0 + 12 ] = s_3 

                          lw                   s0,        0(sp) // pop  s0
                          lw                   s1,        4(sp) // pop  s1
                          lw                   s2,        8(sp) // pop  s2
                          lw                   s3,       12(sp) // pop  s3
                          lw                   s4,       16(sp) // pop  s4
                          lw                   s5,       20(sp) // pop  s5
                          lw                   s6,       24(sp) // pop  s6
                          lw                   s7,       28(sp) // pop  s7
                          lw                   s8,       32(sp) // pop  s8
                          lw                   s9,       36(sp) // pop  s9
                          lw                   s10,      40(sp) // pop  s10
                          lw                   s11,      44(sp) // pop  s11
                          addi                 sp,  sp,  48     // adjust SP

                          ret                                   // return
.endm

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => round TYPE_1

#if  ( ROMULUS_RV32_TYPE1 )
// #error "can't use ROMULUS_RV32_TYPE1: not yet implemented!"

// SubCells

// The problem for TYPE1 to use the "xperm"-style 8-bit SBox: 
// Skinny-128 uses an 8-bit SBox, which means we have to use "xperm8" instruction 
// here. There are 2^8 = _256_ 8-bit entries/values in this LUT, and each 32-bit 
// register can only store 32/8 = 4 values, which means we need 256/4 = _64_ 
// 32-bit registers (impractical and inefficient). Additionally, an "xperm8" 
// needs to work together with "xor" and a mask, namely we need 2*64 = _128_ 
// instructions and _127_ registers for a LUT (64) + all the masks (63).    

// Solutions: conventional (non-"xperm"-style) LUT or bitslice. But in order to 
// serve as a baseline for our TYPE2, I suppose only the former option is possible. 

.macro SKINNY_SBOX s0, lut0, lut1, t0, t1
  romulus.rstep.enc \s0, \s0, x0, 0
.endm

.macro SKINNY_SC s0, s1, s2, s3, lut0, lut1, t0, t1
  SKINNY_SBOX \s0, \lut0, \lut1, \t0, \t1
  SKINNY_SBOX \s1, \lut0, \lut1, \t0, \t1
  SKINNY_SBOX \s2, \lut0, \lut1, \t0, \t1
  SKINNY_SBOX \s3, \lut0, \lut1, \t0, \t1
.endm

// AddConstants

.macro SKINNY_AC s0, s1, s2, rc0, rc1
  xori \s0, \s0, \rc0
  xori \s1, \s1, \rc1
  xori \s2, \s2, 0x02
.endm

// AddTweakKey

.macro SKINNY_ART s0, s1, k10, k11, k20, k21, k30, k31
  xor  \s0, \s0, \k10
  xor  \s0, \s0, \k20
  xor  \s0, \s0, \k30
  xor  \s1, \s1, \k11
  xor  \s1, \s1, \k21
  xor  \s1, \s1, \k31
.endm

// KeyUpdate 

// KeyPerm k0, k1, k2, k3 -> k2, k3, k0, k1

.macro SKINNY_KEYPERM k2, k3, t0, t1  

  rori  \t0, \k3, 16        // t0 = B13 B12 B15 B14
  packh \k3, \t0, \k3       // k3 =         B12 B14
  rev8  \t1, \k2            // t1 = B8  B9  B10 B11
  # pack  \k3, \k3, \t1       // k3 = B10 B11 B12 B14
  slli  \t1, \t1, 16 
  xor   \k3, \k3, \t1
  rev8  \t1, \k2
  # 
  rori  \k3, \k3, 24         // k3 = B11 B12 B14 B10

  and   \t0, \t0, a2        // t0 = B13     B15
  srli  \t1, \t1, 16        // t1 =         B8  B9
  # pack  \k2, \t1, \k2       // k2 = B9  B8  B8  B9
  slli  \k2, \k2, 16
  xor   \k2, \k2, \t1
  #
  and   \k2, \k2, a1        // k2 =     B8      B9
  xor   \k2, \k2, \t0       // k2 = B13 B8  B15 B9
.endm

.macro SKINNY_TK2LFSR k0, t0, t1
  srli \t0, \k0, 7
  srli \t1, \k0, 5
  xor  \t0, \t0, \t1
  and  \t0, \t0, a3
  slli \k0, \k0, 1
  not  \t1, a3
  and  \k0, \k0, \t1
  xor  \k0, \k0, \t0
.endm

.macro SKINNY_TK3LFSR k0, t0, t1
  slli \t0, \k0, 7
  slli \t1, \k0, 1
  xor  \t0, \t0, \t1
  and  \t0, \t0, a4
  not  \t1, a4
  srli \k0, \k0, 1
  and  \k0, \k0, \t1
  xor  \k0, \k0, \t0
.endm

.macro SKINNY_KU k12, k13, k22, k23, k32, k33, t0, t1
  SKINNY_KEYPERM \k12, \k13, \t0,  \t1
  SKINNY_KEYPERM \k22, \k23, \t0,  \t1
  SKINNY_KEYPERM \k32, \k33, \t0,  \t1
  SKINNY_TK2LFSR \k22, \t0,  \t1
  SKINNY_TK2LFSR \k23, \t0,  \t1
  SKINNY_TK3LFSR \k32, \t0,  \t1
  SKINNY_TK3LFSR \k33, \t0,  \t1
.endm

// ShiftRows

.macro SKINNY_SR s0, s1, s2, s3
  rori \s1, \s1, 24
  rori \s2, \s2, 16
  rori \s3, \s3, 8
.endm

// MixColumns s0, s1, s2, s3 -> s3, s0, s1, s2

.macro SKINNY_MC s0, s1, s2, s3
  xor  \s1, \s1, \s2
  xor  \s2, \s2, \s0
  xor  \s3, \s3, \s2  
.endm

.macro SKINNY_ROUND s0, s1, s2, s3, k10, k11, k12, k13, k20, k21, k22, k23, k30, k31, k32, k33, rc0, rc1, t0, t1
  SKINNY_SC  \s0, \s1, \s2, \s3, a5, a6, \t0, \t1
  SKINNY_AC  \s0, \s1, \s2, \rc0, \rc1
  SKINNY_ART \s0, \s1, \k10, \k11, \k20, \k21, \k30, \k31
  SKINNY_KU  \k12, \k13, \k22, \k23, \k32, \k33, \t0, \t1
  SKINNY_SR  \s0, \s1, \s2, \s3
  SKINNY_MC  \s0, \s1, \s2, \s3
.endm
#endif

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => round TYPE_2

#if  ( ROMULUS_RV32_TYPE2 )
.macro SKINNY_ROUND I
                          romulus.rc.upd.enc   a4,  a4          // rc    = romulus.rc.upd.enc( rc )

                          xor                  a5,  s0,  s4     // t_0   = tk1_0 ^ tk2_0
                          xor                  a5,  a5,  s8     // t_0   = tk1_0 ^ tk2_0 ^ tk3_0
                          xor                  a6,  s1,  s5     // t_1   = tk1_1 ^ tk2_1
                          xor                  a6,  a6,  s9     // t_1   = tk1_1 ^ tk2_1 ^ tk3_1

                          romulus.rc.use.enc.0 a5,  a4,  a5     // t_0   = romulus.rc.use.enc.0( rc, t_0 ) !
                          romulus.rc.use.enc.1 a6,  a4,  a6     // t_1   = romulus.rc.use.enc.0( rc, t_1 )

                          romulus.rstep.enc    t0,  t0,  a5,  0 // s_0   = romulus.rstep.enc( s_0, t_0, 0 )
                          romulus.rstep.enc    t1,  t1,  a6,  1 // s_0   = romulus.rstep.enc( s_1, t_1, 1 )
                          romulus.rstep.enc    t2,  t2,  x0,  2 // s_0   = romulus.rstep.enc( s_2,   2, 2 )
                          romulus.rstep.enc    t3,  t3,  x0,  3 // s_0   = romulus.rstep.enc( s_3,   0, 3 )

                          romulus.tk.upd.enc.1 a6,  s2,  s3,  1 // t_1   = romulus.tk.upd.enc.1( tk1_2, tk1_3, 1 )
                          romulus.tk.upd.enc.0 a5,  s2,  s3,  1 // t_0   = romulus.tk.upd.enc.0( tk1_2, tk1_3, 1 )
                          mv                   s3,  s1          // tk1_3 = tk1_1
                          mv                   s2,  s0          // tk1_2 = tk1_0
                          mv                   s1,  a6          // tk1_1 = t_1
                          mv                   s0,  a5          // tk1_0 = t_0

                          romulus.tk.upd.enc.1 a6,  s6,  s7,  2 // t_1   = romulus.tk.upd.enc.1( tk2_2, tk2_3, 2 )
                          romulus.tk.upd.enc.0 a5,  s6,  s7,  2 // t_0   = romulus.tk.upd.enc.0( tk2_2, tk2_3, 2 )
                          mv                   s7,  s5          // tk2_3 = tk2_1
                          mv                   s6,  s4          // tk2_2 = tk2_0
                          mv                   s5,  a6          // tk2_1 = t_1
                          mv                   s4,  a5          // tk2_0 = t_0

                          romulus.tk.upd.enc.1 a6,  s10, s11, 3 // t_1   = romulus.tk.upd.enc.1( tk3_2, tk3_3, 3 )
                          romulus.tk.upd.enc.0 a5,  s10, s11, 3 // t_0   = romulus.tk.upd.enc.0( tk3_2, tk3_3, 3 )
                          mv                   s11, s9          // tk3_3 = tk3_1
                          mv                   s10, s8          // tk3_2 = tk3_0
                          mv                   s9,  a6          // tk3_1 = t_1
                          mv                   s8,  a5          // tk3_0 = t_0

                          mv                   a5,  t0          // t_0  =       s_0;
                          xor                  a6,  t1, t2      // t_1  = s_1 ^ s_2;
                          xor                  a7,  t0, t2      // t_2  = s_0 ^ s_2;
	
                          xor                  t0,  a7, t3      // s_0  = t_2 ^ s_3 = s_0 ^       s_2 ^ s_3
                          mv                   t1,  a5          // s_1  = t_0       = s_0
                          mv                   t2,  a6          // s_2  = t_1       =       s_1 ^ s_2
                          mv                   t3,  a7          // s_3  = t_2       = s_0 ^       s_2
.endm
#endif

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => encrypt

.section .text
  
.global skinny_128_384_plus_enc

skinny_128_384_plus_enc:  SKINNY_PROLOGUE

#if ( ROMULUS_RV32_TYPE2 )
#if !( ROMULUS_UNROLL )
0:                        SKINNY_ROUND
                          SKINNY_ROUND

                          addi                 a2,  a2,   2     // i     = i + 2
                          bgeu                 a2,  a3,   1f    // if i >= n, goto 1
                          
                          j                               0b    //            goto 0
#else
                          .set I,     0
                          .rept 20
                          SKINNY_ROUND I + 0
                          SKINNY_ROUND I + 1
                          .set I, I + 2
                          .endr
#endif

#elif ( ROMULUS_RV32_TYPE1 )
  # li a5, 0xB2A1096C 
  # li a6, 0xF7E4D583
  # li a7, 0x88888888
  li a1, 0x00FF00FF
  li a2, 0xFF00FF00
  li a3, 0x01010101
  li a4, 0x80808080
  //
  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x1, 0x0, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x3, 0x0, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x7, 0x0, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xF, 0x0, t4, t5
  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xF, 0x1, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xE, 0x3, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xD, 0x3, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xB, 0x3, t4, t5

  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x7, 0x3, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xF, 0x2, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xE, 0x1, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xC, 0x3, t4, t5
  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x9, 0x3, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x3, 0x3, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x7, 0x2, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xE, 0x0, t4, t5

  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xD, 0x1, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xA, 0x3, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x5, 0x3, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xB, 0x2, t4, t5
  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x6, 0x1, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xC, 0x2, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x8, 0x1, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x0, 0x3, t4, t5

  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x1, 0x2, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x2, 0x0, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x5, 0x0, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xB, 0x0, t4, t5
  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x7, 0x1, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xE, 0x2, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xC, 0x1, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x8, 0x3, t4, t5

  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x1, 0x3, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x3, 0x2, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0x6, 0x0, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xD, 0x0, t4, t5
  SKINNY_ROUND t0, t1, t2, t3, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xB, 0x1, t4, t5
  SKINNY_ROUND t3, t0, t1, t2, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0x6, 0x3, t4, t5
  SKINNY_ROUND t2, t3, t0, t1, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, 0xD, 0x2, t4, t5
  SKINNY_ROUND t1, t2, t3, t0, s2, s3, s0, s1, s6, s7, s4, s5, s10, s11, s8, s9, 0xA, 0x1, t4, t5
#endif

1:                        SKINNY_EPILOGUE

// ============================================================================
