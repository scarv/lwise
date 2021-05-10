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

// ============================================================================
// TRAXL17 implementation => en/decrypt prologue + epilogue

.macro TRAXL17_ENC_PROLOGUE
              addi         sp, sp, -48                   // adjust SP
              sw           s0,   0(sp)                   // push s0
              sw           s1,   4(sp)                   // push s1
              sw           s2,   8(sp)                   // push s2
              sw           s3,  12(sp)                   // push s3
              sw           s4,  16(sp)                   // push s4
              sw           s5,  20(sp)                   // push s5
              sw           s6,  24(sp)                   // push s6
              sw           s7,  28(sp)                   // push s7
              sw           s8,  32(sp)                   // push s8
              sw           s9,  36(sp)                   // push s9
              sw           s10, 40(sp)                   // push s10
              sw           s11, 44(sp)                   // push s11
              
              lw           s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] =>  x[ 0 ] = xstate[ 0 ]
              lw           s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] =>  x[ 1 ] = xstate[ 1 ]
              lw           s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] =>  x[ 2 ] = xstate[ 2 ]
              lw           s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] =>  x[ 3 ] = xstate[ 3 ]

              lw           s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] =>  y[ 0 ] = ystate[ 0 ]
              lw           s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] =>  y[ 1 ] = ystate[ 1 ]
              lw           s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] =>  y[ 2 ] = ystate[ 2 ]
              lw           s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] =>  y[ 3 ] = ystate[ 3 ]

              lw           s8,   0(a3)                   // s8  = MEM[ a3 +  0 ] => tk[ 0 ] =  tweak[ 0 ]
              lw           s9,   4(a3)                   // s9  = MEM[ a3 +  4 ] => tk[ 1 ] =  tweak[ 1 ]
              lw           s10,  8(a3)                   // s10 = MEM[ a3 +  8 ] => tk[ 2 ] =  tweak[ 2 ]
              lw           s11, 12(a3)                   // s11 = MEM[ a3 + 12 ] => tk[ 3 ] =  tweak[ 3 ]

              li           t2,   0                       // t2  =  0             => i =  0
              li           t3,  16                       // t3  = 16             => n = 16
	
.endm

.macro TRAXL17_ENC_EPILOGUE
              sw           s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] =>  x[ 0 ] = xstate[ 0 ]
              sw           s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] =>  x[ 1 ] = xstate[ 1 ]
              sw           s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] =>  x[ 2 ] = xstate[ 2 ]
              sw           s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] =>  x[ 3 ] = xstate[ 3 ]

              sw           s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] =>  y[ 0 ] = ystate[ 0 ]
              sw           s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] =>  y[ 1 ] = ystate[ 1 ]
              sw           s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] =>  y[ 2 ] = ystate[ 2 ]
              sw           s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] =>  y[ 3 ] = ystate[ 3 ]

              lw           s0,   0(sp)                   // pop  s0
              lw           s1,   4(sp)                   // pop  s1
              lw           s2,   8(sp)                   // pop  s2
              lw           s3,  12(sp)                   // pop  s3
              lw           s4,  16(sp)                   // pop  s4
              lw           s5,  20(sp)                   // pop  s5
              lw           s6,  24(sp)                   // pop  s6
              lw           s7,  28(sp)                   // pop  s7
              lw           s8,  32(sp)                   // pop  s8
              lw           s9,  36(sp)                   // pop  s9
              lw           s10, 40(sp)                   // pop  s10
              lw           s11, 44(sp)                   // pop  s11
              addi         sp, sp,  48                   // adjust SP

              ret                                        // return
.endm

.macro TRAXL17_DEC_PROLOGUE
              addi         sp, sp, -48                   // adjust SP
              sw           s0,   0(sp)                   // push s0
              sw           s1,   4(sp)                   // push s1
              sw           s2,   8(sp)                   // push s2
              sw           s3,  12(sp)                   // push s3
              sw           s4,  16(sp)                   // push s4
              sw           s5,  20(sp)                   // push s5
              sw           s6,  24(sp)                   // push s6
              sw           s7,  28(sp)                   // push s7
              sw           s8,  32(sp)                   // push s8
              sw           s9,  36(sp)                   // push s9
              sw           s10, 40(sp)                   // push s10
              sw           s11, 44(sp)                   // push s11

              lw           s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] =>  x[ 0 ] = xstate[ 0 ]
              lw           s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] =>  x[ 1 ] = xstate[ 1 ]
              lw           s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] =>  x[ 2 ] = xstate[ 2 ]
              lw           s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] =>  x[ 3 ] = xstate[ 3 ]

              lw           s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] =>  y[ 0 ] = ystate[ 0 ]
              lw           s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] =>  y[ 1 ] = ystate[ 1 ]
              lw           s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] =>  y[ 2 ] = ystate[ 2 ]
              lw           s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] =>  y[ 3 ] = ystate[ 3 ]

              lw           s8,   0(a3)                   // s8  = MEM[ a3 +  0 ] => tk[ 0 ] =  tweak[ 0 ]
              lw           s9,   4(a3)                   // s9  = MEM[ a3 +  4 ] => tk[ 1 ] =  tweak[ 1 ]
              lw           s10,  8(a3)                   // s10 = MEM[ a3 +  8 ] => tk[ 2 ] =  tweak[ 2 ]
              lw           s11, 12(a3)                   // s11 = MEM[ a3 + 12 ] => tk[ 3 ] =  tweak[ 3 ]

              li           t2,     16                    // t2  = 16             => i = 16
              li           t3,      0                    // t3  =  0             => n =  0
.endm

.macro TRAXL17_DEC_EPILOGUE
              sw           s0,   0(a0)                   // s0  = MEM[ a0 +  0 ] =>  x[ 0 ] = xstate[ 0 ]
              sw           s1,   4(a0)                   // s1  = MEM[ a0 +  4 ] =>  x[ 1 ] = xstate[ 1 ]
              sw           s2,   8(a0)                   // s2  = MEM[ a0 +  8 ] =>  x[ 2 ] = xstate[ 2 ]
              sw           s3,  12(a0)                   // s3  = MEM[ a0 + 12 ] =>  x[ 3 ] = xstate[ 3 ]

              sw           s4,   0(a1)                   // s4  = MEM[ a1 +  0 ] =>  y[ 0 ] = ystate[ 0 ]
              sw           s5,   4(a1)                   // s5  = MEM[ a1 +  4 ] =>  y[ 1 ] = ystate[ 1 ]
              sw           s6,   8(a1)                   // s6  = MEM[ a1 +  8 ] =>  y[ 2 ] = ystate[ 2 ]
              sw           s7,  12(a1)                   // s7  = MEM[ a1 + 12 ] =>  y[ 3 ] = ystate[ 3 ]

              lw           s0,   0(sp)                   // pop  s0
              lw           s1,   4(sp)                   // pop  s1
              lw           s2,   8(sp)                   // pop  s2
              lw           s3,  12(sp)                   // pop  s3
              lw           s4,  16(sp)                   // pop  s4
              lw           s5,  20(sp)                   // pop  s5
              lw           s6,  24(sp)                   // pop  s6
              lw           s7,  28(sp)                   // pop  s7
              lw           s8,  32(sp)                   // pop  s8
              lw           s9,  36(sp)                   // pop  s9
              lw           s10, 40(sp)                   // pop  s10
              lw           s11, 44(sp)                   // pop  s11
              addi         sp, sp,  48                   // adjust SP

              ret                                        // return
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => add tweak

.macro TRAXL17_ADD_TWEAK 
              xor          s0,  s0,  s8                  // x0 ^= tk[ 0 ]
              xor          s4,  s4,  s9                  // y0 ^= tk[ 1 ]
              xor          s1,  s1,  s10                 // x1 ^= tk[ 2 ]
              xor          s5,  s5,  s11                 // y1 ^= tk[ 3 ]
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt linear layer

.macro TRAXL17_ENC_LINEAR 
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
.endm

.macro TRAXL17_DEC_LINEAR 
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
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => add subkeys

.macro TRAXL17_ADD_SUBKEY sk
              lw           t6,  0(\sk)
              xor          s0,  s0,  t6
              lw           t6,  4(\sk)
              xor          s4,  s4,  t6
              lw           t6,  8(\sk)
              xor          s1,  s1,  t6
              lw           t6, 12(\sk)
              xor          s5,  s5,  t6
              lw           t6, 16(\sk)
              xor          s2,  s2,  t6
              lw           t6, 20(\sk)
              xor          s6,  s6,  t6
              lw           t6, 24(\sk)
              xor          s3,  s3,  t6
              lw           t6, 28(\sk)
              xor          s7,  s7,  t6
.endm

// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt substitution

#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
.macro TRAXL17_ENC_SUBS rc
              lw          t4,     0(\rc)                 // t4 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_ENC s0, s4, t4, t5, t6
              lw          t4,     4(\rc)                 // t4 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_ENC s1, s5, t4, t5, t6
              lw          t4,     8(\rc)                 // t4 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_ENC s2, s6, t4, t5, t6
              lw          t4,    12(\rc)                 // t4 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_ENC s3, s7, t4, t5, t6
.endm

.macro TRAXL17_DEC_SUBS rc
              lw          t4,     0(\rc)                 // t4 = MEM[ \rc +  0 ] => TRAXL1710_RCON[ 0/4 ]
              ALZETTE_DEC s0, s4, t4, t5, t6
              lw          t4,     4(\rc)                 // t4 = MEM[ \rc +  4 ] => TRAXL1710_RCON[ 1/5 ]
              ALZETTE_DEC s1, s5, t4, t5, t6
              lw          t4,     8(\rc)                 // t4 = MEM[ \rc +  8 ] => TRAXL1710_RCON[ 2/6 ]
              ALZETTE_DEC s2, s6, t4, t5, t6
              lw          t4,    12(\rc)                 // t4 = MEM[ \rc + 12 ] => TRAXL1710_RCON[ 3/7 ]
              ALZETTE_DEC s3, s7, t4, t5, t6
.endm
#endif

#if ( RV32_TYPE4 )
.macro TRAXL17_ENC_SUBS rc
              alz.whole.enci.x t4, s0, s4,   \rc
              alz.whole.enci.y s4, s0, s4,   \rc
              mv               s0, t4
              alz.whole.enci.x t4, s1, s5, 1+\rc
              alz.whole.enci.y s5, s1, s5, 1+\rc
              mv               s1, t4
              alz.whole.enci.x t4, s2, s6, 2+\rc
              alz.whole.enci.y s6, s2, s6, 2+\rc
              mv               s2, t4
              alz.whole.enci.x t4, s3, s7, 3+\rc
              alz.whole.enci.y s7, s3, s7, 3+\rc
              mv               s3, t4
.endm

.macro TRAXL17_DEC_SUBS rc
              alz.whole.deci.x t4, s0, s4,   \rc
              alz.whole.deci.y s4, s0, s4,   \rc
              mv               s0, t4
              alz.whole.deci.x t4, s1, s5, 1+\rc
              alz.whole.deci.y s5, s1, s5, 1+\rc
              mv               s1, t4
              alz.whole.deci.x t4, s2, s6, 2+\rc
              alz.whole.deci.y s6, s2, s6, 2+\rc
              mv               s2, t4
              alz.whole.deci.x t4, s3, s7, 3+\rc
              alz.whole.deci.y s7, s3, s7, 3+\rc
              mv               s3, t4
.endm
#endif
	
// ----------------------------------------------------------------------------
// TRAXL17 implementation => en/decrypt step
	
#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 ) || ( RV32_TYPE4 )
.macro TRAXL17_ENC_STEP_EVE sk, rc
              TRAXL17_ADD_SUBKEY \sk
              TRAXL17_ENC_SUBS   \rc            
              TRAXL17_ENC_LINEAR

              addi         \sk, \sk, 32                  //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                    //  t2 =  t2 + 1        => step++
#endif
.endm     

.macro TRAXL17_ENC_STEP_ODD sk, rc
              TRAXL17_ADD_TWEAK
              TRAXL17_ADD_SUBKEY \sk
              TRAXL17_ENC_SUBS   \rc                          
              TRAXL17_ENC_LINEAR

              addi         \sk, \sk, 32                  //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2, t2,  1                    //  t2 =  t2 + 1        => step++
#endif
.endm   

.macro TRAXL17_DEC_STEP_EVE sk, rc
              TRAXL17_DEC_LINEAR
              TRAXL17_DEC_SUBS   \rc            
              TRAXL17_ADD_SUBKEY \sk

              addi         \sk, \sk, -32                 //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                  //  t2 =  t2 - 1        => step++
#endif
.endm       

.macro TRAXL17_DEC_STEP_ODD sk, rc
              TRAXL17_DEC_LINEAR
              TRAXL17_DEC_SUBS   \rc            
              TRAXL17_ADD_SUBKEY \sk
              TRAXL17_ADD_TWEAK

              addi         \sk, \sk, -32                 //                      => sk +=  8
#if !( TRAXL17_ENC_UNROLL )
              addi         t2,   t2, -1                  //  t2 =  t2 - 1        => step++
#endif
.endm   
#endif

// ----------------------------------------------------------------------------	
// TRAXL17 implementation => encrypt

#if ( TRAXL17_ENC_EXTERN )
.section .text
  
.global traxl17_enc

traxl17_enc:  TRAXL17_ENC_PROLOGUE

#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
              mv           t0, a2                        // t0 = &subkeys
              la           t1, TRAXL17_RCON              // t1 = &TRAXL17_RCON
              addi         a7, t1,  16                   // a7 = &TRAXL17_RCON[4]
#if ( TRAXL17_ENC_UNROLL )             
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7 
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
#else             
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              TRAXL17_ENC_STEP_EVE t0, t1    
              TRAXL17_ENC_STEP_ODD t0, a7
              j                    0b                    //            goto 0
#endif
1:            
              TRAXL17_ENC_STEP_EVE t0, t1
              TRAXL17_ADD_SUBKEY   t0
                 
#endif

#if ( RV32_TYPE4 )
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

#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
              addi         t0, a2,  544                  // t0 = &subkeys[17]
                       
              la           t1, TRAXL17_RCON              // t1 = &TRAXL17_RCON
              addi         a7, t1,  16                   // a7 = &TRAXL17_RCON[4]

              TRAXL17_ADD_SUBKEY   t0
              addi         t0, t0, -32                   //                      => sk -=  8
              TRAXL17_DEC_STEP_EVE t0, t1
#if ( TRAXL17_DEC_UNROLL )         
              TRAXL17_DEC_STEP_ODD t0, a7    
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7 
              TRAXL17_DEC_STEP_EVE t0, t1    
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    

#else             
0:            blez         t2,     1f                    // if i <= 0, goto 1
              TRAXL17_DEC_STEP_ODD t0, a7
              TRAXL17_DEC_STEP_EVE t0, t1    
              j                    0b                    //            goto 0
#endif
1:           
            
#endif

#if ( RV32_TYPE4 )
              addi         t0, a2,  544                  // t0 = &subkeys[17]
              TRAXL17_ADD_SUBKEY   t0
              addi         t0, t0, -32                   //                      => sk -=  8
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
