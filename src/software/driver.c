/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "driver.h"

#if !defined( DRIVER_MEASURE )
#define measure_prologue(id)
#define measure_step(id,...) id( __VA_ARGS__ )
#define measure_epilogue(id)
#endif

#if  defined( DRIVER_RANDOM  )
FILE* prg = NULL;

void bytes_rand(           uint8_t* x, int n ) {
  if( n != fread( x, sizeof( uint8_t ), n, prg ) ) {
    abort();
  }
}
#else
void bytes_rand(           uint8_t* x, int n ) {
  for( int i = 0; i < n; i++ ) {
    x[ i ] = rand() & 0xFF;
  }
}
#endif

void bytes_dump( char* id, uint8_t* x, int n ) {
  printf( "%s = ", id );

  for( int i = ( n - 1 ); i >= 0; i-- ) {
    printf( "%02X", x[ i ] );
  }

  printf( "\n" );
}

void test_craxs10( int n ) {
  uint32_t k[ 4 ];
  uint32_t m[ 2 ];
  uint32_t c[ 2 ];

  uint32_t r[ 2 ];

  measure_prologue( craxs10_enc );
  measure_prologue( craxs10_dec );

  for( int i = 0; i < n; i++ ) {
    bytes_rand( ( uint8_t* )( k ), 4 * sizeof( uint32_t ) );
    bytes_rand( ( uint8_t* )( m ), 2 * sizeof( uint32_t ) );

    memcpy( c, m, 2 * sizeof( uint32_t ) );
    measure_step( craxs10_enc, c, k );
    memcpy( r, c, 2 * sizeof( uint32_t ) );
    measure_step( craxs10_dec, r, k );

    if(  memcmp( r, m, 2 * sizeof( uint32_t ) ) ||  // if r != m, i.e., Dec( k, Enc( k, m ) ) != m
        !memcmp( c, m, 2 * sizeof( uint32_t ) ) ||  // or c == m, i.e.,         Enc( k, m )   == m, so Enc is acting as a NOP!
        !memcmp( r, c, 2 * sizeof( uint32_t ) ) ) { // or r == c, i.e.,         Dec( k, c )   == c, so Dec is acting as a NOP!
      printf( "failed craxs10 %d/%d\n", i, n );

      bytes_dump( "k", ( uint8_t* )( k ), 4 * sizeof( uint32_t ) );
      bytes_dump( "m", ( uint8_t* )( m ), 2 * sizeof( uint32_t ) );
      bytes_dump( "c", ( uint8_t* )( c ), 2 * sizeof( uint32_t ) );

      bytes_dump( "r", ( uint8_t* )( r ), 2 * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( craxs10_enc );
  measure_epilogue( craxs10_dec );
}

void test_traxl17( int n ) {
  uint32_t  k[ 8 ];
  uint32_t tk[ 4 ];
  uint32_t mx[ 4 ];
  uint32_t my[ 4 ];
  uint32_t cx[ 4 ];
  uint32_t cy[ 4 ];

  uint32_t rx[ 4 ];
  uint32_t ry[ 4 ];

  uint32_t sk[ 18 * 8 ];

  measure_prologue( traxl17_enc );
  measure_prologue( traxl17_dec );

  for( int i = 0; i < n; i++ ) {
    bytes_rand( ( uint8_t* )(  k ), 8 * sizeof( uint32_t ) );
    bytes_rand( ( uint8_t* )( tk ), 4 * sizeof( uint32_t ) );
    bytes_rand( ( uint8_t* )( mx ), 4 * sizeof( uint32_t ) );
    bytes_rand( ( uint8_t* )( my ), 4 * sizeof( uint32_t ) );

    traxl17_genkeys( sk, k );

    memcpy( cx, mx, 4 * sizeof( uint32_t ) );
    memcpy( cy, my, 4 * sizeof( uint32_t ) );
    measure_step( traxl17_enc, cx, cy, sk, tk );
    memcpy( rx, cx, 4 * sizeof( uint32_t ) );
    memcpy( ry, cy, 4 * sizeof( uint32_t ) );
    measure_step( traxl17_dec, rx, ry, sk, tk );

    if(  memcmp( rx, mx, 4 * sizeof( uint32_t ) ) ||  // if r != m, i.e., Dec( k, Enc( k, m ) ) != m
        !memcmp( cx, mx, 4 * sizeof( uint32_t ) ) ||  // or c == m, i.e.,         Enc( k, m )   == m, so Enc is acting as a NOP!
        !memcmp( rx, cx, 4 * sizeof( uint32_t ) ) ) { // or r == c, i.e.,         Dec( k, c )   == c, so Dec is acting as a NOP!
      printf( "failed traxl17 %d/%d\n", i, n );

      bytes_dump( " k", ( uint8_t* )( k  ), 8 * sizeof( uint32_t ) );
      bytes_dump( "tk", ( uint8_t* )( tk ), 4 * sizeof( uint32_t ) );
      bytes_dump( "mx", ( uint8_t* )( mx ), 4 * sizeof( uint32_t ) );
      bytes_dump( "my", ( uint8_t* )( my ), 4 * sizeof( uint32_t ) );
      bytes_dump( "cx", ( uint8_t* )( cx ), 4 * sizeof( uint32_t ) );
      bytes_dump( "cy", ( uint8_t* )( cy ), 4 * sizeof( uint32_t ) );

      bytes_dump( "rx", ( uint8_t* )( rx ), 4 * sizeof( uint32_t ) );
      bytes_dump( "ry", ( uint8_t* )( ry ), 4 * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( traxl17_enc );
  measure_epilogue( traxl17_dec );
}

void test_sparkle( int n ) {
  uint32_t state_ini [ 2 * MAX_BRANCHES ] = { 0 };
  uint32_t state_fwd [ 2 * MAX_BRANCHES ] = { 0 };
  uint32_t state_inv [ 2 * MAX_BRANCHES ] = { 0 };

  int brans = 6;    // use SPARKLE384 7 steps
  int steps = 7;
 
  measure_prologue( sparkle_fwd );
  measure_prologue( sparkle_inv );

  for( int i = 0; i < n; i++ ) {
    bytes_rand( ( uint8_t* )( state_ini ), 2 * brans * sizeof( uint32_t ) );

    memcpy( state_fwd, state_ini, 2 * brans * sizeof( uint32_t ) );
    measure_step( sparkle_fwd, state_fwd, brans, steps );
    memcpy( state_inv, state_fwd, 2 * brans * sizeof( uint32_t ) );
    measure_step( sparkle_inv, state_inv, brans, steps );

    if(  memcmp( state_inv, state_ini, 2 * brans * sizeof( uint32_t ) ) ||  // if inv != ini , i.e., Inv( Fwd( ini ) ) != ini
        !memcmp( state_fwd, state_ini, 2 * brans * sizeof( uint32_t ) ) ||  // or fwd == ini, i.e.,       Fwd( ini )   == ini, so Fwd is acting as a NOP!
        !memcmp( state_inv, state_fwd, 2 * brans * sizeof( uint32_t ) ) ) { // or inv == fwd, i.e.,       Inv( fwd )   == fwd, so Inv is acting as a NOP!
      printf( "failed sparkle %d/%d\n", i, n );

      bytes_dump( "state_ini", ( uint8_t* )( state_ini ), 2 * brans * sizeof( uint32_t ) );
      bytes_dump( "state_fwd", ( uint8_t* )( state_fwd ), 2 * brans * sizeof( uint32_t ) );
      bytes_dump( "state_inv", ( uint8_t* )( state_inv ), 2 * brans * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( sparkle_fwd );
  measure_epilogue( sparkle_inv );
}

int main( int argc, char* argv[] ) {
#if defined( DRIVER_RANDOM )
  if( NULL == ( prg = fopen( "/dev/urandom", "rb" ) ) ) {
    abort();
  }
#else
  srand( ( argc == 2 ) ? atoi( argv[ 0 ] ) : 0 );
#endif

  printf( "++ testing craxs10\n" );
  test_craxs10( DRIVER_TRIALS );
  printf( "-- testing craxs10\n" );

  printf( "++ testing traxl17\n" );
  test_traxl17( DRIVER_TRIALS );
  printf( "-- testing traxl17\n" );

  printf( "++ testing sparkle\n" );
  test_sparkle( DRIVER_TRIALS );
  printf( "-- testing sparkle\n" );

#if defined( DRIVER_RANDOM )
  fclose( prg );
#endif

  return 0;
}
