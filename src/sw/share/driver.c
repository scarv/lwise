/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "driver.h"

// ============================================================================

void parse_bytes( uint8_t* r, char* x, int n ) {
  char* p = x;

  for( int i = 0; i < n; i += 1, p += 2 ) {
    int t;

    if( sscanf( p, "%02X", &t ) != 1 ) {
      abort();
    }

    r[ i ] = ( uint8_t )( t );
  }
}

void dump_bytes( uint8_t* x, int n ) {
 printf( "%02X:", n );

  for( int i = ( n - 1 ); i >= 0; i-- ) {
    printf( "%02X", x[ i ] );
  }

  printf( "\n" );
}

#if defined( DRIVER_RANDOM )
FILE* rand_bytes_prg = NULL;

void rand_bytes_init() {
  if( NULL == ( rand_bytes_prg = fopen( "/dev/urandom", "rb" ) ) ) {
    abort();
  }
}

void rand_bytes_fini() {
  fclose( rand_bytes_prg );
}

void rand_bytes(           uint8_t* x, int n ) {
  if( n != fread( x, sizeof( uint8_t ), n, rand_bytes_prg ) ) {
    abort();
  }
}
#else
void rand_bytes_init() {
  srand( 0 );
}

void rand_bytes_fini() {

}

void rand_bytes(           uint8_t* x, int n ) {
  for( int i = 0; i < n; i++ ) {
    x[ i ] = rand() & 0xFF;
  }
}
#endif

// ============================================================================

#if defined( API_AEAD ) && !defined( DRIVER_BYPASS_TEST )
void test_encrypt() {
  for( int i = 0; KAT_AEAD[ i ].i >= 0; i++ ) {
    unsigned long long k_n = KAT_AEAD[ i ].k_n; uint8_t k[ k_n ]; parse_bytes( k, KAT_AEAD[ i ].k, KAT_AEAD[ i ].k_n );
    unsigned long long n_n = KAT_AEAD[ i ].n_n; uint8_t n[ n_n ]; parse_bytes( n, KAT_AEAD[ i ].n, KAT_AEAD[ i ].n_n );
    unsigned long long a_n = KAT_AEAD[ i ].a_n; uint8_t a[ a_n ]; parse_bytes( a, KAT_AEAD[ i ].a, KAT_AEAD[ i ].a_n );
    unsigned long long m_n = KAT_AEAD[ i ].m_n; uint8_t m[ m_n ]; parse_bytes( m, KAT_AEAD[ i ].m, KAT_AEAD[ i ].m_n );
    unsigned long long c_n = KAT_AEAD[ i ].c_n; uint8_t c[ c_n ]; parse_bytes( c, KAT_AEAD[ i ].c, KAT_AEAD[ i ].c_n );

    unsigned long long t_n;                     uint8_t t[ m_n + CRYPTO_ABYTES ];

    if( ( 0 != crypto_aead_encrypt( t, &t_n, m, m_n, a, a_n, NULL, n, k ) ) || ( t_n != c_n ) || memcmp( t, c, c_n * sizeof( uint8_t ) ) ) {
      printf( "!! failed " "encrypt" " KAT %ld\n", KAT_AEAD[ i ].i );

      dump_bytes( k, k_n );
      dump_bytes( n, n_n );
      dump_bytes( a, a_n );
      dump_bytes( m, m_n );
      dump_bytes( c, c_n );
      dump_bytes( t, t_n );

      abort();
    }
  }

  printf( "!! passed\n" );
}
#endif

#if defined( API_AEAD ) && !defined( DRIVER_BYPASS_TEST )
void test_decrypt() {
  for( int i = 0; KAT_AEAD[ i ].i >= 0; i++ ) {
    unsigned long long k_n = KAT_AEAD[ i ].k_n; uint8_t k[ k_n ]; parse_bytes( k, KAT_AEAD[ i ].k, KAT_AEAD[ i ].k_n );
    unsigned long long n_n = KAT_AEAD[ i ].n_n; uint8_t n[ n_n ]; parse_bytes( n, KAT_AEAD[ i ].n, KAT_AEAD[ i ].n_n );
    unsigned long long a_n = KAT_AEAD[ i ].a_n; uint8_t a[ a_n ]; parse_bytes( a, KAT_AEAD[ i ].a, KAT_AEAD[ i ].a_n );
    unsigned long long m_n = KAT_AEAD[ i ].m_n; uint8_t m[ m_n ]; parse_bytes( m, KAT_AEAD[ i ].m, KAT_AEAD[ i ].m_n );
    unsigned long long c_n = KAT_AEAD[ i ].c_n; uint8_t c[ c_n ]; parse_bytes( c, KAT_AEAD[ i ].c, KAT_AEAD[ i ].c_n );

    unsigned long long t_n;                     uint8_t t[ c_n                 ];

    if( ( 0 != crypto_aead_decrypt( t, &t_n, NULL, c, c_n, a, a_n, n, k ) ) || ( t_n != m_n ) || memcmp( t, m, m_n * sizeof( uint8_t ) ) ) {
      printf( "!! failed " "decrypt" " KAT %ld\n", KAT_AEAD[ i ].i );

      dump_bytes( k, k_n );
      dump_bytes( n, n_n );
      dump_bytes( a, a_n );
      dump_bytes( m, m_n );
      dump_bytes( c, c_n );
      dump_bytes( t, t_n );

      abort();
    }
  }

  printf( "!! passed\n" );
}
#endif

// ----------------------------------------------------------------------------

#if defined( API_HASH ) && !defined( DRIVER_BYPASS_TEST )
void test_hash() {
  for( int i = 0; KAT_HASH[ i ].i >= 0; i++ ) {
    unsigned long long m_n = KAT_HASH[ i ].m_n; uint8_t m[ m_n ]; parse_bytes( m, KAT_HASH[ i ].m, KAT_HASH[ i ].m_n );
    unsigned long long d_n = KAT_HASH[ i ].d_n; uint8_t d[ d_n ]; parse_bytes( d, KAT_HASH[ i ].d, KAT_HASH[ i ].d_n );

    unsigned long long t_n =               d_n; uint8_t t[ d_n                 ];

    if( ( 0 != crypto_hash( t, m, m_n ) ) || memcmp( t, d, d_n * sizeof( uint8_t ) ) ) {
      printf( "!! failed " "hash"    " KAT %ld\n", KAT_HASH[ i ].i );

      dump_bytes( m, m_n );
      dump_bytes( d, d_n );
      dump_bytes( t, t_n );

      abort();
    }
  }

  printf( "!! passed\n" );
}
#endif

// ----------------------------------------------------------------------------

#if defined( API_AEAD ) && !defined( DRIVER_BYPASS_TIME )
void time_encrypt() {
  unsigned long long k_n = DRIVER_SIZEOF_K; uint8_t k[ k_n ];
  unsigned long long n_n = DRIVER_SIZEOF_N; uint8_t n[ n_n ];
  unsigned long long a_n = DRIVER_SIZEOF_A; uint8_t a[ a_n ];
  unsigned long long m_n = DRIVER_SIZEOF_M; uint8_t m[ m_n ];
  unsigned long long c_n = DRIVER_SIZEOF_C; uint8_t c[ c_n ];

  int trials_warm = DRIVER_TRIALS_WARM;
  int trials_real = DRIVER_TRIALS_REAL;

  int trials      = trials_warm + trials_real;

  printf( "sizeof( k ) = %llu\n", k_n );
  printf( "sizeof( n ) = %llu\n", n_n );
  printf( "sizeof( a ) = %llu\n", a_n );
  printf( "sizeof( m ) = %llu\n", m_n );
  printf( "sizeof( c ) = %llu\n", c_n );

  MEASURE_PROLOGUE( crypto_aead_encrypt );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( k, k_n );
    rand_bytes( n, n_n );
    rand_bytes( a, a_n );
    rand_bytes( m, m_n );

    MEASURE_STEP( crypto_aead_encrypt, c, &c_n, m, m_n, a, a_n, NULL, n, k );
  }

  MEASURE_EPILOGUE( crypto_aead_encrypt );
}
#endif

#if defined( API_AEAD ) && !defined( DRIVER_BYPASS_TIME )
void time_decrypt() {
  unsigned long long k_n = DRIVER_SIZEOF_K; uint8_t k[ k_n ];
  unsigned long long n_n = DRIVER_SIZEOF_N; uint8_t n[ n_n ];
  unsigned long long a_n = DRIVER_SIZEOF_A; uint8_t a[ a_n ];
  unsigned long long m_n = DRIVER_SIZEOF_M; uint8_t m[ m_n ];
  unsigned long long c_n = DRIVER_SIZEOF_C; uint8_t c[ c_n ];

  int trials_warm = DRIVER_TRIALS_WARM;
  int trials_real = DRIVER_TRIALS_REAL;

  int trials      = trials_warm + trials_real;

  printf( "sizeof( k ) = %llu\n", k_n );
  printf( "sizeof( n ) = %llu\n", n_n );
  printf( "sizeof( a ) = %llu\n", a_n );
  printf( "sizeof( m ) = %llu\n", m_n );
  printf( "sizeof( c ) = %llu\n", c_n );

  MEASURE_PROLOGUE( crypto_aead_decrypt );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( k, k_n );
    rand_bytes( n, n_n );
    rand_bytes( a, a_n );
    rand_bytes( c, c_n );

    MEASURE_STEP( crypto_aead_decrypt, m, &m_n, NULL, c, c_n, a, a_n, n, k );
  }

  MEASURE_EPILOGUE( crypto_aead_decrypt );
}
#endif

// ----------------------------------------------------------------------------

#if defined( API_HASH ) && !defined( DRIVER_BYPASS_TIME )
void time_hash() {
  unsigned long long d_n = DRIVER_SIZEOF_D; uint8_t d[ d_n ];
  unsigned long long m_n = DRIVER_SIZEOF_M; uint8_t m[ m_n ];

  int trials_warm = DRIVER_TRIALS_WARM;
  int trials_real = DRIVER_TRIALS_REAL;

  int trials      = trials_warm + trials_real;

  printf( "sizeof( d ) = %llu\n", d_n );
  printf( "sizeof( m ) = %llu\n", m_n );

  MEASURE_PROLOGUE( crypto_hash );

  for( int i = 0; i < trials; i++ ) {
    rand_bytes( m, m_n );

    MEASURE_STEP( crypto_hash, d, m, m_n );
  }

  MEASURE_EPILOGUE( crypto_hash );
}
#endif

// ----------------------------------------------------------------------------

int main( int argc, char* argv[] ) {
  rand_bytes_init();

  #if defined( API_AEAD ) && !defined( DRIVER_BYPASS_TEST )
  printf( "++ test : encrypt" "\n" );
  test_encrypt();
  printf( "-- test : encrypt" "\n" );

  printf( "++ test : decrypt" "\n" );
  test_decrypt();
  printf( "-- test : decrypt" "\n" );
  #endif

  #if defined( API_HASH ) && !defined( DRIVER_BYPASS_TEST )
  printf( "++ test : hash"    "\n" );
  test_hash();
  printf( "-- test : hash"    "\n" );
  #endif

  #if defined( API_AEAD ) && !defined( DRIVER_BYPASS_TIME )
  printf( "++ time : encrypt" "\n" );
  time_encrypt();
  printf( "-- time : encrypt" "\n" );

  printf( "++ time : decrypt" "\n" );
  time_decrypt();
  printf( "-- time : decrypt" "\n" );

  printf( "++ time : kernel"  "\n" );
  time_kernel();
  printf( "-- time : kernel"  "\n" );
  #endif

  #if defined( API_HASH ) && !defined( DRIVER_BYPASS_TIME )
  printf( "++ time : hash"    "\n" );
  time_hash();
  printf( "-- time : hash"    "\n" );
  #endif

  rand_bytes_fini();

  return 0;
}

// ============================================================================
