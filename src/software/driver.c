/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "driver.h"

#if !defined( DRIVER_TRIALS_WARM )
#define DRIVER_TRIALS_WARM   10
#endif
#if !defined( DRIVER_TRIALS_REAL )
#define DRIVER_TRIALS_REAL 1000
#endif

#if !defined( DRIVER_MEASURE )
#define measure_prologue(id)
#define measure_step(id,...) id( __VA_ARGS__ )
#define measure_epilogue(id)
#else
#if ( DRIVER_MEASURE == 0 ) // mode = average
#define measure_prologue(id)                                                           \
  uint32_t id ## _tsc_b =  0;                                                          \
  uint32_t id ## _tsc_a =  0;                                                          \
  uint32_t id ## _tsc_t =  0;
#define measure_step(id,...)                                                           \
  id ## _tsc_b = rdtsc();                                                              \
  id( __VA_ARGS__ );                                                                   \
  id ## _tsc_a = rdtsc();                                                              \
                                                                                       \
  if( i >= trials_warm ) {                                                             \
    id ## _tsc_t += ( id ## _tsc_a - id ## _tsc_b );                                   \
  }
#define measure_epilogue(id)                                                           \
  printf( "tsc (average): %s => %f\n", #id, ( float )( id ## _tsc_t ) / trials_real );
#endif
#if ( DRIVER_MEASURE == 1 ) // mode = minimum
#define measure_prologue(id)                                                           \
  uint32_t id ## _tsc_b =  0;                                                          \
  uint32_t id ## _tsc_a =  0;                                                          \
  uint32_t id ## _tsc_t = -1;
#define measure_step(id,...)                                                           \
  id ## _tsc_b = rdtsc();                                                              \
  id( __VA_ARGS__ );                                                                   \
  id ## _tsc_a = rdtsc();                                                              \
                                                                                       \
  if( i >= trials_warm ) {                                                             \
    id ## _tsc_t  = MIN( id ## _tsc_t, id ## _tsc_a - id ## _tsc_b );                  \
  }
#define measure_epilogue(id)                                                           \
    printf( "tsc (minimum): %s => %f\n", #id, ( float )( id ## _tsc_t )             );
#endif
#if ( DRIVER_MEASURE == 2 ) // mode = maximum
#define measure_prologue(id)                                                           \
  uint32_t id ## _tsc_b =  0;                                                          \
  uint32_t id ## _tsc_a =  0;                                                          \
  uint32_t id ## _tsc_t =  0;
#define measure_step(id,...)                                                           \
  id ## _tsc_b = rdtsc();                                                              \
  id( __VA_ARGS__ );                                                                   \
  id ## _tsc_a = rdtsc();                                                              \
                                                                                       \
  if( i >= trials_warm ) {                                                             \
    id ## _tsc_t  = MAX( id ## _tsc_t, id ## _tsc_a - id ## _tsc_b );                  \
  }
#define measure_epilogue(id)                                                           \
    printf( "tsc (maximum): %s => %f\n", #id, ( float )( id ## _tsc_t )             );
#endif
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

void test_craxs10( int trials_warm, int trials_real ) {
  uint32_t k[ 4 ];
  uint32_t m[ 2 ];
  uint32_t c[ 2 ];

  uint32_t r[ 2 ];

  measure_prologue( craxs10_enc );
  measure_prologue( craxs10_dec );

  for( int i = 0; i < ( trials_warm + trials_real ); i++ ) {
    bytes_rand( ( uint8_t* )( k ), 4 * sizeof( uint32_t ) );
    bytes_rand( ( uint8_t* )( m ), 2 * sizeof( uint32_t ) );

    memcpy( c, m, 2 * sizeof( uint32_t ) );
    measure_step( craxs10_enc, c, k );
    memcpy( r, c, 2 * sizeof( uint32_t ) );
    measure_step( craxs10_dec, r, k );

    if(  memcmp( r, m, 2 * sizeof( uint32_t ) ) ||  // if r != m, i.e., Dec( k, Enc( k, m ) ) != m
        !memcmp( c, m, 2 * sizeof( uint32_t ) ) ||  // or c == m, i.e.,         Enc( k, m )   == m, so Enc is acting as a NOP!
        !memcmp( r, c, 2 * sizeof( uint32_t ) ) ) { // or r == c, i.e.,         Dec( k, c )   == c, so Dec is acting as a NOP!
      printf( "failed craxs10 %d\n", i );

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

void test_traxl17( int trials_warm, int trials_real ) {
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
      printf( "failed traxl17 %d\n", i );

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

void test_sparkle( int trials_warm, int trials_real ) {
  uint32_t state_ini[ 2 * MAX_BRANCHES ] = { 0 };
  uint32_t state_fwd[ 2 * MAX_BRANCHES ] = { 0 };
  uint32_t state_rev[ 2 * MAX_BRANCHES ] = { 0 };

  int brans = 6;    // use SPARKLE384 7 steps
  int steps = 7;
 
  measure_prologue( sparkle_fwd );
  measure_prologue( sparkle_rev );

  for( int i = 0; i < ( trials_warm + trials_real ); i++ ) {
    bytes_rand( ( uint8_t* )( state_ini ), 2 * brans * sizeof( uint32_t ) );

    memcpy( state_fwd, state_ini, 2 * brans * sizeof( uint32_t ) );
    measure_step( sparkle_fwd, state_fwd, brans, steps );
    memcpy( state_rev, state_fwd, 2 * brans * sizeof( uint32_t ) );
    measure_step( sparkle_rev, state_rev, brans, steps );

    if(  memcmp( state_rev, state_ini, 2 * brans * sizeof( uint32_t ) ) ||  // if rev != ini , i.e., Rev( Fwd( ini ) ) != ini
        !memcmp( state_fwd, state_ini, 2 * brans * sizeof( uint32_t ) ) ||  // or fwd == ini, i.e.,       Fwd( ini )   == ini, so Fwd is acting as a NOP!
        !memcmp( state_rev, state_fwd, 2 * brans * sizeof( uint32_t ) ) ) { // or rev == fwd, i.e.,       Rev( fwd )   == fwd, so Rev is acting as a NOP!
      printf( "failed sparkle %d\n", i );

      bytes_dump( "state_ini", ( uint8_t* )( state_ini ), 2 * brans * sizeof( uint32_t ) );
      bytes_dump( "state_fwd", ( uint8_t* )( state_fwd ), 2 * brans * sizeof( uint32_t ) );
      bytes_dump( "state_rev", ( uint8_t* )( state_rev ), 2 * brans * sizeof( uint32_t ) );

      abort();
    }
  }

  measure_epilogue( sparkle_fwd );
  measure_epilogue( sparkle_rev );
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
  test_craxs10( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- testing craxs10\n" );

  printf( "++ testing traxl17\n" );
  test_traxl17( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- testing traxl17\n" );

  printf( "++ testing sparkle\n" );
  test_sparkle( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- testing sparkle\n" );

#if defined( DRIVER_RANDOM )
  fclose( prg );
#endif

  return 0;
}
