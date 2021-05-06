/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "craxs10.h"

#define NSTEPS 10

static const uint32_t RCON[ 10 ] = {
  0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB,
  0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB
};

#if !defined( CRAXS10_ENC_EXTERN )
void craxs10_enc( uint32_t* state, const uint32_t* key ) {
  uint32_t xw = state[ 0 ];
  uint32_t yw = state[ 1 ];

  uint32_t k0 =   key[ 0 ];
  uint32_t k1 =   key[ 1 ];
  uint32_t k2 =   key[ 2 ];
  uint32_t k3 =   key[ 3 ];

  int i =          0;

  while( i < NSTEPS ) {
    xw ^= ( k0 ^ i ); 
    yw ^= ( k1     );
    ALZETTE_ENC( xw, yw, RCON[ i ] );
    i++;
    xw ^= ( k2 ^ i ); 
    yw ^= ( k3     );
    ALZETTE_ENC( xw, yw, RCON[ i ] );
    i++;
  }

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

  int i = NSTEPS - 1;

    xw ^= k0;
    yw ^= k1;

  while( i > 0      ) {
    ALZETTE_DEC( xw, yw, RCON[ i ] );
    xw ^= ( k2 ^ i );
    yw ^= ( k3     );
    i--;
    ALZETTE_DEC( xw, yw, RCON[ i ] );
    xw ^= ( k0 ^ i );
    yw ^= ( k1     );
    i--;
  }

  state[ 0 ] = xw;
  state[ 1 ] = yw;
}
#endif
