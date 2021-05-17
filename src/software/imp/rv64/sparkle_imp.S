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

#if ( RV64_TYPE1 )          
              lwu          s0,   0(a0)                    // s0 = MEM[ a0 +  0 ]  => x0 = state[  0 ]
              lwu          s1,   8(a0)                    // s1 = MEM[ a0 +  8 ]  => x1 = state[  2 ]
              lwu          s2,  16(a0)                    // s2 = MEM[ a0 + 16 ]  => x2 = state[  4 ]
              lwu          s3,  24(a0)                    // s3 = MEM[ a0 + 24 ]  => x3 = state[  6 ]
              lwu          s4,  32(a0)                    // s4 = MEM[ a0 + 32 ]  => x4 = state[  8 ]
              lwu          s5,  40(a0)                    // s5 = MEM[ a0 + 40 ]  => x5 = state[ 10 ]
              lwu          s6,   4(a0)                    // s6 = MEM[ a0 +  4 ]  => y0 = state[  1 ]
              lwu          s7,  12(a0)                    // s7 = MEM[ a0 + 12 ]  => y1 = state[  3 ]
              lwu          s8,  20(a0)                    // s8 = MEM[ a0 + 20 ]  => y2 = state[  5 ]
              lwu          s9,  28(a0)                    // s9 = MEM[ a0 + 28 ]  => y3 = state[  7 ]
              lwu          s10, 36(a0)                    // s10= MEM[ a0 + 36 ]  => y4 = state[  9 ]
              lwu          s11, 44(a0)                    // s11= MEM[ a0 + 44 ]  => y5 = state[ 11 ]
#else
              ld           s0,   0(a0)                    // s0 = MEM[ a0 +  0 ]  => {y0 || x0} = state[  0 ]
              ld           s1,   8(a0)                    // s1 = MEM[ a0 +  8 ]  => {y1 || x1} = state[  2 ]
              ld           s2,  16(a0)                    // s2 = MEM[ a0 + 16 ]  => {y2 || x2} = state[  4 ]
              ld           s3,  24(a0)                    // s3 = MEM[ a0 + 24 ]  => {y3 || x3} = state[  6 ]
              ld           s4,  32(a0)                    // s4 = MEM[ a0 + 32 ]  => {y4 || x4} = state[  8 ]
              ld           s5,  40(a0)                    // s5 = MEM[ a0 + 40 ]  => {y5 || x5} = state[ 10 ]
#endif
              li           t2,   0                        // t2 =  0              => i = 0
              li           t3,   7                        // t3 =  7              => n = 7
	
.endm

.macro SPARKLE_FWD_EPILOGUE
#if(RV64_TYPE1)
              sw           s0,   0(a0)                    // s0 -> MEM[ a0 +  0 ]  => x0 -> state[  0 ]
              sw           s1,   8(a0)                    // s1 -> MEM[ a0 +  8 ]  => x1 -> state[  2 ]
              sw           s2,  16(a0)                    // s2 -> MEM[ a0 + 16 ]  => x2 -> state[  4 ]
              sw           s3,  24(a0)                    // s3 -> MEM[ a0 + 24 ]  => x3 -> state[  6 ]
              sw           s4,  32(a0)                    // s4 -> MEM[ a0 + 32 ]  => x4 -> state[  8 ]
              sw           s5,  40(a0)                    // s5 -> MEM[ a0 + 40 ]  => x5 -> state[ 10 ]
              sw           s6,   4(a0)                    // s6 -> MEM[ a0 +  4 ]  => y0 -> state[  1 ]
              sw           s7,  12(a0)                    // s7 -> MEM[ a0 + 12 ]  => y1 -> state[  3 ]
              sw           s8,  20(a0)                    // s8 -> MEM[ a0 + 20 ]  => y2 -> state[  5 ]
              sw           s9,  28(a0)                    // s9 -> MEM[ a0 + 28 ]  => y3 -> state[  7 ]
              sw           s10, 36(a0)                    // s10-> MEM[ a0 + 36 ]  => y4 -> state[  9 ]
              sw           s11, 44(a0)                    // s11-> MEM[ a0 + 44 ]  => y5 -> state[ 11 ]
#else
              sd           s0,   0(a0)                    // s0 -> MEM[ a0 +  0 ]  => {y0 || x0} -> state[  0 ]
              sd           s1,   8(a0)                    // s1 -> MEM[ a0 +  8 ]  => {y1 || x1} -> state[  2 ]
              sd           s2,  16(a0)                    // s2 -> MEM[ a0 + 16 ]  => {y2 || x2} -> state[  4 ]
              sd           s3,  24(a0)                    // s3 -> MEM[ a0 + 24 ]  => {y3 || x3} -> state[  6 ]
              sd           s4,  32(a0)                    // s4 -> MEM[ a0 + 32 ]  => {y4 || x4} -> state[  8 ]
              sd           s5,  40(a0)                    // s5 -> MEM[ a0 + 40 ]  => {y5 || x5} -> state[ 10 ]
#endif
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

#if ( RV64_TYPE1 )          
              lwu          s0,   0(a0)                    // s0 = MEM[ a0 +  0 ]  => x0 = state[  0 ]
              lwu          s1,   8(a0)                    // s1 = MEM[ a0 +  8 ]  => x1 = state[  2 ]
              lwu          s2,  16(a0)                    // s2 = MEM[ a0 + 16 ]  => x2 = state[  4 ]
              lwu          s3,  24(a0)                    // s3 = MEM[ a0 + 24 ]  => x3 = state[  6 ]
              lwu          s4,  32(a0)                    // s4 = MEM[ a0 + 32 ]  => x4 = state[  8 ]
              lwu          s5,  40(a0)                    // s5 = MEM[ a0 + 40 ]  => x5 = state[ 10 ]
              lwu          s6,   4(a0)                    // s6 = MEM[ a0 +  4 ]  => y0 = state[  1 ]
              lwu          s7,  12(a0)                    // s7 = MEM[ a0 + 12 ]  => y1 = state[  3 ]
              lwu          s8,  20(a0)                    // s8 = MEM[ a0 + 20 ]  => y2 = state[  5 ]
              lwu          s9,  28(a0)                    // s9 = MEM[ a0 + 28 ]  => y3 = state[  7 ]
              lwu          s10, 36(a0)                    // s10= MEM[ a0 + 36 ]  => y4 = state[  9 ]
              lwu          s11, 44(a0)                    // s11= MEM[ a0 + 44 ]  => y5 = state[ 11 ]
#else
              ld           s0,   0(a0)                    // s0 = MEM[ a0 +  0 ]  => {y0 || x0} = state[  0 ]
              ld           s1,   8(a0)                    // s1 = MEM[ a0 +  8 ]  => {y1 || x1} = state[  2 ]
              ld           s2,  16(a0)                    // s2 = MEM[ a0 + 16 ]  => {y2 || x2} = state[  4 ]
              ld           s3,  24(a0)                    // s3 = MEM[ a0 + 24 ]  => {y3 || x3} = state[  6 ]
              ld           s4,  32(a0)                    // s4 = MEM[ a0 + 32 ]  => {y4 || x4} = state[  8 ]
              ld           s5,  40(a0)                    // s5 = MEM[ a0 + 40 ]  => {y5 || x5} = state[ 10 ]
#endif

              li           t2,      7                    // t2 =   7             
.endm

.macro SPARKLE_REV_EPILOGUE
              SPARKLE_FWD_EPILOGUE
.endm

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/inverse linear layer

.macro SPARKLE_FWD_LINEAR 
#if ( RV64_TYPE1 )
              XOR3         t4,  s0,  s1,  s2             //  t4  = x0 ^ x1 ^ x2
              ELL32        t4,  t4,  t5,  t6             // tmpx = ELL(t4)
              XOR3         s9,  s9,  s6,  t4             //  y3 ^= y0 ^ tmpx 
              XOR3         s10, s10, s7,  t4             //  y4 ^= y1 ^ tmpx
              XOR3         s11, s11, s8,  t4             //  y5 ^= y2 ^ tmpx

              XOR3         t4,  s6,  s7,  s8             //  t4  = y0 ^ y1 ^ y2
              ELL32        t4,  t4,  t5,  t6             // tmpy = ELL(t4)
              XOR3         s3,  s3,  s0,  t4             //  x3 ^= x0 ^ tmpy 
              XOR3         s4,  s4,  s1,  t4             //  x4 ^= x1 ^ tmpy
              XOR3         s5,  s5,  s2,  t4             //  x5 ^= x2 ^ tmpy
#else
              XOR3         t4,  s0,  s1,  s2             //  t4  = (y0 || x0) ^ (y1 || x1) ^ (y2 || x2)
              ELL64        t4,  t4,  t5,  t6, a7         //  ELL(t4)     = (tmpx || tmpy)
              XOR3         s3,  s3,  s0,  t4             //  (y3 || x3) ^= (y0 || x0) ^ (tmpx || tmpy) 
              XOR3         s4,  s4,  s1,  t4             //  (y4 || x4) ^= (y1 || x1) ^ (tmpx || tmpy)
              XOR3         s5,  s5,  s2,  t4             //  (y5 || x5) ^= (y2 || x2) ^ (tmpx || tmpy)
#endif
              // 0 1 2  3 4 5
              // 4 5 3  0 1 2
              // Branch swap of the x part
              mv           t4,  s0                       
              mv           s0,  s4
              mv           s4,  s1  
              mv           s1,  s5
              mv           s5,  s2
              mv           s2,  s3
              mv           s3,  t4
#if ( RV64_TYPE1 )
              // Branch swap of the y part
              mv           t4,  s6
              mv           s6,  s10
              mv           s10, s7  
              mv           s7,  s11
              mv           s11, s8
              mv           s8,  s9
              mv           s9,  t4
#endif
.endm

.macro SPARKLE_REV_LINEAR 

              // 0 1 2  3 4 5
              // 3 4 5  2 0 1
              // Branch swap of the x part
              mv           t4,  s2                       
              mv           s2,  s5
              mv           s5,  s1  
              mv           s1,  s4
              mv           s4,  s0
              mv           s0,  s3
              mv           s3,  t4
#if ( RV64_TYPE1 )
              // Branch swap of the y part
              mv           t4,  s8
              mv           s8,  s11
              mv           s11, s7  
              mv           s7,  s10
              mv           s10, s6
              mv           s6,  s9
              mv           s9,  t4
#endif

#if ( RV64_TYPE1 )
              XOR3         t4,  s6,  s7,  s8             //  t4  = y0 ^ y1 ^ y2
              ELL32        t4,  t4,  t5,  t6             // tmpx = ELL(t4)
              XOR3         s3,  s3,  s0,  t4             //  x3 ^= x0 ^ tmpy 
              XOR3         s4,  s4,  s1,  t4             //  x4 ^= x1 ^ tmpy
              XOR3         s5,  s5,  s2,  t4             //  x5 ^= x2 ^ tmpy

              XOR3         t4,  s0,  s1,  s2             //  t4  = x0 ^ x1 ^ x2
              ELL32        t4,  t4,  t5,  t6             // tmpx = ELL(t4)
              XOR3         s9,  s9,  s6,  t4             //  y3 ^= y0 ^ tmpx 
              XOR3         s10, s10, s7,  t4             //  y4 ^= y1 ^ tmpx
              XOR3         s11, s11, s8,  t4             //  y5 ^= y2 ^ tmpx
#else
              XOR3         t4,  s0,  s1,  s2             //  t4  = (y0 || x0) ^ (y1 || x1) ^ (y2 || x2)
              ELL64        t4,  t4,  t5,  t6, a7         //  ELL(t4)     = (tmpx || tmpy)
              XOR3         s3,  s3,  s0,  t4             //  (y3 || x3) ^= (y0 || x0) ^ (tmpx || tmpy) 
              XOR3         s4,  s4,  s1,  t4             //  (y4 || x4) ^= (y1 || x1) ^ (tmpx || tmpy)
              XOR3         s5,  s5,  s2,  t4             //  (y5 || x5) ^= (y2 || x2) ^ (tmpx || tmpy)
#endif
.endm

.macro XOR3 rd, x0, x1, x2
              xor          t6, \x1, \x2 
              xor         \rd, \x0,  t6
.endm

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/inverse ARXBOX
#if ( RV64_TYPE1 )
.macro SPARKLE_FWD_ARXBOX 
              lwu         t4,    0(t0)                 // t4 = MEM[ t0 +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_ENC s0, s6,  t4, t5, t6
              lwu         t4,    4(t0)                 // t4 = MEM[ t0 +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_ENC s1, s7,  t4, t5, t6
              lwu         t4,    8(t0)                 // t4 = MEM[ t0 +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_ENC s2, s8,  t4, t5, t6
              lwu         t4,   12(t0)                 // t4 = MEM[ t0 + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_ENC s3, s9,  t4, t5, t6
              lwu         t4,   16(t0)                 // t4 = MEM[ t0 + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_ENC s4, s10, t4, t5, t6
              lwu         t4,   20(t0)                 // t4 = MEM[ t0 + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_ENC s5, s11, t4, t5, t6
.endm

.macro SPARKLE_REV_ARXBOX 
              lwu         t4,    0(t0)                 // t4 = MEM[ t0 +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_DEC s0, s6,  t4, t5, t6
              lwu         t4,    4(t0)                 // t4 = MEM[ t0 +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_DEC s1, s7,  t4, t5, t6
              lwu         t4,    8(t0)                 // t4 = MEM[ t0 +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_DEC s2, s8,  t4, t5, t6
              lwu         t4,   12(t0)                 // t4 = MEM[ t0 + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_DEC s3, s9,  t4, t5, t6
              lwu         t4,   16(t0)                 // t4 = MEM[ t0 + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_DEC s4, s10, t4, t5, t6
              lwu         t4,   20(t0)                 // t4 = MEM[ t0 + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_DEC s5, s11, t4, t5, t6
.endm
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
.macro SPARKLE_FWD_ARXBOX 
              lwu         t4,  0(t0)                 // t4 = MEM[ t0 +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_ENC s0,    t4
              lwu         t4,  4(t0)                 // t4 = MEM[ t0 +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_ENC s1,    t4
              lwu         t4,  8(t0)                 // t4 = MEM[ t0 +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_ENC s2,    t4
              lwu         t4, 12(t0)                 // t4 = MEM[ t0 + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_ENC s3,    t4
              lwu         t4, 16(t0)                 // t4 = MEM[ t0 + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_ENC s4,    t4
              lwu         t4, 20(t0)                 // t4 = MEM[ t0 + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_ENC s5,    t4
.endm

.macro SPARKLE_REV_ARXBOX 
              lwu         t4,  0(t0)                 // t4 = MEM[ t0 +  0 ] => SPARKLE_RCON[ 0 ]
              ALZETTE_DEC s0,    t4
              lwu         t4,  4(t0)                 // t4 = MEM[ t0 +  4 ] => SPARKLE_RCON[ 1 ]
              ALZETTE_DEC s1,    t4
              lwu         t4,  8(t0)                 // t4 = MEM[ t0 +  8 ] => SPARKLE_RCON[ 2 ]
              ALZETTE_DEC s2,    t4
              lwu         t4, 12(t0)                 // t4 = MEM[ t0 + 12 ] => SPARKLE_RCON[ 3 ]
              ALZETTE_DEC s3,    t4
              lwu         t4, 16(t0)                 // t4 = MEM[ t0 + 16 ] => SPARKLE_RCON[ 4 ]
              ALZETTE_DEC s4,    t4
              lwu         t4, 20(t0)                 // t4 = MEM[ t0 + 20 ] => SPARKLE_RCON[ 5 ]
              ALZETTE_DEC s5,    t4
.endm
#endif

#if ( RV64_TYPE4 )
.macro SPARKLE_FWD_ARXBOX 
              alz.whole.enci  s0, s0, 0
              alz.whole.enci  s1, s1, 1
              alz.whole.enci  s2, s2, 2
              alz.whole.enci  s3, s3, 3
              alz.whole.enci  s4, s4, 4
              alz.whole.enci  s5, s5, 5
.endm

.macro SPARKLE_REV_ARXBOX
              alz.whole.deci  s0, s0, 0
              alz.whole.deci  s1, s1, 1
              alz.whole.deci  s2, s2, 2
              alz.whole.deci  s3, s3, 3
              alz.whole.deci  s4, s4, 4
              alz.whole.deci  s5, s5, 5
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE    implementation => add step counter
#if ( RV64_TYPE1 ) 
.macro SPARKLE_ADDCOUNTER st, rc
              lwu          t4,    0(\rc)
              xor          s6,  s6,  t4                  // y0 ^= rc
              xor          s7,  s7, \st                  // y1 ^= i
.endm

#else
.macro SPARKLE_ADDCOUNTER st, rc
              lwu          t4,    0(\rc)
              slli         t4,  t4,  32
              xor          s0,  s0,  t4                  // y0 ^= rc

              slli         t4, \st,  32
              xor          s1,  s1,  t4                  // y1 ^= i
.endm
#endif

// ----------------------------------------------------------------------------
// SPARKLE    implementation => forward/ inverse step
	
.macro SPARKLE_FWD_STEP st, rc
#if  ( SPARKLE_FWD_UNROLL )
              li           t2,  \st                    //  t2 =  step
              SPARKLE_ADDCOUNTER t2, \rc
#else
              SPARKLE_ADDCOUNTER \st, \rc
#endif
              SPARKLE_FWD_ARXBOX               
              SPARKLE_FWD_LINEAR

              addi         \rc, \rc, 4                  //                      => rc +=  4
#if !( SPARKLE_FWD_UNROLL )
              addi         t2, t2,  1                   //  t2 =  t2 + 1        => step++
#endif
.endm     

.macro SPARKLE_REV_STEP st, rc
#if !( SPARKLE_REV_UNROLL )
              addi         t2,   t2, -1                 //  t2 =  t2 - 1        => step++
#endif
              SPARKLE_REV_LINEAR
              SPARKLE_REV_ARXBOX         

#if  ( SPARKLE_REV_UNROLL )  
              li           t2, \st 
              SPARKLE_ADDCOUNTER t2, \rc
#else
              SPARKLE_ADDCOUNTER \st, \rc
#endif

              addi         \rc, \rc, -4                 //                      => rc -=  4
.endm       

// ----------------------------------------------------------------------------	
// SPARKLE    implementation => forward process

#if ( SPARKLE_FWD_EXTERN )
.section .text  
.global sparkle_fwd
sparkle_fwd:  SPARKLE_FWD_PROLOGUE
              la           t0, SPARKLE_RCON              // t0 = &SPARKLE_RCON_POINTER
              mv           t1, t0                        // t1 = &SPARKLE_RCON_INDEX
#if ( RV64_TYPE1 ) || ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )           
#if ( SPARKLE_FWD_UNROLL )             
              SPARKLE_FWD_STEP 0, t1    
              SPARKLE_FWD_STEP 1, t1
              SPARKLE_FWD_STEP 2, t1    
              SPARKLE_FWD_STEP 3, t1
              SPARKLE_FWD_STEP 4, t1    
              SPARKLE_FWD_STEP 5, t1
              SPARKLE_FWD_STEP 6, t1    
#else             
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              SPARKLE_FWD_STEP t2, t1    
              j                    0b                    //            goto 0
#endif
1:                           
#endif

#if ( RV64_TYPE4 )
#if ( SPARKLE_FWD_UNROLL )
              SPARKLE_FWD_STEP 0, t1    
              SPARKLE_FWD_STEP 1, t1
              SPARKLE_FWD_STEP 2, t1    
              SPARKLE_FWD_STEP 3, t1
              SPARKLE_FWD_STEP 4, t1    
              SPARKLE_FWD_STEP 5, t1
              SPARKLE_FWD_STEP 6, t1  
#else	
#error "can't use RV64_TYPE4 without SPARKLE_FWD_UNROLL"
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
#if ( RV64_TYPE1 ) || ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
#if ( SPARKLE_REV_UNROLL )         
              SPARKLE_REV_STEP 6, t1    
              SPARKLE_REV_STEP 5, t1
              SPARKLE_REV_STEP 4, t1    
              SPARKLE_REV_STEP 3, t1
              SPARKLE_REV_STEP 2, t1    
              SPARKLE_REV_STEP 1, t1
              SPARKLE_REV_STEP 0, t1    
#else             
0:            blez         t2,     1f                    // if i <= 0, goto 1
              SPARKLE_REV_STEP t2, t1     
              j                    0b                    //            goto 0
#endif
1:                       
#endif

#if ( RV64_TYPE4 )
#if ( SPARKLE_REV_UNROLL )
              SPARKLE_REV_STEP 6, t1    
              SPARKLE_REV_STEP 5, t1
              SPARKLE_REV_STEP 4, t1    
              SPARKLE_REV_STEP 3, t1
              SPARKLE_REV_STEP 2, t1    
              SPARKLE_REV_STEP 1, t1
              SPARKLE_REV_STEP 0, t1    
#else	
#error "can't use RV64_TYPE4 without SPARKLE_REV_UNROLL"
#endif
#endif
              SPARKLE_REV_EPILOGUE
#endif

// ============================================================================
