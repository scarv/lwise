// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================
	
#if ( ALZETTE_RV32_TYPE1 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  ROR32                \t0, \yi, 31, \t0, \t1 // \t0 = ROR32( \yi, 31 ) =>             yi >>> 31
  add                  \xi, \xi, \t0          // \xi = \xi + \t0        => xi = xi + ( yi >>> 31 )
  ROR32                \t0, \xi, 24, \t0, \t1 // \t0 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 24 )
  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci

  ROR32                \t0, \yi, 17, \t0, \t1 // \t0 = ROR32( \yi, 17 ) =>             yi >>> 17
  add                  \xi, \xi, \t0          // \xi = \xi + \t0        => xi = xi + ( yi >>> 17 )
  ROR32                \t0, \xi, 17, \t0, \t1 // \t0 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 17 )
  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci

  add                  \xi, \xi, \yi          // \xi = \xi + \yi        => xi = xi + ( yi >>>  0 )
  ROR32                \t0, \xi, 31, \t0, \t1 // \t  = ROR32( \xi, 31 ) =>             xi >>> 31
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t         => yi = yi ^ ( xi >>> 31 )
  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci

  ROR32                \t0, \yi, 24, \t0, \t1 // \t0 = ROR32( \yi, 24 ) =>             yi >>> 24
  add                  \xi, \xi, \t0          // \xi = \xi + \t0        => xi = xi + ( yi >>> 24 )
  ROR32                \t0, \xi, 16, \t0, \t1 // \t0 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 16 )
  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32                \t0, \xi, 16, \t0, \t1 // \t0 = ROR32( \xi, 16 ) =>             xi >>> 16
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 16 )
  ROR32                \t0, \yi, 24, \t0, \t1 // \t0 = ROR32( \yi, 24 ) =>             yi >>> 24
  sub                  \xi, \xi, \t0          // \xi = \xi - \t0        => xi = xi - ( yi >>> 24 )

  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32                \t0, \xi, 31, \t0, \t1 // \t0 = ROR32( \xi, 31 ) =>             xi >>> 31
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 31 )
  sub                  \xi, \xi, \yi          // \xi = \xi - \yi        => xi = xi - ( yi >>>  0 )

  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32                \t0, \xi, 17, \t0, \t1 // \t0 = ROR32( \xi, 17 ) =>             xi >>> 17
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 17 )
  ROR32                \t0, \yi, 17, \t0, \t1 // \t0 = ROR32( \yi, 17 ) =>             yi >>> 17
  sub                  \xi, \xi, \t0          // \xi = \xi - \t0        => xi = xi - ( yi >>> 17 )
 
  xor                  \xi, \xi, \ci          // \xi = \xi ^ \ci        => xi = xi ^ ci
  ROR32                \t0, \xi, 24, \t0, \t1 // \t0 = ROR32( \xi, 24 ) =>             xi >>> 24
  xor                  \yi, \yi, \t0          // \yi = \yi ^ \t0        => yi = yi ^ ( xi >>> 24 )
  ROR32                \t0, \yi, 31, \t0, \t1 // \t0 = ROR32( \yi, 31 ) =>             yi >>> 31
  sub                  \xi, \xi, \t0          // \xi = \xi - \t0        => xi = xi - ( yi >>> 31 )
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV32_TYPE2 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  alzette.addrori      \xi, \xi, \yi, 31
  alzette.xorrori      \yi, \yi, \xi, 24
  xor                  \xi, \xi, \ci    
  alzette.addrori      \xi, \xi, \yi, 17
  alzette.xorrori      \yi, \yi, \xi, 17
  xor                  \xi, \xi, \ci    
  add                  \xi, \xi, \yi    
  alzette.xorrori      \yi, \yi, \xi, 31
  xor                  \xi, \xi, \ci    
  alzette.addrori      \xi, \xi, \yi, 24
  alzette.xorrori      \yi, \yi, \xi, 16
  xor                  \xi, \xi, \ci    
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci    
  alzette.xorrori      \yi, \yi, \xi, 16
  alzette.subrori      \xi, \xi, \yi, 24
  xor                  \xi, \xi, \ci    
  alzette.xorrori      \yi, \yi, \xi, 31
  sub                  \xi, \xi, \yi    
  xor                  \xi, \xi, \ci    
  alzette.xorrori      \yi, \yi, \xi, 17
  alzette.subrori      \xi, \xi, \yi, 17
  xor                  \xi, \xi, \ci    
  alzette.xorrori      \yi, \yi, \xi, 24
  alzette.subrori      \xi, \xi, \yi, 31
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV32_TYPE3 )
.macro ALZETTE_ENC xi, yi, ci, t0, t1
  alzette.addror.31    \xi, \xi, \yi
  alzette.xorror.24    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
  alzette.addror.17    \xi, \xi, \yi
  alzette.xorror.17    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
  add                  \xi, \xi, \yi
  alzette.xorror.31    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
  alzette.addror.24    \xi, \xi, \yi
  alzette.xorror.16    \yi, \yi, \xi
  xor                  \xi, \xi, \ci
.endm

.macro ALZETTE_DEC xi, yi, ci, t0, t1
  xor                  \xi, \xi, \ci    
  alzette.xorror.16    \yi, \yi, \xi
  alzette.subror.24    \xi, \xi, \yi
  xor                  \xi, \xi, \ci    
  alzette.xorror.31    \yi, \yi, \xi
  sub                  \xi, \xi, \yi    
  xor                  \xi, \xi, \ci    
  alzette.xorror.17    \yi, \yi, \xi
  alzette.subror.17    \xi, \xi, \yi
  xor                  \xi, \xi, \ci    
  alzette.xorror.24    \yi, \yi, \xi
  alzette.subror.31    \xi, \xi, \yi
.endm
#endif

// ----------------------------------------------------------------------------
	
#if ( ALZETTE_RV32_TYPE4 )
.macro ALZETTE_ENC xr, yr, xi, yi, i
  alzette.whole.enci.x \xr, \xi, \yi, \i
  alzette.whole.enci.y \yr, \xi, \yi, \i
.endm

.macro ALZETTE_DEC xr, yr, xi, yi, i
  alzette.whole.deci.x \xr, \xi, \yi, \i
  alzette.whole.deci.y \yr, \xi, \yi, \i
.endm
#endif

// ============================================================================
