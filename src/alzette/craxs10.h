/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __CRAXS10_H
#define __CRAXS10_H

#include "share.h"

#define CRAXS10_NSTEPS ( 10 )

extern const uint32_t CRAXS10_RCON[ 10 ];

extern void craxs10_enc( uint32_t* state, const uint32_t* key );
extern void craxs10_dec( uint32_t* state, const uint32_t* key );

#endif
