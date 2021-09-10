#include <stdint.h>


///////////////////////////////////////////////////////////////////////////////
//////////////////// MACROS FOR (FIX-SLICED) KEY-SCHEDULE /////////////////////
///////////////////////////////////////////////////////////////////////////////


#define U32BIG(x)											                         \
    ((((x) & 0x000000FF) << 24) | (((x) & 0x0000FF00) <<  8) | \
     (((x) & 0x00FF0000) >>  8) | (((x) & 0xFF000000) >> 24))


#define U8BIG(x, y)                   \
    do {                              \
        (x)[0] =  (y) >> 24;          \
        (x)[1] = ((y) >> 16) & 0xff;  \
        (x)[2] = ((y) >>  8) & 0xff;  \
        (x)[3] =  (y)        & 0xff;  \
    } while(0)


#define SWAPMOVE(a, b, mask, n)       \
    do {                              \
        tmp = (b ^ (a >> n)) & mask;  \
        b ^= tmp;                     \
        a ^= (tmp << n);              \
    } while(0)


#define REARRANGE_RKEY_0(x)              \
    do {                                 \
        SWAPMOVE(x, x, 0x00550055, 9);   \
        SWAPMOVE(x, x, 0x000f000f, 12);  \
        SWAPMOVE(x, x, 0x00003333, 18);  \
        SWAPMOVE(x, x, 0x000000ff, 24);  \
    } while(0)


#define REARRANGE_RKEY_1(x)              \
    do {                                 \
        SWAPMOVE(x, x, 0x11111111, 3);   \
        SWAPMOVE(x, x, 0x03030303, 6);   \
        SWAPMOVE(x, x, 0x000f000f, 12);  \
        SWAPMOVE(x, x, 0x000000ff, 24);  \
    } while(0)


#define REARRANGE_RKEY_2(x)              \
    do {                                 \
        SWAPMOVE(x, x, 0x0000aaaa, 15);  \
        SWAPMOVE(x, x, 0x00003333, 18);  \
        SWAPMOVE(x, x, 0x0000f0f0, 12);  \
        SWAPMOVE(x, x, 0x000000ff, 24);  \
    } while(0)


#define REARRANGE_RKEY_3(x)              \
    do {                                 \
        SWAPMOVE(x, x, 0x0a0a0a0a, 3);   \
        SWAPMOVE(x, x, 0x00cc00cc, 6);   \
        SWAPMOVE(x, x, 0x0000f0f0, 12);  \
        SWAPMOVE(x, x, 0x000000ff, 24);  \
    } while(0)


#define KEY_UPDATE(x)                                          \
    ((((x) >> 12) & 0x0000000f) | (((x) & 0x00000fff) << 4) |  \
     (((x) >>  2) & 0x3fff0000) | (((x) & 0x00030000) << 14))


#define KEY_DOUBLE_UPDATE_1(x)                                \
    ((((x) >> 4) & 0x0f000f00) | (((x) & 0x0f000f00) << 4) |  \
     (((x) >> 6) & 0x00030003) | (((x) & 0x003f003f) << 2))


#define KEY_DOUBLE_UPDATE_2(x)  \
    (ROR((x) & 0xaaaaaaaa, 24) | ROR((x) & 0x55555555, 16))


#define KEY_DOUBLE_UPDATE_3(x)                                \
    ((((x) >> 2) & 0x03030303) | (((x) & 0x03030303) << 2) |  \
     (((x) >> 1) & 0x70707070) | (((x) & 0x10101010) << 3))


#define KEY_DOUBLE_UPDATE_4(x)                                  \
    ((((x) >> 4) & 0x0fff0000) | (((x) & 0x000f0000) << 12) | 	\
     (((x) >> 8) & 0x000000ff) | (((x) & 0x000000ff) <<  8))


#define KEY_TRIPLE_UPDATE_0(x)  \
    (ROR((x) & 0x33333333, 24) 	| ROR((x) & 0xcccccccc, 16))


#define KEY_TRIPLE_UPDATE_1(x)                                \
    ((((x) >> 6) & 0x03000300) | (((x) & 0x3f003f00) << 2) |  \
     (((x) >> 5) & 0x00070007) | (((x) & 0x001f001f) << 3))


#define KEY_TRIPLE_UPDATE_2(x)  \
    (ROR((x) & 0x55555555, 24) | ROR((x) & 0xaaaaaaaa, 20))


#define KEY_TRIPLE_UPDATE_3(x)                                  \
    ((((x) >> 18) & 0x00003030) | (((x) & 0x01010101) <<  3) |  \
     (((x) >> 14) & 0x0000c0c0) | (((x) & 0x0000e0e0) << 15) |  \
     (((x) >>  1) & 0x07070707) | (((x) & 0x00001010) << 19))


#define KEY_TRIPLE_UPDATE_4(x)                                  \
    ((((x) >>  6) & 0x03ff0000) | (((x) & 0x003f0000) << 10) |  \
     (((x) >>  4) & 0x00000fff) | (((x) & 0x0000000f) << 12))


///////////////////////////////////////////////////////////////////////////////
////////////////////// MACROS FOR (FIX-SLICED) ENCRYPTION /////////////////////
///////////////////////////////////////////////////////////////////////////////


#define ROR(x, y) (((x) >> (y)) | ((x) << (32 - (y))))


// SWAR rotation of eight nibbles in a 32-bit word

#define NIBBLE_ROR_1(x)	((((x) >> 1) & 0x77777777) | (((x) & 0x11111111) << 3))
#define NIBBLE_ROR_2(x)	((((x) >> 2) & 0x33333333) | (((x) & 0x33333333) << 2))
#define NIBBLE_ROR_3(x) ((((x) >> 3) & 0x11111111) | (((x) & 0x77777777) << 1))


// SWAR rotation of four bytes in a 32-bit word

#define BYTE_ROR_2(x) ((((x) >> 2) & 0x3f3f3f3f) | (((x) & 0x03030303) << 6))
#define BYTE_ROR_4(x) ((((x) >> 4) & 0x0f0f0f0f) | (((x) & 0x0f0f0f0f) << 4))
#define BYTE_ROR_6(x) ((((x) >> 6) & 0x03030303) | (((x) & 0x3f3f3f3f) << 2))


// SWAR rotation of two halfwords in a 32-bit word

#define HALF_ROR_4(x)  ((((x) >>  4) & 0x0fff0fff) | (((x) & 0x000f000f) << 12))
#define HALF_ROR_8(x)  ((((x) >>  8) & 0x00ff00ff) | (((x) & 0x00ff00ff) <<  8))
#define HALF_ROR_12(x) ((((x) >> 12) & 0x000f000f) | (((x) & 0x0fff0fff) <<  4))


#define SBOX(s0, s1, s2, s3)  \
    do {                      \
        s1 ^= s0 & s2;        \
        s0 ^= s1 & s3;        \
        s2 ^= s0 | s1;        \
        s3 ^= s2;             \
        s1 ^= s3;             \
        s3 ^= 0xffffffff;     \
        s2 ^= s0 & s1;        \
    } while(0)


#define QUINTUPLE_ROUND(state, rkey, rconst)           \
    do {                                               \
        SBOX(state[0], state[1], state[2], state[3]);  \
        state[3] = NIBBLE_ROR_1(state[3]);             \
        state[1] = NIBBLE_ROR_2(state[1]);             \
        state[2] = NIBBLE_ROR_3(state[2]);             \
        state[1] ^= (rkey)[0];                         \
        state[2] ^= (rkey)[1];                         \
        state[0] ^= (rconst)[0];                       \
        SBOX(state[3], state[1], state[2], state[0]);  \
        state[0] = HALF_ROR_4(state[0]);               \
        state[1] = HALF_ROR_8(state[1]);               \
        state[2] = HALF_ROR_12(state[2]);              \
        state[1] ^= (rkey)[2];                         \
        state[2] ^= (rkey)[3];                         \
        state[3] ^= (rconst)[1];                       \
        SBOX(state[0], state[1], state[2], state[3]);  \
        state[3] = ROR(state[3], 16);                  \
        state[2] = ROR(state[2], 16);                  \
        SWAPMOVE(state[1], state[1], 0x55555555, 1);   \
        SWAPMOVE(state[2], state[2], 0x00005555, 1);   \
        SWAPMOVE(state[3], state[3], 0x55550000, 1);   \
        state[1] ^= (rkey)[4];                         \
        state[2] ^= (rkey)[5];                         \
        state[0] ^= (rconst)[2];                       \
        SBOX(state[3], state[1], state[2], state[0]);  \
        state[0] = BYTE_ROR_6(state[0]);               \
        state[1] = BYTE_ROR_4(state[1]);               \
        state[2] = BYTE_ROR_2(state[2]);               \
        state[1] ^= (rkey)[6];                         \
        state[2] ^= (rkey)[7];                         \
        state[3] ^= (rconst)[3];                       \
        SBOX(state[0], state[1], state[2], state[3]);  \
        state[3] = ROR(state[3], 24);                  \
        state[1] = ROR(state[1], 16);                  \
        state[2] = ROR(state[2], 8);                   \
        state[1] ^= (rkey)[8];                         \
        state[2] ^= (rkey)[9];                         \
        state[0] ^= (rconst)[4];                       \
        state[0] ^= state[3];                          \
        state[3] ^= state[0];                          \
        state[0] ^= state[3];                          \
    } while(0)


///////////////////////////////////////////////////////////////////////////////
/////////// FUNCTIONS FOR (FIX-SLICED) KEY-SCHEDULE AND ENCRYPTION ////////////
///////////////////////////////////////////////////////////////////////////////


// The round constants according to the fixsliced representation

const uint32_t rconst[40] = {
    0x10000008, 0x80018000, 0x54000002, 0x01010181,
    0x8000001f, 0x10888880, 0x6001e000, 0x51500002,
    0x03030180, 0x8000002f, 0x10088880, 0x60016000,
    0x41500002, 0x03030080, 0x80000027, 0x10008880,
    0x4001e000, 0x11500002, 0x03020180, 0x8000002b,
    0x10080880, 0x60014000, 0x01400002, 0x02020080,
    0x80000021, 0x10000080, 0x0001c000, 0x51000002,
    0x03010180, 0x8000002e, 0x10088800, 0x60012000,
    0x40500002, 0x01030080, 0x80000006, 0x10008808,
    0xc001a000, 0x14500002, 0x01020181, 0x8000001a
};


// The first 20 rkeys are computed using the classical representation before
// being rearranged into fixsliced representation depending on round number.
// The 60 remaining rkeys are directly computed in fixscliced representation.

void precompute_rkeys(uint32_t* rkey, const uint8_t* key)
{
    uint32_t tmp;
    int i;

    // classical initialization
    rkey[0] = U32BIG(((uint32_t *) key)[3]);
    rkey[1] = U32BIG(((uint32_t *) key)[1]);
    rkey[2] = U32BIG(((uint32_t *) key)[2]);
    rkey[3] = U32BIG(((uint32_t *) key)[0]);

    // classical key-schedule
    for(i = 0; i < 16; i += 2) {
        rkey[i+4] = rkey[i+1];
        rkey[i+5] = KEY_UPDATE(rkey[i]);
    }

    // transposition to fixsliced representation
    for(i = 0; i < 20; i += 10) {
        REARRANGE_RKEY_0(rkey[i]);
        REARRANGE_RKEY_0(rkey[i+1]);
        REARRANGE_RKEY_1(rkey[i+2]);
        REARRANGE_RKEY_1(rkey[i+3]);
        REARRANGE_RKEY_2(rkey[i+4]);
        REARRANGE_RKEY_2(rkey[i+5]);
        REARRANGE_RKEY_3(rkey[i+6]);
        REARRANGE_RKEY_3(rkey[i+7]);
    }

    // key-schedule according to fixsliced representation
    for(i = 20; i < 80; i += 10) {
        rkey[i] = rkey[i-19];
        rkey[i+1] = KEY_TRIPLE_UPDATE_0(rkey[i-20]);
        rkey[i+2] = KEY_DOUBLE_UPDATE_1(rkey[i-17]);
        rkey[i+3] = KEY_TRIPLE_UPDATE_1(rkey[i-18]);
        rkey[i+4] = KEY_DOUBLE_UPDATE_2(rkey[i-15]);
        rkey[i+5] = KEY_TRIPLE_UPDATE_2(rkey[i-16]);
        rkey[i+6] = KEY_DOUBLE_UPDATE_3(rkey[i-13]);
        rkey[i+7] = KEY_TRIPLE_UPDATE_3(rkey[i-14]);
        rkey[i+8] = KEY_DOUBLE_UPDATE_4(rkey[i-11]);
        rkey[i+9] = KEY_TRIPLE_UPDATE_4(rkey[i-12]);
        SWAPMOVE(rkey[i], rkey[i], 0x00003333, 16);
        SWAPMOVE(rkey[i], rkey[i], 0x55554444, 1);
        SWAPMOVE(rkey[i+1], rkey[i+1], 0x55551100, 1);
    }
}


// Encryption of a single 128-bit block with GIFTb-128 (used in GIFT-COFB).

void giftb128(uint8_t* ctext, const uint8_t* ptext, const uint32_t* rkey) 
{
    uint32_t tmp, state[4];

    // Conversion Big Endian to Little Endian
    state[0] = U32BIG(((uint32_t *) ptext)[0]);
    state[1] = U32BIG(((uint32_t *) ptext)[1]);
    state[2] = U32BIG(((uint32_t *) ptext)[2]);
    state[3] = U32BIG(((uint32_t *) ptext)[3]);

    // Eight quintuple rounds (40 rounds altogether)
    QUINTUPLE_ROUND(state, rkey, rconst);
    QUINTUPLE_ROUND(state, rkey + 10, rconst + 5);
    QUINTUPLE_ROUND(state, rkey + 20, rconst + 10);
    QUINTUPLE_ROUND(state, rkey + 30, rconst + 15);
    QUINTUPLE_ROUND(state, rkey + 40, rconst + 20);
    QUINTUPLE_ROUND(state, rkey + 50, rconst + 25);
    QUINTUPLE_ROUND(state, rkey + 60, rconst + 30);
    QUINTUPLE_ROUND(state, rkey + 70, rconst + 35);

    // Conversion Little Endian to Big Endian
    U8BIG(ctext, state[0]);
    U8BIG(ctext + 4, state[1]);
    U8BIG(ctext + 8, state[2]);
    U8BIG(ctext + 12, state[3]);
}


// Print a byte-string in hex format

static void print_bytes(const char *name, const uint8_t *bytes, int len)
{
    int i;

    if ((name != NULL) && (strlen(name) > 0)) {
        printf("%s", name);
    }
    for (i = 0; i < len; i++) {
        printf("%02X", bytes[i]);
    }
    printf("\n");
}


// Simple test function

void test_giftb128(void)
{
    uint8_t ctext[16];
    uint8_t ptext[16] = { 0 };
    uint32_t key[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    uint32_t rkey[80];

    print_bytes("plaintext : ", ptext, 16);
    print_bytes("masterkey : ", (uint8_t *) key, 16);
    precompute_rkeys(rkey, (uint8_t *) key);
    giftb128(ctext, ptext, rkey);
    print_bytes("ciphertext: ", ctext, 16);

    // Expected result:
    // plaintext : 00000000000000000000000000000000
    // masterkey : 0123456789ABCDEFFEDCBA9876543210
    // ciphertext: 0C9B414C744858846A98715ABBCC1AA6
}

