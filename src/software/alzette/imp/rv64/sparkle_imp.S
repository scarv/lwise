// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// imp_sparkle.S: RISCV-based implementation of the SPARKLE384 permutation.  

#include     "ise.h"
#include     "ell.h"
#include "alzette.h"

// ============================================================================
// register allocation

// t0 => &SPARKLE_RCON_POINTER
// t1 => &SPARKLE_RCON_INDEX 
// t2 => i          ~ loop counter 
// t3 => n          ~ loop bound
// t4 => temp 
// t5 => temp
// t6 => temp

// s0  =>  state[  0 ] =  y0 || x0
// s1  =>  state[  2 ] =  y1 || x1
// s2  =>  state[  4 ] =  y2 || x2
// s3  =>  state[  6 ] =  y3 || x3
// s4  =>  state[  8 ] =  y4 || x4
// s5  =>  state[ 10 ] =  y5 || x5
// s6  =>  state[  1 ] =        y0
// s7  =>  state[  3 ] =        y1
// s8  =>  state[  5 ] =        y2
// s9  =>  state[  7 ] =        y3
// s10 =>  state[  9 ] =        y4
// s11 =>  state[ 11 ] =        y5


// ============================================================================
// SPARKLE    implementation => forward/inverse prologue + epilogue

.macro SPARKLE_FWD_PROLOGUE
              addi         sp, sp, -104                  // adjust SP
              sd           s0,   0(sp)                   // push s0
              sd           s1,   8(sp)                   // push s1
              sd           s2,  16(sp)                   // push s2
              sd           s3,  24(sp)                   // push s3
              sd           s4,  32(sp)                   // push s4
              sd           s5,  40(sp)                   // push s5
              sd           s6,  48(sp)                   // push s6
              sd           s7,  56(sp)                   // push s7
              sd           s8,  72(sp)                   // push s8
              sd           s9,  80(sp)                   // push s9
              sd           s10, 88(sp)                   // push s10
              sd           s11, 96(sp)                   // push s11

              li           t2,   0                        // t2 =  0              => i = 0
              li           t3,   7                        // t3 =  7              => n = 7
	
.endm

.macro SPARKLE_FWD_EPILOGUE
              ld           s0,   0(sp)                   // push s0
              ld           s1,   8(sp)                   // push s1
              ld           s2,  16(sp)                   // push s2
              ld           s3,  24(sp)                   // push s3
              ld           s4,  32(sp)                   // push s4
              ld           s5,  40(sp)                   // push s5
              ld           s6,  48(sp)                   // push s6
              ld           s7,  56(sp)                   // push s7
              ld           s8,  72(sp)                   // push s8
              ld           s9,  80(sp)                   // push s9
              ld           s10, 88(sp)                   // push s10
              ld           s11, 96(sp)                   // push s11
              addi         sp, sp,  104                  // adjust SP

              ret                                        // return
.endm

.macro SPARKLE_REV_PROLOGUE
              addi         sp, sp, -104                  // adjust SP
              sd           s0,   0(sp)                   // push s0
              sd           s1,   8(sp)                   // push s1
              sd           s2,  16(sp)                   // push s2
              sd           s3,  24(sp)                   // push s3
              sd           s4,  32(sp)                   // push s4
              sd           s5,  40(sp)                   // push s5
              sd           s6,  48(sp)                   // push s6
              sd           s7,  56(sp)                   // push s7
              sd           s8,  72(sp)                   // push s8
              sd           s9,  80(sp)                   // push s9
              sd           s10, 88(sp)                   // push s10
              sd           s11, 96(sp)                   // push s11

              li           t2,      7                    // t2 =   7             
.endm

.macro SPARKLE_REV_EPILOGUE
              ld           s0,   0(sp)                   // push s0
              ld           s1,   8(sp)                   // push s1
              ld           s2,  16(sp)                   // push s2
              ld           s3,  24(sp)                   // push s3
              ld           s4,  32(sp)                   // push s4
              ld           s5,  40(sp)                   // push s5
              ld           s6,  48(sp)                   // push s6
              ld           s7,  56(sp)                   // push s7
              ld           s8,  72(sp)                   // push s8
              ld           s9,  80(sp)                   // push s9
              ld           s10, 88(sp)                   // push s10
              ld           s11, 96(sp)                   // push s11
              addi         sp, sp,  104                  // adjust SP

              ret                                        // return
.endm

// ----------------------------------------------------------------------------
// SPARKLE implementation => SPARKLE_RD_STATE
#if ( ALZETTE_RV64_TYPE1 ) 
.macro  SPARKLE_RD_STATE   x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5        
              lwu         \x0,   0(a0)                    // x0 = MEM[ a0 +  0 ]  => x0 = state[  0 ]
              lwu         \x1,   8(a0)                    // x1 = MEM[ a0 +  8 ]  => x1 = state[  2 ]
              lwu         \x2,  16(a0)                    // x2 = MEM[ a0 + 16 ]  => x2 = state[  4 ]
              lwu         \x3,  24(a0)                    // x3 = MEM[ a0 + 24 ]  => x3 = state[  6 ]
              lwu         \x4,  32(a0)                    // x4 = MEM[ a0 + 32 ]  => x4 = state[  8 ]
              lwu         \x5,  40(a0)                    // x5 = MEM[ a0 + 40 ]  => x5 = state[ 10 ]
              lwu         \y0,   4(a0)                    // y0 = MEM[ a0 +  4 ]  => y0 = state[  1 ]
              lwu         \y1,  12(a0)                    // y1 = MEM[ a0 + 12 ]  => y1 = state[  3 ]
              lwu         \y2,  20(a0)                    // y2 = MEM[ a0 + 20 ]  => y2 = state[  5 ]
              lwu         \y3,  28(a0)                    // y3 = MEM[ a0 + 28 ]  => y3 = state[  7 ]
              lwu         \y4,  36(a0)                    // y4 = MEM[ a0 + 36 ]  => y4 = state[  9 ]
              lwu         \y5,  44(a0)                    // y5 = MEM[ a0 + 44 ]  => y5 = state[ 11 ]
.endm
#endif

#if	( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
.macro  SPARKLE_RD_STATE   p0, p1, p2, p3, p4, p5        
              ld          \p0,  0(a0)                    // p0 = MEM[ a0 +  0 ]  => p0 = {y0 || x0} = state[  0 ]
              ld          \p1,  8(a0)                    // p1 = MEM[ a0 +  8 ]  => p1 = {y1 || x1} = state[  2 ]
              ld          \p2, 16(a0)                    // p2 = MEM[ a0 + 16 ]  => p2 = {y2 || x2} = state[  4 ]
              ld          \p3, 24(a0)                    // p3 = MEM[ a0 + 24 ]  => p3 = {y3 || x3} = state[  6 ]
              ld          \p4, 32(a0)                    // p4 = MEM[ a0 + 32 ]  => p4 = {y4 || x4} = state[  8 ]
              ld          \p5, 40(a0)                    // p5 = MEM[ a0 + 40 ]  => p5 = {y5 || x5} = state[ 10 ]
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE implementation => SPARKLE_WR_STATE
#if ( ALZETTE_RV64_TYPE1 ) 
.macro  SPARKLE_WR_STATE   x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5        
              sw          \x0,   0(a0)                    // x0 ->MEM[ a0 +  0 ]  => x0 ->state[  0 ]
              sw          \x1,   8(a0)                    // x1 ->MEM[ a0 +  8 ]  => x1 ->state[  2 ]
              sw          \x2,  16(a0)                    // x2 ->MEM[ a0 + 16 ]  => x2 ->state[  4 ]
              sw          \x3,  24(a0)                    // x3 ->MEM[ a0 + 24 ]  => x3 ->state[  6 ]
              sw          \x4,  32(a0)                    // x4 ->MEM[ a0 + 32 ]  => x4 ->state[  8 ]
              sw          \x5,  40(a0)                    // x5 ->MEM[ a0 + 40 ]  => x5 ->state[ 10 ]

              sw          \y0,   4(a0)                    // y0 ->MEM[ a0 +  4 ]  => y0 ->state[  1 ]
              sw          \y1,  12(a0)                    // y1 ->MEM[ a0 + 12 ]  => y1 ->state[  3 ]
              sw          \y2,  20(a0)                    // y2 ->MEM[ a0 + 20 ]  => y2 ->state[  5 ]
              sw          \y3,  28(a0)                    // y3 ->MEM[ a0 + 28 ]  => y3 ->state[  7 ]
              sw          \y4,  36(a0)                    // y4 ->MEM[ a0 + 36 ]  => y4 ->state[  9 ]
              sw          \y5,  44(a0)                    // y5 ->MEM[ a0 + 44 ]  => y5 ->state[ 11 ]
.endm
#endif

#if	( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
.macro  SPARKLE_WR_STATE   p0, p1, p2, p3, p4, p5         
              sd          \p0,   0(a0)                    // p0 ->MEM[ a0 +  0 ]  => {y0 || x0} ->state[  0 ]
              sd          \p1,   8(a0)                    // p1 ->MEM[ a0 +  8 ]  => {y1 || x1} ->state[  2 ]
              sd          \p2,  16(a0)                    // p2 ->MEM[ a0 + 16 ]  => {y2 || x2} ->state[  4 ]
              sd          \p3,  24(a0)                    // p3 ->MEM[ a0 + 24 ]  => {y3 || x3} ->state[  6 ]
              sd          \p4,  32(a0)                    // p4 ->MEM[ a0 + 32 ]  => {y4 || x4} ->state[  8 ]
              sd          \p5,  40(a0)                    // p5 ->MEM[ a0 + 40 ]  => {y5 || x5} ->state[ 10 ]
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/inverse linear layer

#if ( ALZETTE_RV64_TYPE1 )
.macro SPARKLE_FWD_LINEAR  x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2 
              XOR3        \t0, \x0, \x1, \x2             //  t0  = x0 ^ x1 ^ x2
              ELL32       \t0, \t0, \t1, \t2             // tmpx = ELL(t0)
              XOR3        \y3, \y3, \y0, \t0             //  y3 ^= y0 ^ tmpx 
              XOR3        \y4, \y4, \y1, \t0             //  y4 ^= y1 ^ tmpx
              XOR3        \y5, \y5, \y2, \t0             //  y5 ^= y2 ^ tmpx

              XOR3        \t0, \y0, \y1, \y2             //  t0  = y0 ^ y1 ^ y2
              ELL32       \t0, \t0, \t1, \t2             // tmpy = ELL(t0)
              XOR3        \x3, \x3, \x0, \t0             //  x3 ^= x0 ^ tmpy 
              XOR3        \x4, \x4, \x1, \t0             //  x4 ^= x1 ^ tmpy
              XOR3        \x5, \x5, \x2, \t0             //  x5 ^= x2 ^ tmpy
              // 0 1 2  3 4 5
              // 4 5 3  0 1 2
              // Branch swap of the x part
              mv          \t0, \x0                       
              mv          \x0, \x4
              mv          \x4, \x1  
              mv          \x1, \x5
              mv          \x5, \x2
              mv          \x2, \x3
              mv          \x3, \t0
              // Branch swap of the y part
              mv          \t0, \y0                       
              mv          \y0, \y4
              mv          \y4, \y1  
              mv          \y1, \y5
              mv          \y5, \y2
              mv          \y2, \y3
              mv          \y3, \t0

.endm

.macro SPARKLE_REV_LINEAR  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2  
              // 0 1 2  3 4 5
              // 3 4 5  2 0 1
              // Branch swap of the x part
              mv          \t0, \x2                       
              mv          \x2, \x5
              mv          \x5, \x1  
              mv          \x1, \x4
              mv          \x4, \x0
              mv          \x0, \x3
              mv          \x3, \t0
              // Branch swap of the y part
              mv          \t0, \y2                       
              mv          \y2, \y5
              mv          \y5, \y1  
              mv          \y1, \y4
              mv          \y4, \y0
              mv          \y0, \y3
              mv          \y3, \t0

              XOR3        \t0, \y0, \y1, \y2             //  t0  = y0 ^ y1 ^ y2
              ELL32       \t0, \t0, \t1, \t2             // tmpy = ELL(t0)
              XOR3        \x3, \x3, \x0, \t0             //  x3 ^= x0 ^ tmpy 
              XOR3        \x4, \x4, \x1, \t0             //  x4 ^= x1 ^ tmpy
              XOR3        \x5, \x5, \x2, \t0             //  x5 ^= x2 ^ tmpy

              XOR3        \t0, \x0, \x1, \x2             //  t0  = x0 ^ x1 ^ x2
              ELL32       \t0, \t0, \t1, \t2             // tmpx = ELL(t0)
              XOR3        \y3, \y3, \y0, \t0             //  y3 ^= y0 ^ tmpx 
              XOR3        \y4, \y4, \y1, \t0             //  y4 ^= y1 ^ tmpx
              XOR3        \y5, \y5, \y2, \t0             //  y5 ^= y2 ^ tmpx
.endm
#endif

#if	( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
.macro SPARKLE_FWD_LINEAR  p0,  p1,  p2,  p3,  p4,  p5,  t0,  t1,  t2,  t3
              XOR3        \t0, \p0, \p1, \p2             //  t0  = (y0 || x0) ^ (y1 || x1) ^ (y2 || x2)
              ELL64       \t0, \t0, \t1, \t2, \t3        //  ELL(t0)     = (tmpx || tmpy)
              XOR3        \p3, \p3, \p0, \t0             //  (y3 || x3) ^= (y0 || x0) ^ (tmpx || tmpy) 
              XOR3        \p4, \p4, \p1, \t0             //  (y4 || x4) ^= (y1 || x1) ^ (tmpx || tmpy)
              XOR3        \p5, \p5, \p2, \t0             //  (y5 || x5) ^= (y2 || x2) ^ (tmpx || tmpy)
              #if !( ALZETTE_SPARKLE_FWD_UNROLL ) 
              // 0 1 2  3 4 5
              // 4 5 3  0 1 2
              // Branch swap of the x part
              mv          \t0, \p0                       
              mv          \p0, \p4
              mv          \p4, \p1  
              mv          \p1, \p5
              mv          \p5, \p2
              mv          \p2, \p3
              mv          \p3, \t0
              #endif
.endm

.macro SPARKLE_REV_LINEAR  p0,  p1,  p2,  p3,  p4,  p5,  t0,  t1,  t2,  t3
              #if !( ALZETTE_SPARKLE_REV_UNROLL ) 
              // 0 1 2  3 4 5
              // 3 4 5  2 0 1
              // Branch swap of the x part
              mv          \t0, \p2                       
              mv          \p2, \p5
              mv          \p5, \p1  
              mv          \p1, \p4
              mv          \p4, \p0
              mv          \p0, \p3
              mv          \p3, \t0
              #endif
              XOR3        \t0, \p0, \p1, \p2             //  t0  = (y0 || x0) ^ (y1 || x1) ^ (y2 || x2)
              ELL64       \t0, \t0, \t1, \t2, \t3        //  ELL(t0)     = (tmpx || tmpy)
              XOR3        \p3, \p3, \p0, \t0             //  (y3 || x3) ^= (y0 || x0) ^ (tmpx || tmpy) 
              XOR3        \p4, \p4, \p1, \t0             //  (y4 || x4) ^= (y1 || x1) ^ (tmpx || tmpy)
              XOR3        \p5, \p5, \p2, \t0             //  (y5 || x5) ^= (y2 || x2) ^ (tmpx || tmpy)
.endm
#endif

.macro XOR3 rd, x0, x1, x2
              xor          t6, \x1, \x2 
              xor         \rd, \x0,  t6
.endm

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/inverse ARXBOX
#if ( ALZETTE_RV64_TYPE1 )
.macro SPARKLE_FWD_ARXBOX rcb,  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2
              lwu         \t0,    0(\rcb)                // t0 = MEM[ rc +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_ENC \x0, \y0, \t0, \t1, \t2
              lwu         \t0,    4(\rcb)                // t0 = MEM[ rc +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_ENC \x1, \y1, \t0, \t1, \t2
              lwu         \t0,    8(\rcb)                // t0 = MEM[ rc +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_ENC \x2, \y2, \t0, \t1, \t2
              lwu         \t0,   12(\rcb)                // t0 = MEM[ rc + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_ENC \x3, \y3, \t0, \t1, \t2
              lwu         \t0,   16(\rcb)                // t0 = MEM[ rc + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_ENC \x4, \y4, \t0, \t1, \t2
              lwu         \t0,   20(\rcb)                // t0 = MEM[ rc + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_ENC \x5, \y5, \t0, \t1, \t2
.endm

.macro SPARKLE_REV_ARXBOX rcb,  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2 
              lwu         \t0,    0(\rcb)                // t0 = MEM[ rc +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_DEC \x0, \y0, \t0, \t1, \t2
              lwu         \t0,    4(\rcb)                // t0 = MEM[ rc +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_DEC \x1, \y1, \t0, \t1, \t2
              lwu         \t0,    8(\rcb)                // t0 = MEM[ rc +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_DEC \x2, \y2, \t0, \t1, \t2
              lwu         \t0,   12(\rcb)                // t0 = MEM[ rc + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_DEC \x3, \y3, \t0, \t1, \t2
              lwu         \t0,   16(\rcb)                // t0 = MEM[ rc + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_DEC \x4, \y4, \t0, \t1, \t2
              lwu         \t0,   20(\rcb)                // t0 = MEM[ rc + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_DEC \x5, \y5, \t0, \t1, \t2
.endm
#endif

#if ( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE5 )
.macro SPARKLE_FWD_ARXBOX rcb,  p0,  p1,  p2,  p3,  p4,  p5,  t0
              lwu         \t0,    0(\rcb)                // t0 = MEM[ rc +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_ENC \p0,      \t0
              lwu         \t0,    4(\rcb)                // t0 = MEM[ rc +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_ENC \p1,      \t0          
              lwu         \t0,    8(\rcb)                // t0 = MEM[ rc +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_ENC \p2,      \t0          
              lwu         \t0,   12(\rcb)                // t0 = MEM[ rc + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_ENC \p3,      \t0          
              lwu         \t0,   16(\rcb)                // t0 = MEM[ rc + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_ENC \p4,      \t0          
              lwu         \t0,   20(\rcb)                // t0 = MEM[ rc + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_ENC \p5,      \t0
.endm

.macro SPARKLE_REV_ARXBOX rcb,  p0,  p1,  p2,  p3,  p4,  p5,  t0
              lwu         \t0,    0(\rcb)                // t0 = MEM[ rc +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_DEC \p0,      \t0
              lwu         \t0,    4(\rcb)                // t0 = MEM[ rc +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_DEC \p1,      \t0          
              lwu         \t0,    8(\rcb)                // t0 = MEM[ rc +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_DEC \p2,      \t0          
              lwu         \t0,   12(\rcb)                // t0 = MEM[ rc + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_DEC \p3,      \t0          
              lwu         \t0,   16(\rcb)                // t0 = MEM[ rc + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_DEC \p4,      \t0          
              lwu         \t0,   20(\rcb)                // t0 = MEM[ rc + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_DEC \p5,      \t0 
.endm
#endif

#if ( ALZETTE_RV64_TYPE4 )
.macro SPARKLE_FWD_ARXBOX rcb, p0,  p1,  p2,  p3,  p4,  p5,  t0 
              alzette.whole.enci  \p0, \p0, 0
              alzette.whole.enci  \p1, \p1, 1
              alzette.whole.enci  \p2, \p2, 2
              alzette.whole.enci  \p3, \p3, 3
              alzette.whole.enci  \p4, \p4, 4
              alzette.whole.enci  \p5, \p5, 5
.endm

.macro SPARKLE_REV_ARXBOX rcb, p0,  p1,  p2,  p3,  p4,  p5,  t0
              alzette.whole.deci  \p0, \p0, 0
              alzette.whole.deci  \p1, \p1, 1
              alzette.whole.deci  \p2, \p2, 2
              alzette.whole.deci  \p3, \p3, 3
              alzette.whole.deci  \p4, \p4, 4
              alzette.whole.deci  \p5, \p5, 5
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE    implementation => add step counter
#if ( ALZETTE_RV64_TYPE1 ) 
.macro SPARKLE_FWD_ADDCNT rc, st, y0, y1, t0
              lw          \t0,    0(\rc)
              xor         \y0, \y0, \t0                  // y0 ^= rc
              #if  ( ALZETTE_SPARKLE_FWD_UNROLL )
              xori        \y1, \y1, \st                  // y1 ^= i
              #else
              xor         \y1, \y1, \st                  // y1 ^= i
	          #endif
.endm

.macro SPARKLE_REV_ADDCNT rc, st, y0, y1, t0
              lw          \t0,    0(\rc)
              xor         \y0, \y0, \t0                  // y0 ^= rc
              #if  ( ALZETTE_SPARKLE_REV_UNROLL )
              xori        \y1, \y1, \st                  // y1 ^= i
              #else
              xor         \y1, \y1, \st                  // y1 ^= i
	          #endif
.endm
#endif

#if	( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
.macro SPARKLE_FWD_ADDCNT rc, st, p0, p1, t0
              lwu         \t0,    0(\rc)
              slli        \t0, \t0,  32
              xor         \p0, \p0, \t0                  // y0 ^= rc

              #if  ( ALZETTE_SPARKLE_FWD_UNROLL )
              li          \t0, \st 
              slli        \t0, \t0,  32
              #else
              slli        \t0, \st,  32
              #endif
              xor         \p1, \p1, \t0                  // y1 ^= i
.endm

.macro SPARKLE_REV_ADDCNT rc, st, p0, p1, t0
              lwu         \t0,    0(\rc)
              slli        \t0, \t0,  32
              xor         \p0, \p0, \t0                  // y0 ^= rc

              #if  ( ALZETTE_SPARKLE_REV_UNROLL )
              li          \t0, \st 
              slli        \t0, \t0,  32
              #else
              slli        \t0, \st,  32
              #endif
              xor         \p1, \p1, \t0                  // y1 ^= i
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/ inverse step
#if ( ALZETTE_RV64_TYPE1 ) 
.macro SPARKLE_FWD_STEP           rcb,  rc,  st,  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2

              SPARKLE_FWD_ADDCNT       \rc, \st,                               \y0, \y1,                     \t0
              SPARKLE_FWD_ARXBOX \rcb,           \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2
              SPARKLE_FWD_LINEAR                 \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2

              addi                     \rc, \rc,   4          //          => rc +=  4
              #if !( ALZETTE_SPARKLE_FWD_UNROLL )
              addi                     \st, \st,   1          //  t2 = t2 + 1  => step++
              #endif
.endm     

.macro SPARKLE_REV_STEP           rcb,  rc,  st,  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2
              #if !( ALZETTE_SPARKLE_REV_UNROLL )
              addi                     \st, \st,  -1          //  t2 = t2 - 1   => step++
              #endif
              SPARKLE_REV_LINEAR                 \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2
              SPARKLE_REV_ARXBOX \rcb,           \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2
              SPARKLE_REV_ADDCNT       \rc, \st,                               \y0, \y1,                     \t0
              addi                     \rc, \rc,  -4          //           => rc -=  4
.endm
#endif

#if	( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
.macro SPARKLE_FWD_STEP           rcb,  rc,  st,  p0,  p1,  p2,  p3,  p4,  p5,  t0,  t1,  t2,  t3

              SPARKLE_FWD_ADDCNT       \rc, \st, \p0, \p1,                     \t0
              SPARKLE_FWD_ARXBOX \rcb,           \p0, \p1, \p2, \p3, \p4, \p5, \t0, 
              SPARKLE_FWD_LINEAR                 \p0, \p1, \p2, \p3, \p4, \p5, \t0, \t1, \t2, \t3

              addi                     \rc, \rc,   4          //          => rc +=  4
              #if !( ALZETTE_SPARKLE_FWD_UNROLL )
              addi                     \st, \st,   1          //  t2 = t2 + 1  => step++
              #endif
.endm     

.macro SPARKLE_REV_STEP           rcb,  rc,  st,  p0,  p1,  p2,  p3,  p4,  p5,  t0,  t1,  t2,  t3
              #if !( ALZETTE_SPARKLE_REV_UNROLL )
              addi                     \st, \st,  -1          //  t2 = t2 - 1   => step++
              #endif
              SPARKLE_REV_LINEAR                 \p0, \p1, \p2, \p3, \p4, \p5, \t0, \t1, \t2, \t3
              SPARKLE_REV_ARXBOX \rcb,           \p0, \p1, \p2, \p3, \p4, \p5, \t0
              SPARKLE_REV_ADDCNT       \rc, \st, \p0, \p1,                     \t0
              addi                     \rc, \rc,  -4          //           => rc -=  4
.endm       
#endif
// ----------------------------------------------------------------------------	
// SPARKLE    implementation => forward process

#if ( ALZETTE_SPARKLE_FWD_EXTERN )
.section .text  
.global sparkle_fwd
sparkle_fwd:  SPARKLE_FWD_PROLOGUE
              la           t0, SPARKLE_RCON              // t0 = &SPARKLE_RCON_POINTER
              mv           t1, t0                        // t1 = &SPARKLE_RCON_INDEX
#if ( ALZETTE_RV64_TYPE1 )
              SPARKLE_RD_STATE              s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9,  s10, s11
    #if ( ALZETTE_SPARKLE_FWD_UNROLL )          
              SPARKLE_FWD_STEP  t0, t1,  0, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6    
              SPARKLE_FWD_STEP  t0, t1,  1, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_FWD_STEP  t0, t1,  2, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6    
              SPARKLE_FWD_STEP  t0, t1,  3, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_FWD_STEP  t0, t1,  4, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6 
              SPARKLE_FWD_STEP  t0, t1,  5, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6 
              SPARKLE_FWD_STEP  t0, t1,  6, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11
    #else    
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              SPARKLE_FWD_STEP  t0, t1, t2, s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9,  s10, s11, t4, t5, t6    
              j                    0b                    //            goto 0
1:            SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9,  s10, s11
    #endif                           
#endif

#if ( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
              SPARKLE_RD_STATE              s0, s1, s2, s3, s4, s5  
    #if ( ALZETTE_SPARKLE_FWD_UNROLL )          
              //                             0   1   2   3   4   5
              //                             4   5   3   0   1   2   
              SPARKLE_FWD_STEP  t0, t1,  0, s0, s1, s2, s3, s4, s5, t4, t5, t6, a7    
              SPARKLE_FWD_STEP  t0, t1,  1, s4, s5, s3, s0, s1, s2, t4, t5, t6, a7
              SPARKLE_FWD_STEP  t0, t1,  2, s1, s2, s0, s4, s5, s3, t4, t5, t6, a7
              SPARKLE_FWD_STEP  t0, t1,  3, s5, s3, s4, s1, s2, s0, t4, t5, t6, a7
              SPARKLE_FWD_STEP  t0, t1,  4, s2, s0, s1, s5, s3, s4, t4, t5, t6, a7 
              SPARKLE_FWD_STEP  t0, t1,  5, s3, s4, s5, s2, s0, s1, t4, t5, t6, a7 
              SPARKLE_FWD_STEP  t0, t1,  6, s0, s1, s2, s3, s4, s5, t4, t5, t6, a7
              SPARKLE_WR_STATE              s4, s5, s3, s0, s1, s2, 
    #else    
              #if !( ALZETTE_RV64_TYPE4 )	
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              SPARKLE_FWD_STEP  t0, t1, t2, s0, s1, s2, s3, s4, s5, t4, t5, t6, a7    
              j                    0b                    //            goto 0
1:            SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5, 
              #else	
              #error "can't use ALZETTE_RV64_TYPE4 without ALZETTE_SPARKLE_FWD_UNROLL"
              #endif                           
    #endif
#endif
              SPARKLE_FWD_EPILOGUE
#endif

// ----------------------------------------------------------------------------	
// SPARKLE    implementation => Inverse

#if ( ALZETTE_SPARKLE_REV_EXTERN )
.section .text  
.global sparkle_rev
sparkle_rev:  SPARKLE_REV_PROLOGUE                      
              la           t0, SPARKLE_RCON              // t0 = &SPARKLE_RCON_POINTER
              addi         t1, t0, 4*6                   // t1 = &SPARKLE_RCON_INDEX
#if ( ALZETTE_RV64_TYPE1 )
              SPARKLE_RD_STATE              s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11
    #if ( ALZETTE_SPARKLE_REV_UNROLL )         
              SPARKLE_REV_STEP  t0, t1,  6, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_REV_STEP  t0, t1,  5, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6    
              SPARKLE_REV_STEP  t0, t1,  4, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_REV_STEP  t0, t1,  3, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6 
              SPARKLE_REV_STEP  t0, t1,  2, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6 
              SPARKLE_REV_STEP  t0, t1,  1, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_REV_STEP  t0, t1,  0, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11
    #else             
0:            blez         t2,     1f                    // if i <= 0, goto 1
              SPARKLE_REV_STEP  t0, t1, t2, s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9, s10, s11, t4, t5, t6     
              j                    0b                    //            goto 0
1:            SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9, s10, s11
    #endif
#endif

#if ( ALZETTE_RV64_TYPE2 ) || ( ALZETTE_RV64_TYPE3 ) || ( ALZETTE_RV64_TYPE4 ) || ( ALZETTE_RV64_TYPE5 )
              SPARKLE_RD_STATE              s0, s1, s2, s3, s4, s5
    #if ( ALZETTE_SPARKLE_REV_UNROLL )
              //                             0   1   2   3   4   5
              //                             3   4   5   2   0   1
              SPARKLE_REV_STEP  t0, t1,  6, s3, s4, s5, s2, s0, s1, t4, t5, t6, a7
              SPARKLE_REV_STEP  t0, t1,  5, s2, s0, s1, s5, s3, s4, t4, t5, t6, a7
              SPARKLE_REV_STEP  t0, t1,  4, s5, s3, s4, s1, s2, s0, t4, t5, t6, a7
              SPARKLE_REV_STEP  t0, t1,  3, s1, s2, s0, s4, s5, s3, t4, t5, t6, a7 
              SPARKLE_REV_STEP  t0, t1,  2, s4, s5, s3, s0, s1, s2, t4, t5, t6, a7 
              SPARKLE_REV_STEP  t0, t1,  1, s0, s1, s2, s3, s4, s5, t4, t5, t6, a7
              SPARKLE_REV_STEP  t0, t1,  0, s3, s4, s5, s2, s0, s1, t4, t5, t6, a7
              SPARKLE_WR_STATE              s3, s4, s5, s2, s0, s1 
    #else             
              #if !( ALZETTE_RV64_TYPE4 )	
0:            blez         t2,     1f                    // if i <= 0, goto 1
              SPARKLE_REV_STEP  t0, t1, t2, s0, s1, s2, s3, s4, s5, t4, t5, t6, a7     
              j                    0b                    //            goto 0
1:            SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5
              #else	
              #error "can't use ALZETTE_RV64_TYPE4 without ALZETTE_SPARKLE_FWD_UNROLL"
              #endif  
    #endif
#endif
              SPARKLE_REV_EPILOGUE
#endif

// ============================================================================
