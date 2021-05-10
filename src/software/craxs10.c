/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "craxs10.h"

const uint32_t CRAXS10_RCON[ 10 ] = {
  0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB,
  0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB
};

#if defined( CRAXS10_ENC_UNROLL )
#define CRAXS10_ENC_STEP(k0,k1,i) {         \
  xw ^= ( k0 ^ i );                         \
  yw ^= ( k1     );                         \
  ALZETTE_ENC( xw, yw, CRAXS10_RCON[ i ] ); \
}
#else
#define CRAXS10_ENC_STEP(k0,k1,i) {         \
  xw ^= ( k0 ^ i );                         \
  yw ^= ( k1     );                         \
  ALZETTE_ENC( xw, yw, CRAXS10_RCON[ i ] ); \
  i++;                                      \
}
#endif
#if defined( CRAXS10_DEC_UNROLL )
#define CRAXS10_DEC_STEP(k0,k1,i) {         \
  ALZETTE_DEC( xw, yw, CRAXS10_RCON[ i ] ); \
  xw ^= ( k0 ^ i );                         \
  yw ^= ( k1     );                         \
}
#else
#define CRAXS10_DEC_STEP(k0,k1,i) {         \
  ALZETTE_DEC( xw, yw, CRAXS10_RCON[ i ] ); \
  xw ^= ( k0 ^ i );                         \
  yw ^= ( k1     );                         \
  i--;                                      \
}
#endif

#if !defined( CRAXS10_ENC_EXTERN )
void craxs10_enc( uint32_t* state, const uint32_t* key ) {
  uint32_t xw = state[ 0 ];
  uint32_t yw = state[ 1 ];

  uint32_t k0 =   key[ 0 ];
  uint32_t k1 =   key[ 1 ];
  uint32_t k2 =   key[ 2 ];
  uint32_t k3 =   key[ 3 ];

  int i = 0;

  #if defined( CRAXS10_ENC_UNROLL )
    CRAXS10_ENC_STEP( k0, k1, 0 )
    CRAXS10_ENC_STEP( k2, k3, 1 )
    CRAXS10_ENC_STEP( k0, k1, 2 )
    CRAXS10_ENC_STEP( k2, k3, 3 )
    CRAXS10_ENC_STEP( k0, k1, 4 )  
    CRAXS10_ENC_STEP( k2, k3, 5 )
    CRAXS10_ENC_STEP( k0, k1, 6 )  
    CRAXS10_ENC_STEP( k2, k3, 7 )
    CRAXS10_ENC_STEP( k0, k1, 8 )  
    CRAXS10_ENC_STEP( k2, k3, 9 )
  #else
  while( i < CRAXS10_NSTEPS ) {
    CRAXS10_ENC_STEP( k0, k1, i )
    CRAXS10_ENC_STEP( k2, k3, i )
  }
  #endif

    xw ^= k0;
    yw ^= k1;

  state[ 0 ] = xw;
  state[ 1 ] = yw;
}
#endif

#if !defined( CRAXS10_DEC_EXTERN )
void craxs10_dec( uint32_t* state, const uint32_t* key ) {
  uint32_t xw = state[ 0 ];
  uint32_t yw = state[ 1 ];

  uint32_t k0 =   key[ 0 ];
  uint32_t k1 =   key[ 1 ];
  uint32_t k2 =   key[ 2 ];
  uint32_t k3 =   key[ 3 ];

  int i = CRAXS10_NSTEPS - 1;

    xw ^= k0;
    yw ^= k1;

  #if defined( CRAXS10_DEC_UNROLL )
    CRAXS10_DEC_STEP( k2, k3, 9 )
    CRAXS10_DEC_STEP( k0, k1, 8 )
    CRAXS10_DEC_STEP( k2, k3, 7 )
    CRAXS10_DEC_STEP( k0, k1, 6 )
    CRAXS10_DEC_STEP( k2, k3, 5 )
    CRAXS10_DEC_STEP( k0, k1, 4 )  
    CRAXS10_DEC_STEP( k2, k3, 3 )
    CRAXS10_DEC_STEP( k0, k1, 2 )  
    CRAXS10_DEC_STEP( k2, k3, 1 )
    CRAXS10_DEC_STEP( k0, k1, 0 )  
  #else
  while( i > 0 ) {
    CRAXS10_DEC_STEP( k2, k3, i )
    CRAXS10_DEC_STEP( k0, k1, i )
  }
  #endif

  state[ 0 ] = xw;
  state[ 1 ] = yw;
}
#endif
