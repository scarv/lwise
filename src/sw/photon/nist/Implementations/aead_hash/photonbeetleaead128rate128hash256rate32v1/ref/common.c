#include "beetle.h"

void XOR(
	uint8_t *out,
	const uint8_t *in_left,
	const uint8_t *in_right,
	const size_t iolen_inbytes)
{
	size_t i;
	for (i = 0; i < iolen_inbytes; i++) out[i] = in_left[i] ^ in_right[i];
}

void HASH(
	uint8_t *State_inout,
	const uint8_t *Data_in,
	const uint64_t Dlen_inbytes,
	const uint8_t  Constant,
	const uint8_t  Rate_inbytes)
{
	uint8_t *State = State_inout;
	size_t Dlen_inblocks = (Dlen_inbytes + Rate_inbytes - 1) / Rate_inbytes;
	size_t LastDBlocklen;
	size_t i;

	for (i = 0; i < Dlen_inblocks - 1; i++)
	{
		PHOTON_Permutation(State);
		XOR(State, State, Data_in + i * Rate_inbytes, Rate_inbytes);
	}
	PHOTON_Permutation(State);	
	LastDBlocklen = Dlen_inbytes - i * Rate_inbytes;
	XOR(State, State, Data_in + i * Rate_inbytes, LastDBlocklen);
	if (LastDBlocklen < Rate_inbytes) State[LastDBlocklen] ^= 0x01; // ozs

	State[STATE_INBYTES - 1] ^= (Constant << LAST_THREE_BITS_OFFSET);
}

void TAG(
	uint8_t *Tag_out,
	uint8_t *State)
{
	PHOTON_Permutation(State);
	memcpy(Tag_out, State, SQUEEZE_RATE_INBYTES);
}