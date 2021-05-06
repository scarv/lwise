/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __TRAXL17_H
#define __TRAXL17_H

#include "share.h"
#include   "imp.h"

extern void traxl17_genkeys( uint32_t* subkeys, const uint32_t* key );

extern void traxl17_enc( uint32_t* x, uint32_t* y, const uint32_t* subkeys, const uint32_t* tweak );
extern void traxl17_dec( uint32_t* x, uint32_t* y, const uint32_t* subkeys, const uint32_t* tweak );

#endif
