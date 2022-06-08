#include <stdio.h>
#include <string.h>
#include "api.h"
#include "isap.h"
#include "asconp.h"

const u8 ISAP_IV1[] = {0x01,ISAP_K,ISAP_rH,ISAP_rB,ISAP_sH,ISAP_sB,ISAP_sE,ISAP_sK};
const u8 ISAP_IV2[] = {0x02,ISAP_K,ISAP_rH,ISAP_rB,ISAP_sH,ISAP_sB,ISAP_sE,ISAP_sK};
const u8 ISAP_IV3[] = {0x03,ISAP_K,ISAP_rH,ISAP_rB,ISAP_sH,ISAP_sB,ISAP_sE,ISAP_sK};

/******************************************************************************/
/*                                   IsapRk                                   */
/******************************************************************************/

void isap_rk(
	const u8 *k,
	const u8 *iv,
	const u8 *y,
	const u64 ylen,
	u8 *out,
	const u64 outlen
){
    const u64 *k64 = (u64 *)k;
    const u64 *iv64 = (u64 *)iv;
    u64 *out64 = (u64 *)out;
    u64 x0, x1, x2, x3, x4;
    u64 t0, t1, t2, t3, t4;

    // Init state
    t0 = t1 = t2 = t3 = t4 = 0;
    x0 = U64BIG(k64[0]);
    x1 = U64BIG(k64[1]);
    x2 = U64BIG(iv64[0]);
    x3 = x4 = 0;
    P12;

    // Absorb Y
    for (size_t i = 0; i < ylen*8-1; i++){
        size_t cur_byte_pos = i/8;
        size_t cur_bit_pos = 7-(i%8);
        u8 cur_bit = ((y[cur_byte_pos] >> (cur_bit_pos)) & 0x01) << 7;
        x0 ^= ((u64)cur_bit) << 56;
        P1;
    }
    u8 cur_bit = ((y[ylen-1]) & 0x01) << 7;
    x0 ^= ((u64)cur_bit) << 56;
    P12;

    // Extract K*
    out64[0] = U64BIG(x0);
    out64[1] = U64BIG(x1);
    if(outlen == 24){
        out64[2] = U64BIG(x2);
    }
}

/******************************************************************************/
/*                                  IsapMac                                   */
/******************************************************************************/

void isap_mac(
    const u8 *k,
    const u8 *npub,
    const u8 *ad, u64 adlen,
    const u8 *c, u64 clen,
    u8 *tag
){
    u8 state[ISAP_STATE_SZ];
    const u64 *npub64 = (u64 *)npub;
    u64 *state64 = (u64 *)state;
    u64 x0, x1, x2, x3, x4;
    u64 t0, t1, t2, t3, t4;
    t0 = t1 = t2 = t3 = t4 = 0;

    // Init state
    x0 = U64BIG(npub64[0]);
    x1 = U64BIG(npub64[1]);
    x2 = U64BIG(((u64 *)ISAP_IV1)[0]);
    x3 = x4 = 0;
    P12;

    /* Absorb ad */
    u64 *ad64 = (u64*)ad;
    while(adlen >= ISAP_rH_SZ){
        x0 ^= U64BIG(*ad64);
        P12;
        ad64++;
        adlen -= ISAP_rH_SZ;
    }

    /* Absorb final ad block */
    u8 *xo = (u8*)&x0;
    xo[ISAP_rH_SZ-1-adlen] ^= 0x80;
    while(adlen > 0) {
        xo[ISAP_rH_SZ-adlen] ^= ((u8*)ad64)[adlen-1];
        adlen--;
    }
    P12;

    // Domain seperation
    x4 ^= 0x0000000000000001ULL;

    /* Absorb c */
    u64 *c64 = (u64*)c;
    while(clen >= ISAP_rH_SZ){
        x0 ^= U64BIG(*c64);
        P12;
        c64++;
        clen -= ISAP_rH_SZ;
    }

    /* Absorb final c block */
    xo[ISAP_rH_SZ-1-clen] ^= 0x80;
    while(clen > 0) {
        xo[ISAP_rH_SZ-clen] ^= ((u8*)c64)[clen-1];
        clen--;
    }
    P12;

    // Derive K*
    state64[0] = U64BIG(x0);
    state64[1] = U64BIG(x1);
    state64[2] = U64BIG(x2);
    state64[3] = U64BIG(x3);
    state64[4] = U64BIG(x4);
    isap_rk(k,ISAP_IV2,(u8 *)state64,CRYPTO_KEYBYTES,(u8 *)state64,CRYPTO_KEYBYTES);
    x0 = U64BIG(state64[0]);
    x1 = U64BIG(state64[1]);
    x2 = U64BIG(state64[2]);
    x3 = U64BIG(state64[3]);
    x4 = U64BIG(state64[4]);

    // Squeeze tag
    P12;
    unsigned long long *tag64 = (u64 *)tag;
    tag64[0] = U64BIG(x0);
    tag64[1] = U64BIG(x1);
}

/******************************************************************************/
/*                                  IsapEnc                                   */
/******************************************************************************/

void isap_enc(
	const u8 *k,
	const u8 *npub,
	const u8 *m,
    u64 mlen,
	u8 *c
){
    u8 state[ISAP_STATE_SZ];

    // Init state
    u64 *state64 = (u64 *)state;
    u64 *npub64 = (u64 *)npub;
    isap_rk(k,ISAP_IV3,npub,CRYPTO_NPUBBYTES,state,ISAP_STATE_SZ-CRYPTO_NPUBBYTES);
    u64 x0, x1, x2, x3, x4;
    u64 t0, t1, t2, t3, t4;
    t0 = t1 = t2 = t3 = t4 = 0;
    x0 = U64BIG(state64[0]);
    x1 = U64BIG(state64[1]);
    x2 = U64BIG(state64[2]);
    x3 = U64BIG(npub64[0]);
    x4 = U64BIG(npub64[1]);
    P6;

    /* Encrypt m */
    u64 *m64 = (u64 *)m;
    u64 *c64 = (u64 *)c;
    while(mlen >= ISAP_rH_SZ){
        *c64 = U64BIG(x0) ^ *m64;
        P6;
        m64++;
        c64++;
        mlen -= ISAP_rH_SZ;
    }

    /* Encrypt final m block */
    u8 *xo = (u8*)&x0;
    while(mlen > 0) {
        ((u8*)c64)[mlen-1] = xo[ISAP_rH_SZ-mlen] ^ ((u8*)m64)[mlen-1];
        mlen--;
    }
}
