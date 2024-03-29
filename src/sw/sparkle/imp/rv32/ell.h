// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ELL_H
#define __ELL_H

// ============================================================================

#include "zbkb.h"
#include  "ise.h"

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_ELL )
.macro ELL   r, x0, x1, t0, t1
  sparkle.ell    \r,  \x0, \x1
.endm
#else
.macro ELL   r, x0, x1, t0, t1
  xor            \t0, \x0, \x1
  slli           \t1, \t0,  16
  xor            \r,  \t0, \t1
  rori           \r,  \r,   16
.endm
#endif

// ============================================================================

#endif
