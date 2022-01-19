/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "driver.h"

// ============================================================================

void test_encrypt() {
  for( int i = 0; KAT[ i ].i >= 0; i++ ) {
    unsigned long long k_n = KAT[ i ].k_n; uint8_t k[ k_n ]; parse_bytes( k, KAT[ i ].k, KAT[ i ].k_n );
    unsigned long long n_n = KAT[ i ].n_n; uint8_t n[ n_n ]; parse_bytes( n, KAT[ i ].n, KAT[ i ].n_n );
    unsigned long long a_n = KAT[ i ].a_n; uint8_t a[ a_n ]; parse_bytes( a, KAT[ i ].a, KAT[ i ].a_n );
    unsigned long long m_n = KAT[ i ].m_n; uint8_t m[ m_n ]; parse_bytes( m, KAT[ i ].m, KAT[ i ].m_n );
    unsigned long long c_n = KAT[ i ].c_n; uint8_t c[ c_n ]; parse_bytes( c, KAT[ i ].c, KAT[ i ].c_n );

    unsigned long long t_n;                uint8_t t[ m_n + CRYPTO_ABYTES ];

    if( ( 0 != crypto_aead_encrypt( t, &t_n, m, m_n, a, a_n, NULL, n, k ) ) || ( t_n != c_n ) || memcmp( t, c, c_n * sizeof( uint8_t ) ) ) {
      printf( "!! failed encrypt KAT %ld\n", KAT[ i ].i );

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

void test_decrypt() {
  for( int i = 0; KAT[ i ].i >= 0; i++ ) {
    unsigned long long k_n = KAT[ i ].k_n; uint8_t k[ k_n ]; parse_bytes( k, KAT[ i ].k, KAT[ i ].k_n );
    unsigned long long n_n = KAT[ i ].n_n; uint8_t n[ n_n ]; parse_bytes( n, KAT[ i ].n, KAT[ i ].n_n );
    unsigned long long a_n = KAT[ i ].a_n; uint8_t a[ a_n ]; parse_bytes( a, KAT[ i ].a, KAT[ i ].a_n );
    unsigned long long m_n = KAT[ i ].m_n; uint8_t m[ m_n ]; parse_bytes( m, KAT[ i ].m, KAT[ i ].m_n );
    unsigned long long c_n = KAT[ i ].c_n; uint8_t c[ c_n ]; parse_bytes( c, KAT[ i ].c, KAT[ i ].c_n );

    unsigned long long t_n;                uint8_t t[ c_n                 ];

    if( ( 0 != crypto_aead_decrypt( t, &t_n, NULL, c, c_n, a, a_n, n, k ) ) || ( t_n != m_n ) || memcmp( t, m, m_n * sizeof( uint8_t ) ) ) {
      printf( "!! failed decrypt KAT %ld\n", KAT[ i ].i );

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

// ----------------------------------------------------------------------------

void time_encrypt() {

}

void time_decrypt() {

}

// ----------------------------------------------------------------------------

int main( int argc, char* argv[] ) {
  printf( "++ [ALG=%s, ARCH=%s, IMP=%s] test : encrypt\n", ALG, ARCH, IMP );
  test_encrypt();
  printf( "-- [ALG=%s, ARCH=%s, IMP=%s] test : encrypt\n", ALG, ARCH, IMP );

  printf( "++ [ALG=%s, ARCH=%s, IMP=%s] test : decrypt\n", ALG, ARCH, IMP );
  test_decrypt();
  printf( "-- [ALG=%s, ARCH=%s, IMP=%s] test : decrypt\n", ALG, ARCH, IMP );

  printf( "++ [ALG=%s, ARCH=%s, IMP=%s] time : encrypt\n", ALG, ARCH, IMP );
  time_encrypt();
  printf( "-- [ALG=%s, ARCH=%s, IMP=%s] time : encrypt\n", ALG, ARCH, IMP );

  printf( "++ [ALG=%s, ARCH=%s, IMP=%s] time : decrypt\n", ALG, ARCH, IMP );
  time_decrypt();
  printf( "-- [ALG=%s, ARCH=%s, IMP=%s] time : decrypt\n", ALG, ARCH, IMP );

  return 0;
}

// ============================================================================