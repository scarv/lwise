// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ALZETTE_RV32_ELL )
.macro ELL   r, x, t0, t1
  alzette.ell          \r,  \x,   x0
.endm
#else
.macro ELL   r, x, t0, t1
  slli                 \t0, \x,   16
  xor                  \x,  \x,  \t0
  ROR32                \r,  \x,   16, \t0, \t1
.endm
#endif

// ============================================================================
