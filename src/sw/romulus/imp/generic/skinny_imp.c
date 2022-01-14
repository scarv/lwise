/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "skinny_imp.h"

void skinny_128_384_plus_enc( uint8_t* m, uint8_t* k ) {
  uint8_t   s[ 4 ][ 4 ], rc = 0x00, t_0, t_1, t_2, t_3;

  uint8_t tk1[ 4 ][ 4 ];
  uint8_t tk2[ 4 ][ 4 ];
  uint8_t tk3[ 4 ][ 4 ];

  memcpy(   s, m,      16 * sizeof( uint8_t ) );

  memcpy( tk1, k +  0, 16 * sizeof( uint8_t ) );
  memcpy( tk2, k + 16, 16 * sizeof( uint8_t ) );
  memcpy( tk3, k + 32, 16 * sizeof( uint8_t ) );

  for( int r = 0; r < 40; r++ ){
    // SubCells

    for( int i = 0; i < 4; i++ ) {
      for( int j = 0; j < 4; j++ ) {
        s[ i ][ j ] = SBOX_ENC[ s[ i ][ j ] ];
      }
    }

    // AddConstants

    rc = RC_LFSR_FWD[ rc ]; 

    s[ 0 ][ 0 ] ^= ( ( rc >> 0 ) & 0xF );
    s[ 1 ][ 0 ] ^= ( ( rc >> 4 ) & 0x3 );
    s[ 2 ][ 0 ] ^= (               0x2 );

    // AddTweakKey

    for( int i = 0; i < 2; i++ ) {
      for( int j = 0; j < 4; j++ ) {
        s[ i ][ j ] ^= tk1[ i ][ j ];
        s[ i ][ j ] ^= tk2[ i ][ j ];
        s[ i ][ j ] ^= tk3[ i ][ j ];
      }
    }

    #define PERM_FWD(x) {                                                                 \
      uint8_t t[] = { (x)[  0 ], (x)[  1 ], (x)[  2 ], (x)[  3 ],                         \
                      (x)[  4 ], (x)[  5 ], (x)[  6 ], (x)[  7 ],                         \
                      (x)[  8 ], (x)[  9 ], (x)[ 10 ], (x)[ 11 ],                         \
                      (x)[ 12 ], (x)[ 13 ], (x)[ 14 ], (x)[ 15 ] };                       \
                                                                                          \
      (x)[  0 ] = t[  9 ]; (x)[  1 ] = t[ 15 ]; (x)[  2 ] = t[  8 ]; (x)[  3 ] = t[ 13 ]; \
      (x)[  4 ] = t[ 10 ]; (x)[  5 ] = t[ 14 ]; (x)[  6 ] = t[ 12 ]; (x)[  7 ] = t[ 11 ]; \
      (x)[  8 ] = t[  0 ]; (x)[  9 ] = t[  1 ]; (x)[ 10 ] = t[  2 ]; (x)[ 11 ] = t[  3 ]; \
      (x)[ 12 ] = t[  4 ]; (x)[ 13 ] = t[  5 ]; (x)[ 14 ] = t[  6 ]; (x)[ 15 ] = t[  7 ]; \
    }

    PERM_FWD( ( uint8_t* )( tk1 ) );
    PERM_FWD( ( uint8_t* )( tk2 ) );
    PERM_FWD( ( uint8_t* )( tk3 ) );

    #undef PERM_FWD

    for( int i = 0; i < 2; i++ ) {
      for( int j = 0; j < 4; j++ ) {
        tk2[ i ][ j ] = TK2_LFSR_FWD[ tk2[ i ][ j ] ];
        tk3[ i ][ j ] = TK3_LFSR_FWD[ tk3[ i ][ j ] ];
      }
    }

    // ShiftRows

    t_0         = s[ 1 ][ 3 ];
    s[ 1 ][ 3 ] = s[ 1 ][ 2 ];
    s[ 1 ][ 2 ] = s[ 1 ][ 1 ];
    s[ 1 ][ 1 ] = s[ 1 ][ 0 ];
    s[ 1 ][ 0 ] = t_0;
 
    t_0         = s[ 2 ][ 3 ];
    t_1         = s[ 2 ][ 2 ];
    s[ 2 ][ 3 ] = s[ 2 ][ 1 ];
    s[ 2 ][ 2 ] = s[ 2 ][ 0 ];
    s[ 2 ][ 1 ] = t_0;
    s[ 2 ][ 0 ] = t_1;
 
    t_0         = s[ 3 ][ 0 ];
    s[ 3 ][ 0 ] = s[ 3 ][ 1 ];
    s[ 3 ][ 1 ] = s[ 3 ][ 2 ];
    s[ 3 ][ 2 ] = s[ 3 ][ 3 ];
    s[ 3 ][ 3 ] = t_0;

    // MixColumns

    for( int j = 0; j < 4; j++ ) {
      t_3 = s[ 0 ][ j ] ^               s[ 2 ][ j ]               ;
      t_2 =               s[ 1 ][ j ] ^ s[ 2 ][ j ]               ;
      t_1 = s[ 0 ][ j ]                                           ;
      t_0 = s[ 0 ][ j ] ^               s[ 2 ][ j ] ^ s[ 3 ][ j ] ;

      s[ 3 ][ j ]  = t_3;
      s[ 2 ][ j ]  = t_2;
      s[ 1 ][ j ]  = t_1;
      s[ 0 ][ j ]  = t_0;
    }
  }

  memcpy(   m, s,      16 * sizeof( uint8_t ) );
}
