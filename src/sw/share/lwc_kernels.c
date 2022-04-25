/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */
#include "driver.h"
#include "lwc_kernels.h"

extern void rand_bytes(uint8_t* x, int n );

//because P6 in the nist implementation is a static inline function.
#if defined(ascon_alg)
void P6_nist(state_t* s){
  P6(s);
}
#endif

void time_kernel() {
  int trials_warm = DRIVER_TRIALS_WARM;
  int trials_real = DRIVER_TRIALS_REAL;

  int trials      = trials_warm + trials_real;

#if defined(ascon_alg) || defined(ASCON_RV32_TYPE1) || defined(ASCON_RV32_TYPE2)
  #if defined(ASCON_RV32_TYPE1) || defined(ASCON_RV32_TYPE2)
  unsigned long long s_n = 40; uint8_t s[ s_n ];
  #else
  unsigned long long s_n = 40; uint8_t s_a[ s_n ];
  state_t * s = (state_t *) s_a;
  #endif
  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( P6 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes((uint8_t*) s, s_n );

    MEASURE_STEP( P6, s );
  }

  MEASURE_EPILOGUE( P6 );

#elif defined(elephant_alg) || defined(ELEPHANT_RV32_TYPE1) || defined(ELEPHANT_RV32_TYPE2)
unsigned long long s_n = 20; uint8_t s[ s_n ];

  MEASURE_PROLOGUE( permutation );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( permutation, s );
  }

  MEASURE_EPILOGUE( permutation );

#elif defined(gift_alg) || defined(GIFT_RV32_TYPE1) || defined(GIFT_RV32_TYPE2) || defined(GIFT_RV32_TYPE3)
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
  #elif defined(GIFT_FIXSLICING) 
  unsigned long long rk_n = 80*4; uint8_t rk[ rk_n ];

  MEASURE_PROLOGUE( giftb128_fixslicing );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes(  p,  p_n );
    rand_bytes( rk, rk_n );
    rand_bytes(  c,  c_n );
    MEASURE_STEP( giftb128_fixslicing, p, rk, c );
  }

  MEASURE_EPILOGUE( giftb128_fixslicing );

  MEASURE_PROLOGUE( precompute_rkeys );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( k, k_n );

    MEASURE_STEP( precompute_rkeys, rk, k );
  }

  MEASURE_EPILOGUE( precompute_rkeys );
  #else

  MEASURE_PROLOGUE( giftb128 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( p, p_n );
    rand_bytes( k, k_n );
    rand_bytes( c, c_n );
    MEASURE_STEP( giftb128, p, k, c );
  }

  MEASURE_EPILOGUE( giftb128 );
  #endif

#elif defined(grain_alg) || defined(GRAIN_RV32_TYPE1) || defined(GRAIN_RV32_TYPE2)
unsigned long long s_n =44; uint8_t s[ s_n ];

  MEASURE_PROLOGUE( grain_keystream32 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( grain_keystream32, (grain_ctx *) s );
  }

  MEASURE_EPILOGUE( grain_keystream32 );

#elif defined(photon_alg) || defined(PHOTON_RV32_TYPE1) || defined(PHOTON_RV32_TYPE2)
  unsigned long long s_n = 32; uint8_t s[ s_n ];

  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( PHOTON_Permutation );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( PHOTON_Permutation, s );
  }

  MEASURE_EPILOGUE( PHOTON_Permutation );
#elif defined(romulus_alg) || defined(ROMULUS_RV32_TYPE1) || defined(ROMULUS_RV32_TYPE2) || defined(ROMULUS_RV32_TYPE3) 
  unsigned long long s_n = 16; uint8_t s[ s_n ];
  unsigned long long k_n = 48; uint8_t k[ k_n ];

  printf( "sizeof( s ) = %llu\n", s_n );
  printf( "sizeof( k ) = %llu\n", k_n );

  #ifdef ROMULUS_LUT 
  MEASURE_PROLOGUE( skinny_128_384_plus_enc );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );
    rand_bytes( k, k_n );

    MEASURE_STEP( skinny_128_384_plus_enc, s, k );
  }

  MEASURE_EPILOGUE( skinny_128_384_plus_enc );
  #elif ROMULUS_FIXSLICING
  unsigned long long c_n    = 16;    uint8_t  c  [ c_n ];
  unsigned long long rk1_n  = 64*4;  uint8_t rk1 [ rk1_n ];
  unsigned long long rk23_n = 160*4; uint8_t rk23[ rk23_n ];

  MEASURE_PROLOGUE( skinny128_384_plus );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s,    s_n );
    rand_bytes( c,    c_n );
    rand_bytes( rk1,  rk1_n );
    rand_bytes( rk23, rk23_n );

    MEASURE_STEP( skinny128_384_plus, c, s, rk1, rk23 );
  }

  MEASURE_EPILOGUE( skinny128_384_plus );

  MEASURE_PROLOGUE( precompute_rtk1 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( k, k_n );

    MEASURE_STEP( precompute_rtk1, rk1, k );
  }

  MEASURE_EPILOGUE( precompute_rtk1 );

  MEASURE_PROLOGUE( precompute_rtk2_3 );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( k, k_n );
    rand_bytes( c, c_n );

    MEASURE_STEP( precompute_rtk2_3, rk23, c, k );
  }

  MEASURE_EPILOGUE( precompute_rtk2_3 );
  #endif

#elif defined(sparkle_alg) || defined(SPARKLE_RV32_TYPE1) || defined(SPARKLE_RV32_TYPE2) || defined(SPARKLE_RV32_TYPE3) || defined(SPARKLE_RV32_TYPE4)
  unsigned long long s_n = SPARKLE_STATE/8; uint8_t s[ s_n ];

  printf( "sizeof( s ) = %llu\n", s_n );

  MEASURE_PROLOGUE( sparkle_opt );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );

    MEASURE_STEP( sparkle_opt, s, SPARKLE_STATE/64, 12);
  }

  MEASURE_EPILOGUE( sparkle_opt );

#elif defined(jambu) || defined(JAMBU_RV32_TYPE1) || defined(JAMBU_RV32_TYPE2) || defined(JAMBU_RV32_TYPE3) 
  unsigned long long s_n = 16; uint8_t s[ s_n ];
  unsigned long long k_n = 48; uint8_t k[ k_n ];

  MEASURE_PROLOGUE( state_update );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( s, s_n );
    rand_bytes( k, k_n );
    MEASURE_STEP( state_update, s, k, 128*8);
  }

  MEASURE_EPILOGUE( state_update );

#elif defined(xoodyak_alg) || defined(XOODYAK_RV32_TYPE1) || defined(XOODYAK_RV32_TYPE2)
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
