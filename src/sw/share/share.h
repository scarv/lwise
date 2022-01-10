/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __SHARE_H
#define __SHARE_H

// ============================================================================

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <string.h>

// ----------------------------------------------------------------------------

#define MIN(x,y) ((x)<(y)?(x):(y))
#define MAX(x,y) ((x)>(y)?(x):(y))

#define ROL32(x,n) (((x) << (n)) | ((x) >> (32 - (n))))
#define ROR32(x,n) (((x) >> (n)) | ((x) << (32 - (n))))
#define ROL64(x,n) (((x) << (n)) | ((x) >> (64 - (n))))
#define ROR64(x,n) (((x) >> (n)) | ((x) << (64 - (n))))

// ----------------------------------------------------------------------------

#if !defined( DRIVER_TRIALS_WARM )
#define DRIVER_TRIALS_WARM   10
#endif
#if !defined( DRIVER_TRIALS_REAL )
#define DRIVER_TRIALS_REAL 1000
#endif

#define measure_prologue(id)                                                         \
  uint32_t id ## _tsc_b      =  0;                                                   \
  uint32_t id ## _tsc_a      =  0;                                                   \
                                                                                     \
  uint32_t id ## _tsc_t_mean =  0;                                                   \
  uint32_t id ## _tsc_t_min  = -1;                                                   \
  uint32_t id ## _tsc_t_max  =  0;

#define measure_step(id,...)                                                         \
  id ## _tsc_b = rdtsc();                                                            \
  id( __VA_ARGS__ );                                                                 \
  id ## _tsc_a = rdtsc();                                                            \
                                                                                     \
  if( i >= trials_warm ) {                                                           \
    id ## _tsc_t_mean +=    (                   id ## _tsc_a - id ## _tsc_b );       \
    id ## _tsc_t_min   = MIN( id ## _tsc_t_min, id ## _tsc_a - id ## _tsc_b );       \
    id ## _tsc_t_max   = MAX( id ## _tsc_t_max, id ## _tsc_a - id ## _tsc_b );       \
  }

#define measure_epilogue(id,n)                                                       \
    printf( "tsc (mean)    : %s => %f\n", #id, ( float )( id ## _tsc_t_mean ) / n ); \
    printf( "tsc (minimum) : %s => %f\n", #id, ( float )( id ## _tsc_t_min )      ); \
    printf( "tsc (maximum) : %s => %f\n", #id, ( float )( id ## _tsc_t_max )      );

// ----------------------------------------------------------------------------

extern void parse_bytes( uint8_t* r, char* x, int n );

extern void rand_init();
extern void rand_fini();

extern void rand_bytes( uint8_t* x, int n );

extern void dump_bytes( uint8_t* x, int n );

// ============================================================================

#endif
