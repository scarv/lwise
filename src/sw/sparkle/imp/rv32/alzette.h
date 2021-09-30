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
	
#if ( SPARKLE_RV32_TYPE1 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  rori                 \t0, \yi, 31  // \t0 = ROR32( \yi, 31 ) =>             yi >>> 31
  add                  \xi, \xi, \t0 // \xi = \xi + \t0        => xi = xi + ( yi >>> 31 )
  rori                 \t0, \xi, 24  // \t0 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 24 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  rori                 \t0, \yi, 17  // \t0 = ROR32( \yi, 17 ) =>             yi >>> 17
  add                  \xi, \xi, \t0 // \xi = \xi + \t0        => xi = xi + ( yi >>> 17 )
  rori                 \t0, \xi, 17  // \t0 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 17 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  add                  \xi, \xi, \yi // \xi = \xi + \yi        => xi = xi + ( yi >>>  0 )
  rori                 \t0, \xi, 31  // \t  = ROR32( \xi, 31 ) =>             xi >>> 31
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t         => yi = yi ^ ( xi >>> 31 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci

  rori                 \t0, \yi, 24  // \t0 = ROR32( \yi, 24 ) =>             yi >>> 24
  add                  \xi, \xi, \t0 // \xi = \xi + \t0        => xi = xi + ( yi >>> 24 )
  rori                 \t0, \xi, 16  // \t0 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 16 )
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  rori                 \t0, \xi, 16  // \t0 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 16 )
  rori                 \t0, \yi, 24  // \t0 = ROR32( \yi, 24 ) =>             yi >>> 24
  sub                  \xi, \xi, \t0 // \xi = \xi - \t0        => xi = xi - ( yi >>> 24 )

  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  rori                 \t0, \xi, 31  // \t0 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 31 )
  sub                  \xi, \xi, \yi // \xi = \xi - \yi        => xi = xi - ( yi >>>  0 )

  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  rori                 \t0, \xi, 17  // \t0 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 17 )
  rori                 \t0, \yi, 17  // \t0 = ROR32( \yi, 17 ) =>             yi >>> 17
  sub                  \xi, \xi, \t0 // \xi = \xi - \t0        => xi = xi - ( yi >>> 17 )
 
  xor                  \xi, \xi, \ci // \xi = \xi ^ \ci        => xi = xi ^ ci
  rori                 \t0, \xi, 24  // \t0 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor                  \yi, \yi, \t0 // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 24 )
  rori                 \t0, \yi, 31  // \t0 = ROR32( \yi, 31 ) =>             yi >>> 31
  sub                  \xi, \xi, \t0 // \xi = \xi - \t0        => xi = xi - ( yi >>> 31 )
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_TYPE2 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  sparkle.addrori      \xi, \xi, \yi, 31
  sparkle.xorrori      \yi, \yi, \xi, 24
  xor                  \xi, \xi, \ci    
  sparkle.addrori      \xi, \xi, \yi, 17
  sparkle.xorrori      \yi, \yi, \xi, 17
  xor                  \xi, \xi, \ci    
  add                  \xi, \xi, \yi    
  sparkle.xorrori      \yi, \yi, \xi, 31
  xor                  \xi, \xi, \ci    
  sparkle.addrori      \xi, \xi, \yi, 24
  sparkle.xorrori      \yi, \yi, \xi, 16
  xor                  \xi, \xi, \ci    
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci    
  sparkle.xorrori      \yi, \yi, \xi, 16
  sparkle.subrori      \xi, \xi, \yi, 24
  xor                  \xi, \xi, \ci    
  sparkle.xorrori      \yi, \yi, \xi, 31
  sub                  \xi, \xi, \yi    
  xor                  \xi, \xi, \ci    
  sparkle.xorrori      \yi, \yi, \xi, 17
  sparkle.subrori      \xi, \xi, \yi, 17
  xor                  \xi, \xi, \ci    
  sparkle.xorrori      \yi, \yi, \xi, 24
  sparkle.subrori      \xi, \xi, \yi, 31
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_TYPE3 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  sparkle.addror.31    \xi, \xi, \yi
  sparkle.xorror.24    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
  sparkle.addror.17    \xi, \xi, \yi
  sparkle.xorror.17    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
  add                  \xi, \xi, \yi
  sparkle.xorror.31    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
  sparkle.addror.24    \xi, \xi, \yi
  sparkle.xorror.16    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci    
  sparkle.xorror.16    \yi, \yi, \xi
  sparkle.subror.24    \xi, \xi, \yi
  xor                  \xi, \xi, \ci    
  sparkle.xorror.31    \yi, \yi, \xi
  sub                  \xi, \xi, \yi    
  xor                  \xi, \xi, \ci    
  sparkle.xorror.17    \yi, \yi, \xi
  sparkle.subror.17    \xi, \xi, \yi
  xor                  \xi, \xi, \ci    
  sparkle.xorror.24    \yi, \yi, \xi
  sparkle.subror.31    \xi, \xi, \yi
.endm
#endif

// ----------------------------------------------------------------------------
	
#if ( SPARKLE_RV32_TYPE4 )
.macro ALZETTE_ENC xr, yr, xi, yi, i
  sparkle.whole.enci.x \xr, \xi, \yi, \i
  sparkle.whole.enci.y \yr, \xi, \yi, \i
.endm

.macro ALZETTE_DEC xr, yr, xi, yi, i
  sparkle.whole.deci.x \xr, \xi, \yi, \i
  sparkle.whole.deci.y \yr, \xi, \yi, \i
.endm
#endif

// ============================================================================

#endif
