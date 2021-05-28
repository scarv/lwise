// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __SPARKLE_H
#define __SPARKLE_H

#include "share.h"

#define MAX_BRANCHES 8
extern const uint32_t SPARKLE_RCON[ 8 ];

extern void sparkle_fwd( uint32_t* state, int brans, int steps );
extern void sparkle_rev( uint32_t* state, int brans, int steps );

#endif
