// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================
// register allocation

// t0 => state[ 0 ] = xw
// t1 => state[ 1 ] = yw
// t2 => i          ~ loop counter 
// t3 => n          ~ loop bound
// t4 => temp
// t5 => temp
// t6 => temp

// s0 =>   key[ 0 ] = k0
// s1 =>   key[ 1 ] = k1
// s2 =>   key[ 2 ] = k2
// s3 =>   key[ 3 ] = k3
// s4 =>  &CRAXS10_RCON

// ============================================================================
// ISE instruction definition

#if ( RV32B )
.macro alz.rori         rd, rs1,      imm
.insn r CUSTOM_0,    0, \imm, \rd, \rs1,   x0
.endm
#endif

#if ( RV32_TYPE2 )
.macro alz.addrori      rd, rs1, rs2, imm
.insn r CUSTOM_0,    1, \imm, \rd, \rs1, \rs2
.endm
.macro alz.subrori      rd, rs1, rs2, imm
.insn r CUSTOM_0,    2, \imm, \rd, \rs1, \rs2
.endm
.macro alz.xorrori      rd, rs1, rs2, imm
.insn r CUSTOM_0,    3, \imm, \rd, \rs1, \rs2
.endm
#endif

#if ( RV32_TYPE3 )
.macro alz.addror.31    rd, rs1, rs2
.insn r CUSTOM_1,    0,    0, \rd, \rs1, \rs2
.endm
.macro alz.addror.17    rd, rs1, rs2
.insn r CUSTOM_1,    0,    1, \rd, \rs1, \rs2
.endm
.macro alz.addror.24    rd, rs1, rs2
.insn r CUSTOM_1,    0,    2, \rd, \rs1, \rs2
.endm
.macro alz.subror.31    rd, rs1, rs2
.insn r CUSTOM_1,    0,    3, \rd, \rs1, \rs2
.endm
.macro alz.subror.17    rd, rs1, rs2
.insn r CUSTOM_1,    0,    4, \rd, \rs1, \rs2
.endm
.macro alz.subror.24    rd, rs1, rs2
.insn r CUSTOM_1,    0,    5, \rd, \rs1, \rs2
.endm
.macro alz.xorror.31    rd, rs1, rs2
.insn r CUSTOM_1,    0,    6, \rd, \rs1, \rs2
.endm
.macro alz.xorror.17    rd, rs1, rs2
.insn r CUSTOM_1,    0,     7,\rd, \rs1, \rs2
.endm
.macro alz.xorror.24    rd, rs1, rs2
.insn r CUSTOM_1,    0,    8, \rd, \rs1, \rs2
.endm
.macro alz.xorror.16    rd, rs1, rs2
.insn r CUSTOM_1,    0,    9, \rd, \rs1, \rs2
.endm
#endif

#if ( RV32_TYPE4 )
.macro alz.whole.enci.x rd, rs1, rs2, imm
.insn r CUSTOM_0,    4, \imm, \rd, \rs1, \rs2
.endm
.macro alz.whole.enci.y rd, rs1, rs2, imm
.insn r CUSTOM_0,    5, \imm, \rd, \rs1, \rs2
.endm
.macro alz.whole.deci.x rd, rs1, rs2, imm
.insn r CUSTOM_0,    6, \imm, \rd, \rs1, \rs2
.endm
.macro alz.whole.deci.y rd, rs1, rs2, imm
.insn r CUSTOM_0,    7, \imm, \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
// Alzette implementation

#if ( RV32B )
.macro ROR32 r, x, n
  alz.rori          \r, \x,    \n
.endm
#else
.macro ROR32 r, x, n
  srli              t5, \x,    \n
  slli              t6, \x, 32-\n
  or                \r, t5, t6
.endm
#endif

// ----------------------------------------------------------------------------
	
#if ( RV32_TYPE1 )
.macro ALZETTE_ENC xi, yi, ci
  ROR32             t5, \yi,  31 //  t5 = ROR32( \yi, 31 ) =>             yi >>> 31
  add              \xi, \xi,  t5 // \xi = \xi + t5         => xi = xi + ( yi >>> 31 )
  ROR32             t5, \xi,  24 //  t5 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 24 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  ROR32             t5, \yi,  17 //  t5 = ROR32( \yi, 17 ) =>             yi >>> 17
  add              \xi, \xi,  t5 // \xi = \xi + t5         => xi = xi + ( yi >>> 17 )
  ROR32             t5, \xi,  17 //  t5 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 17 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  add              \xi, \xi, \yi // \xi = \xi + \yi        => xi = xi + ( yi >>>  0 )
  ROR32             t5, \xi,  31 //  t5 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 31 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  ROR32             t5, \yi,  24 //  t5 = ROR32( \yi, 24 ) =>             yi >>> 24
  add              \xi, \xi,  t5 // \xi = \xi + t5         => xi = xi + ( yi >>> 24 )
  ROR32             t5, \xi,  16 //  t5 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 16 )
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
.endm

.macro ALZETTE_DEC xi, yi, ci
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  16 //  t5 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 16 )
  ROR32             t5, \yi,  24 //  t5 = ROR32( \yi, 24 ) =>             yi >>> 24
  sub              \xi, \xi,  t5 // \xi = \xi - t5         => xi = xi - ( yi >>> 24 )

  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  31 //  t5 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 31 )
  sub              \xi, \xi, \yi // \xi = \xi - \yi        => xi = xi - ( yi >>>  0 )

  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  17 //  t5 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 17 )
  ROR32             t5, \yi,  17 //  t5 = ROR32( \yi, 17 ) =>             yi >>> 17
  sub              \xi, \xi,  t5 // \xi = \xi - t5         => xi = xi - ( yi >>> 17 )
 
  xor              \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32             t5, \xi,  24 //  t5 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor              \yi, \yi,  t5 // \yi = \yi ^ t5         => yi = yi ^ ( xi >>> 24 )
  ROR32             t5, \yi,  31 //  t5 = ROR32( \yi, 31 ) =>             yi >>> 31
  sub              \xi, \xi,  t5 // \xi = \xi - t5         => xi = xi - ( yi >>> 31 )
.endm
#endif

#if ( RV32_TYPE2 )
.macro ALZETTE_ENC xi, yi, ci
  alz.addrori      \xi, \xi, \yi, 31
  alz.xorrori      \yi, \yi, \xi, 24
  xor              \xi, \xi, \ci    
  alz.addrori      \xi, \xi, \yi, 17
  alz.xorrori      \yi, \yi, \xi, 17
  xor              \xi, \xi, \ci    
  add              \xi, \xi, \yi    
  alz.xorrori      \yi, \yi, \xi, 31
  xor              \xi, \xi, \ci    
  alz.addrori      \xi, \xi, \yi, 24
  alz.xorrori      \yi, \yi, \xi, 16
  xor              \xi, \xi, \ci    
.endm

.macro ALZETTE_DEC xi, yi, ci
  xor              \xi, \xi, \ci    
  alz.xorrori      \yi, \yi, \xi, 16
  alz.subrori      \xi, \xi, \yi, 24
  xor              \xi, \xi, \ci    
  alz.xorrori      \yi, \yi, \xi, 31
  sub              \xi, \xi, \yi    
  xor              \xi, \xi, \ci    
  alz.xorrori      \yi, \yi, \xi, 17
  alz.subrori      \xi, \xi, \yi, 17
  xor              \xi, \xi, \ci    
  alz.xorrori      \yi, \yi, \xi, 24
  alz.subrori      \xi, \xi, \yi, 31
.endm
#endif

#if ( RV32_TYPE3 )
.macro ALZETTE_ENC xi, yi, ci
  alz.addror.31    \xi, \xi, \yi
  alz.xorror.24    \yi, \yi, \xi
  xor              \xi, \xi, \ci
  alz.addror.17    \xi, \xi, \yi
  alz.xorror.17    \yi, \yi, \xi
  xor              \xi, \xi, \ci
  add              \xi, \xi, \yi
  alz.xorror.31    \yi, \yi, \xi
  xor              \xi, \xi, \ci
  alz.addror.24    \xi, \xi, \yi
  alz.xorror.16    \yi, \yi, \xi
  xor              \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, yi, ci
  xor              \xi, \xi, \ci    
  alz.xorror.16    \yi, \yi, \xi
  alz.subror.24    \xi, \xi, \yi
  xor              \xi, \xi, \ci    
  alz.xorror.31    \yi, \yi, \xi
  sub              \xi, \xi, \yi    
  xor              \xi, \xi, \ci    
  alz.xorror.17    \yi, \yi, \xi
  alz.subror.17    \xi, \xi, \yi
  xor              \xi, \xi, \ci    
  alz.xorror.24    \yi, \yi, \xi
  alz.subror.31    \xi, \xi, \yi
.endm
#endif

#if ( RV32_TYPE4 )
.macro ALZETTE_ENC xr, yr, xi, yi, i
  alz.whole.enci.x \xr, \xi, \yi, \i
  alz.whole.enci.y \yr, \xi, \yi, \i
.endm

.macro ALZETTE_DEC xr, yr, xi, yi, i
  alz.whole.deci.x \xr, \xi, \yi, \i
  alz.whole.deci.y \yr, \xi, \yi, \i
.endm
#endif

// ============================================================================
// CRAX    implementation => en/decrypt prologue + epilogue

.macro CRAXS10_ENC_PROLOGUE
              addi         sp, sp, -20                   // adjust SP
              sw           s0,  0(sp)                    // push s0
              sw           s1,  4(sp)                    // push s1
              sw           s2,  8(sp)                    // push s2
              sw           s3, 12(sp)                    // push s3
              sw           s4, 16(sp)                    // push s4
              
              lw           t0,  0(a0)                    // t0 = MEM[ a0 +  0 ]  => xw = state[ 0 ]
              lw           t1,  4(a0)                    // t1 = MEM[ a0 +  4 ]  => yw = state[ 1 ]

              li           t2,  0                        // t2 =  0              => i =  0
              li           t3, 10                        // t3 = 10              => n = 10
	
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

              li           t2,     10                    // t2 =  10             => i = 10
              li           t3,      0                    // t3 =   0             => n =  0

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
              addi         sp, sp,  20

              ret                                        // return
.endm

// ----------------------------------------------------------------------------
// CRAX    implementation => en/decrypt step
	
#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
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
              ALZETTE_ENC \xw, \yw,  t4                  //                      => ALZETTE_ENC
.endm          

.macro CRAXS10_DEC_STEP xw, yw, xk, yk, i
#if ( CRAXS10_DEC_UNROLL )
              lw           t4,  4*\i(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
#else
              addi         s4,  s4, -4                   //  s4 =  s4 - 4
              lw           t4,     0(s4)                 //  t4 = MEM[ s4 +  0 ] => CRAXS10_RCON[ step ]
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

#if ( RV32_TYPE4 )
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

#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
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

#if ( RV32_TYPE4 )
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
#error "can't use RV32_TYPE4 without CRAXS10_ENC_UNROLL"
#endif
1:            xor          t0, t0, s0                    // t0 = t0 ^ s0         => xw ^= k0
              xor          t1, t1, s1                    // t1 = t1 ^ s1         => yw ^= k1
#endif

              CRAXS10_ENC_EPILOGUE
#endif

// ----------------------------------------------------------------------------	
// CRAX    implementation => decrypt

#if ( CRAXS10_DEC_EXTERN )
.section .text
  
.global craxs10_dec

craxs10_dec:  CRAXS10_DEC_PROLOGUE

#if ( RV32_TYPE1 ) || ( RV32_TYPE2 ) || ( RV32_TYPE3 )
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

#if ( RV32_TYPE4 )
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
#error "can't use RV32_TYPE4 without CRAXS10_DEC_UNROLL"
#endif
#endif

1:            CRAXS10_DEC_EPILOGUE
#endif

// ============================================================================
