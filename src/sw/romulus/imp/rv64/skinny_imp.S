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
// t2  => 
// t3  => 
// t4  => 
// t5  => 
// t6  =>

// s0  => tk1_0
// s1  => tk1_1
// s2  => tk2_0
// s3  => tk2_1
// s4  => tk3_0
// s5  => tk3_1

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => prologue

.macro SKINNY_PROLOGUE
                          addi                 sp,  sp, -48     // adjust SP
                          sd                   s0,        0(sp) // push s0
                          sd                   s1,        8(sp) // push s1
                          sd                   s2,       16(sp) // push s2
                          sd                   s3,       24(sp) // push s3
                          sd                   s4,       32(sp) // push s4
                          sd                   s5,       40(sp) // push s5

#if !( ROMULUS_UNROLL )
                          li                   a2,        0     // i     =  0
                          li                   a3,       40     // n     = 40
#endif
                          li                   a4,        0     // rc    =  0

                          ld                   t0,        0(a0) // s_0   = MEM[ a0 +  0 ]
                          ld                   t1,        8(a0) // s_1   = MEM[ a0 +  8 ]

                          ld                   s0,        0(a1) // tk1_0 = MEM[ a1 +  0 ]
                          ld                   s1,        8(a1) // tk1_1 = MEM[ a1 +  8 ]
                          ld                   s2,       16(a1) // tk2_0 = MEM[ a1 + 16 ]
                          ld                   s3,       24(a1) // tk2_1 = MEM[ a1 + 24 ]
                          ld                   s4,       32(a1) // tk3_0 = MEM[ a1 + 32 ]
                          ld                   s5,       40(a1) // tk3_1 = MEM[ a1 + 40 ]
.endm

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => epilogue

.macro SKINNY_EPILOGUE
                          sd                   t0,        0(a0) // MEM[ a0 +  0 ] = s_0
                          sd                   t1,        8(a0) // MEM[ a0 +  8 ] = s_1

                          ld                   s0,        0(sp) // pop  s0
                          ld                   s1,        8(sp) // pop  s1
                          ld                   s2,       16(sp) // pop  s2
                          ld                   s3,       24(sp) // pop  s3
                          ld                   s4,       32(sp) // pop  s4
                          ld                   s5,       40(sp) // pop  s5
                          addi                 sp,  sp,  48     // adjust SP

                          ret                                   // return
.endm

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => round TYPE_1

#if  ( ROMULUS_RV64_TYPE1 )
#error "can't use ROMULUS_RV64_TYPE1: not yet implemented!"
#endif

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => round TYPE_2

#if  ( ROMULUS_RV64_TYPE2 )
.macro SKINNY_ROUND I
                          romulus.rc.upd.enc   a4,  a4          // rc    = romulus.rc.upd.enc( rc )

                          xor                  a5,  s0,  s2     // t_0   = tk1_0 ^ tk2_0
                          xor                  a5,  a5,  s4     // t_0   = tk1_0 ^ tk2_0 ^ tk3_0

                          romulus.rc.use.enc   a5,  a4,  a5     // t_0   = romulus.rc.use.enc( rc, t_0 )

                          romulus.rstep.enc    a6,  t0,  a5, 0  // t_1   = romulus.rstep.enc( s_0, t_0, 0 )
                          romulus.rstep.enc    a7,  t1,  x0, 1  // t_2   = romulus.rstep.enc( s_1,   0, 1 )
                          romulus.cstep.enc    t0,  a6,  a7, 0  // s_0   = romulus.cstep.enc( t_1, t_2, 0 )
                          romulus.cstep.enc    t1,  a6,  a7, 1  // s_1   = romulus.cstep.enc( t_1, t_2, 1 )

                          romulus.tk.upd.enc   a5,  s1,      1  // t_0   = romulus.tk.upd.enc( tk1_1, 1 )
                          mv                   s1,  s0          // tk1_1 = tk1_0
                          mv                   s0,  a5          // tk1_0 = t_0

                          romulus.tk.upd.enc   a5,  s3,      2  // t_0   = romulus.tk.upd.enc( tk2_1, 2 )
                          mv                   s3,  s2          // tk2_1 = tk2_0
                          mv                   s2,  a5          // tk2_0 = t_0

                          romulus.tk.upd.enc   a5,  s5,      3  // t_0   = romulus.tk.upd.enc( tk3_1, 3 )
                          mv                   s5,  s4          // tk3_1 = tk3_0
                          mv                   s4,  a5          // tk3_0 = t_0
.endm
#endif

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => encrypt

.section .text
  
.global skinny_128_384_plus_enc

skinny_128_384_plus_enc:  SKINNY_PROLOGUE

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

1:                        SKINNY_EPILOGUE

// ============================================================================
