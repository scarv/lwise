/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "rdtsc.h"

uint64_t rdtsc() {
  uint64_t tsc = 0;

  __asm__ __volatile__( "rdcycle %0" : "=r" (tsc) );

  return tsc;
}
