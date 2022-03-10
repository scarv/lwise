// This implementation reuses some code from: 
// https://github.com/rweather/lightweight-crypto/blob/master/src/individual/Elephant/internal-spongent.c

// The current code in this file is efficient for rv32 only, and it needs some 
// further modifications for rv64. 

#include <string.h>
#include <stdint.h>
#include "spongent_imp.h"

#define BCP(x, bit) ((x) & (((uint32_t)1) << (bit)))
#define BUP(x, from, to) (((x) << ((to) - (from))) & (((uint32_t)1) << (to)))

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

#define SWAPMOVE32(x, m, n) { \
  uint32_t z = x ^ (x>>n);    \
  z = z & m;                  \
  z = z ^ (z<<n);             \
  x = z ^ x;                  \
}

// permute the 32-bit word bit[31:0] to 
// bit[31:24]  28 24 20 16 12  8  4  0 
// bit[23:16]  29 25 21 17 13  9  5  1 
// bit[15: 8]  30 26 22 18 14 10  6  2 
// bit[ 7: 0]  31 27 23 19 15 11  7  3 

#define pLayer_STEP1(x)     {      \
  SWAPMOVE32(x, 0x0A0A0A0AUL,  3); \
  SWAPMOVE32(x, 0x00CC00CCUL,  6); \
  SWAPMOVE32(x, 0x0000F0F0UL, 12); \
  SWAPMOVE32(x, 0x000000FFUL, 24); \
}

// -----------------------------------------------------------------------------

// 4x40b: AddRC(table) + pLayer(swapmove) + sBoxLayer(bitsliced)

void Spongent160_4x40b(void *state)
{
  const uint8_t *rc = RC;
  uint32_t s[8] = { 0 }, t[8], u[4];
  int i;

  // The state is in four 40-bit slices (each slice is composed of two uint32_t words). 
  // s1 | s0:  39  38  ...  33  32 |  31  30  ...   1   0
  // s3 | s2:  79  78  ...  73  72 |  71  70  ...  41  40
  // s5 | s4: 119 118  ... 113 112 | 111 110  ...  81  80
  // s7 | s6: 159 158  ... 153 152 | 151 150  ... 121 120

  memcpy(&s[0], state,    5);
  memcpy(&s[2], state+5,  5);
  memcpy(&s[4], state+10, 5);
  memcpy(&s[6], state+15, 5);

  for (i = 0; i < 80; i++, rc += 2) {

    // add round constants

    s[0] ^= rc[0];
    s[7] ^= rc[1];

    // Our implementation swaps the order of pLayer and sBoxLayer, i.e. we 
    // perform first the pLayer then a new bitsliced sBoxLayer. Because the 
    // pLayer actually permutes the current state to a form which is ideal for a 
    // bitsliced sBoxLayer. This swap doesn't affect the correctness and can 
    // reduce the number of performing SBox. 

    // pLayer     
    // 40 * index mod 159
    // permutes the state like this: 

    // s1 | s0:  39  38  ...  33  32 |  31  30  ... ...   1   0
    // s3 | s2:  79  78  ...  73  72 |  71  70  ... ...  41  40
    // s5 | s4: 119 118  ... 113 112 | 111 110  ... ...  81  80
    // s7 | s6: 159 158  ... 153 152 | 151 150  ... ... 121 120
    
    // from the above form to the below form
    
    // s1 | s0: 156 152  ... 132 128 | 124 120  ... ...   4   0
    // s3 | s2: 157 153  ... 133 129 | 125 121  ... ...   5   1
    // s5 | s4: 158 154  ... 134 130 | 126 122  ... ...   6   2
    // s7 | s6: 159 155  ... 135 131 | 127 123  ... ...   7   3

    // step 0
    t[0] =  BUP(s[1],  0,  8) ^ BUP(s[1],  4,  9) ^ BUP(s[3],  0, 18) ^ 
            BUP(s[3],  4, 19) ^ BUP(s[5],  0, 28) ^ BUP(s[5],  4, 29); 
    t[1] =  BUP(s[7],  0,  6) ^ BUP(s[7],  4,  7);

    t[2] =  BUP(s[1],  1,  8) ^ BUP(s[1],  5,  9) ^ BUP(s[3],  1, 18) ^ 
            BUP(s[3],  5, 19) ^ BUP(s[5],  1, 28) ^ BUP(s[5],  5, 29); 
    t[3] =  BUP(s[7],  1,  6) ^ BUP(s[7],  5,  7);  

    t[4] =  BUP(s[1],  2,  8) ^ BUP(s[1],  6,  9) ^ BUP(s[3],  2, 18) ^ 
            BUP(s[3],  6, 19) ^ BUP(s[5],  2, 28) ^ BUP(s[5],  6, 29); 
    t[5] =  BUP(s[7],  2,  6) ^ BUP(s[7],  6,  7);
    
    t[6] =  BUP(s[1],  3,  8) ^ BUP(s[1],  7,  9) ^ BUP(s[3],  3, 18) ^ 
            BUP(s[3],  7, 19) ^ BUP(s[5],  3, 28) ^ BUP(s[5],  7, 29); 
    t[7] =  BUP(s[7],  3,  6) ^ BCP(s[7],  7);

    // step 1
    pLayer_STEP1(s[0]); 
    pLayer_STEP1(s[2]); 
    pLayer_STEP1(s[4]); 
    pLayer_STEP1(s[6]);

    // step 2
    t[0] ^=  (s[0]>>24) & 0xFF;
    t[2] ^=  (s[0]>>16) & 0xFF;
    t[4] ^=  (s[0]>>8)  & 0xFF;
    t[6] ^=  (s[0])     & 0xFF;

    t[0] ^= ((s[2]>>24) & 0xFF) << 10; 
    t[2] ^= ((s[2]>>16) & 0xFF) << 10;
    t[4] ^= ((s[2]>>8)  & 0xFF) << 10;  
    t[6] ^=  (s[2]      & 0xFF) << 10;

    t[0] ^= ((s[4]>>24) & 0xFF) << 20;
    t[2] ^= ((s[4]>>16) & 0xFF) << 20;
    t[4] ^= ((s[4]>>8)  & 0xFF) << 20; 
    t[6] ^=  (s[4]      & 0xFF) << 20;

    t[0] ^= ((s[6]>>24) & 0xFF) << 30;
    t[2] ^= ((s[6]>>16) & 0xFF) << 30;
    t[4] ^= ((s[6]>>8)  & 0xFF) << 30;  
    t[6] ^=  (s[6]      & 0xFF) << 30;

    t[1] ^=  (s[6]>>26) & 0x3F; 
    t[3] ^=  (s[6]>>18) & 0x3F; 
    t[5] ^=  (s[6]>>10) & 0x3F; 
    t[7] ^=  (s[6]>>2)  & 0x3F; 
  
    // sBoxLayer (bitsliced)
    // works on the 40-bit slices.  
    // Our formulas for the SBox (31 bitwise logical operations): 
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

// -----------------------------------------------------------------------------

// 5x32b: AddRC(table) + sBoxLayer(table) + pLayer(swapmove)

uint8_t SBox[256] = {
  0xee, 0xed, 0xeb, 0xe0, 0xe2, 0xe1, 0xe4, 0xef, 0xe7, 0xea, 0xe8, 0xe5, 0xe9, 0xec, 0xe3, 0xe6, 
  0xde, 0xdd, 0xdb, 0xd0, 0xd2, 0xd1, 0xd4, 0xdf, 0xd7, 0xda, 0xd8, 0xd5, 0xd9, 0xdc, 0xd3, 0xd6, 
  0xbe, 0xbd, 0xbb, 0xb0, 0xb2, 0xb1, 0xb4, 0xbf, 0xb7, 0xba, 0xb8, 0xb5, 0xb9, 0xbc, 0xb3, 0xb6, 
  0x0e, 0x0d, 0x0b, 0x00, 0x02, 0x01, 0x04, 0x0f, 0x07, 0x0a, 0x08, 0x05, 0x09, 0x0c, 0x03, 0x06, 
  0x2e, 0x2d, 0x2b, 0x20, 0x22, 0x21, 0x24, 0x2f, 0x27, 0x2a, 0x28, 0x25, 0x29, 0x2c, 0x23, 0x26, 
  0x1e, 0x1d, 0x1b, 0x10, 0x12, 0x11, 0x14, 0x1f, 0x17, 0x1a, 0x18, 0x15, 0x19, 0x1c, 0x13, 0x16, 
  0x4e, 0x4d, 0x4b, 0x40, 0x42, 0x41, 0x44, 0x4f, 0x47, 0x4a, 0x48, 0x45, 0x49, 0x4c, 0x43, 0x46, 
  0xfe, 0xfd, 0xfb, 0xf0, 0xf2, 0xf1, 0xf4, 0xff, 0xf7, 0xfa, 0xf8, 0xf5, 0xf9, 0xfc, 0xf3, 0xf6, 
  0x7e, 0x7d, 0x7b, 0x70, 0x72, 0x71, 0x74, 0x7f, 0x77, 0x7a, 0x78, 0x75, 0x79, 0x7c, 0x73, 0x76, 
  0xae, 0xad, 0xab, 0xa0, 0xa2, 0xa1, 0xa4, 0xaf, 0xa7, 0xaa, 0xa8, 0xa5, 0xa9, 0xac, 0xa3, 0xa6, 
  0x8e, 0x8d, 0x8b, 0x80, 0x82, 0x81, 0x84, 0x8f, 0x87, 0x8a, 0x88, 0x85, 0x89, 0x8c, 0x83, 0x86, 
  0x5e, 0x5d, 0x5b, 0x50, 0x52, 0x51, 0x54, 0x5f, 0x57, 0x5a, 0x58, 0x55, 0x59, 0x5c, 0x53, 0x56, 
  0x9e, 0x9d, 0x9b, 0x90, 0x92, 0x91, 0x94, 0x9f, 0x97, 0x9a, 0x98, 0x95, 0x99, 0x9c, 0x93, 0x96, 
  0xce, 0xcd, 0xcb, 0xc0, 0xc2, 0xc1, 0xc4, 0xcf, 0xc7, 0xca, 0xc8, 0xc5, 0xc9, 0xcc, 0xc3, 0xc6, 
  0x3e, 0x3d, 0x3b, 0x30, 0x32, 0x31, 0x34, 0x3f, 0x37, 0x3a, 0x38, 0x35, 0x39, 0x3c, 0x33, 0x36, 
  0x6e, 0x6d, 0x6b, 0x60, 0x62, 0x61, 0x64, 0x6f, 0x67, 0x6a, 0x68, 0x65, 0x69, 0x6c, 0x63, 0x66 
};

void Spongent160_5x32b(void *state)
{
  const uint8_t *rc = RC;
  uint32_t s[5], t[5];
  uint8_t *s8 = (uint8_t *)s, *t8 = (uint8_t *)t;
  int i, j;

  memcpy(s, state, 20);

  for (i = 0; i < 80; i++, rc += 2) {
    
    // add round constants 

    s[0] ^= rc[0];
    s[4] ^= ((uint32_t)(rc[1])) << 24;

    // sBoxLayer

    for (j = 0; j < 20; j++) 
      t8[j] = SBox[s8[j]];

    // pLayer 

    // step 1
    pLayer_STEP1(t[0]); 
    pLayer_STEP1(t[1]); 
    pLayer_STEP1(t[2]); 
    pLayer_STEP1(t[3]);
    pLayer_STEP1(t[4]);

    // step 2
    s[0]  =  (t[0]>>24) & 0xFF;
    s[0] ^= ((t[1]>>24) & 0xFF) << 8;
    s[0] ^= ((t[2]>>24) & 0xFF) << 16;
    s[0] ^= ((t[3]>>24) & 0xFF) << 24;
    
    s[1]  =  (t[4]>>24) & 0xFF;
    s[1] ^= ((t[0]>>16) & 0xFF) << 8;
    s[1] ^= ((t[1]>>16) & 0xFF) << 16;
    s[1] ^= ((t[2]>>16) & 0xFF) << 24;
    
    s[2]  =  (t[3]>>16) & 0xFF;
    s[2] ^= ((t[4]>>16) & 0xFF) << 8;
    s[2] ^= ((t[0]>>8)  & 0xFF) << 16;
    s[2] ^= ((t[1]>>8)  & 0xFF) << 24;
    
    s[3]  =  (t[2]>>8)  & 0xFF;
    s[3] ^= ((t[3]>>8)  & 0xFF) << 8;
    s[3] ^= ((t[4]>>8)  & 0xFF) << 16;
    s[3] ^= ((t[0])     & 0xFF) << 24;
    
    s[4]  =  (t[1])     & 0xFF;
    s[4] ^= ((t[2])     & 0xFF) << 8;
    s[4] ^= ((t[3])     & 0xFF) << 16;
    s[4] ^= ((t[4])     & 0xFF) << 24;
  }

  memcpy(state, s, 20);
}
