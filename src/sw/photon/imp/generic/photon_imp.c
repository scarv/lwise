/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "photon_imp.h"

static const uint8_t RC[ 12 ][ 8 ] = {
  { 0x1, 0x0, 0x2, 0x6, 0xE, 0xF, 0xD, 0x9 },
  { 0x3, 0x2, 0x0, 0x4, 0xC, 0xD, 0xF, 0xB },
  { 0x7, 0x6, 0x4, 0x0, 0x8, 0x9, 0xB, 0xF },
  { 0xE, 0xF, 0xD, 0x9, 0x1, 0x0, 0x2, 0x6 },
  { 0xD, 0xC, 0xE, 0xA, 0x2, 0x3, 0x1, 0x5 },
  { 0xB, 0xA, 0x8, 0xC, 0x4, 0x5, 0x7, 0x3 },
  { 0x6, 0x7, 0x5, 0x1, 0x9, 0x8, 0xA, 0xE },
  { 0xC, 0xD, 0xF, 0xB, 0x3, 0x2, 0x0, 0x4 },
  { 0x9, 0x8, 0xA, 0xE, 0x6, 0x7, 0x5, 0x1 },
  { 0x2, 0x3, 0x1, 0x5, 0xD, 0xC, 0xE, 0xA },
  { 0x5, 0x4, 0x6, 0x2, 0xA, 0xB, 0x9, 0xD },
  { 0xA, 0xB, 0x9, 0xD, 0x5, 0x4, 0x6, 0x2 }
};

void PHOTON_Permutation( uint8_t* x ) {
  uint8_t *p, s[ 8 ][ 8 ], t[ 8 ];

  p = x;

  for( int i = 0; i < 8; i += 1 ) {
    for( int j = 0; j < 8; j += 2 ) {
      uint8_t t = *p++;

      s[ i ][ j + 0 ] = ( t >> 0 ) & 0xF;
      s[ i ][ j + 1 ] = ( t >> 4 ) & 0xF;
    }
  }

  for( int r = 0; r < 12; r++ ) {
    // AddConstant

    for( int i = 0; i < 8; i++ ) {
      s[ i ][ 0 ] ^= RC[ r ][ i ];
    }

    // SubCells

    for( int i = 0; i < 8; i++ ) {
      for( int j = 0; j < 8; j++ ) {
        s[ i ][ j ] = SBOX[ s[ i ][ j ] ];
      }
    }

    // ShiftRows

    for( int i = 1; i < 8; i++ ) {
      for( int j = 0; j < 8; j++ ) {
        t[ j ] = s[ i ][ j ];
      }

      for( int j = 0; j < 8; j++ ) {
        s[ i ][ j ] = t[ ( j + i ) % 8 ];
      }
    }

    // MixColumnSerial

    for( int j = 0; j < 8; j++ ) {
      for( int i = 0; i < 8; i++ ) {
        t[ i ] = 0;

        for( int k = 0; k < 8; k++ ) {
          t[ i ] ^= GF2N_MUL( M[ i ][ k ], s[ k ][ j ] );
        }
      }

      for( int i = 0; i < 8; i++ ) {
        s[ i ][ j ] = t[ i ];
      }
    }
  }

  p = x;

  for( int i = 0; i < 8; i += 1 ) {
    for( int j = 0; j < 8; j += 2 ) {
      uint8_t t  = ( s[ i ][ j + 0 ] & 0xF ) << 0;
              t |= ( s[ i ][ j + 1 ] & 0xF ) << 4;

      *p++ = t;
    }
  }
}
