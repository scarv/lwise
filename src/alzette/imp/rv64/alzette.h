// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

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

// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------

#if ( RV64_TYPE4 )
.macro ALZETTE_ENC xi, ci, i
  alz.whole.enci   \xi, \xi, \i
.endm

.macro ALZETTE_DEC xi, ci, i
  alz.whole.deci   \xi, \xi, \i
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64_TYPE5 )
.macro ALZETTE_ENC xi, ci
  alz.whole.enc    \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, ci
  alz.whole.dec    \xi, \xi, \ci
.endm
#endif

// ============================================================================

