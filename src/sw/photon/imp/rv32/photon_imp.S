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
// a1  => uint8_t* rc
// a2  => i
// a3  => n
// a4  => s_0
// a5  => s_1
// a6  => s_2
// a7  => s_3

// t0  => s_4
// t1  => s_5
// t2  => s_6
// t3  => s_7
// t4  => t_0
// t5  => t_1
// t6  => t_2

// s0  => t_3
// s1  => t_4
// s2  => t_5
// s3  => t_6
// s4  => t_7
// s5  => 
// s6  => 
// s7  =>
// s8  =>
// s9  =>
// s10 =>
// s11 =>

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => conversion

.macro PHOTON_MATRIX_INTO
                          li                   a4,        0
                          li                   a5,        0
                          li                   a6,        0
                          li                   a7,        0
                          li                   t0,        0
                          li                   t1,        0
                          li                   t2,        0
                          li                   t3,        0

                          li                   t4,        0     // i     =  0
                          li                   t5,       32     // n     = 32
                          mv                   t6,  a0          // t     = &x

\@0:                      lw                   s0,        0(t6)
                          addi                 t6,  t6,   4

                          srli                 s1,  s0,   0
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   a4,  a4,  s1
                          srli                 s1,  s0,   4
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   a5,  a5,  s1
                          srli                 s1,  s0,   8
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   a6,  a6,  s1
                          srli                 s1,  s0,  12
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   a7,  a7,  s1
                          srli                 s1,  s0,  16
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   t0,  t0,  s1
                          srli                 s1,  s0,  20
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   t1,  t1,  s1
                          srli                 s1,  s0,  24
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   t2,  t2,  s1
                          srli                 s1,  s0,  28
                          andi                 s1,  s1, 0xF
                          sll                  s1,  s1,  t4
                          or                   t3,  t3,  s1

                          addi                 t4,  t4,   4     // i     = i + 4
                          bgeu                 t4,  t5, \@1f    // if i >= n, goto 1
                          
                          j                             \@0b    //            goto 0
\@1:
.endm

.macro PHOTON_MATRIX_FROM
                          li                   t4,        0     // i     =  0
                          li                   t5,       32     // n     = 32
                          mv                   t6,  a0          // t     = &x

\@0:                      li                   s0,        0

                          srl                  s1,  a4,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,   0
                          or                   s0,  s0,  s1
                          srl                  s1,  a5,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,   4
                          or                   s0,  s0,  s1
                          srl                  s1,  a6,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,   8
                          or                   s0,  s0,  s1
                          srl                  s1,  a7,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,  12
                          or                   s0,  s0,  s1
                          srl                  s1,  t0,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,  16
                          or                   s0,  s0,  s1
                          srl                  s1,  t1,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,  20
                          or                   s0,  s0,  s1
                          srl                  s1,  t2,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,  24
                          or                   s0,  s0,  s1
                          srl                  s1,  t3,  t4
                          andi                 s1,  s1, 0xF
                          slli                 s1,  s1,  28
                          or                   s0,  s0,  s1

                          sw                   s0,        0(t6)
                          addi                 t6,  t6,   4    

                          addi                 t4,  t4,   4     // i     = i + 4
                          bgeu                 t4,  t5, \@1f    // if i >= n, goto 1
                          
                          j                             \@0b    //            goto 0
\@1:
.endm

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => prologue

.macro PHOTON_PROLOGUE
                          addi                 sp,  sp, -20     // adjust SP
                          sw                   s0,        0(sp) // push s0
                          sw                   s1,        4(sp) // push s1
                          sw                   s2,        8(sp) // push s2
                          sw                   s3,       12(sp) // push s3
                          sw                   s4,       16(sp) // push s4

                          la                   a1,       RC     //       = &RC
#if !( PHOTON_RV32_UNROLL )
                          li                   a2,        0     // i     =  0
                          li                   a3,       12     // n     = 12
#endif

                          PHOTON_MATRIX_INTO
.endm

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => epilogue

.macro PHOTON_EPILOGUE
                          PHOTON_MATRIX_FROM

                          lw                   s0,        0(sp) // pop  s0
                          lw                   s1,        4(sp) // pop  s1
                          lw                   s2,        8(sp) // pop  s2
                          lw                   s3,       12(sp) // pop  s3
                          lw                   s4,       16(sp) // pop  s4
                          addi                 sp,  sp,  20     // adjust SP

                          ret                                   // return
.endm

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => round TYPE_1

#if  ( PHOTON_RV32_TYPE1 )

// r <- s7 || s6 || s5 || s4 || s3 || s2 || s1 || s0

.macro PHOTON_PACK r, s0, s1, s2, s3, s4, s5, s6, s7, t0, t1
  andi   \r,  \s0, 0x0F
  andi   \t0, \s1, 0xF0
  xor    \r,  \r,  \t0
  li     \t1, 0xF
  slli   \t1, \t1, 8
  and    \t0, \s2, \t1
  xor    \r,  \r,  \t0
  slli   \t1, \t1, 4
  and    \t0, \s3, \t1
  xor    \r,  \r,  \t0
  slli   \t1, \t1, 4
  and    \t0, \s4, \t1
  xor    \r,  \r,  \t0
  slli   \t1, \t1, 4
  and    \t0, \s5, \t1
  xor    \r,  \r,  \t0
  slli   \t1, \t1, 4
  and    \t0, \s6, \t1
  xor    \r,  \r,  \t0
  slli   \t1, \t1, 4
  and    \t0, \s7, \t1
  xor    \r,  \r,  \t0
.endm

// s <- SBox[s7] || SBox[s6] || SBox[s5] || SBox[s4] || 
//      SBox[s3] || SBox[s2] || SBox[s1] || SBox[s0]

.macro PHOTON_SBOX s0, t0
  xor    \t0, \s0, s10
  xperm4 \s0,  s5, \s0
  xperm4 \t0,  s6, \t0
  xor    \s0, \s0, \t0
.endm

// r <- y * (M7 || M6 || M5 || M4 || M3 || M2 || M1 || M0)

.macro PHOTON_GF2NMUL r, y, x, t, imm
  lw   \x,  \imm(s9)
  andi \t, \y,  1            
  sub  \t, x0, \t             
  and  \r, \t, \x 

  lw   \x,  \imm+4(s9)
  srli \t, \y, 1
  andi \t, \t, 1             
  sub  \t, x0, \t             
  and  \t, \t, \x             
  xor  \r, \r, \t 

  lw   \x,  \imm+8(s9)
  srli \t, \y, 2
  andi \t, \t, 1             
  sub  \t, x0, \t             
  and  \t, \t, \x             
  xor  \r, \r, \t 

  lw   \x,  \imm+12(s9)
  srli \t, \y, 3
  andi \t, \t, 1             
  sub  \t, x0, \t             
  and  \t, \t, \x             
  xor  \r, \r, \t
.endm

.macro PHOTON_STEP r, x, y, t0, t1, t2, imm
  PHOTON_GF2NMUL \t0, \y, \t1, \t2, \imm
  xor  \r, \x, \t0
  srli \y, \y, 4 
.endm

.macro PHOTON_COLUMN r, s0, s1, s2, s3, s4, s5, s6, s7
  PHOTON_PACK        s7, \s0, \s1, \s2, \s3, \s4, \s5, \s6, \s7, a2, a3
  PHOTON_SBOX        s7, a2
  PHOTON_STEP        \r, x0, s7, a2, a3, s8, 0
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 16
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 32
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 48
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 64
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 80
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 96
  PHOTON_STEP        \r, \r, s7, a2, a3, s8, 112
.endm

.section .data

.align 2

GFMUL_CONST:
.word 0xFC9F14C2, 0xDB1D28B4, 0x95294358, 0x1A4186A3
.word 0x12EC6494, 0x24FBC818, 0x48D5B323, 0x839A5646
.word 0xD2595D82, 0x94A1A934, 0x18727168, 0x23E4E2C3
.word 0xAAFD1DDB, 0x77D92995, 0xEE91411A, 0xFF128227
.word 0x534EC972, 0xA68FB1E4, 0x7C3D52F8, 0xEB69A4D3
.word 0xA1C5D478, 0x72BA98E3, 0xE45713F6, 0xF8AE26DC
.word 0x219EFD55, 0x421FD9AA, 0x842D9177, 0x384912EE
.word 0x3E6DE926, 0x6FC9F14C, 0xCDB1D28B, 0xB9529435

#endif

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => round TYPE_2

#if  ( PHOTON_RV32_TYPE2 )
.macro PHOTON_COLUMN r, s0, s1, s2, s3, s4, s5, s6, s7
                          photon.step          \r, x0, \s0, 0
                          photon.step          \r, \r, \s1, 1
                          photon.step          \r, \r, \s2, 2
                          photon.step          \r, \r, \s3, 3
                          photon.step          \r, \r, \s4, 4
                          photon.step          \r, \r, \s5, 5
                          photon.step          \r, \r, \s6, 6
                          photon.step          \r, \r, \s7, 7
.endm
#endif

.macro PHOTON_ROUND_EVN I
                          lw                   t4,     0(a1)
                          xor                  a4, a4, t4
                          add                  a1, a1, 4

                          PHOTON_COLUMN        t4, a4, a5, a6, a7, t0, t1, t2, t3
                          PHOTON_COLUMN        t5, a5, a6, a7, t0, t1, t2, t3, a4
                          PHOTON_COLUMN        t6, a6, a7, t0, t1, t2, t3, a4, a5
                          PHOTON_COLUMN        s0, a7, t0, t1, t2, t3, a4, a5, a6
                          PHOTON_COLUMN        s1, t0, t1, t2, t3, a4, a5, a6, a7
                          PHOTON_COLUMN        s2, t1, t2, t3, a4, a5, a6, a7, t0
                          PHOTON_COLUMN        s3, t2, t3, a4, a5, a6, a7, t0, t1
                          PHOTON_COLUMN        s4, t3, a4, a5, a6, a7, t0, t1, t2
.endm

.macro PHOTON_ROUND_ODD I
                          lw                   a4,     0(a1)
                          xor                  t4, t4, a4
                          add                  a1, a1, 4

                          PHOTON_COLUMN        a4, t4, t5, t6, s0, s1, s2, s3, s4
                          PHOTON_COLUMN        a5, t5, t6, s0, s1, s2, s3, s4, t4
                          PHOTON_COLUMN        a6, t6, s0, s1, s2, s3, s4, t4, t5
                          PHOTON_COLUMN        a7, s0, s1, s2, s3, s4, t4, t5, t6
                          PHOTON_COLUMN        t0, s1, s2, s3, s4, t4, t5, t6, s0
                          PHOTON_COLUMN        t1, s2, s3, s4, t4, t5, t6, s0, s1
                          PHOTON_COLUMN        t2, s3, s4, t4, t5, t6, s0, s1, s2
                          PHOTON_COLUMN        t3, s4, t4, t5, t6, s0, s1, s2, s3
.endm


// ----------------------------------------------------------------------------
// PHOTON_256 implementation => round constants

.section .data

.align 2

RC:                       .word 0x9DFE6201
                          .word 0xBFDC4023
                          .word 0xFB980467
                          .word 0x62019DFE
                          .word 0x5132AECD
                          .word 0x3754C8AB
                          .word 0xEA891576
                          .word 0x4023BFDC
                          .word 0x1576EA89
                          .word 0xAECD5132
                          .word 0xD9BA2645
                          .word 0x2645D9BA

// ----------------------------------------------------------------------------
// PHOTON_256 implementation => permutation

.section .text
  
.global PHOTON_Permutation

PHOTON_Permutation:       PHOTON_PROLOGUE

#if  ( PHOTON_RV32_TYPE2 )
#if !( PHOTON_RV32_UNROLL )
0:                        PHOTON_ROUND_EVN
                          PHOTON_ROUND_ODD

                          addi                 a2,  a2,   2     // i     = i + 2
                          bgeu                 a2,  a3,   1f    // if i >= n, goto 1
                          
                          j                               0b    //            goto 0
#else
                          .set I,     0
                          .rept 6
                          PHOTON_ROUND_EVN I + 0
                          PHOTON_ROUND_ODD I + 1
                          .set I, I + 2
                          .endr
#endif
#elif( PHOTON_RV32_TYPE1 )
  addi sp, sp, -24 
  sw   s5,   0(sp)
  sw   s6,   4(sp)
  sw   s7,   8(sp)
  sw   s8,  12(sp)
  sw   s9,  16(sp)
  sw   s10, 20(sp)
  li   s5,  0xDA09B65C
  li   s6,  0x21748FE3
  la   s9,  GFMUL_CONST
  li   s10, 0x88888888
  PHOTON_ROUND_EVN
  PHOTON_ROUND_ODD
  PHOTON_ROUND_EVN
  PHOTON_ROUND_ODD
  PHOTON_ROUND_EVN
  PHOTON_ROUND_ODD
  PHOTON_ROUND_EVN
  PHOTON_ROUND_ODD
  PHOTON_ROUND_EVN
  PHOTON_ROUND_ODD
  PHOTON_ROUND_EVN
  PHOTON_ROUND_ODD
  lw   s5,   0(sp)
  lw   s6,   4(sp)
  lw   s7,   8(sp)
  lw   s8,  12(sp)
  lw   s9,  16(sp)
  lw   s10, 20(sp)
  addi sp, sp, 24 
#endif

1:                        PHOTON_EPILOGUE

// ============================================================================
