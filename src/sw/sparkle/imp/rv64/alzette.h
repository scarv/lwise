// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ALZETTE_H
#define __ALZETTE_H

// ============================================================================

#include "zbkb.h"
#include  "ise.h"

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE1 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  roriw                \t0, \yi, 31  // \t0 = ROR32( \yi, 31 ) =>             yi >>> 31
  addw                 \xi, \xi, \t0 // \xi = \xi + \t0        => xi = xi + ( yi >>> 31 )
  roriw                \t0, \xi, 24  // \t0 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 24 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  roriw                \t0, \yi, 17  // \t0 = ROR32( \yi, 17 ) =>             yi >>> 17
  addw                 \xi, \xi, \t0 // \xi = \xi + \t0        => xi = xi + ( yi >>> 17 )
  roriw                \t0, \xi, 17  // \t0 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 17 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  addw                 \xi, \xi, \yi // \xi = \xi + \yi        => xi = xi + ( yi >>>  0 )
  roriw                \t0, \xi, 31  // \t  = ROR32( \xi, 31 ) =>             xi >>> 31
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t         => yi = yi ^ ( xi >>> 31 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  roriw                \t0, \yi, 24  // \t0 = ROR32( \yi, 24 ) =>             yi >>> 24
  addw                 \xi, \xi, \t0 // \xi = \xi + \t0        => xi = xi + ( yi >>> 24 )
  roriw                \t0, \xi, 16  // \t0 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 16 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  roriw                \t0, \xi, 16  // \t0 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 16 )
  roriw                \t0, \yi, 24  // \t0 = ROR32( \yi, 24 ) =>             yi >>> 24
  subw                 \xi, \xi, \t0 // \xi = \xi - \t0        => xi = xi - ( yi >>> 24 )

  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  roriw                \t0, \xi, 31  // \t0 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 31 )
  subw                 \xi, \xi, \yi // \xi = \xi - \yi        => xi = xi - ( yi >>>  0 )

  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  roriw                \t0, \xi, 17  // \t0 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 17 )
  roriw                \t0, \yi, 17  // \t0 = ROR32( \yi, 17 ) =>             yi >>> 17
  subw                 \xi, \xi, \t0 // \xi = \xi - \t0        => xi = xi - ( yi >>> 17 )
 
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  roriw                \t0, \xi, 24  // \t0 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 24 )
  roriw                \t0, \yi, 31  // \t0 = ROR32( \yi, 31 ) =>             yi >>> 31
  subw                 \xi, \xi, \t0 // \xi = \xi - \t0        => xi = xi - ( yi >>> 31 )
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE2 )
.macro ALZETTE_ENC xi, ci
  sparkle.block.enci   \xi, \xi, \ci, 0
  sparkle.block.enci   \xi, \xi, \ci, 1
  sparkle.block.enci   \xi, \xi, \ci, 2
  sparkle.block.enci   \xi, \xi, \ci, 3
.endm

.macro ALZETTE_DEC xi, ci
  sparkle.block.deci   \xi, \xi, \ci, 3
  sparkle.block.deci   \xi, \xi, \ci, 2
  sparkle.block.deci   \xi, \xi, \ci, 1
  sparkle.block.deci   \xi, \xi, \ci, 0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE3 )
.macro ALZETTE_ENC xi, ci
  sparkle.block.enc.0  \xi, \xi, \ci
  sparkle.block.enc.1  \xi, \xi, \ci
  sparkle.block.enc.2  \xi, \xi, \ci
  sparkle.block.enc.3  \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, ci
  sparkle.block.dec.3  \xi, \xi, \ci
  sparkle.block.dec.2  \xi, \xi, \ci
  sparkle.block.dec.1  \xi, \xi, \ci
  sparkle.block.dec.0  \xi, \xi, \ci
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE4 )
.macro ALZETTE_ENC xi, ci, i
  sparkle.whole.enci   \xi, \xi, \i
.endm

.macro ALZETTE_DEC xi, ci, i
  sparkle.whole.deci   \xi, \xi, \i
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE5 )
.macro ALZETTE_ENC xi, ci
  sparkle.whole.enc    \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, ci
  sparkle.whole.dec    \xi, \xi, \ci
.endm
#endif

// ============================================================================

#endif
