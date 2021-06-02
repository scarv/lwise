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
#define COUNTERS(cycle,iret) __asm__ __volatile__( "rdcycle %0 ; rdinstret %1" : "=r" (cycle), "=r" (iret) );

#if ( DRIVER_MEASURE == 0 ) // mode = average
#define measure_prologue(id)                                                       \
  uint64_t id ## _cycle_b =  0;                                                    \
  uint64_t id ## _cycle_a =  0;                                                    \
  uint64_t id ## _cycle_t =  0;                                                    \
                                                                                   \
  uint64_t id ##  _iret_b =  0;                                                    \
  uint64_t id ##  _iret_a =  0;                                                    \
  uint64_t id ##  _iret_t =  0;
#define measure_step(id,...)                                                       \
  COUNTERS(id ## _cycle_b, id ## _iret_b);                                         \
  id( __VA_ARGS__ );                                                               \
  COUNTERS(id ## _cycle_a, id ## _iret_a);                                         \
                                                                                   \
  id ## _cycle_t += ( id ## _cycle_a - id ## _cycle_b );                           \
  id ##  _iret_t += ( id ##  _iret_a - id ##  _iret_b );
#define measure_epilogue(id)                                                       \
    printf( "cycle (average): %s => %f\n", #id, ( float )( id ## _cycle_t ) / n ); \
    printf( "iret  (average): %s => %f\n", #id, ( float )( id ##  _iret_t ) / n );
#endif
#if ( DRIVER_MEASURE == 1 ) // mode = minimum
#define measure_prologue(id)                                                       \
  uint64_t id ## _cycle_b =  0;                                                    \
  uint64_t id ## _cycle_a =  0;                                                    \
  uint64_t id ## _cycle_t = -1;                                                    \
                                                                                   \
  uint64_t id ##  _iret_b =  0;                                                    \
  uint64_t id ##  _iret_a =  0;                                                    \
  uint64_t id ##  _iret_t = -1;
#define measure_step(id,...)                                                       \
  COUNTERS(id ## _cycle_b, id ## _iret_b);                                         \
  id( __VA_ARGS__ );                                                               \
  COUNTERS(id ## _cycle_a, id ## _iret_a);                                         \
                                                                                   \
  id ## _cycle_t  = MIN( id ## _cycle_t, id ## _cycle_a - id ## _cycle_b );        \
  id ##  _iret_t  = MIN( id ##  _iret_t, id ##  _iret_a - id ##  _iret_b );
#define measure_epilogue(id)                                                       \
    printf( "cycle (minimum): %s => %f\n", #id, ( float )( id ## _cycle_t )     ); \
    printf( "iret  (minimum): %s => %f\n", #id, ( float )( id ##  _iret_t )     );
#endif
#if ( DRIVER_MEASURE == 2 ) // mode = maximum
#define measure_prologue(id)                                                       \
  uint64_t id ## _cycle_b =  0;                                                    \
  uint64_t id ## _cycle_a =  0;                                                    \
  uint64_t id ## _cycle_t =  0;                                                    \
                                                                                   \
  uint64_t id ##  _iret_b =  0;                                                    \
  uint64_t id ##  _iret_a =  0;                                                    \
  uint64_t id ##  _iret_t =  0;
#define measure_step(id,...)                                                       \
  COUNTERS(id ## _cycle_b, id ## _iret_b);                                         \
  id( __VA_ARGS__ );                                                               \
  COUNTERS(id ## _cycle_a, id ## _iret_a);                                         \
                                                                                   \
  id ## _cycle_t  = MAX( id ## _cycle_t, id ## _cycle_a - id ## _cycle_b );        \
  id ##  _iret_t  = MAX( id ##  _iret_t, id ##  _iret_a - id ##  _iret_b );
#define measure_epilogue(id)                                                       \
    printf( "cycle (maximum): %s => %f\n", #id, ( float )( id ## _cycle_t )     ); \
    printf( "iret  (maximum): %s => %f\n", #id, ( float )( id ##  _iret_t )     );
#endif
#endif

#endif
