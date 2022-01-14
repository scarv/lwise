/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __SKINNY_H
#define __SKINNY_H

#include "share.h"

extern uint8_t     SBOX_ENC[];
extern uint8_t     SBOX_DEC[];

extern uint8_t  RC_LFSR_FWD[];
extern uint8_t  RC_LFSR_REV[];
extern uint8_t TK2_LFSR_FWD[];
extern uint8_t TK2_LFSR_REV[];
extern uint8_t TK3_LFSR_FWD[];
extern uint8_t TK3_LFSR_REV[];

#endif
