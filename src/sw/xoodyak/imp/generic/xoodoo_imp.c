#include "xoodoo_imp.h"

static void fromBytesToWords(tXoodooLane *stateAsWords, const unsigned char *state)
{
  unsigned int i, j;

  for(i = 0; i < NLANES; i++) {
    stateAsWords[i] = 0;
    for(j = 0; j < sizeof(tXoodooLane); j++)
      stateAsWords[i] |= (tXoodooLane)(state[i*sizeof(tXoodooLane)+j]) << (8*j);
  }
}

static void fromWordsToBytes(unsigned char *state, const tXoodooLane *stateAsWords)
{
  unsigned int i, j;

  for(i = 0; i < NLANES; i++)
    for(j = 0; j < sizeof(tXoodooLane); j++)
      state[i*sizeof(tXoodooLane)+j] = (stateAsWords[i] >> (8*j)) & 0xFF;
}

void Xoodoo_Round(tXoodooLane *a, tXoodooLane rc)
{
  unsigned int x, y;
  tXoodooLane b[NLANES];
  tXoodooLane p[NCOLUMS];
  tXoodooLane e[NCOLUMS];

  // Theta: Column Parity Mixer
  for (x = 0; x < NCOLUMS; ++x)
    p[x] = a[index(x, 0)] ^ a[index(x, 1)] ^ a[index(x, 2)];
  for (x = 0; x < NCOLUMS; ++x)
    e[x] = ROL32(p[(x - 1) % 4], 5) ^ ROL32(p[(x - 1) % 4], 14);
  for (x = 0; x < NCOLUMS; ++x)
    for (y = 0; y < NROWS; ++y)
      a[index(x, y)] ^= e[x];

  // Rho-west: plane shift
  for (x = 0; x < NCOLUMS; ++x) {
    b[index(x, 0)] = a[index(x, 0)];
    b[index(x, 1)] = a[index(x - 1, 1)];
    b[index(x, 2)] = ROL32(a[index(x, 2)], 11);
  }
  memcpy(a, b, sizeof(b));

  // Iota: round constant
  a[0] ^= rc;

  // Chi: non linear layer
  for (x = 0; x < NCOLUMS; ++x)
    for (y = 0; y < NROWS; ++y)
      b[index(x, y)] = a[index(x, y)] ^ (~a[index(x, y + 1)] & a[index(x, y + 2)]);
  memcpy(a, b, sizeof(b));

  // Rho-east: plane shift
  for (x = 0; x < NCOLUMS; ++x) {
    b[index(x, 0)] = a[index(x, 0)];
    b[index(x, 1)] = ROL32(a[index(x, 1)], 1);
    b[index(x, 2)] = ROL32(a[index(x + 2, 2)], 8);
  }
  memcpy(a, b, sizeof(b));
}

void Xoodoo_Round_unrolled(tXoodooLane * a, tXoodooLane rc) {

  tXoodooLane b[NLANES];
  tXoodooLane p[NCOLUMS];
  tXoodooLane e[NCOLUMS];

  /* Theta: Column Parity Mixer */
  p[0] = a[0] ^ a[4] ^ a[8];
  p[1] = a[1] ^ a[5] ^ a[9];
  p[2] = a[2] ^ a[6] ^ a[10];
  p[3] = a[3] ^ a[7] ^ a[11];

  e[0] = ROL32(p[3], 5) ^ ROL32(p[3], 14);
  e[1] = ROL32(p[0], 5) ^ ROL32(p[0], 14);
  e[2] = ROL32(p[1], 5) ^ ROL32(p[1], 14);
  e[3] = ROL32(p[2], 5) ^ ROL32(p[2], 14);

  a[0] ^= e[0];
  a[4] ^= e[0];
  a[8] ^= e[0];
  a[1] ^= e[1];
  a[5] ^= e[1];
  a[9] ^= e[1];
  a[2] ^= e[2];
  a[6] ^= e[2];
  a[10] ^= e[2];
  a[3] ^= e[3];
  a[7] ^= e[3];
  a[11] ^= e[3];

  /* Rho-west: plane shift */
  b[0] = a[0];
  b[4] = a[7];
  b[8] = ROL32(a[8], 11);
  b[1] = a[1];
  b[5] = a[4];
  b[9] = ROL32(a[9], 11);
  b[2] = a[2];
  b[6] = a[5];
  b[10] = ROL32(a[10], 11);
  b[3] = a[3];
  b[7] = a[6];
  b[11] = ROL32(a[11], 11);
  memcpy(a, b, sizeof(b));

  /* Iota: round constant */
  a[0] ^= rc;

  /* Chi: non linear layer */
  b[0] = a[0] ^ (~a[4] & a[8]); // x = 0, y = 0
  b[4] = a[4] ^ (~a[8] & a[0]); // x = 0, y = 1
  b[8] = a[8] ^ (~a[0] & a[4]); // x = 0, y = 2
  b[1] = a[1] ^ (~a[5] & a[9]); // x = 1, y = 0
  b[5] = a[5] ^ (~a[9] & a[1]); // x = 1, y = 1
  b[9] = a[9] ^ (~a[1] & a[5]); // x = 1, y = 2
  b[2] = a[2] ^ (~a[6] & a[10]); // x = 2, y = 0
  b[6] = a[6] ^ (~a[10] & a[2]); // x = 2, y = 1
  b[10] = a[10] ^ (~a[2] & a[6]); // x = 2, y = 2
  b[3] = a[3] ^ (~a[7] & a[11]); // x = 3, y = 0
  b[7] = a[7] ^ (~a[11] & a[3]); // x = 3, y = 1
  b[11] = a[11] ^ (~a[3] & a[7]); // x = 3, y = 2
  memcpy(a, b, sizeof(b));

  /* Rho-east: plane shift */
  b[0] = a[0];
  b[4] = ROL32(a[4], 1);
  b[8] = ROL32(a[10], 8);
  b[1] = a[1];
  b[5] = ROL32(a[5], 1);
  b[9] = ROL32(a[11], 8);
  b[2] = a[2];
  b[6] = ROL32(a[6], 1);
  b[10] = ROL32(a[8], 8);
  b[3] = a[3];
  b[7] = ROL32(a[7], 1);
  b[11] = ROL32(a[9], 8);
  memcpy(a, b, sizeof(b));
}

void Xoodoo_Permute_Nrounds(void * state, uint32_t nr)
{
  tXoodooLane a[NLANES];
  unsigned int i;

  fromBytesToWords(a, (const unsigned char *) state);

  for (i = MAXROUNDS - nr; i < MAXROUNDS; ++i ) {
    #if defined( XOODOO_PERM_UNROLL )
    Xoodoo_Round_unrolled( a, RC[i] );
    #else 
    Xoodoo_Round( a, RC[i] );
    #endif
  }

  fromWordsToBytes((unsigned char *) state, a);
}
