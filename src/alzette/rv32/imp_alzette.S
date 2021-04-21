// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================
// register allocation
// t5 => temp
// t6 => temp

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


