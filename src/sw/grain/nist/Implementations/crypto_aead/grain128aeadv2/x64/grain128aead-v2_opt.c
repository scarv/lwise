/*
 * Algorithm     : Grain128-AEADv2
 * Implementation: C/C++, 64-bit, semi-optimised
 * Endianness    : Little endian
 * Author        : Alexander Maximov
 * Year          : 2021
 */

// NOTE: this file was in the `x64` folder

// Modifications by Johann Groszschaedl:
// - removed all SIMD (AVX512) code
// - converted the C++ function to pure C code
// - added a few type casts to get rid of wanrings
// - fixed alignment issues in the high-level encrypt and decrypt finction
// - renamed original grain_keystream32 function to grain_keystream32_unaligned
// - added grain_keystream32_aligned function that has fewer alignment issues
// - added some basic test code

#include "grain128aead-v2_opt.h"
// #include <memory.h>
#include <string.h>

// ------------------------------------------------------------------
// Internals
// ------------------------------------------------------------------
#define N64(byte) (*(u64*) (((u8*) grain->nfsr) + (byte)))
#define L64(byte) (*(u64*) (((u8*) grain->lfsr) + (byte)))
#define N32(byte) (*(u32*) (((u8*) grain->nfsr) + (byte)))
#define L32(byte) (*(u32*) (((u8*) grain->lfsr) + (byte)))

#ifdef __GRAIN_DEBUG_PRINTS__
#include <stdio.h>
int ctr = 0;
#endif

// Performs 32 clocks of the cipher and return 32-bit value of y
static inline u32 grain_keystream32_unaligned(grain_ctx *grain)
{
#ifdef __GRAIN_DEBUG_PRINTS__
	printf("=== time %d ===\n", ctr);
	printf("A=%016llx R=%016llx S=%016llx A^R=%016llx\n", grain->A, grain->R, grain->S, grain->A ^ grain->R);
	printf("LFSR="); for (int i = 0; i < 16; i++) printf("%02x ", (int) grain->lfsr[i]); printf("\n");
	printf("NFSR="); for (int i = 0; i < 16; i++) printf("%02x ", (int) grain->nfsr[i]); printf("\n");
	ctr += 32;
#endif

#if 0 /* Legacy expressions for debug purposes */
#define st(x)  (u32) (*(u64*) (grain->lfsr + ((x)/8)) >> ((x)%8))
#define bt(x)  (u32) (*(u64*) (grain->nfsr + ((x)/8)) >> ((x)%8))

	u32 y = (bt(12) & st(8)) ^ (st(13) & st(20)) ^ (bt(95) & st(42)) ^ (st(60) & st(79)) ^ (bt(12) & bt(95) & st(94))
		^ st(93) ^ bt(2) ^ bt(15) ^ bt(36) ^ bt(45) ^ bt(64) ^ bt(73) ^ bt(89);
	u32 nn = st(0) ^ bt(0) ^ bt(26) ^ bt(56) ^ bt(91) ^ bt(96) ^ (bt(3) & bt(67)) ^ (bt(11) & bt(13))
		^ (bt(17) & bt(18)) ^ (bt(27) & bt(59)) ^ (bt(40) & bt(48)) ^ (bt(61) & bt(65)) ^ (bt(68) & bt(84))
		^ (bt(22) & bt(24) & bt(25)) ^ (bt(70) & bt(78) & bt(82)) ^ (bt(88) & bt(92) & bt(93) & bt(95));
	u32 ln = st(0) ^ st(7) ^ st(38) ^ st(70) ^ st(81) ^ st(96);

	L32(0) = L32(4);
	L32(4) = L32(8);
	L32(8) = L32(12);
	L32(12) = ln;

	N32(0) = N32(4);
	N32(4) = N32(8);
	N32(8) = N32(12);
	N32(12) = nn;

#else
	u64 ln0 = L64(0), nn0 = N64(0), nn1 = N64(4), nn2 = N64(8), nn2_p16 = N64(6);
	u64 nn0_2 = nn0 >> 2, nn0_1 = nn0 >> 1;

	u64 nn4 = ln0 ^ nn0 ^ N64(12) ^ (((nn0 & nn1) ^ nn2) >> 27) ^ ((nn0 & nn2) >> 3) ^ ((nn0 & nn0_2) >> 11) ^
		(((nn0 & nn0_1) ^ ((nn1 >> 12) & nn2_p16)) >> 17) ^ (N64(5) & N64(6)) ^
		((nn2_p16 & nn2) >> 20) ^ ((nn0_2 ^ nn1 ^ ((nn0 & (nn0 << 2)) & nn0_1)) >> 24) ^
		(N64(11) & (nn2 >> 28) & (nn2 >> 29) & (nn2 >> 31)) ^ (((nn2 & N64(9)) >> 6) & (nn2 >> 18));
	
	N64(0) = nn1;
	N32(8) = N32(12);
	N32(12) = (u32)nn4;

	u64 ln2 = L64(8), ln1 = L64(4);
	u64 ln2_17 = ln2 >> 17, ln0_7 = ln0 >> 7;

	L64(0) = ln1;
	L32(8) = L32(12);
	L32(12) ^= ln0 ^ ((ln1 ^ ln2) >> 6) ^ ln0_7 ^ ln2_17;

	u64 nn2_21 = nn2 >> 21;

	u32 y = (u32) (nn2 ^ nn0_2 ^ (nn1 >> 4) ^ ((nn2 ^ nn2_p16) >> 25) ^ ((ln1 >> 28) & (ln2 >> 15)) ^
		((ln2_17 ^ (nn0 & (ln0 << 4))) >> 12) ^ (((ln0 & ln0_7) ^ nn1 ^ nn0_2) >> 13) ^
		(((ln1 & nn2_21) ^ (nn0_2 & nn2_21 & (ln2 >> 20))) >> 10));
#endif

#ifdef __GRAIN_DEBUG_PRINTS__
	printf("y=%08x\n", y);
#endif
	return y;
}

static inline void grain_init(grain_ctx *grain, const u8 *key, const u8 *iv)
{
	// load key, and IV along with padding
	memcpy(grain->nfsr, key, 16);
	memcpy(grain->lfsr, iv, 12);
	L32(12) = 0x7fffffffUL;

	// 320 + 64 clocks of Initialisation & Key-Reintroduction
	for (int i = -10; i < 2; i++)
	{
		u32 ks = grain_keystream32(grain);
		L32(12) ^= ks;
		N32(12) ^= ks;
		if (i < 0) continue;
		L32(12) ^= ((u32*) key)[i + 2];
		N32(12) ^= ((u32*) key)[i];
	}

	// 128 clocks of A/R initialisation
	for (int i = 0; i < 4; i++)
		((u32*) (&grain->A))[i] = grain_keystream32(grain);
}

/* Deinterleave 64 bits of the keystream */
static inline void grain_getz(grain_ctx *grain)
{
	u64 tmp, x;
	x = grain_keystream32(grain);
	x |= ((u64) grain_keystream32(grain)) << 32;
	tmp = (x ^ (x >> 1)) & 0x2222222222222222ULL; x ^= tmp ^ (tmp << 1); // a(Ab)Bc(Cd)De(Ef)Fg(Gh)H
	tmp = (x ^ (x >> 2)) & 0x0c0c0c0c0c0c0c0cULL; x ^= tmp ^ (tmp << 2); // ab(ABcd)CDef(EFgh)GH
	tmp = (x ^ (x >> 4)) & 0x00f000f000f000f0ULL; x ^= tmp ^ (tmp << 4); // abcd(ABCDefgh)EFGH
	tmp = (x ^ (x >> 8)) & 0x0000ff000000ff00ULL; x ^= tmp ^ (tmp << 8); // ...
	tmp = (x ^ (x >> 16)) & 0x00000000ffff0000ULL; x ^= tmp ^ (tmp << 16);
	grain->S = x >> 32;
	*(u32*) grain->z = (u32) x;
}

/* Classical bitwise solution, variable length = [0..4] */
static inline void grain_auth(grain_ctx *grain, u8 * data, int bytes)
{
	for (int t = 0; t < bytes; t++)
	{
		u8 msg = data[t];
		for (int i = 0; i < 8; ++i, grain->S >>= 1, msg >>= 1)
		{
			u64 mask = (u64) -((long long) (msg & 1));
			grain->A ^= grain->R & mask;
			grain->R = (grain->R >> 1) | (grain->S << 63);
		}
	}
}

// Full block authentication for 4 bytes
static inline void grain_authF(grain_ctx *grain, u8 * data)
{
	grain_auth(grain, data, 4);
}


// ------------------------------------------------------------------
// NIST API for Grain-128AEADv2
// ------------------------------------------------------------------
int crypto_aead_encrypt(
	unsigned char *c, unsigned long long *clen,
	const unsigned char *m, unsigned long long mlen,
	const unsigned char *ad, unsigned long long adlen,
	const unsigned char *nsec,
	const unsigned char *iv,
	const unsigned char *k)
{
	u64 tmp;
	grain_ctx grain;
	grain_init(&grain, k, iv);

	// DER encoding of the adlen
	u8 der[9];
	int der_len;
	// *(u64*) (der + 1) = adlen;
	memcpy(der + 1, &adlen, 8);

	der[0] = 0x80;
	for (der_len = 8; !der[der_len]; --der_len);

	if ((der_len <= 1) && (der[1] < 128))
	{
		der[0] = der[1];
		der_len = 0;
	}
	else
		der[0] |= der_len;

	++der_len;

	// Authenticate ADlen
	grain_getz(&grain);

	long long i;
	for (i = 0; i <= (der_len - GRAIN_Z_BLOCK); i += GRAIN_Z_BLOCK)
	{
		grain_authF(&grain, der + i);
		grain_getz(&grain);
	}

	grain_auth(&grain, der + i, (int) der_len - (int) i);

	// Authenticate AD
	// long long rem = GRAIN_Z_BLOCK - (der_len % GRAIN_Z_BLOCK);
	long long rem = GRAIN_Z_BLOCK - (der_len & (GRAIN_Z_BLOCK - 1));

	if ((long long) adlen < rem)
	{
		grain_auth(&grain, (u8*) ad, (int) adlen);
		rem -= (long long) adlen;
	}
	else
	{
		grain_auth(&grain, (u8*) ad, (int) rem);
		grain_getz(&grain);

		for (i = rem; i <= ((long long) adlen - GRAIN_Z_BLOCK); i += GRAIN_Z_BLOCK)
		{
			grain_authF(&grain, (u8*) ad + i);
			grain_getz(&grain);
		}

		grain_auth(&grain, (u8*) ad + i, (int) adlen - (int) i);
		rem = GRAIN_Z_BLOCK - ((long long) adlen - i);
	}

	// Auth and Encrypt/Decrypt
	i = (long long) mlen < rem ? (long long) mlen : rem;

	grain_auth(&grain, (u8*) m, (int) i);
	for (int j = 0; j < i; j++)
		c[j] = m[j] ^ grain.z[GRAIN_Z_BLOCK - rem + j];

	grain_getz(&grain);

	for (; i <= ((long long) mlen - GRAIN_Z_BLOCK); i += GRAIN_Z_BLOCK)
	{
		grain_authF(&grain, (u8*) m + (int) i);
		// *(GRAIN_Z_TYPE *) (c + i) = *(GRAIN_Z_TYPE *) (m + i) ^ *(GRAIN_Z_TYPE *) (grain.z);
		for (int j = 0; j < 4; j++) c[i + j] = m[i + j] ^ grain.z[j];
		grain_getz(&grain);
	}

	grain_auth(&grain, (u8*) m + i, (int) ((long long) mlen - i));
	for (rem = 0; i < (long long) mlen; i++, rem++)
		c[i] = m[i] ^ grain.z[rem];

	// append MAC to ciphertext
	// *(u64*)(c + mlen) = grain.A ^ grain.R;
	tmp = grain.A ^ grain.R;
	memcpy(c + mlen, &tmp, 8);
	*clen = i + 8;

	return 0;
}


int crypto_aead_decrypt(
	unsigned char *m, unsigned long long *mlen,
	unsigned char *nsec,
	const unsigned char *c, unsigned long long clen,
	const unsigned char *ad, unsigned long long adlen,
	const unsigned char *iv,
	const unsigned char *k)
{
	if (clen < 8) return -1;
	clen -= 8;

	u64 tmp;
	grain_ctx grain;
	grain_init(&grain, k, iv);

	// DER encoding of the adlen
	u8 der[9];
	int der_len;
	// *(u64*) (der + 1) = adlen;
	memcpy(der + 1, &adlen, 8);

	der[0] = 0x80;
	for (der_len = 8; !der[der_len]; --der_len);
	if ((der_len <= 1) && (der[1] < 128))
	{
		der[0] = der[1];
		der_len = 0;
	}
	else
		der[0] |= der_len;

	++der_len;

	// Authenticate ADlen
	grain_getz(&grain);

	long long i;
	for (i = 0; i <= (der_len - GRAIN_Z_BLOCK); i += GRAIN_Z_BLOCK)
	{
		grain_authF(&grain, der + i);
		grain_getz(&grain);
	}

	grain_auth(&grain, der + i, (int) der_len - (int) i);

	// Authenticate AD
	// long long rem = GRAIN_Z_BLOCK - (der_len % GRAIN_Z_BLOCK);
	long long rem  = GRAIN_Z_BLOCK - (der_len & (GRAIN_Z_BLOCK - 1));

	if ((long long) adlen < rem)
	{
		grain_auth(&grain, (u8*) ad, (int) adlen);
		rem -= (long long) adlen;
	}
	else
	{
		grain_auth(&grain, (u8*) ad, (int) rem);
		grain_getz(&grain);

		for (i = rem; i <= ((long long) adlen - GRAIN_Z_BLOCK); i += GRAIN_Z_BLOCK)
		{
			grain_authF(&grain, (u8*) ad + i);
			grain_getz(&grain);
		}

		grain_auth(&grain, (u8*) ad + i, (int) adlen - (int) i);
		rem = GRAIN_Z_BLOCK - ((long long) adlen - i);
	}

	// Auth and Encrypt/Decrypt
	i = (long long) clen < rem ? (long long) clen : rem;

	for (int j = 0; j < i; j++)
		m[j] = c[j] ^ grain.z[GRAIN_Z_BLOCK - rem + j];
	grain_auth(&grain, (u8*) m, (int) i);

	grain_getz(&grain);
	for (; i <= ((long long) clen - GRAIN_Z_BLOCK); i += GRAIN_Z_BLOCK)
	{
		// *(GRAIN_Z_TYPE *) (m + i) = *(GRAIN_Z_TYPE *) (c + i) ^ *(GRAIN_Z_TYPE *) (grain.z);
		for (int j = 0; j < 4; j ++) m[i + j] = c[i + j] ^ grain.z[j];
		grain_authF(&grain, (u8*) m + i);
		grain_getz(&grain);
	}

	for (rem = 0; i < (long long) clen; i++, rem++)
		m[i] = c[i] ^ grain.z[rem];
	grain_auth(&grain, (u8*) m + i - rem, (int) ((long long) clen - i + rem));

	*mlen = i;
	// verify MAC
	memcpy(&tmp, c + clen, 8);
	if (tmp ^ grain.A ^ grain.R)
		return -1;

	return 0;
}






// Modified version with (hopefully) fewer alignment issues
u32 grain_keystream32_aligned(grain_ctx *grain)
{
	u32 *lptr = (u32 *) grain->lfsr;  // lsfr is hopefully word-aligned
	u32 *nptr = (u32 *) grain->nfsr;  // nsfr is hopefully word-aligned

	u64 ln0 = (((u64) lptr[1]) << 32) | lptr[0],
		ln1 = (((u64) lptr[2]) << 32) | lptr[1],
		ln2 = (((u64) lptr[3]) << 32) | lptr[2],
		ln3 = (((u64) lptr[3]));
	u64 nn0 = (((u64) nptr[1]) << 32) | nptr[0],
		nn1 = (((u64) nptr[2]) << 32) | nptr[1],
		nn2 = (((u64) nptr[3]) << 32) | nptr[2],
		nn3 = (((u64) nptr[3]));

	// g      s0    b0        b26       b96       b56             b91 + b27b59
	u32 nn4 = (u32) (ln0 ^ nn0 ^ (nn0 >> 26) ^ nn3 ^ (nn1 >> 24) ^ (((nn0 & nn1) ^ nn2) >> 27) ^
		//     b3b67                   b11b13                        b17b18
		((nn0 & nn2) >> 3) ^ ((nn0 >> 11) & (nn0 >> 13)) ^ ((nn0 >> 17) & (nn0 >> 18)) ^
		//       b40b48                        b61b65                      b68b84
		((nn1 >> 8) & (nn1 >> 16)) ^ ((nn1 >> 29) & (nn2 >> 1)) ^ ((nn2 >> 4) & (nn2 >> 20)) ^
		//                   b88b92b93b95
		((nn2 >> 24) & (nn2 >> 28) & (nn2 >> 29) & (nn2 >> 31)) ^
		//              b22b24b25                                  b70b78b82
		((nn0 >> 22) & (nn0 >> 24) & (nn0 >> 25)) ^ ((nn2 >> 6) & (nn2 >> 14) & (nn2 >> 18)));

	nptr[0] = nptr[1];
	nptr[1] = nptr[2];
	nptr[2] = nptr[3];
	nptr[3] = nn4;

	// f
	u32 ln4 = (u32) ((ln0 ^ ln3) ^ ((ln1 ^ ln2) >> 6) ^ (ln0 >> 7) ^ (ln2 >> 17));

	lptr[0] = lptr[1];
	lptr[1] = lptr[2];
	lptr[2] = lptr[3];
	lptr[3] = ln4;

	return (u32) ((nn0 >> 2) ^ (nn0 >> 15) ^ (nn1 >> 4) ^ (nn1 >> 13) ^ nn2 ^ (nn2 >> 9) ^ (nn2 >> 25) ^ (ln2 >> 29) ^
		((nn0 >> 12) & (ln0 >> 8)) ^ ((ln0 >> 13) & (ln0 >> 20)) ^ ((nn2 >> 31) & (ln1 >> 10)) ^
		((ln1 >> 28) & (ln2 >> 15)) ^ ((nn0 >> 12) & (nn2 >> 31) & (ln2 >> 30)));
}





///////////////////////////////////
// CUSTOM INSTRUCTIONS FOR GRAIN //
///////////////////////////////////

// extract a 32-bit word from a 64-bit word
static inline u32 grain_extr(u32 hi, u32 lo, int imm)
{
	u64 tmp = (((u64) hi) << 32) | lo;
	return (u32) (tmp >> imm);
}

// operations of f-function that use ln0 as input
static inline u32 grain_fln0(u32 ln0hi, u32 ln0lo)
{
	u64 ln0 = (((u64) ln0hi) << 32) | ln0lo;
	u32 res = ln0lo ^ ((u32) (ln0 >> 7));

	return res;
}

// operations of f-function that use ln2 as input
static inline u32 grain_fln2(u32 ln2hi, u32 ln2lo)
{
	u64 ln2 = (((u64) ln2hi) << 32) | ln2lo;
	u32 res = ln2hi ^ ((u32)((ln2 >> 6) ^ (ln2 >> 17)));

	return res;
}

// operations of g-function that use nn0 as input
static inline u32 grain_gnn0(u32 nn0hi, u32 nn0lo)
{
	u64 nn0 = (((u64) nn0hi) << 32) | nn0lo;
	u32 res;

	res = (u32) (nn0 ^ (nn0 >> 26) ^ ((nn0 >> 11) & (nn0 >> 13)) ^ \
		((nn0 >> 17) & (nn0 >> 18)) ^ ((nn0 >> 22) & (nn0 >> 24) & (nn0 >> 25)));

	return res;
}

// operations of g-function that use nn1 as input
static inline u32 grain_gnn1(u32 nn1hi, u32 nn1lo)
{
	u64 nn1 = (((u64) nn1hi) << 32) | nn1lo;
	u32 res = (u32) ((nn1 >> 24) ^ ((nn1 >> 8) & (nn1 >> 16)));

	return res;
}

// operations of g-function that use nn2 as input
static inline u32 grain_gnn2(u32 nn2hi, u32 nn2lo)
{
	u64 nn2 = (((u64) nn2hi) << 32) | nn2lo;
	u32 res;

	res = nn2hi ^ ((u32) (((nn2 >> 4) & (nn2 >> 20)) ^          \
		((nn2 >> 24) & (nn2 >> 28) & (nn2 >> 29) & (nn2 >> 31)) ^ \
		((nn2 >> 6) & (nn2 >> 14) & (nn2 >> 18)) ^ (nn2 >> 27)));

	return res;
}

// operations of h-function that use nn0 as input
static inline u32 grain_hnn0(u32 nn0hi, u32 nn0lo)
{
	u64 nn0 = (((u64) nn0hi) << 32) | nn0lo;
	u32 res = (u32) ((nn0 >> 2) ^ (nn0 >> 15));

	return res;
}

// operations of h-function that use nn1 as input
static inline u32 grain_hnn1(u32 nn1hi, u32 nn1lo)
{
	u64 nn1 = (((u64) nn1hi) << 32) | nn1lo;
	u32 res = (u32) ((nn1 >> 4) ^ (nn1 >> 13));

	return res;
}

// operations of h-function that use nn2 as input
static inline u32 grain_hnn2(u32 nn2hi, u32 nn2lo)
{
	u64 nn2 = (((u64) nn2hi) << 32) | nn2lo;
	u32 res = (u32) (nn2 ^ (nn2 >> 9) ^ (nn2 >> 25));

	return res;
}

// operations of h-function that use ln0 as input
static inline u32 grain_hln0(u32 ln0hi, u32 ln0lo)
{
	u64 ln0 = (((u64) ln0hi) << 32) | ln0lo;
	u32 res = (u32) ((ln0 >> 13) & (ln0 >> 20));

	return res;
}


// ise-supported version of grain_keystream32
u32 grain_keystream32_ise(grain_ctx *grain)
{
	u32 *lptr = (u32 *) grain->lfsr;  // lsfr is hopefully word-aligned
	u32 *nptr = (u32 *) grain->nfsr;  // nsfr is hopefully word-aligned

	u32 ln0 = lptr[0], ln1 = lptr[1], ln2 = lptr[2], ln3 = lptr[3];
	u32 nn0 = nptr[0], nn1 = nptr[1], nn2 = nptr[2], nn3 = nptr[3];
	u32 tmp;

	// g-function
	tmp = ln0 ^ grain_gnn0(nn1, nn0) ^ grain_gnn1(nn2, nn1) ^ grain_gnn2(nn3, nn2) ^  \
		(grain_extr(nn1, nn0,  3) & grain_extr(nn3, nn2,  3)) ^ \
		(grain_extr(nn2, nn1, 29) & grain_extr(nn3, nn2,  1)) ^ \
		(grain_extr(nn1, nn0, 27) & grain_extr(nn2, nn1, 27));

	nptr[0] = nptr[1];
	nptr[1] = nptr[2];
	nptr[2] = nptr[3];
	nptr[3] = tmp;

	// f-function
	tmp =  grain_fln2(ln3, ln2) ^ grain_extr(ln2, ln1, 6) ^ grain_fln0(ln1, ln0);

	lptr[0] = lptr[1];
	lptr[1] = lptr[2];
	lptr[2] = lptr[3];
	lptr[3] = tmp;

	// h-function
	tmp = grain_hnn0(nn1, nn0) ^ grain_hnn1(nn2, nn1) ^ grain_hnn2(nn3, nn2) ^ \
		grain_hln0(ln1, ln0) ^ grain_extr(ln3, ln2, 29) ^       \
		(grain_extr(nn1, nn0, 12) & grain_extr(ln1, ln0,  8)) ^ \
		(grain_extr(nn3, nn2, 31) & grain_extr(ln2, ln1, 10)) ^ \
		(grain_extr(ln2, ln1, 28) & grain_extr(ln3, ln2, 15)) ^ \
		(grain_extr(nn1, nn0, 12) & grain_extr(nn3, nn2, 31) & grain_extr(ln3, ln2, 30));

	return tmp;
}



void test_grain_keystream32(void)
{
	grain_ctx grainctx;
	grain_ctx *grain = &grainctx;
	u8 iv[12] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 };
	u8 key[16] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
	u32 ks;
	int i;

	// load key, and IV along with padding
	memcpy(grain->nfsr, key, 16);
	memcpy(grain->lfsr, iv, 12);
	L32(12) = 0x7fffffffUL;
	// test latest version of grain_keystream32
	printf("original version of grain_keystream32():\n");
	for (i = -10; i < 2; i++)
	{
		ks = grain_keystream32(grain);
		printf("%08x ", ks);
		L32(12) ^= ks;
		N32(12) ^= ks;
		if (i < 0) continue;
		L32(12) ^= ((u32*) key)[i + 2];
		N32(12) ^= ((u32*) key)[i];
	}
	printf("\n");

	// load key, and IV along with padding
	memcpy(grain->nfsr, key, 16);
	memcpy(grain->lfsr, iv, 12);
	L32(12) = 0x7fffffffUL;
	// test aligned version of grain_keystream32
	printf("aligned version of grain_keystream32():\n");
	for (i = -10; i < 2; i++)
	{
		ks = grain_keystream32_aligned(grain);
		printf("%08x ", ks);
		L32(12) ^= ks;
		N32(12) ^= ks;
		if (i < 0) continue;
		L32(12) ^= ((u32*) key)[i + 2];
		N32(12) ^= ((u32*) key)[i];
	}
	printf("\n");

	// load key, and IV along with padding
	memcpy(grain->nfsr, key, 16);
	memcpy(grain->lfsr, iv, 12);
	L32(12) = 0x7fffffffUL;
	// test ise version of grain_keystream32
	printf("ise version of grain_keystream32():\n");
	for (i = -10; i < 2; i++)
	{
		ks = grain_keystream32_ise(grain);
		printf("%08x ", ks);
		L32(12) ^= ks;
		N32(12) ^= ks;
		if (i < 0) continue;
		L32(12) ^= ((u32*) key)[i + 2];
		N32(12) ^= ((u32*) key)[i];
	}
	printf("\n");

#if defined(__riscv_xlen) && (__riscv_xlen == 32)
	// load key, and IV along with padding
	memcpy(grain->nfsr, key, 16);
	memcpy(grain->lfsr, iv, 12);
	L32(12) = 0x7fffffffUL;
	// test asm version of grain_keystream32
	printf("asm version of grain_keystream32():\n");
	for (i = -10; i < 2; i++)
	{
#ifdef GRAIN_RV32_TYPE1
		ks = grain_keystream32_rv32(grain);
#endif
		printf("%08x ", ks);
		L32(12) ^= ks;
		N32(12) ^= ks;
		if (i < 0) continue;
		L32(12) ^= ((u32*) key)[i + 2];
		N32(12) ^= ((u32*) key)[i];
	}
	printf("\n");
#endif
}



#define MAX_AD_LEN  256
#define MAX_MSG_LEN 256

#define CRYPTO_KEYBYTES	16
#define CRYPTO_NSECBYTES 0
#define CRYPTO_NPUBBYTES 12
#define CRYPTO_ABYTES 8
#define CRYPTO_NOOVERLAP 1

static void init_buffer(u8 *buffer, size_t len)
{
	size_t i;

	for (i = 0; i < len; i++)
		buffer[i] = (u8) i;
}

static void print_buffer(const char *str, const u8 *buffer, size_t len)
{
	size_t i;
 
	if ((str != NULL) && (strlen(str) > 0))
		printf(str);
	for (i = 0; i < len; i++)
		printf("%02X", buffer[i]);
	printf("\n");
}

void test_grain128(void)
{
	u8 c[MAX_MSG_LEN + CRYPTO_ABYTES], m[MAX_MSG_LEN], ad[MAX_AD_LEN];
	u8 npub[CRYPTO_NPUBBYTES], k[CRYPTO_KEYBYTES];
	u64 adlen, clen, mlen;

	init_buffer(m, MAX_MSG_LEN);
	init_buffer(ad, MAX_AD_LEN);
	init_buffer(npub, CRYPTO_NPUBBYTES);
	init_buffer(k, CRYPTO_KEYBYTES);

	adlen = 16; mlen = 16;  // Count = 545 in KAT file
	crypto_aead_encrypt(c, &clen, m, mlen, ad, adlen, NULL, npub, k);
	printf("AEAD output for adlen = %i, mlen = %i:\n", (int) adlen, (int )mlen);
	print_buffer("CT = ", c, (size_t) mlen);
	print_buffer("AT = ", c + mlen, (size_t) CRYPTO_ABYTES);
	// Expected result for Grain-128AEADv2 with adlen = 16 and mlen = 16:
	// CT = 80B53BE28E938BAE76B64CCD53BE4DE5
	// AT = FB0720DE18EA8FAE

	adlen = 32; mlen = 0;  // Count = 33 in KAT file
	crypto_aead_encrypt(c, &clen, m, mlen, ad, adlen, NULL, npub, k);
	printf("AEAD output for adlen = %i, mlen = %i:\n", (int) adlen, (int) mlen);
	print_buffer("CT = ", c, (size_t) mlen);
	print_buffer("AT = ", c + mlen, (size_t) CRYPTO_ABYTES);
	// Expected result for Grain-128AEADv2 with adlen = 32 and mlen = 0:
	// CT = 
	// AT = 41F7A9669AE4779F

	adlen = 128; mlen = 128;
	crypto_aead_encrypt(c, &clen, m, mlen, ad, adlen, NULL, npub, k);
	printf("AEAD output for adlen = %i, mlen = %i:\n", (int) adlen, (int) mlen);
	print_buffer("CT = ", c, (size_t) mlen);
	print_buffer("AT = ", c + mlen, (size_t) CRYPTO_ABYTES);
	// Expected result for Grain-128AEADv2 with adlen = 128 and mlen = 128:
	// CT = 8D11446EE56D3CEA9232367F7A439F33..922D606F9F3EC8231A33063FDA608E84
	// AT = 3EFCB349DFEC8364

	adlen = 0; mlen = 256;
	crypto_aead_encrypt(c, &clen, m, mlen, ad, adlen, NULL, npub, k);
	printf("AEAD output for adlen = %i, mlen = %i:\n", (int) adlen, (int) mlen);
	print_buffer("CT = ", c, (size_t) mlen);
	print_buffer("AT = ", c + mlen, (size_t) CRYPTO_ABYTES);
	// Expected result for Grain-128AEADv2 with adlen = 0 and mlen = 256:
	// CT = 21678706FB8AB6369ED9B5AFA619F8B2..E613AEE1E81EBD49AC9BB087B85BE30F
	// AT = 3BD020C635C0ECDF
}
