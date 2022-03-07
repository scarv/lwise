/*
GIFT-128 implementation
Written by: Siang Meng Sim
Email: crypto.s.m.sim@gmail.com
Date: 08 Feb 2019
*/

#include <stdint.h>

#if !defined( LWISE )
void giftb128(uint8_t P[16], const uint8_t K[16], uint8_t C[16]);
#else 
#if   (GIFT_BITSLICING)
extern void giftb128_bitslicing(void *P, const void *K, void *C);
#define giftb128 giftb128_bitslicing
#elif (GIFT_FIXSLICING)
extern void giftb128_fixslicing(void *P, const void *K, void *C);
extern void precompute_rkeys(void* rkeys, const void* key);
#define giftb128 giftb128_fixslicing
#endif

#endif
