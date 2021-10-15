// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================	
	
#include    "zbkb.h"
#include    "zbkx.h"
#include     "ise.h"

#include "alzette.h"
#include     "ell.h"

// ----------------------------------------------------------------------------	
// register allocation

// t0  => subkey
// t1  => &TRAXL17_RCON
// t2  => i          ~ loop counter 
// t3  => n          ~ loop bound
// t4  => temp 
// t5  => temp
// t6  => temp

// s0  =>  xstate[ 0 ] =  x0
// s1  =>  xstate[ 1 ] =  x1
// s2  =>  xstate[ 2 ] =  x2
// s3  =>  xstate[ 3 ] =  x3
// s4  =>  ystate[ 0 ] =  y0
// s5  =>  ystate[ 1 ] =  y1
// s6  =>  ystate[ 2 ] =  y2
// s7  =>  ystate[ 3 ] =  y3
// s8  =>   tweak[ 0 ] = tk0
// s9  =>   tweak[ 1 ] = tk1
// s10 =>   tweak[ 2 ] = tk2
// s11 =>   tweak[ 3 ] = tk3

// ----------------------------------------------------------------------------	
// TRAXL17 implementation => en/decrypt prologue + epilogue

.macro TRAXL17_ENC_PROLOGUE
              addi                 sp, sp, -48              // adjust SP
              sw                   s0,   0(sp)              // push s0
              sw                   s1,   4(sp)              // push s1
              sw                   s2,   8(sp)              // push s2
              sw                   s3,  12(sp)              // push s3
              sw                   s4,  16(sp)              // push s4
              sw                   s5,  20(sp)              // push s5
              sw                   s6,  24(sp)              // push s6
              sw                   s7,  28(sp)              // push s7
              sw                   s8,  32(sp)              // push s8
              sw                   s9,  36(sp)              // push s9
              sw                   s10, 40(sp)              // push s10
              sw                   s11, 44(sp)              // push s11
              
              li                   t2,   0                  // t2  =  0             => i =  0
              li                   t3,  16                  // t3  = 16             => n = 16
.endm

.macro TRAXL17_ENC_EPILOGUE        
              lw                   s0,   0(sp)              // pop  s0
              lw                   s1,   4(sp)              // pop  s1
              lw                   s2,   8(sp)              // pop  s2
              lw                   s3,  12(sp)              // pop  s3
              lw                   s4,  16(sp)              // pop  s4
              lw                   s5,  20(sp)              // pop  s5
              lw                   s6,  24(sp)              // pop  s6
              lw                   s7,  28(sp)              // pop  s7
              lw                   s8,  32(sp)              // pop  s8
              lw                   s9,  36(sp)              // pop  s9
              lw                   s10, 40(sp)              // pop  s10
              lw                   s11, 44(sp)              // pop  s11
              addi                 sp, sp,  48              // adjust SP

              ret                                           // return
.endm

.macro TRAXL17_DEC_PROLOGUE
              addi                 sp, sp, -48              // adjust SP
              sw                   s0,   0(sp)              // push s0
              sw                   s1,   4(sp)              // push s1
              sw                   s2,   8(sp)              // push s2
              sw                   s3,  12(sp)              // push s3
              sw                   s4,  16(sp)              // push s4
              sw                   s5,  20(sp)              // push s5
              sw                   s6,  24(sp)              // push s6
              sw                   s7,  28(sp)              // push s7
              sw                   s8,  32(sp)              // push s8
              sw                   s9,  36(sp)              // push s9
              sw                   s10, 40(sp)              // push s10
              sw                   s11, 44(sp)              // push s11

              li                   t2,     16               // t2  = 16             => i = 16
              li                   t3,      0               // t3  =  0             => n =  0
.endm

.macro TRAXL17_DEC_EPILOGUE
              lw                   s0,   0(sp)              // pop  s0
              lw                   s1,   4(sp)              // pop  s1
              lw                   s2,   8(sp)              // pop  s2
              lw                   s3,  12(sp)              // pop  s3
              lw                   s4,  16(sp)              // pop  s4
              lw                   s5,  20(sp)              // pop  s5
              lw                   s6,  24(sp)              // pop  s6
              lw                   s7,  28(sp)              // pop  s7
              lw                   s8,  32(sp)              // pop  s8
              lw                   s9,  36(sp)              // pop  s9
              lw                   s10, 40(sp)              // pop  s10
              lw                   s11, 44(sp)              // pop  s11
              addi                 sp, sp,  48              // adjust SP

              ret                                           // return
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => TRAXL17_RD_STATE

.macro  TRAXL17_RD_STATE x0, x1, x2, x3, y0, y1, y2, y3, tk0, tk1, tk2, tk3
              lw                   \x0,   0(a0)             // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              lw                   \x1,   4(a0)             // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              lw                   \x2,   8(a0)             // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              lw                   \x3,  12(a0)             // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              lw                   \y0,   0(a1)             // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              lw                   \y1,   4(a1)             // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              lw                   \y2,   8(a1)             // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              lw                   \y3,  12(a1)             // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

              lw                   \tk0,  0(a3)             // s8  = MEM[ a3 +  0 ] => tk[ 0 ] = tweak[ 0 ]
              lw                   \tk1,  4(a3)             // s9  = MEM[ a3 +  4 ] => tk[ 1 ] = tweak[ 1 ]
              lw                   \tk2,  8(a3)             // s10 = MEM[ a3 +  8 ] => tk[ 2 ] = tweak[ 2 ]
              lw                   \tk3, 12(a3)             // s11 = MEM[ a3 + 12 ] => tk[ 3 ] = tweak[ 3 ]
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => TRAXL17_WR_STATE

.macro  TRAXL17_WR_STATE x0, x1, x2, x3, y0, y1, y2, y3
              sw                   \x0,   0(a0)             // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              sw                   \x1,   4(a0)             // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              sw                   \x2,   8(a0)             // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              sw                   \x3,  12(a0)             // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              sw                   \y0,   0(a1)             // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              sw                   \y1,   4(a1)             // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              sw                   \y2,   8(a1)             // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              sw                   \y3,  12(a1)             // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => add tweak

.macro TRAXL17_ADD_TWEAK x0, x1, y0, y1, tk0, tk1, tk2, tk3
              xor                  \x0, \x0, \tk0           // x0 ^= tk[0]
              xor                  \y0, \y0, \tk1           // y0 ^= tk[1]
              xor                  \x1, \x1, \tk2           // x1 ^= tk[2]
              xor                  \y1, \y1, \tk3           // y1 ^= tk[3]
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt linear layer

.macro TRAXL17_ENC_LINEAR x0, x1, x2, x3, y0, y1, y2, y3, t0, t1, t2
              ELL                  \t0, \x2, \x3, \t1, \t2
              xor                  \y0, \y0, \t0 
              xor                  \y1, \y1, \t0 

              ELL                  \t0, \y2, \y3, \t1, \t2
              xor                  \x0, \x0, \t0 
              xor                  \x1, \x1, \t0 
#if !( TRAXL17_ENC_UNROLL )
              mv                   \t0, \x0
              mv                   \x0, \x3
              mv                   \x3, \x1
              mv                   \x1, \x2
              mv                   \x2, \t0

              mv                   \t0, \y0
              mv                   \y0, \y3
              mv                   \y3, \y1
              mv                   \y1, \y2
              mv                   \y2, \t0
#endif
.endm

.macro TRAXL17_DEC_LINEAR x0, x1, x2, x3, y0, y1, y2, y3, t0, t1, t2
#if !( TRAXL17_DEC_UNROLL )
              mv                   \t0, \x0
              mv                   \x0, \x2
              mv                   \x2, \x1
              mv                   \x1, \x3
              mv                   \x3, \t0

              mv                   \t0, \y0
              mv                   \y0, \y2
              mv                   \y2, \y1
              mv                   \y1, \y3
              mv                   \y3, \t0
#endif
              ELL                  \t0, \x2, \x3, \t1, \t2
              xor                  \y0, \y0, \t0 
              xor                  \y1, \y1, \t0 

              ELL                  \t0, \y2, \y3, \t1, \t2
              xor                  \x0, \x0, \t0 
              xor                  \x1, \x1, \t0 
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => add subkeys
	
.macro TRAXL17_ADD_SUBKEY sk, x0, x1, x2, x3, y0, y1, y2, y3, t0
              lw                   \t0,  0(\sk)
              xor                  \x0, \x0, \t0
              lw                   \t0,  4(\sk)
              xor                  \y0, \y0, \t0
              lw                   \t0,  8(\sk)
              xor                  \x1, \x1, \t0
              lw                   \t0, 12(\sk)
              xor                  \y1, \y1, \t0
              lw                   \t0, 16(\sk)
              xor                  \x2, \x2, \t0
              lw                   \t0, 20(\sk)
              xor                  \y2, \y2, \t0
              lw                   \t0, 24(\sk)
              xor                  \x3, \x3, \t0
              lw                   \t0, 28(\sk)
              xor                  \y3, \y3, \t0
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt substitution

#if ( SPARKLE_RV32_TYPE1 ) || ( SPARKLE_RV32_TYPE2 ) || ( SPARKLE_RV32_TYPE3 )
.macro TRAXL17_ENC_SUBS rc, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              lw                   \t0,   0(\rc)            // t0 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_ENC          \x0, \y0, \t0, \t1, \t2
              lw                   \t0,   4(\rc)            // t0 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_ENC          \x1, \y1, \t0, \t1, \t2
              lw                   \t0,   8(\rc)            // t0 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_ENC          \x2, \y2, \t0, \t1, \t2
              lw                   \t0,  12(\rc)            // t0 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_ENC          \x3, \y3, \t0, \t1, \t2
.endm

.macro TRAXL17_DEC_SUBS rc, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              lw                   \t0,   0(\rc)            // t0 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_DEC          \x0, \y0, \t0, \t1, \t2
              lw                   \t0,   4(\rc)            // t0 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_DEC          \x1, \y1, \t0, \t1, \t2
              lw                   \t0,   8(\rc)            // t0 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_DEC          \x2, \y2, \t0, \t1, \t2
              lw                   \t0,  12(\rc)            // t0 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_DEC          \x3, \y3, \t0, \t1, \t2
.endm
#endif

#if ( SPARKLE_RV32_TYPE4 )
.macro TRAXL17_ENC_SUBS rc, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              sparkle.whole.enci.x \t0, \x0, \y0,   \rc
              sparkle.whole.enci.y \y0, \x0, \y0,   \rc
              mv                   \x0, \t0
              sparkle.whole.enci.x \t0, \x1, \y1, 1+\rc
              sparkle.whole.enci.y \y1, \x1, \y1, 1+\rc
              mv                   \x1, \t0
              sparkle.whole.enci.x \t0, \x2, \y2, 2+\rc
              sparkle.whole.enci.y \y2, \x2, \y2, 2+\rc
              mv                   \x2, \t0
              sparkle.whole.enci.x \t0, \x3, \y3, 3+\rc
              sparkle.whole.enci.y \y3, \x3, \y3, 3+\rc
              mv                   \x3, \t0
.endm

.macro TRAXL17_DEC_SUBS rc, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              sparkle.whole.deci.x \t0, \x0, \y0,   \rc
              sparkle.whole.deci.y \y0, \x0, \y0,   \rc
              mv                   \x0, \t0
              sparkle.whole.deci.x \t0, \x1, \y1, 1+\rc
              sparkle.whole.deci.y \y1, \x1, \y1, 1+\rc
              mv                   \x1, \t0
              sparkle.whole.deci.x \t0, \x2, \y2, 2+\rc
              sparkle.whole.deci.y \y2, \x2, \y2, 2+\rc
              mv                   \x2, \t0
              sparkle.whole.deci.x \t0, \x3, \y3, 3+\rc
              sparkle.whole.deci.y \y3, \x3, \y3, 3+\rc
              mv                   \x3, \t0
.endm
#endif
	
// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt step
	
#if ( SPARKLE_RV32_TYPE1 ) || ( SPARKLE_RV32_TYPE2 ) || ( SPARKLE_RV32_TYPE3 ) || ( SPARKLE_RV32_TYPE4 )
.macro TRAXL17_ENC_STEP_EVE sk, rc, x0, x1, x2, x3, y0, y1, y2, y3,                     t0, t1, t2
              TRAXL17_ADD_SUBKEY   \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0
              TRAXL17_ENC_SUBS     \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2    
              TRAXL17_ENC_LINEAR        \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2

              addi                 \sk, \sk, 32             //             => sk += 8
#if !( TRAXL17_ENC_UNROLL )
              addi                  t2,  t2,  1             // t2 = t2 + 1 => step++
#endif
.endm     

.macro TRAXL17_ENC_STEP_ODD sk, rc, x0, x1, x2, x3, y0, y1, y2, y3, tk0, tk1, tk2, tk3, t0, t1, t2
              TRAXL17_ADD_TWEAK         \x0, \x1,           \y0, \y1,           \tk0, \tk1, \tk2, \tk3
              TRAXL17_ADD_SUBKEY   \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0
              TRAXL17_ENC_SUBS     \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2
              TRAXL17_ENC_LINEAR        \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2

              addi                 \sk, \sk, 32             //             => sk += 8
#if !( TRAXL17_ENC_UNROLL )
              addi                  t2,  t2,  1             // t2 = t2 + 1 => step++
#endif
.endm   

.macro TRAXL17_DEC_STEP_EVE sk, rc, x0, x1, x2, x3, y0, y1, y2, y3,                     t0, t1, t2
              TRAXL17_DEC_LINEAR        \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2
              TRAXL17_DEC_SUBS     \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2             
              TRAXL17_ADD_SUBKEY   \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0

              addi                 \sk, \sk, -32            //             => sk += 8
#if !( TRAXL17_ENC_UNROLL )
              addi                  t2,  t2, -1             // t2 = t2 - 1 => step++
#endif
.endm       

.macro TRAXL17_DEC_STEP_ODD sk, rc, x0, x1, x2, x3, y0, y1, y2, y3, tk0, tk1, tk2, tk3, t0, t1, t2
              TRAXL17_DEC_LINEAR        \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2
              TRAXL17_DEC_SUBS     \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2             
              TRAXL17_ADD_SUBKEY   \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0
              TRAXL17_ADD_TWEAK         \x0, \x1,           \y0, \y1,           \tk0, \tk1, \tk2, \tk3

              addi                 \sk, \sk, -32            //             => sk += 8
#if !( TRAXL17_ENC_UNROLL )
              addi                  t2,  t2, -1             // t2 = t2 - 1 => step++
#endif
.endm   
#endif

// ----------------------------------------------------------------------------	
// TRAXL17 implementation => encrypt

.section .text
  
.global traxl17_enc

traxl17_enc:  TRAXL17_ENC_PROLOGUE

#if ( SPARKLE_RV32_TYPE1 ) || ( SPARKLE_RV32_TYPE2 ) || ( SPARKLE_RV32_TYPE3 )
              mv                   t0, a2
              la                   t1, TRAXL17_RCON         // t1 = &TRAXL17_RCON
              addi                 a7, t1,  16
              TRAXL17_RD_STATE             s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11
#if ( TRAXL17_ENC_UNROLL )
              TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,     s3, s2, s0, s1, s7, s6, s4, s5,                   t4
              TRAXL17_WR_STATE             s3, s2, s0, s1, s7, s6, s4, s5
#else             
0:            bgeu                 t2, t3, 1f               // if i >= n, goto 1
              TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              j                            0b               //            goto 0

1:            TRAXL17_ENC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,     s0, s1, s2, s3, s4, s5, s6, s7,                   t4        
              TRAXL17_WR_STATE             s0, s1, s2, s3, s4, s5, s6, s7  
#endif       
#endif

#if ( SPARKLE_RV32_TYPE4 )
              mv                   t0, a2
              TRAXL17_RD_STATE             s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11
#if ( TRAXL17_ENC_UNROLL )
              TRAXL17_ENC_STEP_EVE t0,  0, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s3, s2, s0, s1, s7, s6, s4, s5, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s1, s0, s3, s2, s5, s4, s7, s6,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4, s2, s3, s1, s0, s6, s7, s5, s4, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,     s3, s2, s0, s1, s7, s6, s4, s5,                   t4
              TRAXL17_WR_STATE             s3, s2, s0, s1, s7, s6, s4, s5
#else	
#error "can't use SPARKLE_RV32_TYPE4 without TRAXL17_ENC_UNROLL"
#endif
#endif
              TRAXL17_ENC_EPILOGUE

// ----------------------------------------------------------------------------	
// TRAXL17 implementation => decrypt

.section .text
  
.global traxl17_dec

traxl17_dec:  TRAXL17_DEC_PROLOGUE

#if ( SPARKLE_RV32_TYPE1 ) || ( SPARKLE_RV32_TYPE2 ) || ( SPARKLE_RV32_TYPE3 )
              addi                 t0, a2,  544                       
              la                   t1, TRAXL17_RCON         // t1 = &TRAXL17_RCON
              addi                 a7, t1,  16
              TRAXL17_RD_STATE             s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11
              TRAXL17_ADD_SUBKEY   t0,     s0, s1, s2, s3, s4, s5, s6, s7,                   t4
              addi                 t0, t0, -32
#if ( TRAXL17_DEC_UNROLL )         
              TRAXL17_DEC_STEP_EVE t0, t1, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0, a7, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, t1, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6
              TRAXL17_WR_STATE             s2, s3, s1, s0, s6, s7, s5, s4
#else             
0:            blez                 t2, 1f                   // if i <= 0, goto 1
              TRAXL17_DEC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              j                        0b                   //            goto 0

1:            TRAXL17_DEC_STEP_EVE t0, t1, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_WR_STATE             s0, s1, s2, s3, s4, s5, s6, s7
#endif
#endif

#if ( SPARKLE_RV32_TYPE4 )
              addi                 t0, a2,  544
              TRAXL17_RD_STATE             s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11
              TRAXL17_ADD_SUBKEY   t0,     s0, s1, s2, s3, s4, s5, s6, s7,                   t4
              addi                 t0, t0, -32
#if ( TRAXL17_DEC_UNROLL )
              TRAXL17_DEC_STEP_EVE t0,  0, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0,  4, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s1, s0, s3, s2, s5, s4, s7, s6, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s3, s2, s0, s1, s7, s6, s4, s5,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0, s2, s3, s1, s0, s6, s7, s5, s4,                   t4, t5, t6
              TRAXL17_WR_STATE             s2, s3, s1, s0, s6, s7, s5, s4
#else	
#error "can't use SPARKLE_RV32_TYPE4 without TRAXL17_DEC_UNROLL"
#endif
#endif
              TRAXL17_DEC_EPILOGUE

// ============================================================================
