#include "crypto_hash.h"

#include "beetle.h"
#include "photon.h"

/* Declaration of basic internal functions */
static uint8_t selectConst(
	const bool condition,
	const uint8_t option1,
	const uint8_t option2);
	
static void XOR(
	uint8_t *out,
	const uint8_t *in_left,
	const uint8_t *in_right,
	const size_t iolen_inbytes);

static void XOR_const(
	uint8_t *State_inout,
	const uint8_t  Constant);

static void HASH(
	uint8_t *State_inout,
	const uint8_t *Data_in,
	const uint64_t Dlen_inbytes,
	const uint8_t  Constant);

static void TAG(
	uint8_t *Tag_out,
	uint8_t *State);

/* Definition of basic internal functions */
static uint8_t selectConst(
	const bool condition,
	const uint8_t option1,
	const uint8_t option2)
{
	if (condition) return option1;
	return option2;
}

static void XOR(
	uint8_t *out,
	const uint8_t *in_left,
	const uint8_t *in_right,
	const size_t iolen_inbytes)
{
	size_t i;
	for (i = 0; i < iolen_inbytes; i++) out[i] = in_left[i] ^ in_right[i];
}

static void XOR_const(
	uint8_t *State_inout,
	const uint8_t  Constant)
{
	State_inout[STATE_INBYTES - 1] ^= (Constant << LAST_THREE_BITS_OFFSET);
}

static void HASH(
	uint8_t *State_inout,
	const uint8_t *Data_in,
	const uint64_t Dlen_inbytes,
	const uint8_t  Constant)
{
	uint8_t *State = State_inout;
	size_t Dlen_inblocks = (Dlen_inbytes + RATE_INBYTES - 1) / RATE_INBYTES;
	size_t LastDBlocklen;
	size_t i;

	for (i = 0; i < Dlen_inblocks - 1; i++)
	{
		PHOTON_Permutation(State);
		XOR(State, State, Data_in + i * RATE_INBYTES, RATE_INBYTES);
	}
	PHOTON_Permutation(State);	
	LastDBlocklen = Dlen_inbytes - i * RATE_INBYTES;
	XOR(State, State, Data_in + i * RATE_INBYTES, LastDBlocklen);
	if (LastDBlocklen < RATE_INBYTES) State[LastDBlocklen] ^= 0x01; // ozs

	XOR_const(State, Constant);
}

static void TAG(
	uint8_t *Tag_out,
	uint8_t *State)
{
	size_t i;

	i = TAG_INBYTES;
	while (i > SQUEEZE_RATE_INBYTES)
	{
		PHOTON_Permutation(State);
		memcpy(Tag_out, State, SQUEEZE_RATE_INBYTES);
		Tag_out += SQUEEZE_RATE_INBYTES;
		i -= SQUEEZE_RATE_INBYTES;
	}
	PHOTON_Permutation(State);
	memcpy(Tag_out, State, i);
}

int crypto_hash(
	unsigned char *out,
	const unsigned char *in,
	unsigned long long inlen
)
{
	/*
	...
	... the code for the hash function implementation goes here
	... generating a hash value out[0],out[1],...,out[CRYPTO_BYTES-1]
	... from a message in[0],in[1],...,in[in-1] 
	...
	... return 0;
	*/
	uint8_t State[STATE_INBYTES] = { 0 };

	uint8_t c0;

	if (inlen == 0)
	{
		XOR_const(State, 1);
	}
	else if (inlen <= INITIAL_RATE_INBYTES)
	{
		c0 = selectConst((inlen < INITIAL_RATE_INBYTES), 1, 2);
		memcpy(State, in, inlen);
		if (inlen < INITIAL_RATE_INBYTES) State[inlen] ^= 0x01; // ozs
		XOR_const(State, c0);
	}
	else
	{
		memcpy(State, in, INITIAL_RATE_INBYTES);
		inlen -= INITIAL_RATE_INBYTES;
		c0 = selectConst((inlen % RATE_INBYTES) == 0, 1, 2);
		HASH(State, in + INITIAL_RATE_INBYTES, inlen, c0);
	}
	TAG(out, State);

	return 0;
}