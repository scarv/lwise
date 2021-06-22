// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#include     "ise.h"
#include "alzette.h"

// ============================================================================
// register allocation

// t0  => state[ 0 ] = xw
// t1  => state[ 1 ] = yw
// t2  => i          ~ loop counter 
// t3  => n          ~ loop bound
// t4  => temp
// t5  => temp
// t6  => temp

// s0  =>   key[ 0 ] = k0
// s1  =>   key[ 1 ] = k1
// s2  =>   key[ 2 ] = k2
// s3  =>   key[ 3 ] = k3
// s4  =>  &CRAXS10_RCON

// ============================================================================
// CRAXS10 implementation => en/decrypt prologue + epilogue

.macro CRAXS10_ENC_PROLOGUE
              addi         sp, sp, -20                   // adjust SP
              sw           s0,  0(sp)                    // push s0
              sw           s1,  4(sp)                    // push s1
              sw           s2,  8(sp)                    // push s2
              sw           s3, 12(sp)                    // push s3
              sw           s4, 16(sp)                    // push s4
              
              lw           t0,  0(a0)                    // t0 = MEM[ a0 +  0 ]  => xw = state[ 0 ]
              lw           t1,  4(a0)                    // t1 = MEM[ a0 +  4 ]  => yw = state[ 1 ]
#if !( CRAXS10_ENC_UNROLL )
              li           t2,  0                        // t2 =  0              => i =  0
              li           t3, 10                        // t3 = 10              => n = 10
#endif	
              lw           s0,  0(a1)                    // s0 = MEM[ a1 +  0 ]  => k0 =   key[ 0 ]
              lw           s1,  4(a1)                    // s1 = MEM[ a1 +  4 ]  => k1 =   key[ 1 ]
              lw           s2,  8(a1)                    // s2 = MEM[ a1 +  8 ]  => k2 =   key[ 2 ]
              lw           s3, 12(a1)                    // s3 = MEM[ a1 + 12 ]  => k3 =   key[ 3 ]
.endm

.macro CRAXS10_ENC_EPILOGUE
              sw           t0,  0(a0)                    // MEM[ a0 +  0 ] = t0  => state[ 0 ] = xw
              sw           t1,  4(a0)                    // MEM[ a0 +  4 ] = t1  => state[ 1 ] = yw

              lw           s0,  0(sp)                    // pop  s0
              lw           s1,  4(sp)                    // pop  s1
              lw           s2,  8(sp)                    // pop  s2
              lw           s3, 12(sp)                    // pop  s3
              lw           s4, 16(sp)                    // pop  s4
              addi         sp, sp,  20                   // adjust SP

              ret                                        // return
.endm

.macro CRAXS10_DEC_PROLOGUE
              addi         sp, sp, -20                   // adjust SP
              sw           s0,  0(sp)                    // push s0
              sw           s1,  4(sp)                    // push s1
              sw           s2,  8(sp)                    // push s2
              sw           s3, 12(sp)                    // push s3
              sw           s4, 16(sp)                    // push s4

              lw           t0,  0(a0)                    // t0 = MEM[ a0 +  0 ]  => xw = state[ 0 ]
              lw           t1,  4(a0)                    // t1 = MEM[ a0 +  4 ]  => yw = state[ 1 ]
#if !( CRAXS10_DEC_UNROLL )
              li           t2,     10                    // t2 =  10             => i = 10
              li           t3,      0                    // t3 =   0             => n =  0
#endif
              lw           s0,  0(a1)                    // s0 = MEM[ a1 +  0 ]  => k0 =   key[ 0 ]
              lw           s1,  4(a1)                    // s1 = MEM[ a1 +  4 ]  => k1 =   key[ 1 ]
              lw           s2,  8(a1)                    // s2 = MEM[ a1 +  8 ]  => k2 =   key[ 2 ]
              lw           s3, 12(a1)                    // s3 = MEM[ a1 + 12 ]  => k3 =   key[ 3 ]
.endm

.macro CRAXS10_DEC_EPILOGUE
              sw           t0,  0(a0)                    // MEM[ a0 +  0 ] = t0  => state[ 0 ] = xw
              sw           t1,  4(a0)                    // MEM[ a0 +  4 ] = t1  => state[ 1 ] = yw

              lw           s0,  0(sp)                    // pop  s0
              lw           s1,  4(sp)                    // pop  s1
              lw           s2,  8(sp)                    // pop  s2
              lw           s3, 12(sp)                    // pop  s3
              lw           s4, 16(sp)                    // pop  s4
              addi         sp, sp,  20                   // adjust SP

              ret                                        // return
.endm

// ----------------------------------------------------------------------------
// CRAXS10 implementation => en/decrypt step
	
#if ( ALZETTE_RV32_TYPE1 ) || ( ALZETTE_RV32_TYPE2 ) || ( ALZETTE_RV32_TYPE3 )
.macro CRAXS10_ENC_STEP xw, yw, xk, yk, i
#if ( CRAXS10_ENC_UNROLL )
              xori         t5, \xk, \i                   //  t5 = \xk ^ \i       =>        ( \xk ^ step )
#else
              xor          t5, \xk,  t2                  //  t5 = \xk ^  t2      =>        ( \xk ^ step )
              addi         t2,  t2,  1                   //  t2 =  t2 + 1        => step++
#endif
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => \xw ^= ( \xk ^ step )
              xor         \yw, \yw, \yk                  // \yw = \yw ^ \yk      => \yw ^= ( \yk        )
#if ( CRAXS10_ENC_UNROLL )
              lw           t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              lw           t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
              addi         s4,  s4,  4                   //  s4 =  s4 + 4
#endif
              ALZETTE_ENC \xw, \yw,  t4, t5, t6          //                      => ALZETTE_ENC
.endm          

.macro CRAXS10_DEC_STEP xw, yw, xk, yk, i
#if ( CRAXS10_DEC_UNROLL )
              lw           t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              addi         s4,  s4, -4                   //  s4 =  s4 - 4
              lw           t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#endif
              ALZETTE_DEC \xw, \yw,  t4, t5, t6          //                      => ALZETTE_DEC
#if ( CRAXS10_DEC_UNROLL )
              xori         t5, \xk, \i                   //  t5 = \xk ^ \i       =>        ( \xk ^ step )
#else
              addi         t2,  t2, -1                   //  t2 =  t2 - 1        => step--
              xor          t5, \xk,  t2                  //  t5 = \xk ^  t2      =>        ( \xk ^ step )
#endif
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => \xw ^= ( \xk ^ step )
              xor         \yw, \yw, \yk                  // \yw = \yw ^ \yk      => \yw ^= ( \yk        )
.endm
#endif

#if ( ALZETTE_RV32_TYPE4 )
.macro CRAXS10_ENC_STEP xr, yr, xw, yw, xk, yk, i, j
              xori         t5, \xk, \i                   //  t5 = \xk ^  t2      =>        ( \xk ^ step )
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => \xw ^= ( \xk ^ step )
              xor         \yw, \yw, \yk                  // \yw = \yw ^ \yk      => \yw ^= ( \yk        )
              ALZETTE_ENC \xr, \yr, \xw, \yw, \j         //                      => ALZETTE_ENC
.endm

.macro CRAXS10_DEC_STEP xr, yr, xw, yw, xk, yk, i, j
              ALZETTE_DEC \xr, \yr, \xw, \yw, \j         //                      => ALZETTE_DEC
              xori         t5, \xk, \i                   //  t5 = \xk ^  t2      =>        ( \xk ^ step )
              xor         \xr, \xr,  t5                  // \xw = \xw ^  t5      => \xw ^= ( \xk ^ step )
              xor         \yr, \yr, \yk                  // \yw = \yw ^ \yk      => \yw ^= ( \yk        )
.endm       
#endif

// ----------------------------------------------------------------------------	
// CRAXS10 implementation => encrypt

#if ( CRAXS10_ENC_EXTERN )
.section .text
  
.global craxs10_enc

craxs10_enc:  CRAXS10_ENC_PROLOGUE

#if ( ALZETTE_RV32_TYPE1 ) || ( ALZETTE_RV32_TYPE2 ) || ( ALZETTE_RV32_TYPE3 )
              la           s4, CRAXS10_RCON              // s4 = &CRAXS10_RCON
#if ( CRAXS10_ENC_UNROLL )             
              CRAXS10_ENC_STEP t0, t1, s0, s1,         0    
              CRAXS10_ENC_STEP t0, t1, s2, s3,         1
              CRAXS10_ENC_STEP t0, t1, s0, s1,         2    
              CRAXS10_ENC_STEP t0, t1, s2, s3,         3
              CRAXS10_ENC_STEP t0, t1, s0, s1,         4    
              CRAXS10_ENC_STEP t0, t1, s2, s3,         5
              CRAXS10_ENC_STEP t0, t1, s0, s1,         6    
              CRAXS10_ENC_STEP t0, t1, s2, s3,         7
              CRAXS10_ENC_STEP t0, t1, s0, s1,         8    
              CRAXS10_ENC_STEP t0, t1, s2, s3,         9
#else             
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              CRAXS10_ENC_STEP t0, t1, s0, s1    
              CRAXS10_ENC_STEP t0, t1, s2, s3
              j                    0b                    //            goto 0
#endif
1:            xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#endif

#if ( ALZETTE_RV32_TYPE4 )
#if ( CRAXS10_ENC_UNROLL )
              CRAXS10_ENC_STEP t2, t3, t0, t1, s0, s1, 0, 0
              CRAXS10_ENC_STEP t0, t1, t2, t3, s2, s3, 1, 1
              CRAXS10_ENC_STEP t2, t3, t0, t1, s0, s1, 2, 2
              CRAXS10_ENC_STEP t0, t1, t2, t3, s2, s3, 3, 3
              CRAXS10_ENC_STEP t2, t3, t0, t1, s0, s1, 4, 4
              CRAXS10_ENC_STEP t0, t1, t2, t3, s2, s3, 5, 0
              CRAXS10_ENC_STEP t2, t3, t0, t1, s0, s1, 6, 1
              CRAXS10_ENC_STEP t0, t1, t2, t3, s2, s3, 7, 2
              CRAXS10_ENC_STEP t2, t3, t0, t1, s0, s1, 8, 3
              CRAXS10_ENC_STEP t0, t1, t2, t3, s2, s3, 9, 4
#else	
#error "can't use ALZETTE_RV32_TYPE4 without CRAXS10_ENC_UNROLL"
#endif
1:            xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#endif

              CRAXS10_ENC_EPILOGUE
#endif

// ----------------------------------------------------------------------------	
// CRAXS10 implementation => decrypt

#if ( CRAXS10_DEC_EXTERN )
.section .text
  
.global craxs10_dec

craxs10_dec:  CRAXS10_DEC_PROLOGUE

#if ( ALZETTE_RV32_TYPE1 ) || ( ALZETTE_RV32_TYPE2 ) || ( ALZETTE_RV32_TYPE3 )
              la           s4, CRAXS10_RCON              // s4 = &CRAXS10_RCON

              xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#if ( CRAXS10_DEC_UNROLL )             
              CRAXS10_DEC_STEP t0, t1, s2, s3,         9
              CRAXS10_DEC_STEP t0, t1, s0, s1,         8
              CRAXS10_DEC_STEP t0, t1, s2, s3,         7
              CRAXS10_DEC_STEP t0, t1, s0, s1,         6
              CRAXS10_DEC_STEP t0, t1, s2, s3,         5
              CRAXS10_DEC_STEP t0, t1, s0, s1,         4
              CRAXS10_DEC_STEP t0, t1, s2, s3,         3
              CRAXS10_DEC_STEP t0, t1, s0, s1,         2
              CRAXS10_DEC_STEP t0, t1, s2, s3,         1
              CRAXS10_DEC_STEP t0, t1, s0, s1,         0
#else
              addi         s4, s4,  40                   // s4 = &CRAXS10_RCON + ( N_STEPS - 1 ) * sizeof( uint32_t )

0:            blez         t2,     1f                    // if i <= 0, goto 1
              CRAXS10_DEC_STEP t0, t1, s2, s3
              CRAXS10_DEC_STEP t0, t1, s0, s1
              j                    0b                    //            goto 0
#endif
#endif

#if ( ALZETTE_RV32_TYPE4 )
              xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#if ( CRAXS10_DEC_UNROLL )
              CRAXS10_DEC_STEP t2, t3, t0, t1, s2, s3, 9, 4
              CRAXS10_DEC_STEP t0, t1, t2, t3, s0, s1, 8, 3
              CRAXS10_DEC_STEP t2, t3, t0, t1, s2, s3, 7, 2
              CRAXS10_DEC_STEP t0, t1, t2, t3, s0, s1, 6, 1
              CRAXS10_DEC_STEP t2, t3, t0, t1, s2, s3, 5, 0
              CRAXS10_DEC_STEP t0, t1, t2, t3, s0, s1, 4, 4
              CRAXS10_DEC_STEP t2, t3, t0, t1, s2, s3, 3, 3
              CRAXS10_DEC_STEP t0, t1, t2, t3, s0, s1, 2, 2
              CRAXS10_DEC_STEP t2, t3, t0, t1, s2, s3, 1, 1
              CRAXS10_DEC_STEP t0, t1, t2, t3, s0, s1, 0, 0
#else	
#error "can't use ALZETTE_RV32_TYPE4 without CRAXS10_DEC_UNROLL"
#endif
#endif

1:            CRAXS10_DEC_EPILOGUE
#endif

// ============================================================================
