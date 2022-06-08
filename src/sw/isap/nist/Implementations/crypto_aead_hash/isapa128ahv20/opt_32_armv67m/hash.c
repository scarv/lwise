#include "api.h"
#include "crypto_hash.h"
#include "asconp.h"

const unsigned char ASCON_HASH_IV[] = {0x00, 0x40, 0x0c, 0x00, 0x00, 0x00, 0x01, 0x00};

#define P_12L P_LOOP(12)
#define P_12_UROL P_12()

int crypto_hash(unsigned char *out, const unsigned char *in,
                unsigned long long len)
{
    // State and temporary variables
    u32_2 x0, x1, x2, x3, x4;
    u32_2 t0;

    // Initialize
    to_bit_interleaving(&x0, U64BIG(*(u64 *)(ASCON_HASH_IV)));
    x1.o = x1.e = x2.o = x2.e = x3.o = x3.e = x4.o = x4.e = 0;
    P_12L;

    // absorb input
    while (len >= ASCON_128_RATE)
    {
        to_bit_interleaving(&t0, U64BIG(*(u64 *)in));
        x0.e ^= t0.e;
        x0.o ^= t0.o;
        len -= ASCON_128_RATE;
        in += ASCON_128_RATE;
        P_12_UROL;
    }

    /* absorb final input block */
    u64 tmp0 = 0;
    u8 *xo = (u8 *)&tmp0;
    xo[len] = 0x80;
    while(len > 0) {
        xo[len-1] ^= in[len-1];
        len--;
    }
    to_bit_interleaving(&t0, U64BIG(tmp0));
    x0.e ^= t0.e;
    x0.o ^= t0.o;
    P_12L;

    /* squeeze hash */
    u64 outlen = CRYPTO_BYTES;
    while (outlen > ASCON_128_RATE)
    {
        from_bit_interleaving(&tmp0, x0);
        *(u64 *)out = U64BIG(tmp0);
        P_12L;
        outlen -= ASCON_128_RATE;
        out += ASCON_128_RATE;
    }
    from_bit_interleaving(&tmp0, x0);
    *(u64 *)out = U64BIG(tmp0);

    return 0;
}
