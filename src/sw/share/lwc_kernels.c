/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */
#include "driver.h"
#include "lwc_kernels.h"
extern void rand_bytes(uint8_t* x, int n );

void time_kernel() {
  int trials_warm = DRIVER_TRIALS_WARM;
  int trials_real = DRIVER_TRIALS_REAL;

  int trials      = trials_warm + trials_real;

#if defined(ASCON_RV32_TYPE1) || defined(ASCON_RV32_TYPE2)
  unsigned long long s_n = 40; uint8_t s[ s_n ];

  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( P12 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( P12, s );
  }

  MEASURE_EPILOGUE( P12 );

  MEASURE_PROLOGUE( P6 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( P6, s );
  }

  MEASURE_EPILOGUE( P6 );

#elif defined(GIFT_RV32_TYPE1) || defined(GIFT_RV32_TYPE2)
  unsigned long long p_n = 16; uint8_t p[ p_n ];
  unsigned long long k_n = 16; uint8_t k[ k_n ];
  unsigned long long c_n = 16; uint8_t c[ c_n ];

  #ifdef GIFT_BITSLICING 
  MEASURE_PROLOGUE( giftb128_bitslicing );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( p, p_n );
    rand_bytes( k, k_n );
    rand_bytes( c, c_n );
    MEASURE_STEP( giftb128_bitslicing, p, k, c );
  }

  MEASURE_EPILOGUE( giftb128_bitslicing );
  #else 
  MEASURE_PROLOGUE( giftb128_fixslicing );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( p, p_n );
    rand_bytes( k, k_n );
    rand_bytes( c, c_n );
    MEASURE_STEP( giftb128_fixslicing, p, k, c );
  }

  MEASURE_EPILOGUE( giftb128_fixslicing );
  #endif

#elif defined(PHOTON_RV32_TYPE1) || defined(PHOTON_RV32_TYPE2)
  unsigned long long s_n = 32; uint8_t s[ s_n ];

  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( PHOTON_Permutation );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( PHOTON_Permutation, s );
  }

  MEASURE_EPILOGUE( PHOTON_Permutation );
#elif defined(ROMULUS_RV32_TYPE1) || defined(ROMULUS_RV32_TYPE2)
  unsigned long long s_n = 16; uint8_t s[ s_n ];
  unsigned long long k_n = 48; uint8_t k[ k_n ];

  printf( "sizeof( s ) = %llu\n", s_n );
  printf( "sizeof( k ) = %llu\n", k_n );

  MEASURE_PROLOGUE( skinny_128_384_plus_enc );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );
    rand_bytes( k, k_n );

    MEASURE_STEP( skinny_128_384_plus_enc, s, k );
  }

  MEASURE_EPILOGUE( skinny_128_384_plus_enc );
#elif defined(SPARKLE_RV32_TYPE1) || defined(SPARKLE_RV32_TYPE2) || defined(SPARKLE_RV32_TYPE3) || defined(SPARKLE_RV32_TYPE4)
  unsigned long long s_n = SPARKLE_STATE/8; uint8_t s[ s_n ];

  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( sparkle_opt );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( sparkle_opt, s, SPARKLE_STATE/64, 12);
  }

  MEASURE_EPILOGUE( sparkle_opt );

#elif defined(XOODYAK_RV32_TYPE1) || defined(XOODYAK_RV32_TYPE2)
  unsigned long long s_n = 48; uint8_t s[ s_n ];

  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( Xoodoo_Permute_12rounds );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( Xoodoo_Permute_12rounds, s );
  }

  MEASURE_EPILOGUE( Xoodoo_Permute_12rounds );
#endif
}
