// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#include <assert.h>
#include <stdio.h>
#include "sparkle.h"

// Round constants
static const uint32_t RCON[MAX_BRANCHES] = {      
  0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 
  0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D  
};

#if !defined( SPARKLE_FWD_EXTERN )
void sparkle_fwd(uint32_t *state, int brans, int steps)
{
  int i, j;  // Step and branch counter
  uint32_t rc, tmpx, tmpy, x0, y0;
  
  // The number of branches must be in {4, 6, 8}.
  assert((brans == 4) || (brans == 6) || (brans ==8));
  i=0;
  for(i = 0; i < steps; i++) {
    // Add step counter
    state[1] ^= RCON[i%MAX_BRANCHES];
    state[3] ^= i;
    // ARXBox layer
   for(j = 0; j < 2*brans; j += 2) {
      rc = RCON[j>>1];
      ALZETTE_ENC(state[j], state[j+1], rc);
    }
    // Linear layer
    x0 = state[0];
    y0 = state[1];
    tmpx = x0;
    tmpy = y0;
    for(j = 2; j < brans; j += 2) {
      tmpx ^= state[j];
      tmpy ^= state[j+1];
    }
    tmpx = ELL(tmpx);
    tmpy = ELL(tmpy);

    for (j = 2; j < brans; j += 2) {
      state[j-2] = state[j+brans  ] ^ state[j  ] ^ tmpy;
      state[j-1] = state[j+brans+1] ^ state[j+1] ^ tmpx;

      state[j+brans  ] = state[j  ];
      state[j+brans+1] = state[j+1];
    }
    state[brans-2] = state[brans  ] ^ x0 ^ tmpy;
    state[brans-1] = state[brans+1] ^ y0 ^ tmpx;
    state[brans  ] = x0;
    state[brans+1] = y0;
  }
}
#endif

#if !defined( SPARKLE_INV_EXTERN )
void sparkle_inv(uint32_t *state, int brans, int steps)
{
  int i, j;  // Step and branch counter
  uint32_t rc, tmpx, tmpy, xb1, yb1;
  
  // The number of branches must be in {4, 6, 8}.
  assert((brans == 4) || (brans == 6) || (brans ==8));
  
  for(i = steps - 1; i >= 0; i--) {
    // Linear layer
    tmpx = tmpy = 0;
    xb1 = state[brans-2];
    yb1 = state[brans-1];
    for (j = brans-2; j > 0; j -= 2) {
      state[j  ] = state[j+brans  ];
      state[j+1] = state[j+brans+1];
      state[j+brans  ] = state[j-2];
      state[j+brans+1] = state[j-1];
      tmpx ^= state[j  ];
      tmpy ^= state[j+1];
    }
    tmpx ^= (state[0] = state[brans]);
    tmpy ^= (state[1] = state[brans+1]);
    state[brans  ] = xb1;
    state[brans+1] = yb1;
    tmpx = ELL(tmpx);
    tmpy = ELL(tmpy);
    for(j = brans-2; j >= 0; j -= 2) {
      state[j+brans  ] ^= tmpy ^ state[j  ];
      state[j+brans+1] ^= tmpx ^ state[j+1];
    }
    // ARXbox layer
    for(j = 0; j < 2*brans; j += 2) {
      rc = RCON[j>>1];
      ALZETTE_DEC(state[j], state[j+1], rc);
    }
    // Add step counter
    state[1] ^= RCON[i%MAX_BRANCHES];
    state[3] ^= i;
  }
}

#endif

void print_state(const uint32_t *state, int brans)
{
  uint8_t *sbytes = (uint8_t *) state;
  int i, j;
  
  for (i = 0; i < brans; i ++) {
    j = 8*i;
    printf("(%02x%02x%02x%02x %02x%02x%02x%02x)",       \
    sbytes[j],   sbytes[j+1], sbytes[j+2], sbytes[j+3], \
    sbytes[j+4], sbytes[j+5], sbytes[j+6], sbytes[j+7]);
    if (i < brans-1) printf(" ");
  }
  printf("\n");
}

void test_sparkle_ref(int brans, int steps)
{
  uint32_t state[2*MAX_BRANCHES] = { 0 };
  
  printf("input:\n");
  print_state(state, brans);
  sparkle_fwd(state, brans, steps);
  printf("sparkle fwd:\n");
  print_state(state, brans);
  sparkle_inv(state, brans, steps);
  printf("sparkle inv:\n");
  print_state(state, brans);
  printf("\n");
}
