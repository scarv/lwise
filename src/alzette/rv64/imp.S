// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================
// register allocation

// t0 => state[ 0 ] = xw => yw || xw
// t1 => state[ 1 ] = yw
// t2 => i          ~ loop counter 
// t3 => n          ~ loop bound
// t4 => temp
// t5 => temp
// t6 => temp

// s0 =>   key[ 0 ] = k0 => k1 || k0
// s1 =>   key[ 1 ] = k1
// s2 =>   key[ 2 ] = k2 => k3 || k2
// s3 =>   key[ 3 ] = k3
// s4 =>  &CRAXS10_RCON

// ============================================================================
// ISE instruction definition

#if ( RV64B )
.macro alz.roriw        rd, rs1,      imm
.insn r CUSTOM_2,    0, \imm, \rd, \rs1,   x0
.endm
.macro alz.pack         rd, rs1, rs2
.insn r CUSTOM_2,    1,    0, \rd, \rs1, \rs2
.endm
.macro alz.packu        rd, rs1, rs2
.insn r CUSTOM_2,    2,    0, \rd, \rs1, \rs2
.endm
#endif

#if ( RV64_TYPE2 )
.macro alz.block.enci   rd, rs1, rs2, imm
.insn r CUSTOM_2,    3, \imm, \rd, \rs1, \rs2
.endm
.macro alz.block.deci   rd, rs1, rs2, imm
.insn r CUSTOM_2,    4, \imm, \rd, \rs1, \rs2
.endm
#endif

#if ( RV64_TYPE3 )
.macro alz.block.enc.0  rd, rs1, rs2
.insn r CUSTOM_3,    0,    0, \rd, \rs1, \rs2
.endm
.macro alz.block.enc.1  rd, rs1, rs2
.insn r CUSTOM_3,    0,    1, \rd, \rs1, \rs2
.endm
.macro alz.block.enc.2  rd, rs1, rs2
.insn r CUSTOM_3,    0,    2, \rd, \rs1, \rs2
.endm
.macro alz.block.enc.3  rd, rs1, rs2
.insn r CUSTOM_3,    0,    3, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.0  rd, rs1, rs2
.insn r CUSTOM_3,    0,    4, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.1  rd, rs1, rs2
.insn r CUSTOM_3,    0,    5, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.2  rd, rs1, rs2
.insn r CUSTOM_3,    0,    6, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.3  rd, rs1, rs2
.insn r CUSTOM_3,    0,    7, \rd, \rs1, \rs2
.endm
#endif

#if ( RV64_TYPE4 )
.macro alz.whole.enci   rd, rs1,      imm
.insn r CUSTOM_2,    5, \imm, \rd, \rs1,   x0
.endm
.macro alz.whole.deci   rd, rs1,      imm
.insn r CUSTOM_2,    6, \imm, \rd, \rs1,   x0
.endm
#endif
#if ( RV64_TYPE5 )
.macro alz.whole.enc    rd, rs1, rs2
.insn r CUSTOM_3,    0,    8, \rd, \rs1, \rs2
.endm
.macro alz.whole.dec    rd, rs1, rs2
.insn r CUSTOM_3,    0,    9, \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
// Alzette implementation

#if ( RV64B )
.macro ROR32 r, x, n
  alz.roriw         \r, \x,    \n
.endm
#else
.macro ROR32 r, x, n
  srliw             t5, \x,    \n
  slliw             t6, \x, 32-\n
  or                \r, t5, t6
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64_TYPE1 )
.macro ALZETTE_ENC xi, yi, ci
  ROR32             t5, \yi,  31 //  t5 = ROR32( \yi, 31 ) =>             yi >>> 31
  addw             \xi, \xi,  t5 // \xi = \xi + t5         => xi = xi + ( yi >>> 31 )
  ROR32             t5, \xi,  24 //  t5 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 24 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  ROR32             t5, \yi,  17 //  t5 = ROR32( \yi, 17 ) =>             yi >>> 17
  addw             \xi, \xi,  t5 // \xi = \xi + t5         => xi = xi + ( yi >>> 17 )
  ROR32             t5, \xi,  17 //  t5 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 17 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  addw             \xi, \xi, \yi // \xi = \xi + \yi        => xi = xi + ( yi >>>  0 )
  ROR32             t5, \xi,  31 //  t5 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 31 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  ROR32             t5, \yi,  24 //  t5 = ROR32( \yi, 24 ) =>             yi >>> 24
  addw             \xi, \xi,  t5 // \xi = \xi + t5         => xi = xi + ( yi >>> 24 )
  ROR32             t5, \xi,  16 //  t5 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 16 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
.endm

.macro ALZETTE_DEC xi, yi, ci
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  16 //  t5 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 16 )
  ROR32             t5, \yi,  24 //  t5 = ROR32( \yi, 24 ) =>             yi >>> 24
  subw             \xi, \xi,  t5 // \xi = \xi - t5         => xi = xi - ( yi >>> 24 )

  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  31 //  t5 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 31 )
  subw             \xi, \xi, \yi // \xi = \xi - \yi        => xi = xi - ( yi >>>  0 )

  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  17 //  t5 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 17 )
  ROR32             t5, \yi,  17 //  t5 = ROR32( \yi, 17 ) =>             yi >>> 17
  subw             \xi, \xi,  t5 // \xi = \xi - t5         => xi = xi - ( yi >>> 17 )

  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  24 //  t5 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 24 )
  ROR32             t5, \yi,  31 //  t5 = ROR32( \yi, 31 ) =>             yi >>> 31
  subw             \xi, \xi,  t5 // \xi = \xi - t5         => xi = xi - ( yi >>> 31 )
.endm
#endif

#if ( RV64_TYPE2 )
.macro ALZETTE_ENC xi, ci
  alz.block.enci   \xi, \xi, \ci, 0
  alz.block.enci   \xi, \xi, \ci, 1
  alz.block.enci   \xi, \xi, \ci, 2
  alz.block.enci   \xi, \xi, \ci, 3
.endm

.macro ALZETTE_DEC xi, ci
  alz.block.deci   \xi, \xi, \ci, 3
  alz.block.deci   \xi, \xi, \ci, 2
  alz.block.deci   \xi, \xi, \ci, 1
  alz.block.deci   \xi, \xi, \ci, 0
.endm
#endif

#if ( RV64_TYPE3 )
.macro ALZETTE_ENC xi, ci
  alz.block.enc.0  \xi, \xi, \ci
  alz.block.enc.1  \xi, \xi, \ci
  alz.block.enc.2  \xi, \xi, \ci
  alz.block.enc.3  \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, ci
  alz.block.dec.3  \xi, \xi, \ci
  alz.block.dec.2  \xi, \xi, \ci
  alz.block.dec.1  \xi, \xi, \ci
  alz.block.dec.0  \xi, \xi, \ci
.endm
#endif

#if ( RV64_TYPE4 )
.macro ALZETTE_ENC xi, ci, i
  alz.whole.enci   \xi, \xi, \i
.endm

.macro ALZETTE_DEC xi, ci, i
  alz.whole.deci   \xi, \xi, \i
.endm
#endif
#if ( RV64_TYPE5 )
.macro ALZETTE_ENC xi, ci
  alz.whole.enc    \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, ci
  alz.whole.dec    \xi, \xi, \ci
.endm
#endif

// ============================================================================
// CRAX    implementation => en/decrypt prologue + epilogue

.macro CRAXS10_ENC_PROLOGUE
              addi         sp, sp, -40                   // adjust SP
              sd           s0,  0(sp)                    // push s0
              sd           s1,  8(sp)                    // push s1
              sd           s2, 16(sp)                    // push s2
              sd           s3, 24(sp)                    // push s3
              sd           s4, 32(sp)                    // push s4

              lwu          t0,  0(a0)                    // t0 = MEM[ a0 +  0 ]  => xw = state[ 0 ]
              lwu          t1,  4(a0)                    // t1 = MEM[ a0 +  4 ]  => yw = state[ 1 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
#if ( RV64B )
              alz.pack     t0, t0, t1                    //                      => ( yw || xw )
#else	
              slli         t1, t1,  32                   // t1 = t1 << 32
              or           t0, t0, t1                    // t0 = t0 | t1         => ( yw || xw )
#endif
#endif
              li           t2,       0                   // t2 =  0              => i =  0
              li           t3,      10                   // t3 = 10              => n = 10
	
              lwu          s0,  0(a1)                    // s0 = MEM[ a1 +  0 ]  => k0 =   key[ 0 ]
              lwu          s1,  4(a1)                    // s1 = MEM[ a1 +  4 ]  => k1 =   key[ 1 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
#if ( RV64B )
              alz.pack     s0, s0, s1                    //                      => ( k1 || k0 )
#else
              slli         s1, s1,  32                   // s1 = s1 << 32
              or           s0, s0, s1                    // s0 = s0 | s1         => ( k1 || k0 )
#endif
#endif
              lwu          s2,  8(a1)                    // s2 = MEM[ a1 +  8 ]  => k2 =   key[ 2 ]
              lwu          s3, 12(a1)                    // s3 = MEM[ a1 + 12 ]  => k3 =   key[ 3 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
#if ( RV64B )
              alz.pack     s2, s2, s3                    //                      => ( k3 || k2 )
#else
              slli         s3, s3,  32                   // s3 = s3 << 32
              or           s2, s2, s3                    // s2 = s2 | s3         => ( k3 || k2 )
#endif
#endif
.endm

.macro CRAXS10_ENC_EPILOGUE
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              srli         t1, t0,  32                   // t1 = t0 >> 32        => ( yw || xw )
#endif
              sw           t0,  0(a0)                    // MEM[ a0 +  0 ] = t0  => state[ 0 ] = xw
              sw           t1,  4(a0)                    // MEM[ a0 +  4 ] = t1  => state[ 1 ] = yw

              ld           s0,  0(sp)                    // pop  s0
              ld           s1,  8(sp)                    // pop  s1
              ld           s2, 16(sp)                    // pop  s2
              ld           s3, 24(sp)                    // pop  s3
              ld           s4, 32(sp)                    // pop  s4
              addi         sp, sp,  40                   // adjust SP

              ret                                        // return
.endm

.macro CRAXS10_DEC_PROLOGUE
              addi         sp, sp, -40                   // adjust SP
              sd           s0,  0(sp)                    // push s0
              sd           s1,  8(sp)                    // push s1
              sd           s2, 16(sp)                    // push s2
              sd           s3, 24(sp)                    // push s3
              sd           s4, 32(sp)                    // push s4

              lwu          t0,  0(a0)                    // t0 = MEM[ a0 +  0 ]  => xw = state[ 0 ]
              lwu          t1,  4(a0)                    // t1 = MEM[ a0 +  4 ]  => yw = state[ 1 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
#if ( RV64B )
              alz.pack     t0, t0, t1                    //                      => ( yw || xw )
#else
              slli         t1, t1,  32                   // t1 = t1 << 32
              or           t0, t0, t1                    // t0 = t0 | t1         => ( yw || xw )
#endif
#endif
              li           t2,      10                   // t2 =  10             => i = 10
              li           t3,       0                   // t3 =   0             => n =  0

              lwu          s0,  0(a1)                    // s0 = MEM[ a1 +  0 ]  => k0 =   key[ 0 ]
              lwu          s1,  4(a1)                    // s1 = MEM[ a1 +  4 ]  => k1 =   key[ 1 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
#if ( RV64B )
              alz.pack     s0, s0, s1                    //                      => ( k1 || k0 )
#else
              slli         s1, s1,  32                   // s1 = s1 << 32
              or           s0, s0, s1                    // s0 = s0 | s1         => ( k1 || k0 )
#endif
#endif
              lwu          s2,  8(a1)                    // s2 = MEM[ a1 +  8 ]  => k2 =   key[ 2 ]
              lwu          s3, 12(a1)                    // s3 = MEM[ a1 + 12 ]  => k3 =   key[ 3 ]
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
#if ( RV64B )
              alz.pack     s2, s2, s3                    //                      => ( k3 || k2 )
#else
              slli         s3, s3,  32                   // s3 = s3 << 32
              or           s2, s2, s3                    // s2 = s2 | s3         => ( k3 || k2 )
#endif
#endif
.endm

.macro CRAXS10_DEC_EPILOGUE
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
              srli         t1, t0,  32                   // t1 = t0 >> 32        => ( yw || xw )
#endif
              sw           t0,  0(a0)                    // MEM[ a0 +  0 ] = t0  => state[ 0 ] = xw
              sw           t1,  4(a0)                    // MEM[ a0 +  4 ] = t1  => state[ 1 ] = yw

              ld           s0,  0(sp)                    // pop  s0
              ld           s1,  8(sp)                    // pop  s1
              ld           s2, 16(sp)                    // pop  s2
              ld           s3, 24(sp)                    // pop  s3
              ld           s4, 32(sp)                    // pop  s4
              addi         sp, sp,  40                   // adjust SP

              ret                                        // return
.endm

// ----------------------------------------------------------------------------
// CRAX    implementation => en/decrypt step

#if ( RV64_TYPE1 )
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
              lwu          t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              lwu          t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
              addi         s4,  s4,  4                   //  s4 =  s4 + 4
#endif
              ALZETTE_ENC \xw, \yw,  t4                  //                      => ALZETTE_ENC
.endm          

.macro CRAXS10_DEC_STEP xw, yw, xk, yk, i
#if ( CRAXS10_DEC_UNROLL )
              lwu          t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              addi         s4,  s4, -4                   //  s4 =  s4 - 4
              lwu          t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#endif
              ALZETTE_DEC \xw, \yw,  t4                  //                      => ALZETTE_DEC
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

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
.macro CRAXS10_ENC_STEP xw, xk, i
#if ( CRAXS10_ENC_UNROLL )
              xori         t5, \xk, \i                   //  t5 = \xk ^ \i       =>                   ( \yk || \xk ^ step )
#else
              xor          t5, \xk,  t2                  //  t5 = \xk ^  t2      =>                   ( \yk || \xk ^ step )
              addi         t2,  t2,  1                   //  t2 =  t2 + 1        => step++
#endif
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => ( \yw || \xw ) ^= ( \yk || \xk ^ step )
#if ( CRAXS10_ENC_UNROLL )
              lwu          t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              lwu          t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
              addi         s4,  s4,  4                   //  s4 =  s4 + 4
#endif
              ALZETTE_ENC \xw,  t4                       //                      => ALZETTE_ENC
.endm

.macro CRAXS10_DEC_STEP xw, xk, i
#if ( CRAXS10_DEC_UNROLL )
              lwu          t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              addi         s4,  s4, -4                   //  s4 =  s4 - 4
              lwu          t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#endif
              ALZETTE_DEC \xw,  t4                       //                      => ALZETTE_DEC
#if ( CRAXS10_DEC_UNROLL )
              xori         t5, \xk, \i                   //  t5 = \xk ^ \i       =>                   ( \yk || \xk ^ step )
#else
              addi         t2,  t2, -1                   //  t2 =  t2 - 1        => step--
              xor          t5, \xk,  t2                  //  t5 = \xk ^  t2      =>                   ( \yk || \xk ^ step )
#endif
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => ( \yw || \xw ) ^= ( \yk || \xk ^ step )
.endm
#endif

#if ( RV64_TYPE4 )
.macro CRAXS10_ENC_STEP xw, xk, i, j
              xori         t5, \xk, \i                   //  t5 = \xk ^  t2      =>                   ( \yk || \xk ^ step )
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => ( \yw || \xw ) ^= ( \yk || \xk ^ step )
              ALZETTE_ENC \xw,  t4, \j                   //                      => ALZETTE_ENC
.endm

.macro CRAXS10_DEC_STEP xw, xk, i, j
              ALZETTE_DEC \xw,  t4, \j                   //                      => ALZETTE_DEC
              xori         t5, \xk, \i                   //  t5 = \xk ^  t2      =>                   ( \yk || \xk ^ step )
              xor         \xw, \xw,  t5                  // \xw = \xw ^  t5      => ( \yw || \xw ) ^= ( \yk || \xk ^ step )
.endm
#endif

// ----------------------------------------------------------------------------
// CRAX    implementation => RCON

#if ( CRAXS10_ENC_EXTERN ) || ( CRAXS10_DEC_EXTERN )
.section .rodata

.balign 4

CRAXS10_RCON: .word 0xB7E15162
              .word 0xBF715880
              .word 0x38B4DA56
              .word 0x324E7738
              .word 0xBB1185EB
              .word 0xB7E15162
              .word 0xBF715880
              .word 0x38B4DA56
              .word 0x324E7738
              .word 0xBB1185EB
#endif

// ----------------------------------------------------------------------------	
// CRAX    implementation => encrypt

#if ( CRAXS10_ENC_EXTERN )
.section .text
  
.global craxs10_enc

craxs10_enc:  CRAXS10_ENC_PROLOGUE

#if ( RV64_TYPE1 )	
              la           s4, CRAXS10_RCON              // s4 = &CRAXS10_RCON
#if ( CRAXS10_ENC_UNROLL )
              CRAXS10_ENC_STEP t0, t1, s0, s1, 0
              CRAXS10_ENC_STEP t0, t1, s2, s3, 1
              CRAXS10_ENC_STEP t0, t1, s0, s1, 2 
              CRAXS10_ENC_STEP t0, t1, s2, s3, 3
              CRAXS10_ENC_STEP t0, t1, s0, s1, 4
              CRAXS10_ENC_STEP t0, t1, s2, s3, 5
              CRAXS10_ENC_STEP t0, t1, s0, s1, 6 
              CRAXS10_ENC_STEP t0, t1, s2, s3, 7
              CRAXS10_ENC_STEP t0, t1, s0, s1, 8 
              CRAXS10_ENC_STEP t0, t1, s2, s3, 9
#else	
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              CRAXS10_ENC_STEP t0, t1, s0, s1    
              CRAXS10_ENC_STEP t0, t1, s2, s3
              j                    0b                    //            goto 0
#endif
1:            xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
              la           s4, CRAXS10_RCON              // s4 = &CRAXS10_RCON
#if ( CRAXS10_ENC_UNROLL )
              CRAXS10_ENC_STEP t0,     s0,     0
              CRAXS10_ENC_STEP t0,     s2,     1
              CRAXS10_ENC_STEP t0,     s0,     2
              CRAXS10_ENC_STEP t0,     s2,     3
              CRAXS10_ENC_STEP t0,     s0,     4
              CRAXS10_ENC_STEP t0,     s2,     5
              CRAXS10_ENC_STEP t0,     s0,     6
              CRAXS10_ENC_STEP t0,     s2,     7
              CRAXS10_ENC_STEP t0,     s0,     8
              CRAXS10_ENC_STEP t0,     s2,     9
#else	
0:            bgeu         t2, t3, 1f                    // if i >= n, goto 1
              CRAXS10_ENC_STEP t0,     s0
              CRAXS10_ENC_STEP t0,     s2
              j                    0b                    //            goto 0
#endif	
1:            xor          t0, t0, s0                    // t0 = t0 ^ s0         => ( yw || xw ) = ( yw || xw ) ^ ( k1 || k0 )
#endif

#if ( RV64_TYPE4 )
#if ( CRAXS10_ENC_UNROLL )
              CRAXS10_ENC_STEP t0,     s0,     0, 0
              CRAXS10_ENC_STEP t0,     s2,     1, 1
              CRAXS10_ENC_STEP t0,     s0,     2, 2
              CRAXS10_ENC_STEP t0,     s2,     3, 3
              CRAXS10_ENC_STEP t0,     s0,     4, 4
              CRAXS10_ENC_STEP t0,     s2,     5, 0
              CRAXS10_ENC_STEP t0,     s0,     6, 1
              CRAXS10_ENC_STEP t0,     s2,     7, 2
              CRAXS10_ENC_STEP t0,     s0,     8, 3
              CRAXS10_ENC_STEP t0,     s2,     9, 4
#else	
#error "can't use RV64_TYPE4 without CRAXS10_ENC_UNROLL"
#endif
1:            xor          t0, t0, s0                    // t0 = t0 ^ s0         => ( yw || xw ) = ( yw || xw ) ^ ( k1 || k0 )
#endif

              CRAXS10_ENC_EPILOGUE
#endif

// ----------------------------------------------------------------------------	
// CRAX    implementation => decrypt

#if ( CRAXS10_DEC_EXTERN )
.section .text
  
.global craxs10_dec

craxs10_dec:  CRAXS10_DEC_PROLOGUE

#if ( RV64_TYPE1 )
              la           s4, CRAXS10_RCON              // s4 = &CRAXS10_RCON
             
              xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#if ( CRAXS10_DEC_UNROLL )
              CRAXS10_DEC_STEP t0, t1, s2, s3, 9
              CRAXS10_DEC_STEP t0, t1, s0, s1, 8
              CRAXS10_DEC_STEP t0, t1, s2, s3, 7
              CRAXS10_DEC_STEP t0, t1, s0, s1, 6
              CRAXS10_DEC_STEP t0, t1, s2, s3, 5
              CRAXS10_DEC_STEP t0, t1, s0, s1, 4
              CRAXS10_DEC_STEP t0, t1, s2, s3, 3
              CRAXS10_DEC_STEP t0, t1, s0, s1, 2
              CRAXS10_DEC_STEP t0, t1, s2, s3, 1
              CRAXS10_DEC_STEP t0, t1, s0, s1, 0
#else
              addi         s4, s4,  40                   // s4 = &CRAXS10_RCON + ( N_STEPS - 1 ) * sizeof( uint32_t )

0:            blez         t2,     1f                    // if i <= 0, goto 1
              CRAXS10_DEC_STEP t0, t1, s2, s3
              CRAXS10_DEC_STEP t0, t1, s0, s1
              j                    0b                    //            goto 0
#endif
#endif

#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE5 )
              la           s4, CRAXS10_RCON              // s4 = &CRAXS10_RCON

              xor          t0, t0, s0                    // t0 = t0 ^ s0         => ( yw || xw ) = ( yw || xw ) ^ ( k1 || k0 )
#if ( CRAXS10_DEC_UNROLL )
              CRAXS10_DEC_STEP t0,     s2,     9
              CRAXS10_DEC_STEP t0,     s0,     8
              CRAXS10_DEC_STEP t0,     s2,     7
              CRAXS10_DEC_STEP t0,     s0,     6
              CRAXS10_DEC_STEP t0,     s2,     5
              CRAXS10_DEC_STEP t0,     s0,     4
              CRAXS10_DEC_STEP t0,     s2,     3
              CRAXS10_DEC_STEP t0,     s0,     2
              CRAXS10_DEC_STEP t0,     s2,     1
              CRAXS10_DEC_STEP t0,     s0,     0
#else	
              addi         s4, s4,  40                   // s4 = &CRAXS10_RCON + ( N_STEPS - 1 ) * sizeof( uint32_t )

0:            blez         t2,     1f                    // if i <= 0, goto 1
              CRAXS10_DEC_STEP t0,     s2
              CRAXS10_DEC_STEP t0,     s0
              j                    0b                    //            goto 0
#endif
#endif

#if ( RV64_TYPE4 )
              xor          t0, t0, s0                    // t0 = t0 ^ s0         => ( yw || xw ) = ( yw || xw ) ^ ( k1 || k0 )
#if ( CRAXS10_DEC_UNROLL )
              CRAXS10_DEC_STEP t0,     s2,     9, 4
              CRAXS10_DEC_STEP t0,     s0,     8, 3
              CRAXS10_DEC_STEP t0,     s2,     7, 2
              CRAXS10_DEC_STEP t0,     s0,     6, 1
              CRAXS10_DEC_STEP t0,     s2,     5, 0
              CRAXS10_DEC_STEP t0,     s0,     4, 4
              CRAXS10_DEC_STEP t0,     s2,     3, 3
              CRAXS10_DEC_STEP t0,     s0,     2, 2
              CRAXS10_DEC_STEP t0,     s2,     1, 1
              CRAXS10_DEC_STEP t0,     s0,     0, 0
#else	
#error "can't use RV64_TYPE4 without CRAXS10_DEC_UNROLL"
#endif
#endif

1:            CRAXS10_DEC_EPILOGUE
#endif

// ============================================================================
