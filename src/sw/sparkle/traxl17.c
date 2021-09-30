/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "traxl17.h"

const uint32_t TRAXL17_RCON[ 8 ] = {
  0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738,
  0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D
};

void traxl17_genkeys( uint32_t* subkeys, const uint32_t* key ) {
  uint32_t tmpk[ 8 ];
    
  memcpy( tmpk, key, 8 * sizeof( uint32_t ) );

  for( int i = 0; i < ( TRAXL17_NSTEPS + 1 ); i++ ) {
    for( int j = 0; j < 8; j++ ) {
      subkeys[ 8 * i + j ] = tmpk[ j ];
    }

    tmpk[ 0 ] += tmpk[ 1 ] + TRAXL17_RCON[ ( 2 * i     ) % 8 ];
    tmpk[ 2 ] ^= tmpk[ 3 ] ^ ( ( uint32_t )( i       ) );
    tmpk[ 4 ] += tmpk[ 5 ] + TRAXL17_RCON[ ( 2 * i + 1 ) % 8 ];
    tmpk[ 6 ] ^= tmpk[ 7 ] ^ ( ( uint32_t )( i << 16 ) );

    uint32_t tmp = tmpk[ 0 ];

    for( int j = 1; j < 8; j++ ) {
      tmpk[ j - 1 ] = tmpk[ j ];
    }

             tmpk[ 7 ] = tmp;
  }
}
