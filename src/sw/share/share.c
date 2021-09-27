/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "share.h"

// ============================================================================

void dump_bytes( char* id, uint8_t* x, int n ) {
  printf( "%s = ", id );

  for( int i = ( n - 1 ); i >= 0; i-- ) {
    printf( "%02X", x[ i ] );
  }

  printf( "\n" );
}

// ----------------------------------------------------------------------------

#if  defined( DRIVER_RANDOM )
FILE* prg = NULL;

void rand_init() {
  if( NULL == ( prg = fopen( "/dev/urandom", "rb" ) ) ) {
    abort();
  }
}

void rand_fini() {
  fclose( prg );
}

void rand_bytes(           uint8_t* x, int n ) {
  if( n != fread( x, sizeof( uint8_t ), n, prg ) ) {
    abort();
  }
}
#else
void rand_init() {
  srand( 0 );
}

void rand_fini() {

}

void rand_bytes(           uint8_t* x, int n ) {
  for( int i = 0; i < n; i++ ) {
    x[ i ] = rand() & 0xFF;
  }
}
#endif

// ============================================================================
