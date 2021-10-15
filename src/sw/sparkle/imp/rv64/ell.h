// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ELL_H
#define __ELL_H

// ============================================================================

#include "zbkb.h"
#include "zbkx.h"
#include  "ise.h"

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_ELL )
.macro ELL32 r, x0, x1, t0, t1
  sparkle.ell    \r,  \x0, \x1
.endm
#else
.macro ELL32 r, x0, x1, t0, t1
  xor            \t0, \x0, \x1
  slliw          \t1, \t0,  16
  xor            \r,  \t0, \t1
  roriw          \r,  \r,   16
.endm
#endif

#if ( SPARKLE_RV64_ELL )
.macro ELL64 r, x0, x1, t0, t1, t2
  sparkle.ellrev \r,  \x0, \x1
.endm
#else
.macro ELL64 r, x0, x1, t0, t1, t2
  xor            \t0, \x0, \x1 
  slliw          \t1, \t0,  16
  xor            \t2, \t0, \t1
  srli           \t0, \t0,  32
  slliw          \t1, \t0,  16                    
  xor            \t1, \t1, \t0
  mv             \r,  \t2
  roriw          \r,  \r,   16
  roriw          \t1, \t1,  16
  pack           \r,  \t1, \r
.endm
#endif

// ============================================================================

#endif
