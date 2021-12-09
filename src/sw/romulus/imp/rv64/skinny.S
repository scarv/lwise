// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================	
	
#include "zbkb.h"
#include "zbkx.h"
#include  "ise.h"

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => encrypt

.section .text
  
.global skinny_enc_schedule
.global skinny_enc

skinny_enc_schedule: ret

skinny_enc:          ret

// ----------------------------------------------------------------------------
// Skinny-128-384+ implementation => decrypt

.section .text
  
.global skinny_dec_schedule
.global skinny_dec

skinny_dec_schedule: ret

skinny_dec:          ret

// ============================================================================
