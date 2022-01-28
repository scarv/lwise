/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __PHOTON_H
#define __PHOTON_H

#include "share.h"

extern uint8_t M[ 8 ][ 8 ];
extern uint8_t SBOX[ 16 ];

extern uint8_t GF2N_MUL( uint8_t x, uint8_t y );

#endif
