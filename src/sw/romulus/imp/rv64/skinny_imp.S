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

                          li                   a2,        0     // i     =  0
                          li                   a3,       40     // n     = 40

                          lw                   t0,        0(a0) // s_0   = MEM[ a0 +  0 ]
                          lw                   t1,        4(a0) // s_1   = MEM[ a0 +  8 ]

                          lw                   s0,        0(a1) // tk1_0 = MEM[ a1 +  0 ]
                          lw                   s1,        8(a1) // tk1_1 = MEM[ a1 +  8 ]
                          lw                   s4,       16(a1) // tk2_0 = MEM[ a1 + 16 ]
                          lw                   s5,       24(a1) // tk2_1 = MEM[ a1 + 24 ]
                          lw                   s8,       32(a1) // tk3_0 = MEM[ a1 + 32 ]
                          lw                   s9,       40(a1) // tk3_1 = MEM[ a1 + 40 ]
.endm

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => epilogue

.macro SKINNY_EPILOGUE
                          sw                   t0,        0(a0) // MEM[ a0 +  0 ] = s_0
                          sw                   t1,        8(a0) // MEM[ a0 +  8 ] = s_1

                          sd                   s0,        0(sp) // pop  s0
                          sd                   s1,        8(sp) // pop  s1
                          sd                   s2,       16(sp) // pop  s2
                          sd                   s3,       24(sp) // pop  s3
                          sd                   s4,       32(sp) // pop  s4
                          sd                   s5,       40(sp) // pop  s5
                          addi                 sp,  sp,  48     // adjust SP

                          ret                                 // return
.endm

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => round TYPE_1

#if ( ROMULUS_RV64_TYPE1 )
#error "can't use ROMULUS_RV64_TYPE1: not yet implemented!"
#endif

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => round TYPE_2

#if ( ROMULUS_RV64_TYPE2 )
.macro SKINNY_ROUND
                          romulus.rc.upd.enc   a4,  a4          // rc    = romulus.rc.upd.enc( rc )

                          xor                  a5,  s0,  s2     // t_0   = tk1_0 ^ tk2_0
                          xor                  a5,  a5,  s3     // t_0   = tk1_0 ^ tk2_0 ^ tk3_0

                          romulus.rc.use.enc   a5,  a5          // t_0   = romulus.rc.use.enc( t_0 )

                          romulus.rstep.enc    a6,  t0,  a5, 0  // t_1   = romulus.rstep.enc( s_0, t_0, 0 )
                          romulus.rstep.enc    a7,  t1,  x0, 1  // t_2   = romulus.rstep.enc( s_1,   0, 1 )

                          romulus.cstep.enc    t0,  a6,  a7, 0  // s_0   = romulus.cstep.enc( t_1, t_2, 0 )
                          romulus.cstep.enc    t1,  a6,  a7, 1  // s_1   = romulus.cstep.enc( t_1, t_2, 1 )

                          romulus.tk.upd.enc   a5,  s1,      1  // t_0   = romulus.tk.upd.enc( tk1_1, 1 )
                          mv                   s1,  s0          // tk1_1 = tk1_0
                          mv                   s0,  a5          // tk1_0 = t_0

                          romulus.tk.upd.enc   a5,  t3,      2  // t_0   = romulus.tk.upd.enc( tk2_1, 2 )
                          mv                   t3,  t2          // tk2_1 = tk2_0
                          mv                   t2,  a5          // tk2_0 = t_0

                          romulus.tk.upd.enc   a5,  s5,      3  // t_0   = romulus.tk.upd.enc( tk3_1, 3 )
                          mv                   s5,  s4          // tk3_1 = tk3_0
                          mv                   s4,  a5          // tk3_0 = t_0
.endf
#endif

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => encrypt

.section .text
  
.global skinny_128_384_plus_enc

skinny_128_384_plus_enc : SKINNY_EPILOGUE

0:                        SKINNY_ROUND

                          addi                 a2,  a2,   1     // i     = i + 1
                          bgeu                 a2,  a3,   1f    // if i >= n, goto 1
                          
                          j                               0b    //            goto 0

1:                        SKINNY_EPILOGUE

// ============================================================================
