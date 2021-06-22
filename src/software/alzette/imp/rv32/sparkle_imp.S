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

// s0  =>  state[  0 ] =  x0
// s1  =>  state[  2 ] =  x1
// s2  =>  state[  4 ] =  x2
// s3  =>  state[  6 ] =  x3
// s4  =>  state[  8 ] =  x4
// s5  =>  state[ 10 ] =  x5
// s6  =>  state[  1 ] =  y0
// s7  =>  state[  3 ] =  y1
// s8  =>  state[  5 ] =  y2
// s9  =>  state[  7 ] =  y3
// s10 =>  state[  9 ] =  y4
// s11 =>  state[ 11 ] =  y5


// ----------------------------------------------------------------------------
// SPARKLE384  implementation => RCON

#if ( SPARKLE_FWD_EXTERN ) || ( SPARKLE_REV_EXTERN )
.section .rodata

.balign 4

SPARKLE_RCON: .word 0xB7E15162
              .word 0xBF715880
              .word 0x38B4DA56
              .word 0x324E7738
              .word 0xBB1185EB
              .word 0x4F7C7B57
              .word 0xCFBFA1C8
              .word 0xC2B3293D
#endif

// ============================================================================
// SPARKLE    implementation => forward/inverse prologue + epilogue

.macro SPARKLE_FWD_PROLOGUE
              addi         sp, sp, -48                    // adjust SP
              sw           s0,   0(sp)                    // push s0
              sw           s1,   4(sp)                    // push s1
              sw           s2,   8(sp)                    // push s2
              sw           s3,  12(sp)                    // push s3
              sw           s4,  16(sp)                    // push s4
              sw           s5,  20(sp)                    // push s5
              sw           s6,  24(sp)                    // push s6
              sw           s7,  28(sp)                    // push s7
              sw           s8,  32(sp)                    // push s8
              sw           s9,  36(sp)                    // push s9
              sw           s10, 40(sp)                    // push s10
              sw           s11, 44(sp)                    // push s11

              li           t2,   0                        // t2 =  0              => i = 0
              li           t3,   7                        // t3 =  7              => n = 7
	
.endm

.macro SPARKLE_FWD_EPILOGUE
              lw           s0,   0(sp)                    // pop  s0
              lw           s1,   4(sp)                    // pop  s1
              lw           s2,   8(sp)                    // pop  s2
              lw           s3,  12(sp)                    // pop  s3
              lw           s4,  16(sp)                    // pop  s4
              lw           s5,  20(sp)                    // pop  s5
              lw           s6,  24(sp)                    // pop  s6
              lw           s7,  28(sp)                    // pop  s7
              lw           s8,  32(sp)                    // pop  s8
              lw           s9,  36(sp)                    // pop  s9
              lw           s10, 40(sp)                    // pop  s10
              lw           s11, 44(sp)                    // pop  s11
              addi         sp, sp,  48                   // adjust SP

              ret                                        // return
.endm

.macro SPARKLE_REV_PROLOGUE
              addi         sp, sp, -48                    // adjust SP
              sw           s0,   0(sp)                    // push s0
              sw           s1,   4(sp)                    // push s1
              sw           s2,   8(sp)                    // push s2
              sw           s3,  12(sp)                    // push s3
              sw           s4,  16(sp)                    // push s4
              sw           s5,  20(sp)                    // push s5
              sw           s6,  24(sp)                    // push s6
              sw           s7,  28(sp)                    // push s7
              sw           s8,  32(sp)                    // push s8
              sw           s9,  36(sp)                    // push s9
              sw           s10, 40(sp)                    // push s10
              sw           s11, 44(sp)                    // push s11

              li           t2,      7                    // t2 =   7             
.endm

.macro SPARKLE_REV_EPILOGUE
              lw           s0,   0(sp)                    // pop  s0
              lw           s1,   4(sp)                    // pop  s1
              lw           s2,   8(sp)                    // pop  s2
              lw           s3,  12(sp)                    // pop  s3
              lw           s4,  16(sp)                    // pop  s4
              lw           s5,  20(sp)                    // pop  s5
              lw           s6,  24(sp)                    // pop  s6
              lw           s7,  28(sp)                    // pop  s7
              lw           s8,  32(sp)                    // pop  s8
              lw           s9,  36(sp)                    // pop  s9
              lw           s10, 40(sp)                    // pop  s10
              lw           s11, 44(sp)                    // pop  s11
              addi         sp, sp,  48                   // adjust SP

              ret                                        // return
.endm

// ----------------------------------------------------------------------------
// SPARKLE implementation => SPARKLE_RD_STATE
.macro  SPARKLE_RD_STATE   x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5              
              lw          \x0,   0(a0)                    // s0 = MEM[ a0 +  0 ]  => x0 = state[  0 ]
              lw          \x1,   8(a0)                    // s1 = MEM[ a0 +  8 ]  => x1 = state[  2 ]
              lw          \x2,  16(a0)                    // s2 = MEM[ a0 + 16 ]  => x2 = state[  4 ]
              lw          \x3,  24(a0)                    // s3 = MEM[ a0 + 24 ]  => x3 = state[  6 ]
              lw          \x4,  32(a0)                    // s4 = MEM[ a0 + 32 ]  => x4 = state[  8 ]
              lw          \x5,  40(a0)                    // s5 = MEM[ a0 + 40 ]  => x5 = state[ 10 ]

              lw          \y0,   4(a0)                    // s6 = MEM[ a0 +  4 ]  => y0 = state[  1 ]
              lw          \y1,  12(a0)                    // s7 = MEM[ a0 + 12 ]  => y1 = state[  3 ]
              lw          \y2,  20(a0)                    // s8 = MEM[ a0 + 20 ]  => y2 = state[  5 ]
              lw          \y3,  28(a0)                    // s9 = MEM[ a0 + 28 ]  => y3 = state[  7 ]
              lw          \y4,  36(a0)                    // s10= MEM[ a0 + 36 ]  => y4 = state[  9 ]
              lw          \y5,  44(a0)                    // s11= MEM[ a0 + 44 ]  => y5 = state[ 11 ]
.endm
// ----------------------------------------------------------------------------
// SPARKLE implementation => SPARKLE_WR_STATE
.macro  SPARKLE_WR_STATE   x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5              
              sw          \x0,   0(a0)                    // s0 ->MEM[ a0 +  0 ]  => x0 -> state[  0 ]
              sw          \x1,   8(a0)                    // s1 ->MEM[ a0 +  8 ]  => x1 -> state[  2 ]
              sw          \x2,  16(a0)                    // s2 ->MEM[ a0 + 16 ]  => x2 -> state[  4 ]
              sw          \x3,  24(a0)                    // s3 ->MEM[ a0 + 24 ]  => x3 -> state[  6 ]
              sw          \x4,  32(a0)                    // s4 ->MEM[ a0 + 32 ]  => x4 -> state[  8 ]
              sw          \x5,  40(a0)                    // s5 ->MEM[ a0 + 40 ]  => x5 -> state[ 10 ]

              sw          \y0,   4(a0)                    // s6 ->MEM[ a0 +  4 ]  => y0 -> state[  1 ]
              sw          \y1,  12(a0)                    // s7 ->MEM[ a0 + 12 ]  => y1 -> state[  3 ]
              sw          \y2,  20(a0)                    // s8 ->MEM[ a0 + 20 ]  => y2 -> state[  5 ]
              sw          \y3,  28(a0)                    // s9 ->MEM[ a0 + 28 ]  => y3 -> state[  7 ]
              sw          \y4,  36(a0)                    // s10->MEM[ a0 + 36 ]  => y4 -> state[  9 ]
              sw          \y5,  44(a0)                    // s11->MEM[ a0 + 44 ]  => y5 -> state[ 11 ]
.endm

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/inverse linear layer

.macro SPARKLE_FWD_LINEAR  x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2 
              XOR3        \t0, \x0, \x1, \x2             //  t0  = x0 ^ x1 ^ x2
              ELL         \t0, \t0, \t1, \t2             // tmpx = ELL(t0)
              XOR3        \y3, \y3, \y0, \t0             //  y3 ^= y0 ^ tmpx 
              XOR3        \y4, \y4, \y1, \t0             //  y4 ^= y1 ^ tmpx
              XOR3        \y5, \y5, \y2, \t0             //  y5 ^= y2 ^ tmpx

              XOR3        \t0, \y0, \y1, \y2             //  t0  = y0 ^ y1 ^ y2
              ELL         \t0, \t0, \t1, \t2             // tmpy = ELL(t0)
              XOR3        \x3, \x3, \x0, \t0             //  x3 ^= x0 ^ tmpy 
              XOR3        \x4, \x4, \x1, \t0             //  x4 ^= x1 ^ tmpy
              XOR3        \x5, \x5, \x2, \t0             //  x5 ^= x2 ^ tmpy
              #if !( SPARKLE_FWD_UNROLL )
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
              #endif
.endm

.macro SPARKLE_REV_LINEAR  x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2  
              #if !( SPARKLE_REV_UNROLL )
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
              #endif
              XOR3        \t0, \y0, \y1, \y2             //  t0  = y0 ^ y1 ^ y2
              ELL         \t0, \t0, \t1, \t2             // tmpy = ELL(t0)
              XOR3        \x3, \x3, \x0, \t0             //  x3 ^= x0 ^ tmpy 
              XOR3        \x4, \x4, \x1, \t0             //  x4 ^= x1 ^ tmpy
              XOR3        \x5, \x5, \x2, \t0             //  x5 ^= x2 ^ tmpy

              XOR3        \t0, \x0, \x1, \x2             //  t0  = x0 ^ x1 ^ x2
              ELL         \t0, \t0, \t1, \t2             // tmpx = ELL(t0)
              XOR3        \y3, \y3, \y0, \t0             //  y3 ^= y0 ^ tmpx 
              XOR3        \y4, \y4, \y1, \t0             //  y4 ^= y1 ^ tmpx
              XOR3        \y5, \y5, \y2, \t0             //  y5 ^= y2 ^ tmpx
.endm

.macro XOR3 rd, x0, x1, x2
              xor          t6, \x1, \x2 
              xor         \rd, \x0,  t6
.endm

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/inverse ARXBOX
#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
.macro SPARKLE_FWD_ARXBOX rcb, x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2 
              lw          \t0,    0(\rcb)                 // t0 = MEM[ rc +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_ENC \x0, \y0, \t0, \t1, \t2
              lw          \t0,    4(\rcb)                 // t0 = MEM[ rc +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_ENC \x1, \y1, \t0, \t1, \t2
              lw          \t0,    8(\rcb)                 // t0 = MEM[ rc +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_ENC \x2, \y2, \t0, \t1, \t2
              lw          \t0,   12(\rcb)                 // t0 = MEM[ rc + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_ENC \x3, \y3, \t0, \t1, \t2
              lw          \t0,   16(\rcb)                 // t0 = MEM[ rc + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_ENC \x4, \y4, \t0, \t1, \t2
              lw          \t0,   20(\rcb)                 // t0 = MEM[ rc + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_ENC \x5, \y5, \t0, \t1, \t2
.endm

.macro SPARKLE_REV_ARXBOX rcb, x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2 
              lw          \t0,    0(\rcb)                 // t0 = MEM[ rc +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_DEC \x0, \y0, \t0, \t1, \t2
              lw          \t0,    4(\rcb)                 // t0 = MEM[ rc +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_DEC \x1, \y1, \t0, \t1, \t2
              lw          \t0,    8(\rcb)                 // t0 = MEM[ rc +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_DEC \x2, \y2, \t0, \t1, \t2
              lw          \t0,   12(\rcb)                 // t0 = MEM[ rc + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_DEC \x3, \y3, \t0, \t1, \t2
              lw          \t0,   16(\rcb)                 // t0 = MEM[ rc + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_DEC \x4, \y4, \t0, \t1, \t2
              lw          \t0,   20(\rcb)                 // t0 = MEM[ rc + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_DEC \x5, \y5, \t0, \t1, \t2
.endm
#endif

#if ( RV32_TYPE4 )
.macro SPARKLE_FWD_ARXBOX   rcb, x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2
              alz.whole.enci.x \t0, \x0, \y0,  0
              alz.whole.enci.y \y0, \x0, \y0,  0
              mv               \x0, \t0
              alz.whole.enci.x \t0, \x1, \y1,  1
              alz.whole.enci.y \y1, \x1, \y1,  1
              mv               \x1, \t0
              alz.whole.enci.x \t0, \x2, \y2,  2
              alz.whole.enci.y \y2, \x2, \y2,  2
              mv               \x2, \t0
              alz.whole.enci.x \t0, \x3, \y3,  3
              alz.whole.enci.y \y3, \x3, \y3,  3
              mv               \x3, \t0
              alz.whole.enci.x \t0, \x4, \y4,  4
              alz.whole.enci.y \y4, \x4, \y4,  4
              mv               \x4, \t0
              alz.whole.enci.x \t0, \x5, \y5,  5
              alz.whole.enci.y \y5, \x5, \y5,  5
              mv               \x5, \t0
.endm

.macro SPARKLE_REV_ARXBOX   rcb, x0, x1, x2, x3, x4, x5, y0, y1, y2, y3, y4, y5, t0, t1, t2
              alz.whole.deci.x \t0, \x0, \y0,  0
              alz.whole.deci.y \y0, \x0, \y0,  0
              mv               \x0, \t0
              alz.whole.deci.x \t0, \x1, \y1,  1
              alz.whole.deci.y \y1, \x1, \y1,  1
              mv               \x1, \t0
              alz.whole.deci.x \t0, \x2, \y2,  2
              alz.whole.deci.y \y2, \x2, \y2,  2
              mv               \x2, \t0
              alz.whole.deci.x \t0, \x3, \y3,  3
              alz.whole.deci.y \y3, \x3, \y3,  3
              mv               \x3, \t0
              alz.whole.deci.x \t0, \x4, \y4,  4
              alz.whole.deci.y \y4, \x4, \y4,  4
              mv               \x4, \t0
              alz.whole.deci.x \t0, \x5, \y5,  5
              alz.whole.deci.y \y5, \x5, \y5,  5
              mv               \x5, \t0
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/ inverse add step counter

.macro SPARKLE_FWD_ADDCNT rc, st, y0, y1, t0
              lw          \t0,    0(\rc)
              xor         \y0, \y0, \t0                  // y0 ^= rc
              #if  ( SPARKLE_FWD_UNROLL )
              xori        \y1, \y1, \st                  // y1 ^= i
              #else
              xor         \y1, \y1, \st                  // y1 ^= i
	          #endif
.endm

.macro SPARKLE_REV_ADDCNT rc, st, y0, y1, t0
              lw          \t0,    0(\rc)
              xor         \y0, \y0, \t0                  // y0 ^= rc
              #if  ( SPARKLE_REV_UNROLL )
              xori        \y1, \y1, \st                  // y1 ^= i
              #else
              xor         \y1, \y1, \st                  // y1 ^= i
	          #endif
.endm
// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/ inverse step
	
#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 ) || ( RV32_TYPE4 )
.macro SPARKLE_FWD_STEP           rcb,  rc,  st,  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2

              SPARKLE_FWD_ADDCNT       \rc, \st,                               \y0, \y1,                     \t0
              SPARKLE_FWD_ARXBOX \rcb,           \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2
              SPARKLE_FWD_LINEAR                 \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2

              addi                     \rc, \rc,   4          //          => rc +=  4
              #if !( SPARKLE_FWD_UNROLL )
              addi                     \st, \st,   1          //  t2 = t2 + 1  => step++
              #endif
.endm     

.macro SPARKLE_REV_STEP           rcb,  rc,  st,  x0,  x1,  x2,  x3,  x4,  x5,  y0,  y1,  y2,  y3,  y4,  y5,  t0,  t1,  t2
              #if !( SPARKLE_REV_UNROLL )
              addi                     \st, \st,  -1          //  t2 = t2 - 1   => step++
              #endif
              SPARKLE_REV_LINEAR                 \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2
              SPARKLE_REV_ARXBOX \rcb,           \x0, \x1, \x2, \x3, \x4, \x5, \y0, \y1, \y2, \y3, \y4, \y5, \t0, \t1, \t2
              SPARKLE_REV_ADDCNT       \rc, \st,                               \y0, \y1,                     \t0
              addi                     \rc, \rc,  -4          //           => rc -=  4
.endm       

#endif

// ----------------------------------------------------------------------------	
// SPARKLE    implementation => forward process

#if ( SPARKLE_FWD_EXTERN )
.section .text  
.global sparkle_fwd
sparkle_fwd:  SPARKLE_FWD_PROLOGUE
              la           t0, SPARKLE_RCON              // t0 = &SPARKLE_RCON_POINTER
              mv           t1, t0                        // t1 = &SPARKLE_RCON_INDEX
              //               rcb  rc  st  x0  x1  x2  x3  x4  x5   y0   y1   y2   y3    y4   y5  t0  t1  t2
              SPARKLE_RD_STATE              s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9,  s10, s11
#if ( SPARKLE_FWD_UNROLL )          
              //                             0   1   2   3   4   5
              //                             4   5   3   0   1   2   
              SPARKLE_FWD_STEP  t0, t1,  0, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6    
              SPARKLE_FWD_STEP  t0, t1,  1, s4, s5, s3, s0, s1, s2,  s10, s11, s9 , s6 , s7 , s8 , t4, t5, t6
              SPARKLE_FWD_STEP  t0, t1,  2, s1, s2, s0, s4, s5, s3,  s7 , s8 , s6 , s10, s11, s9 , t4, t5, t6    
              SPARKLE_FWD_STEP  t0, t1,  3, s5, s3, s4, s1, s2, s0,  s11, s9 , s10, s7 , s8 , s6 , t4, t5, t6
              SPARKLE_FWD_STEP  t0, t1,  4, s2, s0, s1, s5, s3, s4,  s8 , s6 , s7 , s11, s9 , s10, t4, t5, t6 
              SPARKLE_FWD_STEP  t0, t1,  5, s3, s4, s5, s2, s0, s1,  s9 , s10, s11, s8 , s6 , s7 , t4, t5, t6 
              SPARKLE_FWD_STEP  t0, t1,  6, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_WR_STATE              s4, s5, s3, s0, s1, s2,  s10, s11, s9 , s6 , s7 , s8 
#else    
              #if !( RV32_TYPE4 )	
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              SPARKLE_FWD_STEP  t0, t1, t2, s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9,  s10, s11, t4, t5, t6    
              j                    0b                    //            goto 0
1:            SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9,  s10, s11
              #else	
              #error "can't use RV32_TYPE4 without SPARKLE_FWD_UNROLL"
              #endif                           
#endif
              SPARKLE_FWD_EPILOGUE
#endif

// ----------------------------------------------------------------------------	
// SPARKLE    implementation => Inverse

#if ( SPARKLE_REV_EXTERN )
.section .text  
.global sparkle_rev
sparkle_rev:  SPARKLE_REV_PROLOGUE                      
              la           t0, SPARKLE_RCON              // t0 = &SPARKLE_RCON_POINTER
              addi         t1, t0, 4*6                   // t1 = &SPARKLE_RCON_INDEX
              //               rcb  rc  st  x0  x1  x2  x3  x4  x5   y0   y1   y2   y3   y4   y5  t0  t1  t2
              SPARKLE_RD_STATE              s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11
#if ( SPARKLE_REV_UNROLL )         
              //                             0   1   2   3   4   5
              //                             3   4   5   2   0   1
              SPARKLE_REV_STEP  t0, t1,  6, s3, s4, s5, s2, s0, s1,  s9 , s10, s11, s8 , s6 , s7 , t4, t5, t6
              SPARKLE_REV_STEP  t0, t1,  5, s2, s0, s1, s5, s3, s4,  s8 , s6 , s7 , s11, s9 , s10, t4, t5, t6    
              SPARKLE_REV_STEP  t0, t1,  4, s5, s3, s4, s1, s2, s0,  s11, s9 , s10, s7 , s8 , s6 , t4, t5, t6
              SPARKLE_REV_STEP  t0, t1,  3, s1, s2, s0, s4, s5, s3,  s7 , s8 , s6 , s10, s11, s9 , t4, t5, t6 
              SPARKLE_REV_STEP  t0, t1,  2, s4, s5, s3, s0, s1, s2,  s10, s11, s9 , s6 , s7 , s8 , t4, t5, t6 
              SPARKLE_REV_STEP  t0, t1,  1, s0, s1, s2, s3, s4, s5,  s6 , s7 , s8 , s9 , s10, s11, t4, t5, t6
              SPARKLE_REV_STEP  t0, t1,  0, s3, s4, s5, s2, s0, s1,  s9 , s10, s11, s8 , s6 , s7 , t4, t5, t6
              SPARKLE_WR_STATE              s3, s4, s5, s2, s0, s1,  s9 , s10, s11, s8 , s6 , s7 
#else             
              #if !( RV32_TYPE4 )	
0:            blez         t2,     1f                    // if i <= 0, goto 1
              SPARKLE_REV_STEP  t0, t1, t2, s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9, s10, s11, t4, t5, t6     
              j                    0b                    //            goto 0
1:            SPARKLE_WR_STATE              s0, s1, s2, s3, s4, s5,  s6,  s7,  s8,  s9, s10, s11
              #else	
              #error "can't use RV32_TYPE4 without SPARKLE_FWD_UNROLL"
              #endif  
#endif
              SPARKLE_REV_EPILOGUE
#endif

// ============================================================================
