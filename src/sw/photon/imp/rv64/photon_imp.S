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

// a0  => uint8_t* x
// a1  =>
// a2  => i
// a3  => n
// a4  =>
// a5  => 
// a6  => 
// a7  => 

// t0  =>
// t1  =>
// t2  =>
// t3  =>
// t4  => 
// t5  => 
// t6  =>

// s0  =>
// s1  =>
// s2  =>
// s3  =>
// s4  =>
// s5  =>
// s6  =>
// s7  =>
// s8  =>
// s9  =>
// s10 =>
// s11 =>

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => prologue

.macro PHOTON_PROLOGUE

.endm

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => epilogue

.macro PHOTON_EPILOGUE

.endm

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => round TYPE_1

#if  ( PHOTON_RV64_TYPE1 )
#error "can't use PHOTON_RV64_TYPE1: not yet implemented!"
#endif

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => round TYPE_2

#if  ( PHOTON_RV64_TYPE2 )
#error "can't use PHOTON_RV64_TYPE2: not yet implemented!"
#endif

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => permutation

.section .text
  
.global PHOTON_Permutation

PHOTON_Permutation : PHOTON_PROLOGUE

#if !( PHOTON_UNROLL )
0:                   PHOTON_ROUND_EVN
                     PHOTON_ROUND_ODD

                     addi                 a2,  a2,   1     // i     = i + 1
                     bgeu                 a2,  a3,   1f    // if i >= n, goto 1
                          
                     j                               0b    //            goto 0
#else
                     .rept 6
                     PHOTON_ROUND_EVN
                     PHOTON_ROUND_ODD
                     .endr
#endif

1:                   PHOTON_EPILOGUE

// ============================================================================
