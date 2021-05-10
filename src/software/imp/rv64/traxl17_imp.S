// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#include     "ise.h"
#include     "ell.h"
#include "alzette.h"

// ============================================================================
// register allocation

// t0  => subkey
// t1  => temp 
// t2  => i          ~ loop counter 
// t3  => n          ~ loop bound
// t4  => temp 
// t5  => temp
// t6  => temp

// a6  => &TRAXL17_RCON
// a7  => &TRAXL17_RCON[4]

// s0  =>  xstate[ 0 ] =  y0 ||  x0 
// s1  =>  xstate[ 1 ] =  y1 ||  x1
// s2  =>  xstate[ 2 ] =  y2 ||  x2
// s3  =>  xstate[ 3 ] =  y3 ||  x3
// s4  =>  ystate[ 0 ] =  y0
// s5  =>  ystate[ 1 ] =  y1
// s6  =>  ystate[ 2 ] =  y2
// s7  =>  ystate[ 3 ] =  y3
// s8  =>   tweak[ 0 ] = tk1 || tk0
// s9  =>   tweak[ 1 ] = tk1
// s10 =>   tweak[ 2 ] = tk3 || tk2
// s11 =>   tweak[ 3 ] = tk3

// ============================================================================
// TRAXL17 implementation => en/decrypt prologue + epilogue

.macro TRAXL17_ENC_PROLOGUE
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
              
              lwu          s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              lwu          s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              lwu          s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              lwu          s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              lwu          s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              lwu          s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              lwu          s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              lwu          s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

              lwu          s8,   0(a3)                   // s8  = MEM[ a3 +  0 ] => tk[ 0 ] = tweak[ 0 ]
              lwu          s9,   4(a3)                   // s9  = MEM[ a3 +  4 ] => tk[ 1 ] = tweak[ 1 ]
              lwu          s10,  8(a3)                   // s10 = MEM[ a3 +  8 ] => tk[ 2 ] = tweak[ 2 ]
              lwu          s11, 12(a3)                   // s11 = MEM[ a3 + 12 ] => tk[ 3 ] = tweak[ 3 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              PACK         s0,  s0,  s4                  //                      => ( yw || xw )
              PACK         s1,  s1,  s5                  //                      => ( yw || xw )
              PACK         s2,  s2,  s6                  //                      => ( yw || xw )
              PACK         s3,  s3,  s7                  //                      => ( yw || xw )
              PACK         s8,  s8,  s9                  //                      => ( yw || xw )
              PACK         s10, s10, s11                 //                      => ( yw || xw )
#endif
              li           t2,        0                  // t2  =  0             => i =  0
              li           t3,       16                  // t3  = 16             => n = 16
.endm

.macro TRAXL17_ENC_EPILOGUE
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              srli         s4,  s0,  32                  // s4  = s0 >> 32       => ( yw || xw )
              srli         s5,  s1,  32                  // s5  = s1 >> 32       => ( yw || xw )
              srli         s6,  s2,  32                  // s6  = s2 >> 32       => ( yw || xw )
              srli         s7,  s3,  32                  // s7  = s3 >> 32       => ( yw || xw )
#endif
              sw           s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              sw           s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              sw           s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              sw           s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              sw           s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              sw           s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              sw           s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              sw           s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

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

.macro TRAXL17_DEC_PROLOGUE
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
              
              lwu          s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              lwu          s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              lwu          s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              lwu          s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              lwu          s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              lwu          s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              lwu          s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              lwu          s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

              lwu          s8,   0(a3)                   // s8  = MEM[ a3 +  0 ] => tk[ 0 ] = tweak[ 0 ]
              lwu          s9,   4(a3)                   // s9  = MEM[ a3 +  4 ] => tk[ 1 ] = tweak[ 1 ]
              lwu          s10,  8(a3)                   // s10 = MEM[ a3 +  8 ] => tk[ 2 ] = tweak[ 2 ]
              lwu          s11, 12(a3)                   // s11 = MEM[ a3 + 12 ] => tk[ 3 ] = tweak[ 3 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              PACK         s0,  s0,  s4                  //                      => ( yw || xw )
              PACK         s1,  s1,  s5                  //                      => ( yw || xw )
              PACK         s2,  s2,  s6                  //                      => ( yw || xw )
              PACK         s3,  s3,  s7                  //                      => ( yw || xw )
              PACK         s8,  s8,  s9                  //                      => ( yw || xw )
              PACK         s10, s10, s11                 //                      => ( yw || xw )
#endif
              li           t2,       16                  // t2  = 16             => i = 16
              li           t3,        0                  // t3  =  0             => n =  0
.endm

.macro TRAXL17_DEC_EPILOGUE
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              srli         s4,  s0,  32                  // s4  = s0 >> 32       => ( yw || xw )
              srli         s5,  s1,  32                  // s5  = s1 >> 32       => ( yw || xw )
              srli         s6,  s2,  32                  // s6  = s2 >> 32       => ( yw || xw )
              srli         s7,  s3,  32                  // s7  = s3 >> 32       => ( yw || xw )
#endif
              sw           s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              sw           s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              sw           s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              sw           s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              sw           s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              sw           s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              sw           s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              sw           s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

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
// TRAXL17 implementation => add tweak

.macro TRAXL17_ADD_TWEAK 
#if ( RV64_TYPE1 )
              xor          s0,  s0,  s8                  // x0 ^= tk[0]
              xor          s4,  s4,  s9                  // y0 ^= tk[1]
              xor          s1,  s1,  s10                 // x1 ^= tk[2]
              xor          s5,  s5,  s11                 // y1 ^= tk[3]
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              xor          s0,  s0,  s8                  // ( y0 || x0 ) ^= ( tk[1] || tk[0])
              xor          s1,  s1,  s10                 // ( y1 || x1 ) ^= ( tk[3] || tk[2])
#endif
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt linear layer

.macro TRAXL17_ENC_LINEAR 
#if ( RV64_TYPE1 )
              xor          t4,  s2,  s3
              ELL          t4,  t4,  t5,  t6
              xor          s4,  s4,  t4 
              xor          s5,  s5,  t4 

              xor          t4,  s6,  s7
              ELL          t4,  t4,  t5,  t6
              xor          s0,  s0,  t4 
              xor          s1,  s1,  t4 

              mv           t4,  s0
              mv           s0,  s3
              mv           s3,  s1
              mv           s1,  s2
              mv           s2,  t4

              mv           t4,  s4
              mv           s4,  s7
              mv           s7,  s5
              mv           s5,  s6
              mv           s6,  t4
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              xor          t4,  s2,  s3                 //          t4 = ( y2 || x2) ^ (  y3 || x3  )
              ELL          t4,  t4,  t5, t6             //          t4 = tmpx || tmpy
              xor          s0,  s0,  t4                 // ( y0 || x0) = ( y0 || x0) ^ (tmpx || tmpy)
              xor          s1,  s1,  t4                 // ( y1 || x1) = ( y1 || x1) ^ (tmpx || tmpy)  

              mv           t4,  s0
              mv           s0,  s3
              mv           s3,  s1
              mv           s1,  s2
              mv           s2,  t4
#endif
.endm

.macro TRAXL17_DEC_LINEAR 
#if ( RV64_TYPE1 )
              mv           t4,  s0
              mv           s0,  s2
              mv           s2,  s1
              mv           s1,  s3
              mv           s3,  t4

              mv           t4,  s4
              mv           s4,  s6
              mv           s6,  s5
              mv           s5,  s7
              mv           s7,  t4

              xor          t4,  s2,  s3
              ELL          t4,  t4,  t5,  t6
              xor          s4,  s4,  t4 
              xor          s5,  s5,  t4 

              xor          t4,  s6,  s7
              ELL          t4,  t4,  t5,  t6
              xor          s0,  s0,  t4 
              xor          s1,  s1,  t4 
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              mv           t4,  s0
              mv           s0,  s2
              mv           s2,  s1
              mv           s1,  s3
              mv           s3,  t4
	
              xor          t4,  s2,  s3                 //          t4 = ( y2 || x2) ^ (  y3 || x3  )
              ELL          t4,  t4,  t5, t6             //          t4 = tmpx || tmpy
              xor          s0,  s0,  t4                 // ( y0 || x0) = ( y0 || x0) ^ (tmpx || tmpy)
              xor          s1,  s1,  t4                 // ( y1 || x1) = ( y1 || x1) ^ (tmpx || tmpy)  
#endif
.endm	

// ----------------------------------------------------------------------------
// TRAXL17 implementation => add subkeys

#if ( RV64_TYPE1 )
.macro TRAXL17_ADD_SUBKEY sk
              lwu          t6,  0(\sk)
              xor          s0,  s0,  t6
              lwu          t6,  4(\sk)
              xor          s4,  s4,  t6
              lwu          t6,  8(\sk)
              xor          s1,  s1,  t6
              lwu          t6, 12(\sk)
              xor          s5,  s5,  t6
              lwu          t6, 16(\sk)
              xor          s2,  s2,  t6
              lwu          t6, 20(\sk)
              xor          s6,  s6,  t6
              lwu          t6, 24(\sk)
              xor          s3,  s3,  t6
              lwu          t6, 28(\sk)
              xor          s7,  s7,  t6
.endm
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro TRAXL17_ADD_SUBKEY sk
              ld           t6,  0(\sk)
              xor          s0,  s0,  t6
              ld           t6,  8(\sk)
              xor          s1,  s1,  t6
              ld           t6, 16(\sk)
              xor          s2,  s2,  t6
              ld           t6, 24(\sk)
              xor          s3,  s3,  t6
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt substitution

#if ( RV64_TYPE1 ) 
.macro TRAXL17_ENC_SUBS rc
              lwu          t4,     0(\rc)                 // t4 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_ENC s0, s4, t4, t5, t6
              lwu          t4,     4(\rc)                 // t4 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_ENC s1, s5, t4, t5, t6
              lwu          t4,     8(\rc)                 // t4 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_ENC s2, s6, t4, t5, t6
              lwu          t4,    12(\rc)                 // t4 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_ENC s3, s7, t4, t5, t6
.endm

.macro TRAXL17_DEC_SUBS rc
              lwu          t4,     0(\rc)                 // t4 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_DEC s0, s4, t4, t5, t6
              lwu          t4,     4(\rc)                 // t4 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_DEC s1, s5, t4, t5, t6
              lwu          t4,     8(\rc)                 // t4 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_DEC s2, s6, t4, t5, t6
              lwu          t4,    12(\rc)                 // t4 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_DEC s3, s7, t4, t5, t6
.endm
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
.macro TRAXL17_ENC_SUBS rc
              lwu          t4,     0(\rc)                 // t4 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_ENC s0, t4
              lwu          t4,     4(\rc)                 // t4 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_ENC s1, t4
              lwu          t4,     8(\rc)                 // t4 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_ENC s2, t4
              lwu          t4,    12(\rc)                 // t4 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_ENC s3, t4
.endm

.macro TRAXL17_DEC_SUBS rc
              lwu          t4,     0(\rc)                 // t4 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_DEC s0, t4
              lwu          t4,     4(\rc)                 // t4 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_DEC s1, t4
              lwu          t4,     8(\rc)                 // t4 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_DEC s2, t4
              lwu          t4,    12(\rc)                 // t4 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_DEC s3, t4
.endm
#endif
#if ( RV64_TYPE4 ) 
.macro TRAXL17_ENC_SUBS rc
              alz.whole.enci  s0, s0,   \rc
              alz.whole.enci  s1, s1, 1+\rc
              alz.whole.enci  s2, s2, 2+\rc
              alz.whole.enci  s3, s3, 3+\rc
.endm

.macro TRAXL17_DEC_SUBS rc
              alz.whole.deci  s0, s0,   \rc
              alz.whole.deci  s1, s1, 1+\rc
              alz.whole.deci  s2, s2, 2+\rc
              alz.whole.deci  s3, s3, 3+\rc
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt step
	
.macro TRAXL17_ENC_STEP_EVE sk, rc
              TRAXL17_ADD_SUBKEY \sk
              TRAXL17_ENC_SUBS   \rc            
              TRAXL17_ENC_LINEAR

              addi         \sk, \sk, 32                 //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                   //  t2 =  t2 + 1        => step++
#endif
.endm     

.macro TRAXL17_ENC_STEP_ODD sk, rc
              TRAXL17_ADD_TWEAK
              TRAXL17_ADD_SUBKEY \sk
              TRAXL17_ENC_SUBS   \rc                          
              TRAXL17_ENC_LINEAR

              addi         \sk, \sk, 32                 //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                   //  t2 =  t2 + 1        => step++
#endif
.endm   

.macro TRAXL17_DEC_STEP_EVE sk, rc
              TRAXL17_DEC_LINEAR
              TRAXL17_DEC_SUBS   \rc            
              TRAXL17_ADD_SUBKEY \sk

              addi         \sk, \sk, -32                //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                 //  t2 =  t2 - 1        => step++
#endif
.endm       

.macro TRAXL17_DEC_STEP_ODD sk, rc
              TRAXL17_DEC_LINEAR
              TRAXL17_DEC_SUBS   \rc            
              TRAXL17_ADD_SUBKEY \sk
              TRAXL17_ADD_TWEAK

              addi         \sk, \sk, -32                //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                 //  t2 =  t2 - 1        => step++
#endif
.endm   

// ----------------------------------------------------------------------------	
// TRAXL17 implementation => encrypt

#if ( TRAXL17_ENC_EXTERN )
.section .text
  
.global traxl17_enc

traxl17_enc:  TRAXL17_ENC_PROLOGUE

#if ( RV64_TYPE1 ) || ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
              mv           t0, a2                        // t0 = &subkeys
              la           a6, TRAXL17_RCON              // a6 = &TRAXL17_RCON
              addi         a7, a6,  16                   // a7 = &TRAXL17_RCON[4]
#if ( TRAXL17_ENC_UNROLL )             
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7 
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
#else             
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              TRAXL17_ENC_STEP_EVE t0, a6    
              TRAXL17_ENC_STEP_ODD t0, a7
              j                    0b                    //            goto 0
#endif
1:            
              TRAXL17_ENC_STEP_EVE t0, a6
              TRAXL17_ADD_SUBKEY   t0
                 
#endif

#if ( RV64_TYPE4 )
              mv           t0, a2                        // t0 = &subkeys
#if ( TRAXL17_ENC_UNROLL )
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4 
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0    
              TRAXL17_ENC_STEP_ODD t0, 4
              TRAXL17_ENC_STEP_EVE t0, 0
              TRAXL17_ADD_SUBKEY   t0
#else	
#error "can't use RV32_TYPE4 without TRAXL17_ENC_UNROLL"
#endif

#endif

              TRAXL17_ENC_EPILOGUE
#endif

// ----------------------------------------------------------------------------	
// TRAXL17 implementation => decrypt

#if ( TRAXL17_DEC_EXTERN )
.section .text
  
.global traxl17_dec

traxl17_dec:  TRAXL17_DEC_PROLOGUE

#if ( RV64_TYPE1 ) || ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
              addi         t0, a2,  544               // t0 = &subkeys[17]
                       
              la           a6, TRAXL17_RCON           // a6 = &TRAXL17_RCON
              addi         a7, a6,  16                // a7 = &TRAXL17_RCON[4]

              TRAXL17_ADD_SUBKEY   t0
              addi         t0, t0, -32                //                      => sk -=  8
              TRAXL17_DEC_STEP_EVE t0, a6
#if ( TRAXL17_DEC_UNROLL )         
              TRAXL17_DEC_STEP_ODD t0, a7    
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7 
              TRAXL17_DEC_STEP_EVE t0, a6    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    

#else             
0:            blez         t2,     1f                    // if i <= 0, goto 1
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, a6    
              j                    0b                    //            goto 0
#endif
1:           
            
#endif

#if ( RV64_TYPE4 )
              addi         t0, a2,  544                  // t0 = &subkeys[17]
              TRAXL17_ADD_SUBKEY   t0
              addi         t0, t0, -32                //                      => sk -=  8
#if ( TRAXL17_DEC_UNROLL )
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4 
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0    
              TRAXL17_DEC_STEP_ODD t0, 4
              TRAXL17_DEC_STEP_EVE t0, 0
#else	
#error "can't use RV32_TYPE4 without TRAXL17_DEC_UNROLL"
#endif

#endif

              TRAXL17_DEC_EPILOGUE
#endif

// ============================================================================
