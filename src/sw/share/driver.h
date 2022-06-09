/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __DRIVER_H
#define __DRIVER_H

// ============================================================================

#include "share.h"
#include "rdtsc.h"

#if !defined( DRIVER_BYPASS_TEST )
#include   "kat.h"
#endif

#if defined( API_AEAD )
#include         "api.h"
#include "crypto_aead.h"
#endif

#if defined( API_HASH )
#include         "api.h"
#include "crypto_hash.h"
#endif

#include "lwc_kernels.h"

// ----------------------------------------------------------------------------

#if !defined( DRIVER_TRIALS_WARM )
#define DRIVER_TRIALS_WARM   10
#endif
#if !defined( DRIVER_TRIALS_REAL )
#define DRIVER_TRIALS_REAL 1000
#endif

#if defined( API_AEAD )
#if !defined( DRIVER_SIZEOF_A    )
#define DRIVER_SIZEOF_A ( 16 )
#endif
#if !defined( DRIVER_SIZEOF_M    )
#define DRIVER_SIZEOF_M ( 16 )
#endif

#define DRIVER_SIZEOF_K ( CRYPTO_KEYBYTES )
#define DRIVER_SIZEOF_N ( CRYPTO_NSECBYTES + CRYPTO_NPUBBYTES )
#define DRIVER_SIZEOF_C ( DRIVER_SIZEOF_M + CRYPTO_ABYTES )
#endif

#if defined( API_HASH )
#if !defined( DRIVER_SIZEOF_M    )
#define DRIVER_SIZEOF_M ( 16 )
#endif

#define DRIVER_SIZEOF_D ( CRYPTO_BYTES )
#endif

// ----------------------------------------------------------------------------

#define MEASURE_PROLOGUE(id)                                                                   \
  uint32_t id ## _tsc_b      =  0;                                                             \
  uint32_t id ## _tsc_a      =  0;                                                             \
                                                                                               \
  uint32_t id ## _tsc_t_mean =  0;                                                             \
  uint32_t id ## _tsc_t_min  = -1;                                                             \
  uint32_t id ## _tsc_t_max  =  0;

#define MEASURE_STEP(id,...)                                                                   \
  id ## _tsc_b = rdtsc();                                                                      \
  id( __VA_ARGS__ );                                                                           \
  id ## _tsc_a = rdtsc();                                                                      \
                                                                                               \
  if( i >= trials_warm ) {                                                                     \
    id ## _tsc_t_mean +=    (                   id ## _tsc_a - id ## _tsc_b );                 \
    id ## _tsc_t_min   = MIN( id ## _tsc_t_min, id ## _tsc_a - id ## _tsc_b );                 \
    id ## _tsc_t_max   = MAX( id ## _tsc_t_max, id ## _tsc_a - id ## _tsc_b );                 \
  }

#define MEASURE_EPILOGUE(id)                                                                   \
    printf( "tsc (mean)    : %s => %f\n", #id, ( float )( id ## _tsc_t_mean ) / trials_real ); \
    printf( "tsc (minimum) : %s => %f\n", #id, ( float )( id ## _tsc_t_min )                ); \
    printf( "tsc (maximum) : %s => %f\n", #id, ( float )( id ## _tsc_t_max )                );

// ============================================================================

#endif
