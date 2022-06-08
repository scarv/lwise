#include "api.h"
#include "crypto_hash.h"
#include "asconp.h"

int crypto_hash(unsigned char* out, const unsigned char* in,
                unsigned long long len) {

    u8 state[ASCON_128_STATE_SZ];
    u64 x0, x1, x2, x3, x4;
    u64 t0, t1, t2, t3, t4;
    t0 = t1 = t2 = t3 = t4 = 0;

    /* init state */
    x0 = ASCON_HASH_IV;
    x1 = x2 = x3 = x4 = 0;
    P12;

    /* absorb */
    u64 *in64 = (u64*)in;
    while(len >= ASCON_128_RATE){
        x0 ^= U64BIG(*in64);
        P12;
        in64++;
        len -= 8;
    }

    /* absorb final input block */
    u8 *lane8 = (u8*)&x0;
    lane8[ASCON_128_RATE-1-len] ^= 0x80;
    while(len > 0) {
        lane8[ASCON_128_RATE-len] ^= ((u8*)in64)[len-1];
        len--;
    }
    P12;

    // squeeze
    u64 *out64 = (u64 *)out;
    u64 outlen = CRYPTO_BYTES;
    while (outlen > ASCON_128_RATE) {
        *out64 = U64BIG(x0);
        P12;
        out64 += 1;
        outlen -= ASCON_128_RATE;
    }

    /* squeeze final output block */
    *out64 = U64BIG(x0);

  return 0;
}
