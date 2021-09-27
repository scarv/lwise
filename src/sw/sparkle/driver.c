/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "driver.h"

#if defined( DRIVER_TRIALS_KAT  )
void test_craxs10_kat ( int trials_warm, int trials_real ) {

}
#endif

#if defined( DRIVER_TRIALS_BIST )
void test_craxs10_bist( int trials_warm, int trials_real ) {
  uint32_t k[ 4 ];
  uint32_t m[ 2 ];
  uint32_t c[ 2 ];

  uint32_t r[ 2 ];

  measure_prologue( craxs10_enc );
  measure_prologue( craxs10_dec );

  for( int i = 0; i < ( trials_warm + trials_real ); i++ ) {
    rand_bytes( ( uint8_t* )( k ), 4 * sizeof( uint32_t ) );
    rand_bytes( ( uint8_t* )( m ), 2 * sizeof( uint32_t ) );

    memcpy( c, m, 2 * sizeof( uint32_t ) );
    measure_step( craxs10_enc, c, k );
    memcpy( r, c, 2 * sizeof( uint32_t ) );
    measure_step( craxs10_dec, r, k );

    if(  memcmp( r, m, 2 * sizeof( uint32_t ) ) ||  // if r != m, i.e., Dec( k, Enc( k, m ) ) != m
        !memcmp( c, m, 2 * sizeof( uint32_t ) ) ||  // or c == m, i.e.,         Enc( k, m )   == m, so Enc is acting as a NOP!
        !memcmp( r, c, 2 * sizeof( uint32_t ) ) ) { // or r == c, i.e.,         Dec( k, c )   == c, so Dec is acting as a NOP!
      printf( "failed craxs10 %d\n", i );

      dump_bytes( "k", ( uint8_t* )( k ), 4 * sizeof( uint32_t ) );
      dump_bytes( "m", ( uint8_t* )( m ), 2 * sizeof( uint32_t ) );
      dump_bytes( "c", ( uint8_t* )( c ), 2 * sizeof( uint32_t ) );

      dump_bytes( "r", ( uint8_t* )( r ), 2 * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( craxs10_enc );
  measure_epilogue( craxs10_dec );
}
#endif
/*
#if defined( DRIVER_TRIALS_KAT  )
void test_traxl17_kat ( int trials_warm, int trials_real ) {

}
#endif

#if defined( DRIVER_TRIALS_BIST )
void test_traxl17_bist( int trials_warm, int trials_real ) {
  #if defined( DRIVER_TRIALS_KAT  )

  #endif

  #if defined( DRIVER_TRIALS_BIST )
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

  for( int i = 0; i < ( trials_warm + trials_real ); i++ ) {
    rand_bytes( ( uint8_t* )(  k ), 8 * sizeof( uint32_t ) );
    rand_bytes( ( uint8_t* )( tk ), 4 * sizeof( uint32_t ) );
    rand_bytes( ( uint8_t* )( mx ), 4 * sizeof( uint32_t ) );
    rand_bytes( ( uint8_t* )( my ), 4 * sizeof( uint32_t ) );

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
      printf( "failed traxl17 %d\n", i );

      dump_bytes( " k", ( uint8_t* )( k  ), 8 * sizeof( uint32_t ) );
      dump_bytes( "tk", ( uint8_t* )( tk ), 4 * sizeof( uint32_t ) );
      dump_bytes( "mx", ( uint8_t* )( mx ), 4 * sizeof( uint32_t ) );
      dump_bytes( "my", ( uint8_t* )( my ), 4 * sizeof( uint32_t ) );
      dump_bytes( "cx", ( uint8_t* )( cx ), 4 * sizeof( uint32_t ) );
      dump_bytes( "cy", ( uint8_t* )( cy ), 4 * sizeof( uint32_t ) );

      dump_bytes( "rx", ( uint8_t* )( rx ), 4 * sizeof( uint32_t ) );
      dump_bytes( "ry", ( uint8_t* )( ry ), 4 * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( traxl17_enc );
  measure_epilogue( traxl17_dec );
  #endif
}

#if defined( DRIVER_TRIALS_KAT  )
void test_sparkle_kat ( int trials_warm, int trials_real ) {

}
#endif

#if defined( DRIVER_TRIALS_BIST )
void test_sparkle_bist( int trials_warm, int trials_real ) {
  #if defined( DRIVER_TRIALS_KAT  )

  #endif

  #if defined( DRIVER_TRIALS_BIST )
  uint32_t state_ini[ 2 * SPARKLE_BRANS ] = { 0 };
  uint32_t state_fwd[ 2 * SPARKLE_BRANS ] = { 0 };
  uint32_t state_rev[ 2 * SPARKLE_BRANS ] = { 0 };

  int brans = 6;    // use SPARKLE384 7 steps
  int steps = 7;
 
  measure_prologue( sparkle_fwd );
  measure_prologue( sparkle_rev );

  for( int i = 0; i < ( trials_warm + trials_real ); i++ ) {
    rand_bytes( ( uint8_t* )( state_ini ), 2 * brans * sizeof( uint32_t ) );

    memcpy( state_fwd, state_ini, 2 * brans * sizeof( uint32_t ) );
    measure_step( sparkle_fwd, state_fwd, brans, steps );
    memcpy( state_rev, state_fwd, 2 * brans * sizeof( uint32_t ) );
    measure_step( sparkle_rev, state_rev, brans, steps );

    if(  memcmp( state_rev, state_ini, 2 * brans * sizeof( uint32_t ) ) ||  // if rev != ini , i.e., Rev( Fwd( ini ) ) != ini
        !memcmp( state_fwd, state_ini, 2 * brans * sizeof( uint32_t ) ) ||  // or fwd == ini, i.e.,       Fwd( ini )   == ini, so Fwd is acting as a NOP!
        !memcmp( state_rev, state_fwd, 2 * brans * sizeof( uint32_t ) ) ) { // or rev == fwd, i.e.,       Rev( fwd )   == fwd, so Rev is acting as a NOP!
      printf( "failed sparkle %d\n", i );

      dump_bytes( "state_ini", ( uint8_t* )( state_ini ), 2 * brans * sizeof( uint32_t ) );
      dump_bytes( "state_fwd", ( uint8_t* )( state_fwd ), 2 * brans * sizeof( uint32_t ) );
      dump_bytes( "state_rev", ( uint8_t* )( state_rev ), 2 * brans * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( sparkle_fwd );
  measure_epilogue( sparkle_rev );
  #endif
}
*/
int main( int argc, char* argv[] ) {
  rand_init();

  #if defined( DRIVER_TRIALS_KAT  )
  printf( "++ KAT  : testing craxs10\n" );
  test_craxs10_kat ( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- KAT  : testing craxs10\n" );

  printf( "++ KAT  : testing traxl17\n" );
//test_traxl17_kat ( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- KAT  : testing traxl17\n" );

  printf( "++ KAT  : testing sparkle\n" );
//test_sparkle_kat ( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- KAT  : testing sparkle\n" );
  #endif

  #if defined( DRIVER_TRIALS_BIST )
  printf( "++ BIST : testing craxs10\n" );
  test_craxs10_bist( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- BIST : testing craxs10\n" );

  printf( "++ BIST : testing traxl17\n" );
//test_traxl17_bist( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- BIST : testing traxl17\n" );

  printf( "++ BIST : testing sparkle\n" );
//test_sparkle_bist( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- BIST : testing sparkle\n" );
  #endif

  rand_fini();

  return 0;
}
