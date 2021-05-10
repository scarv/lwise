// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( RV64_ELL )
.macro ELL32 r, x, t0, t1
  alz.ell   \r,  \x
.endm
#else
.macro ELL32 r, x, t0, t1
  slliw     \t0, \x,  16
  xor       \x,  \x, \t0
  ROR32     \r,  \x,  16, \t0, \t1
.endm
#endif

#if ( RV64_ELL )
.macro ELL64 r, x, t0, t1
  alz.ell   \r,  \x
.endm
#else
.macro ELL64 r, x, t0, t1

.endm
#endif

#if ( RV64_TYPE1 )
.macro ELL   r, x, t0, t1
  ELL32     \r,  \x, \t0, \t1
.endm
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro ELL   r, x, t0, t1
  ELL64     \r,  \x, \t0, \t1
.endm
#endif

// ============================================================================
