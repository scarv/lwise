/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "rdtsc.h"

uint64_t rdtsc() {
  uint64_t t, tsc_lo = 0, tsc_hi = 0;

//  __asm__ __volatile__( "1: rdcycleh %0    ;"
//                        "   rdcycle  %1    ;"
//                        "   rdcycleh %2    ;"
//                        "   bne %0, %2, 1b ;" : "=r" (t), "=r" (tsc_lo), "=r" (tsc_hi) );
  __asm__ __volatile__ ("csrr %0, mcycle \n":"=r" (tsc_lo) ::);

  return ( ( uint64_t )( tsc_lo ) <<  0 ) |
         ( ( uint64_t )( tsc_hi ) << 32 ) ;
}
