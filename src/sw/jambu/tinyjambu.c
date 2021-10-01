#include <string.h>  
#include <stdio.h>
#include <stdint.h>


static void print_twords(int idx, uint32_t t1, uint32_t t2, uint32_t t3, uint32_t t4)
{
  printf("\n----------------- State[%i] 32-bit modification -----------------\n", idx);
  printf("t1 : %08x\n", t1);
  printf("t2 : %08x\n", t2);
  printf("t3 : %08x\n", t3);
  printf("t4 : %08x\n", t4);
}


static void print_state(uint32_t *state)
{
  int i;

	printf("-------- 128-bit state: --------\n");
	for (i = 0 ; i < 4 ; i++) {
		printf("%08x", state[i]);
	}
  printf("\n");
}


/* state update function */    
void test_state_update_32(uint32_t *state, const uint32_t *key)
{
	uint32_t t1, t2, t3, t4;

	t1 = (state[1] >> 15) | (state[2] << 17);  // 47 = 1*32+15 
	t2 = (state[2] >>  6) | (state[3] << 26);  // 47 + 23 = 70 = 2*32 + 6 
	t3 = (state[2] >> 21) | (state[3] << 11);  // 47 + 23 + 15 = 85 = 2*32 + 21
	t4 = (state[2] >> 27) | (state[3] <<  5);  // 47 + 23 + 15 + 6 = 91 = 2*32 + 27
	state[0] ^= t1 ^ (~(t2 & t3)) ^ t4 ^ key[0]; 

	// print_twords(0, t1, t2, t3, t4);

	t1 = (state[2] >> 15) | (state[3] << 17);   
	t2 = (state[3] >>  6) | (state[0] << 26);   
	t3 = (state[3] >> 21) | (state[0] << 11);        
	t4 = (state[3] >> 27) | (state[0] <<  5);    
	state[1] ^= t1 ^ (~(t2 & t3)) ^ t4 ^ key[1];

	// print_twords(1, t1, t2, t3, t4);

	t1 = (state[3] >> 15) | (state[0] << 17);
	t2 = (state[0] >>  6) | (state[1] << 26);
	t3 = (state[0] >> 21) | (state[1] << 11);
	t4 = (state[0] >> 27) | (state[1] <<  5);
	state[2] ^= t1 ^ (~(t2 & t3)) ^ t4 ^ key[2]; 

	// print_twords(2, t1, t2, t3, t4);

	t1 = (state[0] >> 15) | (state[1] << 17);
	t2 = (state[1] >>  6) | (state[2] << 26);
	t3 = (state[1] >> 21) | (state[2] << 11);
	t4 = (state[1] >> 27) | (state[2] <<  5);
	state[3] ^= t1 ^ (~(t2 & t3)) ^ t4 ^ key[3];

	// print_twords(3, t1, t2, t3, t4);
}


void test_state_update_64(uint32_t *state, const uint32_t *key)
{

}


void test_tinyjambu(void)
{

	uint32_t state[4], key[4];
  int i;

  // initialize state and key
  for (i = 0; i < 4; i++) {
    state[i] = 0x01234567;
    key[i] = 0x01234567;
  }

  printf("==== 32-bit implementation: ====\n");
  print_state(state);
  test_state_update_32(state, key);
  print_state(state);
  printf("\n");

  // initialize state and key
  for (i = 0; i < 4; i++) {
    state[i] = 0x01234567;
    key[i] = 0x01234567;
  }

  printf("==== 64-bit implementation: ====\n");
  print_state(state);
  test_state_update_64(state, key);
	print_state(state);
}
