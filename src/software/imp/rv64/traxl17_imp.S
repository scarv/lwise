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
              
              li           t2,        0                  // t2  =  0             => i =  0
              li           t3,       16                  // t3  = 16             => n = 16
.endm

.macro TRAXL17_ENC_EPILOGUE 
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

              li           t2,       16                  // t2  = 16             => i = 16
              li           t3,        0                  // t3  =  0             => n =  0
.endm

.macro TRAXL17_DEC_EPILOGUE 
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
// TRAXL17 implementation => TRAXL17_RD_STATE

#if ( RV64_TYPE1 )
.macro  TRAXL17_RD_STATE  x0, x1, x2, x3, y0, y1, y2, y3, tk0, tk1, tk2, tk3
              lwu         \x0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              lwu         \x1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              lwu         \x2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              lwu         \x3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              lwu         \y0,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              lwu         \y1,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              lwu         \y2,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              lwu         \y3,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

              lwu         \tk0,  0(a3)                   // s8  = MEM[ a3 +  0 ] => tk[ 0 ] = tweak[ 0 ]
              lwu         \tk1,  4(a3)                   // s9  = MEM[ a3 +  4 ] => tk[ 1 ] = tweak[ 1 ]
              lwu         \tk2,  8(a3)                   // s10 = MEM[ a3 +  8 ] => tk[ 2 ] = tweak[ 2 ]
              lwu         \tk3, 12(a3)                   // s11 = MEM[ a3 + 12 ] => tk[ 3 ] = tweak[ 3 ]
.endm
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro  TRAXL17_RD_STATE  yx0, yx1, yx2, yx3, tk0, tk1, tk2, tk3
              lwu         \yx0,  0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              lwu         \yx1,  4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              lwu         \yx2,  8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              lwu         \yx3, 12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              lwu         \tk0,  0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              lwu         \tk1,  4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              lwu         \tk2,  8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              lwu         \tk3, 12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]

              PACK        \yx0, \yx0, \tk0               //                      => ( yw || xw )
              PACK        \yx1, \yx1, \tk1               //                      => ( yw || xw )
              PACK        \yx2, \yx2, \tk2               //                      => ( yw || xw )
              PACK        \yx3, \yx3, \tk3               //                      => ( yw || xw )

              lwu         \tk0,  0(a3)                   // s8  = MEM[ a3 +  0 ] => tk[ 0 ] = tweak[ 0 ]
              lwu         \tk1,  4(a3)                   // s9  = MEM[ a3 +  4 ] => tk[ 1 ] = tweak[ 1 ]
              lwu         \tk2,  8(a3)                   // s10 = MEM[ a3 +  8 ] => tk[ 2 ] = tweak[ 2 ]
              lwu         \tk3, 12(a3)                   // s11 = MEM[ a3 + 12 ] => tk[ 3 ] = tweak[ 3 ]

              PACK        \tk0, \tk0, \tk1               //                      => ( yw || xw )
              PACK        \tk2, \tk2, \tk3               //                      => ( yw || xw )
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => TRAXL17_WR_STATE
	
#if ( RV64_TYPE1 )
.macro  TRAXL17_WR_STATE  x0, x1, x2, x3, y0, y1, y2, y3
              sw          \x0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              sw          \x1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              sw          \x2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              sw          \x3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              sw          \y0,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              sw          \y1,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              sw          \y2,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              sw          \y3,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]
.endm
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro  TRAXL17_WR_STATE  x0, x1, x2, x3, y0, y1, y2, y3
              srli        \y0, \x0,  32                  // s4  = s0 >> 32       => ( yw || xw )
              srli        \y1, \x1,  32                  // s5  = s1 >> 32       => ( yw || xw )
              srli        \y2, \x2,  32                  // s6  = s2 >> 32       => ( yw || xw )
              srli        \y3, \x3,  32                  // s7  = s3 >> 32       => ( yw || xw )
              
              sw          \x0,   0(a0)                   // s0  = MEM[ a0 +  0 ] => x[ 0 ] = xstate[ 0 ]
              sw          \x1,   4(a0)                   // s1  = MEM[ a0 +  4 ] => x[ 1 ] = xstate[ 1 ]
              sw          \x2,   8(a0)                   // s2  = MEM[ a0 +  8 ] => x[ 2 ] = xstate[ 2 ]
              sw          \x3,  12(a0)                   // s3  = MEM[ a0 + 12 ] => x[ 3 ] = xstate[ 3 ]

              sw          \y0,   0(a1)                   // s4  = MEM[ a1 +  0 ] => y[ 0 ] = ystate[ 0 ]
              sw          \y1,   4(a1)                   // s5  = MEM[ a1 +  4 ] => y[ 1 ] = ystate[ 1 ]
              sw          \y2,   8(a1)                   // s6  = MEM[ a1 +  8 ] => y[ 2 ] = ystate[ 2 ]
              sw          \y3,  12(a1)                   // s7  = MEM[ a1 + 12 ] => y[ 3 ] = ystate[ 3 ]
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => add tweak

#if ( RV64_TYPE1 )
.macro TRAXL17_ADD_TWEAK   x0,  x1,  y0,  y1, tk0, tk1, tk2, tk3
              xor         \x0, \x0, \tk0                 // x0 ^= tk[0]
              xor         \y0, \y0, \tk1                 // y0 ^= tk[1]
              xor         \x1, \x1, \tk2                 // x1 ^= tk[2]
              xor         \y1, \y1, \tk3                 // y1 ^= tk[3]
.endm
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro TRAXL17_ADD_TWEAK  yx0,  yx1, tk0, tk2
              xor        \yx0, \yx0, \tk0                 // ( y0 || x0 ) ^= ( tk[1] || tk[0])
              xor        \yx1, \yx1, \tk2                 // ( y1 || x1 ) ^= ( tk[3] || tk[2])
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt linear layer

#if ( RV64_TYPE1 )
.macro TRAXL17_ENC_LINEAR  x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              ELL32       \t0, \x2, \x3, \t1, \t2
              xor         \y0, \y0, \t0 
              xor         \y1, \y1, \t0 

              ELL32       \t0, \y2, \y3, \t1, \t2
              xor         \x0, \x0, \t0 
              xor         \x1, \x1, \t0 

              mv          \t0, \x0
              mv          \x0, \x3
              mv          \x3, \x1
              mv          \x1, \x2
              mv          \x2, \t0

              mv          \t0, \y0
              mv          \y0, \y3
              mv          \y3, \y1
              mv          \y1, \y2
              mv          \y2, \t0
.endm

.macro TRAXL17_DEC_LINEAR  x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              mv          \t0, \x0
              mv          \x0, \x2
              mv          \x2, \x1
              mv          \x1, \x3
              mv          \x3, \t0

              mv          \t0, \y0
              mv          \y0, \y2
              mv          \y2, \y1
              mv          \y1, \y3
              mv          \y3, \t0

              ELL32       \t0, \x2, \x3, \t1, \t2
              xor         \y0, \y0, \t0 
              xor         \y1, \y1, \t0 

              ELL32       \t0, \y2, \y3, \t1, \t2
              xor         \x0, \x0, \t0 
              xor         \x1, \x1, \t0 
.endm	
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro TRAXL17_ENC_LINEAR yx0,  yx1,  yx2, yx3,  t0,  t1,  t2,  t3
              ELL64       \t0 , \yx2, \yx3, \t1, \t2, \t3 //          t0 = tmpx || tmpy
              xor         \yx0, \yx0, \t0                 // ( y0 || x0) = ( y0 || x0) ^ (tmpx || tmpy)
              xor         \yx1, \yx1, \t0                 // ( y1 || x1) = ( y1 || x1) ^ (tmpx || tmpy)  
              #if !( TRAXL17_ENC_UNROLL )
              mv          \t0 , \yx0
              mv          \yx0, \yx3
              mv          \yx3, \yx1
              mv          \yx1, \yx2
              mv          \yx2, \t0
              #endif
.endm

.macro TRAXL17_DEC_LINEAR yx0,  yx1,  yx2, yx3,  t0,  t1,  t2,  t3
              #if !( TRAXL17_DEC_UNROLL )
              mv          \t0 , \yx0
              mv          \yx0, \yx2
              mv          \yx2, \yx1
              mv          \yx1, \yx3
              mv          \yx3, \t0
              #endif	
              ELL64       \t0 , \yx2, \yx3, \t1, \t2, \t3 //          t0 = tmpx || tmpy
              xor         \yx0, \yx0, \t0                 // ( y0 || x0) = ( y0 || x0) ^ (tmpx || tmpy)
              xor         \yx1, \yx1, \t0                 // ( y1 || x1) = ( y1 || x1) ^ (tmpx || tmpy)  
.endm	
#endif


// ----------------------------------------------------------------------------
// TRAXL17 implementation => add subkeys

#if ( RV64_TYPE1 )
.macro TRAXL17_ADD_SUBKEY  sk, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0
              lwu         \t0,    0(\sk)
              xor         \x0, \x0, \t0
              lwu         \t0,    4(\sk)
              xor         \y0, \y0, \t0
              lwu         \t0,    8(\sk)
              xor         \x1, \x1, \t0
              lwu         \t0,   12(\sk)
              xor         \y1, \y1, \t0
              lwu         \t0,   16(\sk)
              xor         \x2, \x2, \t0
              lwu         \t0,   20(\sk)
              xor         \y2, \y2, \t0
              lwu         \t0,   24(\sk)
              xor         \x3, \x3, \t0
              lwu         \t0,   28(\sk)
              xor         \y3, \y3, \t0
.endm
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro TRAXL17_ADD_SUBKEY  sk ,  yx0,  yx1,  yx2,  yx3,  t0
              ld          \t0 ,     0(\sk)
              xor         \yx0, \yx0, \t0
              ld          \t0 ,     8(\sk)
              xor         \yx1, \yx1, \t0
              ld          \t0 ,    16(\sk)
              xor         \yx2, \yx2, \t0
              ld          \t0 ,    24(\sk)
              xor         \yx3, \yx3, \t0
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt substitution

#if ( RV64_TYPE1 ) 
.macro TRAXL17_ENC_SUBS rc, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              lwu         \t0,     0(\rc)                 // t0 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_ENC \x0, \y0,  \t0, \t1, \t2
              lwu         \t0,     4(\rc)                 // t0 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_ENC \x1, \y1,  \t0, \t1, \t2
              lwu         \t0,     8(\rc)                 // t0 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_ENC \x2, \y2,  \t0, \t1, \t2
              lwu         \t0,    12(\rc)                 // t0 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_ENC \x3, \y3,  \t0, \t1, \t2
.endm

.macro TRAXL17_DEC_SUBS rc, x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  t0,  t1,  t2
              lwu         \t0,     0(\rc)                 // t0 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_DEC \x0, \y0,  \t0, \t1, \t2
              lwu         \t0,     4(\rc)                 // t0 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_DEC \x1, \y1,  \t0, \t1, \t2
              lwu         \t0,     8(\rc)                 // t0 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_DEC \x2, \y2,  \t0, \t1, \t2
              lwu         \t0,    12(\rc)                 // t0 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_DEC \x3, \y3,  \t0, \t1, \t2
.endm
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
.macro TRAXL17_ENC_SUBS rc,  yx0,  yx1,  yx2,  yx3,  t0
              lwu         \t0 ,    0(\rc)                 // t0 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_ENC \yx0, \t0
              lwu         \t0 ,    4(\rc)                 // t0 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_ENC \yx1, \t0
              lwu         \t0 ,    8(\rc)                 // t0 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_ENC \yx2, \t0
              lwu         \t0 ,   12(\rc)                 // t0 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_ENC \yx3, \t0
.endm

.macro TRAXL17_DEC_SUBS rc,  yx0,  yx1,  yx2,  yx3,  t0
              lwu         \t0 ,    0(\rc)                 // t0 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_DEC \yx0, \t0
              lwu         \t0 ,    4(\rc)                 // t0 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_DEC \yx1, \t0
              lwu         \t0 ,    8(\rc)                 // t0 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_DEC \yx2, \t0
              lwu         \t0 ,   12(\rc)                 // t0 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_DEC \yx3, \t0
.endm
#endif

#if ( RV64_TYPE4 ) 
.macro TRAXL17_ENC_SUBS rc,  yx0,  yx1,  yx2,  yx3,  t0
              alz.whole.enci \yx0, \yx0,   \rc
              alz.whole.enci \yx1, \yx1, 1+\rc
              alz.whole.enci \yx2, \yx2, 2+\rc
              alz.whole.enci \yx3, \yx3, 3+\rc
.endm

.macro TRAXL17_DEC_SUBS rc,  yx0,  yx1,  yx2,  yx3,  t0
              alz.whole.deci \yx0, \yx0,   \rc
              alz.whole.deci \yx1, \yx1, 1+\rc
              alz.whole.deci \yx2, \yx2, 2+\rc
              alz.whole.deci \yx3, \yx3, 3+\rc
.endm
#endif

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt step
#if ( RV64_TYPE1 )
.macro TRAXL17_ENC_STEP_EVE   sk, rc,  x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,                          t0,  t1,  t2
              TRAXL17_ADD_SUBKEY \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0
              TRAXL17_ENC_SUBS   \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2    
              TRAXL17_ENC_LINEAR      \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2

              addi         \sk, \sk, 32                 //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                   // t2 = t2 + 1 => step++
              #endif
.endm     

.macro TRAXL17_ENC_STEP_ODD   sk, rc,  x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  tk0,  tk1,  tk2,  tk3,  t0,  t1,  t2
              TRAXL17_ADD_TWEAK       \x0, \x1,           \y0, \y1,           \tk0, \tk1, \tk2, \tk3
              TRAXL17_ADD_SUBKEY \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0
              TRAXL17_ENC_SUBS   \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2
              TRAXL17_ENC_LINEAR      \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2

              addi         \sk, \sk, 32                 //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                   // t2 = t2 + 1 => step++
              #endif
.endm   

.macro TRAXL17_DEC_STEP_EVE   sk, rc,  x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,                          t0,  t1,  t2
              TRAXL17_DEC_LINEAR      \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2
              TRAXL17_DEC_SUBS   \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2             
              TRAXL17_ADD_SUBKEY \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0

              addi         \sk, \sk, -32                //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                 // t2 = t2 - 1 => step++
              #endif
.endm       

.macro TRAXL17_DEC_STEP_ODD   sk, rc,  x0,  x1,  x2,  x3,  y0,  y1,  y2,  y3,  tk0,  tk1,  tk2,  tk3,  t0,  t1,  t2
              TRAXL17_DEC_LINEAR      \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2
              TRAXL17_DEC_SUBS   \rc, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0, \t1, \t2             
              TRAXL17_ADD_SUBKEY \sk, \x0, \x1, \x2, \x3, \y0, \y1, \y2, \y3,                         \t0
              TRAXL17_ADD_TWEAK       \x0, \x1,           \y0, \y1,           \tk0, \tk1, \tk2, \tk3

              addi         \sk, \sk, -32                //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                 // t2 = t2 - 1 => step++
              #endif
.endm   
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro TRAXL17_ENC_STEP_EVE   sk, rc,  yx0,  yx1,  yx2,  yx3,              t0,  t1,  t2,  t3
              TRAXL17_ADD_SUBKEY \sk, \yx0, \yx1, \yx2, \yx3,             \t0
              TRAXL17_ENC_SUBS   \rc, \yx0, \yx1, \yx2, \yx3,             \t0            
              TRAXL17_ENC_LINEAR      \yx0, \yx1, \yx2, \yx3,             \t0, \t1, \t2, \t3

              addi         \sk, \sk, 32                 //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                   // t2 = t2 + 1 => step++
              #endif
.endm     

.macro TRAXL17_ENC_STEP_ODD   sk, rc,  yx0,  yx1,  yx2,  yx3,  tk0,  tk2,  t0,  t1,  t2,  t3
              TRAXL17_ADD_TWEAK       \yx0, \yx1,             \tk0, \tk2
              TRAXL17_ADD_SUBKEY \sk, \yx0, \yx1, \yx2, \yx3,             \t0
              TRAXL17_ENC_SUBS   \rc, \yx0, \yx1, \yx2, \yx3,             \t0                          
              TRAXL17_ENC_LINEAR      \yx0, \yx1, \yx2, \yx3,             \t0, \t1, \t2, \t3

              addi         \sk, \sk, 32                 //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                   // t2 = t2 + 1 => step++
              #endif
.endm   

.macro TRAXL17_DEC_STEP_EVE   sk, rc,  yx0,  yx1,  yx2,  yx3,              t0,  t1,  t2,  t3
              TRAXL17_DEC_LINEAR      \yx0, \yx1, \yx2, \yx3,             \t0, \t1, \t2, \t3
              TRAXL17_DEC_SUBS   \rc, \yx0, \yx1, \yx2, \yx3,             \t0            
              TRAXL17_ADD_SUBKEY \sk, \yx0, \yx1, \yx2, \yx3,             \t0

              addi         \sk, \sk, -32                //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                 // t2 = t2 - 1 => step++
              #endif
.endm       

.macro TRAXL17_DEC_STEP_ODD   sk, rc,  yx0,  yx1,  yx2,  yx3,  tk0,  tk2,  t0,  t1,  t2,  t3
              TRAXL17_DEC_LINEAR      \yx0, \yx1, \yx2, \yx3,             \t0, \t1, \t2, \t3
              TRAXL17_DEC_SUBS   \rc, \yx0, \yx1, \yx2, \yx3,             \t0             
              TRAXL17_ADD_SUBKEY \sk, \yx0, \yx1, \yx2, \yx3,             \t0
              TRAXL17_ADD_TWEAK       \yx0, \yx1,             \tk0, \tk2

              addi         \sk, \sk, -32                //             => sk += 8
              #if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                 // t2 = t2 - 1 => step++
              #endif
.endm   
#endif
// ----------------------------------------------------------------------------	
// TRAXL17 implementation => encrypt

#if ( TRAXL17_ENC_EXTERN )
.section .text  
.global traxl17_enc
traxl17_enc:  TRAXL17_ENC_PROLOGUE 

#if ( RV64_TYPE1 ) 
              mv           t0, a2                        // t0 = &subkeys
              la           a6, TRAXL17_RCON              // a6 = &TRAXL17_RCON
              addi         a7, a6,  16                   // a7 = &TRAXL17_RCON[4]
              //                   sk  rc  x0  x1  x2  x3  y0  y1  y2  y3 tk0 tk1  tk2  tk3  t0  t1  t2
              TRAXL17_RD_STATE             s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11
              #if ( TRAXL17_ENC_UNROLL )
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6 
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,     s0, s1, s2, s3, s4, s5, s6, s7,                   t4
			  TRAXL17_WR_STATE             s0, s1, s2, s3, s4, s5, s6, s7
              #else             
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              j                    0b                    //            goto 0
1:            TRAXL17_ENC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,     s0, s1, s2, s3, s4, s5, s6, s7,                   t4
			  TRAXL17_WR_STATE             s0, s1, s2, s3, s4, s5, s6, s7
              #endif
                 
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
              mv           t0, a2                        // t0 = &subkeys
              la           a6, TRAXL17_RCON              // a6 = &TRAXL17_RCON
              addi         a7, a6,  16                   // a7 = &TRAXL17_RCON[4]
              //                   sk  rc  yx0  yx1  yx2  yx3  tk0 tk1  tk2  tk3 t0  t1  t2  t3
              TRAXL17_RD_STATE              s0,  s1,  s2,  s3,  s8, s9, s10, s11
              #if ( TRAXL17_ENC_UNROLL )
              TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6 
              TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0, a7,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,      s3,  s2,  s0,  s1,                   t1
			  TRAXL17_WR_STATE              s3,  s2,  s0,  s1,                   s7, s6, s4, s5
              #else             
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0, a7,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              j                    0b                    //            goto 0
1:            TRAXL17_ENC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,      s0,  s1,  s2,  s3,                   t1
			  TRAXL17_WR_STATE              s0,  s1,  s2,  s3,                   s4, s5, s6, s7
              #endif
#endif

#if ( RV64_TYPE4 )
              mv           t0, a2                        // t0 = &subkeys
              TRAXL17_RD_STATE              s0,  s1,  s2,  s3,  s8, s9, s10, s11
              #if ( TRAXL17_ENC_UNROLL )
              TRAXL17_ENC_STEP_EVE t0,  0,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6
              TRAXL17_ENC_STEP_ODD t0,  4,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0,  4,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0,  4,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0,  4,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0,  4,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6 
              TRAXL17_ENC_STEP_EVE t0,  0,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0,  4,  s3,  s2,  s0,  s1,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s1,  s0,  s3,  s2,                   t1, t4, t5, t6    
              TRAXL17_ENC_STEP_ODD t0,  4,  s2,  s3,  s1,  s0,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_ENC_STEP_EVE t0,  0,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_ADD_SUBKEY   t0,      s3,  s2,  s0,  s1,                   t1
			  TRAXL17_WR_STATE              s3,  s2,  s0,  s1,                   s7, s6, s4, s5
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

#if ( RV64_TYPE1 ) 
              addi         t0, a2,  544               // t0 = &subkeys[17]                       
              la           a6, TRAXL17_RCON           // a6 = &TRAXL17_RCON
              addi         a7, a6,  16                // a7 = &TRAXL17_RCON[4]
              //                   sk  rc  x0  x1  x2  x3  y0  y1  y2  y3 tk0 tk1  tk2  tk3  t0  t1  t2
              TRAXL17_RD_STATE             s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11
              TRAXL17_ADD_SUBKEY   t0,     s0, s1, s2, s3, s4, s5, s6, s7,                   t4
              addi         t0, t0, -32                // sk-=  8
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              #if ( TRAXL17_DEC_UNROLL )         
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6 
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              TRAXL17_WR_STATE             s0, s1, s2, s3, s4, s5, s6, s7    
              #else             
0:            blez         t2,     1f                 // if i <= 0, goto 1
              TRAXL17_DEC_STEP_ODD t0, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6, s0, s1, s2, s3, s4, s5, s6, s7,                   t4, t5, t6
              j                    0b                 //            goto 0
1:            TRAXL17_WR_STATE             s0, s1, s2, s3, s4, s5, s6, s7               
              #endif
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
              addi         t0, a2,  544               // t0 = &subkeys[17]                       
              la           a6, TRAXL17_RCON           // a6 = &TRAXL17_RCON
              addi         a7, a6,  16                // a7 = &TRAXL17_RCON[4]
              //                   sk  rc  yx0  yx1  yx2  yx3  tk0 tk1  tk2  tk3 t0  t1  t2  t3
              TRAXL17_RD_STATE              s0,  s1,  s2,  s3,  s8, s9, s10, s11
              TRAXL17_ADD_SUBKEY   t0,      s0,  s1,  s2,  s3, t1
              addi         t0, t0, -32                // sk-=  8
              #if ( TRAXL17_DEC_UNROLL )         
              TRAXL17_DEC_STEP_EVE t0, a6,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0, a7,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0, a7,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6 
              TRAXL17_DEC_STEP_EVE t0, a6,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0, a7,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0, a6,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6
              TRAXL17_WR_STATE              s2,  s3,  s1,  s0,                   s6, s7, s5, s4
              #else      
0:            blez         t2,     1f                 // if i <= 0, goto 1
              TRAXL17_DEC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6       
              TRAXL17_DEC_STEP_ODD t0, a7,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              j                    0b                 //            goto 0
1:            TRAXL17_DEC_STEP_EVE t0, a6,  s0,  s1,  s2,  s3,                   t1, t4, t5, t6
              TRAXL17_WR_STATE              s0,  s1,  s2,  s3,                   s4, s5, s6, s7
              #endif
#endif

#if ( RV64_TYPE4 )
              addi         t0, a2,  544               // t0 = &subkeys[17]
              //                   sk  rc  yx0  yx1  yx2  yx3  tk0 tk1  tk2  tk3 t0  t1  t2  t3
              TRAXL17_RD_STATE              s0,  s1,  s2,  s3,  s8, s9, s10, s11
              TRAXL17_ADD_SUBKEY   t0,      s0,  s1,  s2,  s3,                   t1
              addi         t0, t0, -32                // sk-=  8
              #if ( TRAXL17_DEC_UNROLL )
              TRAXL17_DEC_STEP_EVE t0,  0,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0,  4,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6
              TRAXL17_DEC_STEP_ODD t0,  4,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6 
              TRAXL17_DEC_STEP_EVE t0,  0,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4,  s1,  s0,  s3,  s2,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s3,  s2,  s0,  s1,                   t1, t4, t5, t6    
              TRAXL17_DEC_STEP_ODD t0,  4,  s0,  s1,  s2,  s3,  s8,     s10,     t1, t4, t5, t6
              TRAXL17_DEC_STEP_EVE t0,  0,  s2,  s3,  s1,  s0,                   t1, t4, t5, t6
              TRAXL17_WR_STATE              s2,  s3,  s1,  s0,                   s6, s7, s5, s4
              #else	
              #error "can't use RV32_TYPE4 without TRAXL17_DEC_UNROLL"
              #endif
#endif
              TRAXL17_DEC_EPILOGUE
#endif

// ============================================================================
