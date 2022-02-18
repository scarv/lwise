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
extern void giftb128(void *P, const void *K, void *C);
#endif
