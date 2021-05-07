/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __MEASURE_H
#define __MEASURE_H

#include "share.h"

#if defined( DRIVER_MEASURE )
#define measure_prologue(id)
#define measure_step(id,...) id( __VA_ARGS__ )
#define measure_epilogue(id)
#endif

#endif
