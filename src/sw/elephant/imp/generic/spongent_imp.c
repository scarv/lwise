#include <string.h>
#include <stdint.h>
#include "spongent_imp.h"

#define BCP(x, bit) ((x) & (((uint32_t)1) << (bit)))
#define BUP(x, from, to) (((x) << ((to) - (from))) & (((uint32_t)1) << (to)))
#define BDN(x, from, to) (((x) >> ((from) - (to))) & (((uint32_t)1) << (to)))

// Round constants for Spongent-pi[160]

static const uint8_t RC[] = {
  0x75, 0xae, 0x6a, 0x56, 0x54, 0x2a, 0x29, 0x94,
  0x53, 0xca, 0x27, 0xe4, 0x4f, 0xf2, 0x1f, 0xf8,
  0x3e, 0x7c, 0x7d, 0xbe, 0x7a, 0x5e, 0x74, 0x2e,
  0x68, 0x16, 0x50, 0x0a, 0x21, 0x84, 0x43, 0xc2,
  0x07, 0xe0, 0x0e, 0x70, 0x1c, 0x38, 0x38, 0x1c,
  0x71, 0x8e, 0x62, 0x46, 0x44, 0x22, 0x09, 0x90,
  0x12, 0x48, 0x24, 0x24, 0x49, 0x92, 0x13, 0xc8,
  0x26, 0x64, 0x4d, 0xb2, 0x1b, 0xd8, 0x36, 0x6c,
  0x6d, 0xb6, 0x5a, 0x5a, 0x35, 0xac, 0x6b, 0xd6,
  0x56, 0x6a, 0x2d, 0xb4, 0x5b, 0xda, 0x37, 0xec,
  0x6f, 0xf6, 0x5e, 0x7a, 0x3d, 0xbc, 0x7b, 0xde,
  0x76, 0x6e, 0x6c, 0x36, 0x58, 0x1a, 0x31, 0x8c,
  0x63, 0xc6, 0x46, 0x62, 0x0d, 0xb0, 0x1a, 0x58,
  0x34, 0x2c, 0x69, 0x96, 0x52, 0x4a, 0x25, 0xa4,
  0x4b, 0xd2, 0x17, 0xe8, 0x2e, 0x74, 0x5d, 0xba,
  0x3b, 0xdc, 0x77, 0xee, 0x6e, 0x76, 0x5c, 0x3a,
  0x39, 0x9c, 0x73, 0xce, 0x66, 0x66, 0x4c, 0x32,
  0x19, 0x98, 0x32, 0x4c, 0x65, 0xa6, 0x4a, 0x52,
  0x15, 0xa8, 0x2a, 0x54, 0x55, 0xaa, 0x2b, 0xd4,
  0x57, 0xea, 0x2f, 0xf4, 0x5f, 0xfa, 0x3f, 0xfc,
};

void Spongent_160(BYTE *state)
{
  const uint8_t *rc = RC;
  uint32_t s[8] = { 0 }, t[8], u[4];
  int i;

  // Convert the state to 40-bit limbs 
  // The state is in four 40-bit limbs (each limb composed of two uint32_t words). 

  memcpy(&s[0], state,    5);
  memcpy(&s[2], state+5,  5);
  memcpy(&s[4], state+10, 5);
  memcpy(&s[6], state+15, 5);

  for (i = 0; i < 80; i++, rc += 2) {

    // add round constants

    s[0] ^= rc[0];
    s[7] ^= rc[1];

    // We perform first the pLayer then a new bitsliced sBoxLayer, but this 
    // doesn't affect the correctness. 

    // pLayer

    t[0] =  BCP(s[0],  0)     ^ BDN(s[0],  4,  1) ^ BDN(s[0],  8,  2) ^
            BDN(s[0], 12,  3) ^ BDN(s[0], 16,  4) ^ BDN(s[0], 20,  5) ^
            BDN(s[0], 24,  6) ^ BDN(s[0], 28,  7) ^ BUP(s[1],  0,  8) ^
            BUP(s[1],  4,  9) ^ BUP(s[2],  0, 10) ^ BUP(s[2],  4, 11) ^ 
            BUP(s[2],  8, 12) ^ BUP(s[2], 12, 13) ^ BDN(s[2], 16, 14) ^ 
            BDN(s[2], 20, 15) ^ BDN(s[2], 24, 16) ^ BDN(s[2], 28, 17) ^ 
            BUP(s[3],  0, 18) ^ BUP(s[3],  4, 19) ^ BUP(s[4],  0, 20) ^ 
            BUP(s[4],  4, 21) ^ BUP(s[4],  8, 22) ^ BUP(s[4], 12, 23) ^ 
            BUP(s[4], 16, 24) ^ BUP(s[4], 20, 25) ^ BUP(s[4], 24, 26) ^
            BDN(s[4], 28, 27) ^ BUP(s[5],  0, 28) ^ BUP(s[5],  4, 29) ^
            BUP(s[6],  0, 30) ^ BUP(s[6],  4, 31);
    t[1] =  BDN(s[6],  8,  0) ^ BDN(s[6], 12,  1) ^ BDN(s[6], 16,  2) ^
            BDN(s[6], 20,  3) ^ BDN(s[6], 24,  4) ^ BDN(s[6], 28,  5) ^
            BUP(s[7],  0,  6) ^ BUP(s[7],  4,  7);

    t[2] =  BDN(s[0],  1,  0) ^ BDN(s[0],  5,  1) ^ BDN(s[0],  9,  2) ^
            BDN(s[0], 13,  3) ^ BDN(s[0], 17,  4) ^ BDN(s[0], 21,  5) ^
            BDN(s[0], 25,  6) ^ BDN(s[0], 29,  7) ^ BUP(s[1],  1,  8) ^
            BUP(s[1],  5,  9) ^ BUP(s[2],  1, 10) ^ BUP(s[2],  5, 11) ^ 
            BUP(s[2],  9, 12) ^ BCP(s[2], 13)     ^ BDN(s[2], 17, 14) ^ 
            BDN(s[2], 21, 15) ^ BDN(s[2], 25, 16) ^ BDN(s[2], 29, 17) ^ 
            BUP(s[3],  1, 18) ^ BUP(s[3],  5, 19) ^ BUP(s[4],  1, 20) ^ 
            BUP(s[4],  5, 21) ^ BUP(s[4],  9, 22) ^ BUP(s[4], 13, 23) ^ 
            BUP(s[4], 17, 24) ^ BUP(s[4], 21, 25) ^ BUP(s[4], 25, 26) ^
            BDN(s[4], 29, 27) ^ BUP(s[5],  1, 28) ^ BUP(s[5],  5, 29) ^
            BUP(s[6],  1, 30) ^ BUP(s[6],  5, 31);
    t[3] =  BDN(s[6],  9,  0) ^ BDN(s[6], 13,  1) ^ BDN(s[6], 17,  2) ^
            BDN(s[6], 21,  3) ^ BDN(s[6], 25,  4) ^ BDN(s[6], 29,  5) ^
            BUP(s[7],  1,  6) ^ BUP(s[7],  5,  7);

    t[4] =  BDN(s[0],  2,  0) ^ BDN(s[0],  6,  1) ^ BDN(s[0], 10,  2) ^
            BDN(s[0], 14,  3) ^ BDN(s[0], 18,  4) ^ BDN(s[0], 22,  5) ^
            BDN(s[0], 26,  6) ^ BDN(s[0], 30,  7) ^ BUP(s[1],  2,  8) ^
            BUP(s[1],  6,  9) ^ BUP(s[2],  2, 10) ^ BUP(s[2],  6, 11) ^ 
            BUP(s[2], 10, 12) ^ BDN(s[2], 14, 13) ^ BDN(s[2], 18, 14) ^ 
            BDN(s[2], 22, 15) ^ BDN(s[2], 26, 16) ^ BDN(s[2], 30, 17) ^ 
            BUP(s[3],  2, 18) ^ BUP(s[3],  6, 19) ^ BUP(s[4],  2, 20) ^ 
            BUP(s[4],  6, 21) ^ BUP(s[4], 10, 22) ^ BUP(s[4], 14, 23) ^ 
            BUP(s[4], 18, 24) ^ BUP(s[4], 22, 25) ^ BCP(s[4], 26)     ^
            BDN(s[4], 30, 27) ^ BUP(s[5],  2, 28) ^ BUP(s[5],  6, 29) ^
            BUP(s[6],  2, 30) ^ BUP(s[6],  6, 31);
    t[5] =  BDN(s[6], 10,  0) ^ BDN(s[6], 14,  1) ^ BDN(s[6], 18,  2) ^
            BDN(s[6], 22,  3) ^ BDN(s[6], 26,  4) ^ BDN(s[6], 30,  5) ^
            BUP(s[7],  2,  6) ^ BUP(s[7],  6,  7);

    t[6] =  BDN(s[0],  3,  0) ^ BDN(s[0],  7,  1) ^ BDN(s[0], 11,  2) ^
            BDN(s[0], 15,  3) ^ BDN(s[0], 19,  4) ^ BDN(s[0], 23,  5) ^
            BDN(s[0], 27,  6) ^ BDN(s[0], 31,  7) ^ BUP(s[1],  3,  8) ^
            BUP(s[1],  7,  9) ^ BUP(s[2],  3, 10) ^ BUP(s[2],  7, 11) ^ 
            BUP(s[2], 11, 12) ^ BDN(s[2], 15, 13) ^ BDN(s[2], 19, 14) ^ 
            BDN(s[2], 23, 15) ^ BDN(s[2], 27, 16) ^ BDN(s[2], 31, 17) ^ 
            BUP(s[3],  3, 18) ^ BUP(s[3],  7, 19) ^ BUP(s[4],  3, 20) ^ 
            BUP(s[4],  7, 21) ^ BUP(s[4], 11, 22) ^ BUP(s[4], 15, 23) ^ 
            BUP(s[4], 19, 24) ^ BUP(s[4], 23, 25) ^ BDN(s[4], 27, 26) ^
            BDN(s[4], 31, 27) ^ BUP(s[5],  3, 28) ^ BUP(s[5],  7, 29) ^
            BUP(s[6],  3, 30) ^ BUP(s[6],  7, 31);
    t[7] =  BDN(s[6], 11,  0) ^ BDN(s[6], 15,  1) ^ BDN(s[6], 19,  2) ^
            BDN(s[6], 23,  3) ^ BDN(s[6], 27,  4) ^ BDN(s[6], 31,  5) ^
            BUP(s[7],  3,  6) ^ BCP(s[7],  7);

    // sBoxLayer
    // works on the 40-bit limbs.  
    // The formulas for the SBox: 
    // y0 = x0 + x1 + x3 + x1x2 
    // y1 = x0 + x0x3 + x1x2 + x1x3 + x2x3 + x1x2x3 + 1
    // y2 = x1 + x2 + x0x3 + x1x2x3 + 1
    // y3 = x2 + x3 + x0x1 + x0x3 + x1x3 + x0x1x3 + x0x2x3 + 1

    u[0] = t[0] ^ (t[2]&t[4]);
    u[1] = t[1] ^ (t[3]&t[5]);

    u[2] = (t[0]&t[6]) ^ (t[2]&t[4]&t[6]);
    u[3] = (t[1]&t[7]) ^ (t[3]&t[5]&t[7]);

    s[0] = t[2] ^ t[6] ^ u[0];
    s[1] = t[3] ^ t[7] ^ u[1];

    s[2] = ~((t[2]&t[6]) ^ (t[4]&t[6]) ^ u[0] ^ u[2]);
    s[3] = ~((t[3]&t[7]) ^ (t[5]&t[7]) ^ u[1] ^ u[3]);
    
    s[4] = ~(t[2] ^ t[4] ^ u[2]);
    s[5] = ~(t[3] ^ t[5] ^ u[3]);

    s[6] = ~(t[4] ^ t[6] ^ (t[0]&t[2]) ^ (t[0]&t[6]) ^ (t[2]&t[6]) ^ (t[0]&t[2]&t[6]) ^ (t[0]&t[4]&t[6]));
    s[7] = ~(t[5] ^ t[7] ^ (t[1]&t[3]) ^ (t[1]&t[7]) ^ (t[3]&t[7]) ^ (t[1]&t[3]&t[7]) ^ (t[1]&t[5]&t[7]));
  }

  memcpy(state,     s,    5);
  memcpy(state+5,  &s[2], 5);
  memcpy(state+10, &s[4], 5);
  memcpy(state+15, &s[6], 5);
}
