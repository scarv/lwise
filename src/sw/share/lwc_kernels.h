/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __LWC_KERNELS_H
#define __LWC_KERNELS_H
void time_kernel();

extern void P6(void * state);
extern void P12(void * state);

extern void giftb128_bitslicing(void *P, const void *K, void *C);
extern void giftb128_fixslicing(void *P, const void *K, void *C);

extern void PHOTON_Permutation(void *state);
extern void skinny_128_384_plus_enc (void * input, void* userkey);

#define SPARKLE_STATE 384
extern void sparkle_opt( void* state, int brans, int steps );
//extern void sparkle_inv_opt( void* state, int brans, int steps ); not used

extern void Xoodoo_Permute_12rounds( void * state);

#endif
