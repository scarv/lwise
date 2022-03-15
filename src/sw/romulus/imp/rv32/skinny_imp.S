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
// SubCells

.macro SKINNY_SBOX s0, t0, t1
  andi \t0, \s0, 0xFF   // t0  = s0 & 0xFF
  add   t6,  a7, \t0    // t6 -> LUT[s0&0xFF]
  lbu  \t1, 0(t6)       // t1  = LUT[s0&0xFF]
  srli \s0, \s0, 8      // s0  = s0 >> 8
  andi \t0, \s0, 0xFF   // t0  = s0>>8 & 0xFF
  add   t6,  a7, \t0    // t6 -> LUT[s0>>8&0xFF]
  lbu   t6, 0(t6)       // t6  = LUT[s0>>8&0xFF]
  slli  t6,  t6, 8      // t6  = LUT[s0>>8&0xFF] << 8
  xor  \t1, \t1, t6     // t1  = LUT[s0>>8&0xFF] LUT[s0&0xFF]
  srli \s0, \s0, 8      // s0  = s0 >> 16
  andi \t0, \s0, 0xFF   // t0  = s0>>16 & 0xFF
  add   t6,  a7, \t0    // t6 -> LUT[s0>>16&0xFF]
  lbu   t6, 0(t6)       // t6  = LUT[s0>>16&0xFF]
  slli  t6,  t6, 16     // t6  = LUT[s0>>16&0xFF] << 16
  xor  \t1, \t1, t6     // t1  = LUT[s0>>16&0xFF] LUT[s0>>8&0xFF] LUT[s0&0xFF]
  srli \t0, \s0, 8      // t0  = s0 >> 24
  add   t6,  a7, \t0    // t6 -> LUT[s0>>24&0xFF]
  lbu   t6, 0(t6)       // t6  = LUT[s0>>24&0xFF]
  slli  t6,  t6, 24     // t6  = LUT[s0>>24&0xFF] << 24
  xor  \s0, \t1, t6     // s0  = LUT[s0>>24&0xFF] LUT[s0>>16&0xFF] LUT[s0>>8&0xFF] LUT[s0&0xFF]
.endm

.macro SKINNY_SC s0, s1, s2, s3, t0, t1
  SKINNY_SBOX \s0, \t0, \t1
  SKINNY_SBOX \s1, \t0, \t1
  SKINNY_SBOX \s2, \t0, \t1
  SKINNY_SBOX \s3, \t0, \t1
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
  pack  \k3, \k3, \t1       // k3 = B10 B11 B12 B14
  rori  \k3, \k3, 24        // k3 = B11 B12 B14 B10
  and   \t0, \t0, a2        // t0 = B13     B15
  srli  \t1, \t1, 16        // t1 =         B8  B9
  pack  \k2, \t1, \k2       // k2 = B9  B8  B8  B9
  and   \k2, \k2, a1        // k2 =     B8      B9
  xor   \k2, \k2, \t0       // k2 = B13 B8  B15 B9
.endm

.macro SKINNY_TK2LFSR k0, t0, t1
  srli \t0, \k0, 7
  srli \t1, \k0, 5
  xor  \t0, \t0, \t1
  and  \t0, \t0, a3
  slli \k0, \k0, 1
  and  \k0, \k0, a5
  xor  \k0, \k0, \t0
.endm

.macro SKINNY_TK3LFSR k0, t0, t1
  slli \t0, \k0, 7
  slli \t1, \k0, 1
  xor  \t0, \t0, \t1
  and  \t0, \t0, a4
  srli \k0, \k0, 1
  and  \k0, \k0, a6
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
  SKINNY_SC  \s0, \s1, \s2, \s3, \t0, \t1
  SKINNY_AC  \s0, \s1, \s2, \rc0, \rc1
  SKINNY_ART \s0, \s1, \k10, \k11, \k20, \k21, \k30, \k31
  SKINNY_KU  \k12, \k13, \k22, \k23, \k32, \k33, \t0, \t1
  SKINNY_SR  \s0, \s1, \s2, \s3
  SKINNY_MC  \s0, \s1, \s2, \s3
.endm

.section .data

.align 2

SBOX_LUT:
.byte  0x65, 0x4C, 0x6A, 0x42, 0x4B, 0x63, 0x43, 0x6B, 0x55, 0x75, 0x5A, 0x7A, 0x53, 0x73, 0x5B, 0x7B 
.byte  0x35, 0x8C, 0x3A, 0x81, 0x89, 0x33, 0x80, 0x3B, 0x95, 0x25, 0x98, 0x2A, 0x90, 0x23, 0x99, 0x2B 
.byte  0xE5, 0xCC, 0xE8, 0xC1, 0xC9, 0xE0, 0xC0, 0xE9, 0xD5, 0xF5, 0xD8, 0xF8, 0xD0, 0xF0, 0xD9, 0xF9 
.byte  0xA5, 0x1C, 0xA8, 0x12, 0x1B, 0xA0, 0x13, 0xA9, 0x05, 0xB5, 0x0A, 0xB8, 0x03, 0xB0, 0x0B, 0xB9
.byte  0x32, 0x88, 0x3C, 0x85, 0x8D, 0x34, 0x84, 0x3D, 0x91, 0x22, 0x9C, 0x2C, 0x94, 0x24, 0x9D, 0x2D 
.byte  0x62, 0x4A, 0x6C, 0x45, 0x4D, 0x64, 0x44, 0x6D, 0x52, 0x72, 0x5C, 0x7C, 0x54, 0x74, 0x5D, 0x7D 
.byte  0xA1, 0x1A, 0xAC, 0x15, 0x1D, 0xA4, 0x14, 0xAD, 0x02, 0xB1, 0x0C, 0xBC, 0x04, 0xB4, 0x0D, 0xBD 
.byte  0xE1, 0xC8, 0xEC, 0xC5, 0xCD, 0xE4, 0xC4, 0xED, 0xD1, 0xF1, 0xDC, 0xFC, 0xD4, 0xF4, 0xDD, 0xFD 
.byte  0x36, 0x8E, 0x38, 0x82, 0x8B, 0x30, 0x83, 0x39, 0x96, 0x26, 0x9A, 0x28, 0x93, 0x20, 0x9B, 0x29 
.byte  0x66, 0x4E, 0x68, 0x41, 0x49, 0x60, 0x40, 0x69, 0x56, 0x76, 0x58, 0x78, 0x50, 0x70, 0x59, 0x79 
.byte  0xA6, 0x1E, 0xAA, 0x11, 0x19, 0xA3, 0x10, 0xAB, 0x06, 0xB6, 0x08, 0xBA, 0x00, 0xB3, 0x09, 0xBB 
.byte  0xE6, 0xCE, 0xEA, 0xC2, 0xCB, 0xE3, 0xC3, 0xEB, 0xD6, 0xF6, 0xDA, 0xFA, 0xD3, 0xF3, 0xDB, 0xFB 
.byte  0x31, 0x8A, 0x3E, 0x86, 0x8F, 0x37, 0x87, 0x3F, 0x92, 0x21, 0x9E, 0x2E, 0x97, 0x27, 0x9F, 0x2F 
.byte  0x61, 0x48, 0x6E, 0x46, 0x4F, 0x67, 0x47, 0x6F, 0x51, 0x71, 0x5E, 0x7E, 0x57, 0x77, 0x5F, 0x7F 
.byte  0xA2, 0x18, 0xAE, 0x16, 0x1F, 0xA7, 0x17, 0xAF, 0x01, 0xB2, 0x0E, 0xBE, 0x07, 0xB7, 0x0F, 0xBF 
.byte  0xE2, 0xCA, 0xEE, 0xC6, 0xCF, 0xE7, 0xC7, 0xEF, 0xD2, 0xF2, 0xDE, 0xFE, 0xD7, 0xF7, 0xDF, 0xFF 

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
  li a1, 0x00FF00FF
  li a2, 0xFF00FF00
  li a3, 0x01010101
  li a4, 0x80808080
  li a5, 0xFEFEFEFE
  li a6, 0x7F7F7F7F 
  la a7, SBOX_LUT
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
