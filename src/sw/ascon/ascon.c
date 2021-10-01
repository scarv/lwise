#include <stdint.h>
#include <stdio.h>
#include <string.h>


#define ROTR64(x, d) (((x) >> (d)) | ((x) << (64 - (d))))
#define START_CONSTANT(x) (((0xf - (12 - (x))) << 4) | (12 - (x)))

typedef struct {
  uint64_t x0, x1, x2, x3, x4;
} state;

#define ROUND(C)                    \
  do {                              \
    state t;                        \
    s.x2 ^= C;                      \
    s.x0 ^= s.x4;                   \
    s.x4 ^= s.x3;                   \
    s.x2 ^= s.x1;                   \
    t.x0 = s.x0;                    \
    t.x4 = s.x4;                    \
    t.x3 = s.x3;                    \
    t.x1 = s.x1;                    \
    t.x2 = s.x2;                    \
    s.x0 = t.x0 ^ ((~t.x1) & t.x2); \
    s.x2 = t.x2 ^ ((~t.x3) & t.x4); \
    s.x4 = t.x4 ^ ((~t.x0) & t.x1); \
    s.x1 = t.x1 ^ ((~t.x2) & t.x3); \
    s.x3 = t.x3 ^ ((~t.x4) & t.x0); \
    s.x1 ^= s.x0;                   \
    s.x3 ^= s.x2;                   \
    s.x0 ^= s.x4;                   \
    s.x2 = ~s.x2;                   \
    t.x1 = s.x1;                    \
    s.x1 = ROTR64(s.x1, 39);        \
    t.x2 = s.x2;                    \
    s.x2 = ROTR64(s.x2, 1);         \
    t.x4 = s.x4;                    \
    t.x2 ^= s.x2;                   \
    s.x2 = ROTR64(s.x2, 6 - 1);     \
    t.x3 = s.x3;                    \
    t.x1 ^= s.x1;                   \
    s.x3 = ROTR64(s.x3, 10);        \
    s.x4 = ROTR64(s.x4, 7);         \
    t.x3 ^= s.x3;                   \
    s.x2 ^= t.x2;                   \
    s.x1 = ROTR64(s.x1, 61 - 39);   \
    t.x0 = s.x0;                    \
    s.x3 = ROTR64(s.x3, 17 - 10);   \
    t.x4 ^= s.x4;                   \
    s.x4 = ROTR64(s.x4, 41 - 7);    \
    s.x3 ^= t.x3;                   \
    s.x1 ^= t.x1;                   \
    s.x0 = ROTR64(s.x0, 19);        \
    s.x4 ^= t.x4;                   \
    t.x0 ^= s.x0;                   \
    s.x0 = ROTR64(s.x0, 28 - 19);   \
    s.x0 ^= t.x0;                   \
  } while (0)


static void print_state(state *s)
{
  printf("x0: %016llx\n", s->x0);
  printf("x1: %016llx\n", s->x1);
  printf("x2: %016llx\n", s->x2);
  printf("x3: %016llx\n", s->x3);
  printf("x4: %016llx\n", s->x4);
}


void sbox_layer_c(state *s)
{
  uint64_t t0, t1, t2;

  s->x0 ^= s->x4;
  s->x2 ^= s->x1;
  s->x4 ^= s->x3;
  t0 = (~(s->x1)) & s->x2;
  t1 = (~(s->x2)) & s->x3;
  t2 = (~(s->x3)) & s->x4;
  s->x2 ^= t2;
  t2 = (~(s->x4)) & s->x0;
  s->x3 ^= t2;
  t2 = (~(s->x0)) & s->x1;
  s->x4 ^= t2;
  s->x0 ^= t0;
  s->x1 ^= t1;
  s->x1 ^= s->x0;
  s->x3 ^= s->x2;
  s->x0 ^= s->x4;
  s->x2 = ~(s->x2);
}


void sbox_layer_ise(state *s)
{
  uint64_t x0 = s->x0, x1 = s->x1, x2 = s->x2, x3 = s->x3, x4 = s->x4;
  uint64_t t0, t1, t2;

  // 15 instructions
  t0 = x1 ^ x2;
  t1 = x0 ^ x4;
  t2 = x3 ^ x4;
  x4 = x3 | ~x4;  // custom instruction
  x4 = x4 ^ t0;
  x3 = x3 ^ x1;
  x3 = x3 | t0;
  x3 = x3 ^ t1;
  x2 = x2 ^ t1;
  x2 = x2 | x1;
  x2 = x2 ^ t2;
  x1 = x1 & ~t1;  // custom instruction
  x1 = x1 ^ t2;
  x0 = x0 | t2;
  x0 = x0 ^ t0;

  // write state to RAM
  s->x0 = x2;
  s->x1 = x3;
  s->x2 = x4;
  s->x3 = x0;
  s->x4 = x1;
}


void sbox_test(void)
{
  state s;

  s.x0 = 0x0120120120120120;
  s.x1 = 0x3453453453453453;
  s.x2 = 0x6786786786786786;
  s.x3 = 0x9ab9ab9ab9ab9ab9;
  s.x4 = 0xcdecdecdecdecdec;

  printf("Initial state:\n");
  print_state(&s);

  sbox_layer_c(&s);
  printf("Original C implementation:\n");
  print_state(&s);

  s.x0 = 0x0120120120120120;
  s.x1 = 0x3453453453453453;
  s.x2 = 0x6786786786786786;
  s.x3 = 0x9ab9ab9ab9ab9ab9;
  s.x4 = 0xcdecdecdecdecdec;

  sbox_layer_ise(&s);
  printf("Modified C implementation:\n");
  print_state(&s);
}


void lin_layer_c(state *s)
{
  s->x0 ^= (ROTR64(s->x0, 19) ^ ROTR64(s->x0, 28));
  s->x1 ^= (ROTR64(s->x1, 61) ^ ROTR64(s->x1, 39));
  s->x2 ^= (ROTR64(s->x2,  1) ^ ROTR64(s->x2,  6));
  s->x3 ^= (ROTR64(s->x3, 10) ^ ROTR64(s->x3, 17));
  s->x4 ^= (ROTR64(s->x4,  7) ^ ROTR64(s->x4, 41));
}


// custom instruction for ASCON linear layer
// note that the second parameter is an immediate value!

uint64_t all(uint64_t a, int imm)
{
  uint64_t r;

  switch (imm) {
    case 0:  // state-word x0
      r = a ^ ROTR64(a, 19) ^ ROTR64(a, 28);
      break;
    case 1:  // state-word x1
      r = a ^ ROTR64(a, 61) ^ ROTR64(a, 39);
      break;
    case 2:  // state-word x2
      r = a ^ ROTR64(a,  1) ^ ROTR64(a,  6);
      break;
    case 3:  // state-word x3
      r = a ^ ROTR64(a, 10) ^ ROTR64(a, 17);
      break;
    case 4:  // state-word x4
      r = a ^ ROTR64(a,  7) ^ ROTR64(a, 41);
      break;
  }

  return r;
}


void lin_layer_ise(state *s)
{
  s->x0 = all(s->x0, 0);
  s->x1 = all(s->x1, 1);
  s->x2 = all(s->x2, 2);
  s->x3 = all(s->x3, 3);
  s->x4 = all(s->x4, 4);
}


void lin_test(void)
{
  state s;

  s.x0 = 0x0123456789abcdef;
  s.x1 = 0x0123456789abcdef;
  s.x2 = 0x0123456789abcdef;
  s.x3 = 0x0123456789abcdef;
  s.x4 = 0x0123456789abcdef;

  printf("Initial state:\n");
  print_state(&s);

  lin_layer_c(&s);
  printf("Original C implementation:\n");
  print_state(&s);

  s.x0 = 0x0123456789abcdef;
  s.x1 = 0x0123456789abcdef;
  s.x2 = 0x0123456789abcdef;
  s.x3 = 0x0123456789abcdef;
  s.x4 = 0x0123456789abcdef;

  lin_layer_ise(&s);
  printf("Modified C implementation:\n");
  print_state(&s);
}


// original implementation
void ascon_perm_c(state *p, int rounds) {
  state s = *p;
  int i, start = START_CONSTANT(rounds);

  for (i = start; i > 0x4a; i -= 0x0f) {
    ROUND(i);
  }
  *p = s;
}


// permutation with ise
void ascon_perm_ise(state *p, int rounds) {
  state s = *p;
  int i, start = START_CONSTANT(rounds);

  for (i = start; i > 0x4a; i -= 0x0f) {
    s.x2 ^= i;           // addition rcon
    sbox_layer_ise(&s);  // sbox layer
    lin_layer_ise(&s);   // linear layer
  }
  *p = s;
}


void test_ascon(void)
{
  state s;

  s.x0 = s.x1 = s.x2 = s.x3 = s.x4 = 0;

  printf("Initial state:\n");
  print_state(&s);

  ascon_perm_c(&s, 8);  // original code by the designers
  printf("Original C implementation:\n");
  print_state(&s);

  s.x0 = s.x1 = s.x2 = s.x3 = s.x4 = 0;

  ascon_perm_ise(&s, 8);  // modified code for using ISE
  printf("C Implementation using ISE:\n");
  print_state(&s);
  
  // Expected result
  // x0: 1418f8af721aa830
  // x1: a5425f1f8cb31388
  // x2: a01ef761bf8e1652
  // x3: f01fdabf8c8a82b4
  // x4: 0168260badf76a06
}

