/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#include "driver.h"

// #include <inttypes.h>

// ============================================================================

#if defined( DRIVER_TRIALS_KAT  )
void test_xoodoo_kat( int trials_warm, int trials_real ) {
  uint32_t a[ NLANES ];

  measure_prologue( Xoodoo_Permute_Nrounds );

  for( int i = 0; i < ( trials_warm + trials_real ); i++ ) {
    rand_bytes( ( uint8_t* )( a ), NLANES * sizeof( uint32_t ) );
    
    measure_step( Xoodoo_Permute_Nrounds, a, 12);
  }

  measure_epilogue( Xoodoo_Permute_Nrounds );
}
#endif

// ----------------------------------------------------------------------------

#if defined( DRIVER_TRIALS_BIST )
void test_xoodoo_bist( int trials_warm, int trials_real ) {
}
#endif

// ----------------------------------------------------------------------------

int main( int argc, char* argv[] ) {
  rand_init();

  #if defined( DRIVER_TRIALS_KAT  )
  printf( "++ KAT  : testing xoodoo\n" );
  test_xoodoo_kat ( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- KAT  : testing xoodoo\n" );
  #endif

  #if defined( DRIVER_TRIALS_BIST )
  printf( "++ BIST : testing xoodoo\n" );
  test_xoodoo_bist( DRIVER_TRIALS_WARM, DRIVER_TRIALS_REAL );
  printf( "-- BIST : testing xoodoo\n" );
  #endif

  rand_fini();

  return 0;
}

// void print_state(uint32_t * a) {
//   printf("a00 %08"
//     PRIx32 ", a01 %08"
//     PRIx32 ", a02 %08"
//     PRIx32 ", a03 %08"
//     PRIx32 "\n", a[0 + 0], a[0 + 1], a[0 + 2], a[0 + 3]);
//   printf("a10 %08"
//     PRIx32 ", a11 %08"
//     PRIx32 ", a12 %08"
//     PRIx32 ", a13 %08"
//     PRIx32 "\n", a[4 + 0], a[4 + 1], a[4 + 2], a[4 + 3]);
//   printf("a20 %08"
//     PRIx32 ", a21 %08"
//     PRIx32 ", a22 %08"
//     PRIx32 ", a23 %08"
//     PRIx32 "\n", a[8 + 0], a[8 + 1], a[8 + 2], a[8 + 3]);
// }

// int main(void) {
//   uint32_t a[12];
//   uint32_t ai;
//   int i;
  
//   ai = 0xc83fb728;
//   for (i = 0; i < 12; i++) {
//     a[i] = ai;
//     ai = ai - 0x12345678;
//   }

//   printf("\n------------------ ORIGINAL STATE ------------------\n");
//   print_state(a);

//   printf("\n-------------- 12-Round C Permutation --------------\n");
//   Xoodoo_Permute_Nrounds(a, 12);
//   print_state(a);
  
//   return 0;
// }