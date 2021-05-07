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

    for( int j = 0; j < 8; j++ ) {
      tmpk[ j - 1 ] = tmpk[ j ];
    }

             tmpk[ 7 ] = tmp;
  }
}

#if !defined( TRAXL17_ENC_EXTERN )
void traxl17_enc( uint32_t* x, uint32_t* y, const uint32_t* subkeys, const uint32_t* tweak ) {
  uint32_t tmpx;
  uint32_t tmpy;

  int i = 0;

  while( i < TRAXL17_NSTEPS - 1 ) {
    for( int j = 0; j < 4; j++ ) {
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
      ALZETTE_ENC( x[ j ], y[ j ], TRAXL17_RCON[ j     ] );
    }

    tmpx = ELL( x[ 2 ] ^ x[ 3 ] ); y[ 0 ] ^= tmpx; y[ 1 ] ^= tmpx;
    tmpy = ELL( y[ 2 ] ^ y[ 3 ] ); x[ 0 ] ^= tmpy; x[ 1 ] ^= tmpy;
    tmpx = x[ 0 ]; x[ 0 ] = x[ 3 ]; x[ 3 ] = x[ 1 ]; x[ 1 ] = x[ 2 ]; x[ 2 ] = tmpx;
    tmpy = y[ 0 ]; y[ 0 ] = y[ 3 ]; y[ 3 ] = y[ 1 ]; y[ 1 ] = y[ 2 ]; y[ 2 ] = tmpy;

    i++;

    x[ 0 ] ^= tweak[ 0 ]; y[ 0 ] ^= tweak[ 1 ];
    x[ 1 ] ^= tweak[ 2 ]; y[ 1 ] ^= tweak[ 3 ];

    for( int j = 0; j < 4; j++ ) {
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
      ALZETTE_ENC( x[ j ], y[ j ], TRAXL17_RCON[ j + 4 ] );
    }

    tmpx = ELL( x[ 2 ] ^ x[ 3 ] ); y[ 0 ] ^= tmpx; y[ 1 ] ^= tmpx;
    tmpy = ELL( y[ 2 ] ^ y[ 3 ] ); x[ 0 ] ^= tmpy; x[ 1 ] ^= tmpy;
    tmpx = x[ 0 ]; x[ 0 ] = x[ 3 ]; x[ 3 ] = x[ 1 ]; x[ 1 ] = x[ 2 ]; x[ 2 ] = tmpx;
    tmpy = y[ 0 ]; y[ 0 ] = y[ 3 ]; y[ 3 ] = y[ 1 ]; y[ 1 ] = y[ 2 ]; y[ 2 ] = tmpy;

    i++;
  }

    for( int j = 0; j < 4; j++ ) {
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
      ALZETTE_ENC( x[ j ], y[ j ], TRAXL17_RCON[ j     ] );
    }

    tmpx = ELL( x[ 2 ] ^ x[ 3 ] ); y[ 0 ] ^= tmpx; y[ 1 ] ^= tmpx;
    tmpy = ELL( y[ 2 ] ^ y[ 3 ] ); x[ 0 ] ^= tmpy; x[ 1 ] ^= tmpy;
    tmpx = x[ 0 ]; x[ 0 ] = x[ 3 ]; x[ 3 ] = x[ 1 ]; x[ 1 ] = x[ 2 ]; x[ 2 ] = tmpx;
    tmpy = y[ 0 ]; y[ 0 ] = y[ 3 ]; y[ 3 ] = y[ 1 ]; y[ 1 ] = y[ 2 ]; y[ 2 ] = tmpy;

    i++;

    for( int j = 0; j < 4; j++ ) {
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
    }
}
#endif

#if !defined( TRAXL17_DEC_EXTERN )
void traxl17_dec( uint32_t* x, uint32_t* y, const uint32_t* subkeys, const  uint32_t* tweak ) {
  uint32_t tmpx;
  uint32_t tmpy;

  int i = TRAXL17_NSTEPS;

    for( int j = 0; j < 4; j++ ) {
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
    }

    i--;

    tmpy = y[ 0 ]; y[ 0 ] = y[ 2 ]; y[ 2 ] = y[ 1 ]; y[ 1 ] = y[ 3 ]; y[ 3 ] = tmpy;
    tmpx = x[ 0 ]; x[ 0 ] = x[ 2 ]; x[ 2 ] = x[ 1 ]; x[ 1 ] = x[ 3 ]; x[ 3 ] = tmpx;
    tmpy = ELL( y[ 2 ] ^ y[ 3 ] ); x[ 0 ] ^= tmpy; x[ 1 ] ^= tmpy;
    tmpx = ELL( x[ 2 ] ^ x[ 3 ] ); y[ 0 ] ^= tmpx; y[ 1 ] ^= tmpx;

    for( int j = 0; j < 4; j++ ) {
      ALZETTE_DEC( x[ j ], y[ j ], TRAXL17_RCON [ j    ] );
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
    }

    i--;

  while( i > 0 ) {
    tmpy = y[ 0 ]; y[ 0 ] = y[ 2 ]; y[ 2 ] = y[ 1 ]; y[ 1 ] = y[ 3 ]; y[ 3 ] = tmpy;
    tmpx = x[ 0 ]; x[ 0 ] = x[ 2 ]; x[ 2 ] = x[ 1 ]; x[ 1 ] = x[ 3 ]; x[ 3 ] = tmpx;
    tmpy = ELL( y[ 2 ] ^ y[ 3 ] ); x[ 0 ] ^= tmpy; x[ 1 ] ^= tmpy;
    tmpx = ELL( x[ 2 ] ^ x[ 3 ] ); y[ 0 ] ^= tmpx; y[ 1 ] ^= tmpx;

    for( int j = 0; j < 4; j++ ) {
      ALZETTE_DEC( x[ j ], y[ j ], TRAXL17_RCON[ j + 4 ] );
      y[ j ] ^=  subkeys[ 8 * i + 2 * j + 1 ];
      x[ j ] ^=  subkeys[ 8 * i + 2 * j     ];
    }

    y[ 1 ] ^= tweak[ 3 ]; x[ 1 ] ^= tweak[ 2 ];
    y[ 0 ] ^= tweak[ 1 ]; x[ 0 ] ^= tweak[ 0 ];

    i--;

    tmpy = y[ 0 ]; y[ 0 ] = y[ 2 ]; y[ 2 ] = y[ 1 ]; y[ 1 ] = y[ 3 ]; y[ 3 ] = tmpy;
    tmpx = x[ 0 ]; x[ 0 ] = x[ 2 ]; x[ 2 ] = x[ 1 ]; x[ 1 ] = x[ 3 ]; x[ 3 ] = tmpx;
    tmpy = ELL( y[ 2 ] ^ y[ 3 ] ); x[ 0 ] ^= tmpy; x[ 1 ] ^= tmpy;
    tmpx = ELL( x[ 2 ] ^ x[ 3 ] ); y[ 0 ] ^= tmpx; y[ 1 ] ^= tmpx;

    for( int j = 0; j < 4; j++ ) {
      ALZETTE_DEC( x[ j ], y[ j ], TRAXL17_RCON [ j    ] );
      y[ j ] ^= subkeys[ 8 * i + 2 * j + 1 ];
      x[ j ] ^= subkeys[ 8 * i + 2 * j     ];
    }

    i--;
  }
}
#endif

