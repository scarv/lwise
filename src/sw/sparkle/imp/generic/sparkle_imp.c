/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "sparkle_imp.h"

void sparkle_fwd( uint32_t* state, int brans, int steps ) { // brans \in { 4, 6, 8 }
  uint32_t x, y, tmpx, tmpy;

  for( int i = 0; i < steps; i++ ) {
    state[ 1 ] ^= SPARKLE_RCON[ i % SPARKLE_BRANS ];
    state[ 3 ] ^= i;

    for( int j = 0; j < ( 2 * brans ); j += 2 ) {
      ALZETTE_ENC( state[ j ], state[ j + 1 ], SPARKLE_RCON[ j >> 1 ] );
    }

    x = state[ 0 ]; tmpx = x;
    y = state[ 1 ]; tmpy = y;
    
    for( int j = 2; j < ( 1 * brans ); j += 2 ) {
      tmpx ^= state[ j     ];
      tmpy ^= state[ j + 1 ];
    }

    tmpx = ELL( tmpx );
    tmpy = ELL( tmpy );

    for( int j = 2; j < ( 1 * brans ); j += 2 ) {
      state[ j         - 2 ] = state[ j + brans     ] ^ state[ j     ] ^ tmpy;
      state[ j         - 1 ] = state[ j + brans + 1 ] ^ state[ j + 1 ] ^ tmpx;
      state[ j + brans     ] = state[ j             ];
      state[ j + brans + 1 ] = state[ j         + 1 ];
    }

    state[ brans - 2 ] = state[ brans     ] ^ tmpy ^ x;
    state[ brans - 1 ] = state[ brans + 1 ] ^ tmpx ^ y;
    state[ brans     ] =                             x;
    state[ brans + 1 ] =                             y;
  }
}

void sparkle_rev( uint32_t* state, int brans, int steps ) { // brans \in { 4, 6, 8 }
  uint32_t x, y, tmpx, tmpy;
  
  for( int i = ( steps - 1 ); i >= 0; i-- ) {
    tmpx = 0; 
    tmpy = 0;

    x = state[ brans - 2 ];
    y = state[ brans - 1 ];

    for( int j = ( brans - 2 ); j > 0; j -= 2 ) {
      state[ j             ] = state[ j + brans     ];
      state[ j +         1 ] = state[ j + brans + 1 ];
      state[ j + brans     ] = state[ j -         2 ];
      state[ j + brans + 1 ] = state[ j -         1 ];

      tmpx ^= state[ j     ];
      tmpy ^= state[ j + 1 ];
    }

    tmpx ^= state[ 0 ] = state[ brans     ];
    tmpy ^= state[ 1 ] = state[ brans + 1 ];

    state[ brans     ] = x;
    state[ brans + 1 ] = y;

    tmpx = ELL( tmpx );
    tmpy = ELL( tmpy );

    for( int j = ( brans - 2 ); j >= 0; j -= 2 ) {
      state[ j + brans     ] ^= tmpy ^ state[ j     ];
      state[ j + brans + 1 ] ^= tmpx ^ state[ j + 1 ];
    }

    for( int j = 0; j < ( 2 * brans ); j += 2 ) {
      ALZETTE_DEC( state[ j ], state[ j + 1 ], SPARKLE_RCON[ j >> 1 ] );
    }

    state[ 1 ] ^= SPARKLE_RCON[ i % SPARKLE_BRANS ];
    state[ 3 ] ^= i;
  }
}
