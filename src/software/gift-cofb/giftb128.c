#include <assert.h>
#include <stdint.h>
#include <stdio.h>


static const uint32_t NIBBLE_MASK[4] = { \
    0x00000000, 0x11111111, 0x33333333, 0x77777777  \
};

static const uint32_t BYTE_MASK[8] = { \
    0x00000000, 0x01010101, 0x03030303, 0x07070707,  \
    0x0F0F0F0F, 0x1F1F1F1F, 0x3F3F3F3F, 0x7F7F7F7F   \
};

static const uint32_t HALF_MASK[16] = { \
    0x00000000, 0x00010001, 0x00030003, 0x00070007,  \
    0x000F000F, 0x001F001F, 0x003F003F, 0x007F007F,  \
    0x00FF00FF, 0x01FF01FF, 0x03FF03FF, 0x07FF07FF,  \
    0x0FFF0FFF, 0x1FFF1FFF, 0x3FFF3FFF, 0x7FFF7FFF   \
};


///////////////////////////////////////////////////////////////////////////////
///////// CUSTOM INSTRUCTIONS (FIX-SLICED) KEY-SCHEDULE AND ENCRYPTION ////////
///////////////////////////////////////////////////////////////////////////////


uint32_t ReverseByteOrder(uint32_t x)
{
    uint32_t r;
    
    r  = x >> 24;
    r |= ((((x) >> 16) & 0xff) <<  8);
    r |= ((((x) >> 8 ) & 0xff) << 16);
    r |= (x << 24);

    return r;
}


uint32_t SwapMove(uint32_t x, uint32_t mask, int n)
{
    uint32_t r;

    r  = (x ^ (x >> n)) & mask;
    r ^= (x ^ (r << n));

    return r;
}


// SWAR right-rotation of eight nibbles in a 32-bit word

uint32_t NibbleRor(uint32_t x, int n)
{
    uint32_t r;

    assert((n > 0) && (n < 4));
    r = ((x >> n) & NIBBLE_MASK[4-n]) | ((x & NIBBLE_MASK[n]) << (4 - n));

    return r;
}


// SWAR right-rotation of four bytes in a 32-bit word

uint32_t ByteRor(uint32_t x, int n)
{
    uint32_t r;

    assert((n > 0) && (n < 8));
    r = ((x >> n) & BYTE_MASK[8-n]) | ((x & BYTE_MASK[n]) << (8 - n));

    return r;
}


// SWAR right-rotation of two halfwords in a 32-bit word

uint32_t HalfRor(uint32_t x, int n)
{
    uint32_t r;

    assert((n > 0) && (n < 16));
    r = ((x >> n) & HALF_MASK[16 - n]) | ((x & HALF_MASK[n]) << (16 - n));

    return r;
}


// Right-rotation of a 32-bit word

uint32_t WordRor(uint32_t x, int n)
{
    uint32_t r;

    assert((n > 0) && (n < 32));
    r = (x >> n) | (x << (32 - n));

    return r;
}


uint32_t RearrangeKey(uint32_t x, int n)
{
    uint32_t r;

    switch(n) {
        case 0:  // macro REARRANGE_RKEY_0
            r = SwapMove(x, 0x00550055,  9);
            r = SwapMove(r, 0x00003333, 18);
            r = SwapMove(r, 0x000f000f, 12);
            r = SwapMove(r, 0x000000ff, 24);
            break;
        case 1:  // macro REARRANGE_RKEY_1
            r = SwapMove(x, 0x11111111,  3);
            r = SwapMove(r, 0x03030303,  6);
            r = SwapMove(r, 0x000f000f, 12);
            r = SwapMove(r, 0x000000ff, 24);
            break;
        case 2:  // macro REARRANGE_RKEY_2
            r = SwapMove(x, 0x0000aaaa, 15);
            r = SwapMove(r, 0x00003333, 18);
            r = SwapMove(r, 0x0000f0f0, 12);
            r = SwapMove(r, 0x000000ff, 24);
            break;
        case 3:  // macro REARRANGE_RKEY_3
            r = SwapMove(x, 0x0a0a0a0a,  3);
            r = SwapMove(r, 0x00cc00cc,  6);
            r = SwapMove(r, 0x0000f0f0, 12);
            r = SwapMove(r, 0x000000ff, 24);
            break;
        default:
            printf("RearrangeKey: Invalid parameter n = %i !!!\n", n);
            break;
    } 
    
    return r;
}


uint32_t ClassicalKeyUpdate(uint32_t x)
{
    uint32_t r;

    r  = ((x >> 12) & 0x0000000f) | ((x & 0x00000fff) <<  4);
    r |= ((x >>  2) & 0x3fff0000) | ((x & 0x00030000) << 14);

    return r;
}


uint32_t FixslicedKeyUpdate(uint32_t x, int n)
{
    uint32_t r;

    switch (n) {
        case 0:  // two SwapMove operations
            r = SwapMove(x, 0x00003333, 16);
            r = SwapMove(r, 0x55554444,  1);
            break;
        case 1:  // macro KEY_TRIPLE_UPDATE_0 + SwapMove
            r = WordRor(x & 0x33333333, 24) | WordRor(x & 0xcccccccc, 16);
            r = SwapMove(r, 0x55551100, 1);
            break;
        case 2:  // macro KEY_DOUBLE_UPDATE_1
            r  = ((x >> 4) & 0x0f000f00) | ((x & 0x0f000f00) << 4);
            r |= ((x >> 6) & 0x00030003) | ((x & 0x003f003f) << 2);
            break;
        case 3:  // macro KEY_TRIPLE_UPDATE_1
            r  = ((x >> 6) & 0x03000300) | ((x & 0x3f003f00) << 2);
            r |= ((x >> 5) & 0x00070007) | ((x & 0x001f001f) << 3);
            break;
        case 4:  // macro KEY_DOUBLE_UPDATE_2
            r = WordRor(x & 0xaaaaaaaa, 24) | WordRor(x & 0x55555555, 16);
            break;
        case 5:  // macro KEY_TRIPLE_UPDATE_2
            r = WordRor(x & 0x55555555, 24) | WordRor(x & 0xaaaaaaaa, 20);
            break;
        case 6:  // macro KEY_DOUBLE_UPDATE_3
            r  = ((x >> 2) & 0x03030303) | ((x & 0x03030303) << 2);
            r |= ((x >> 1) & 0x70707070) | ((x & 0x10101010) << 3);
            break;
        case 7:  // macro KEY_TRIPLE_UPDATE_3
            r  = ((x >> 18) & 0x00003030) | ((x & 0x01010101) <<  3);
            r |= ((x >> 14) & 0x0000c0c0) | ((x & 0x0000e0e0) << 15);
            r |= ((x >>  1) & 0x07070707) | ((x & 0x00001010) << 19);
            break;
        case 8:  // macro KEY_DOUBLE_UPDATE_4
            r  = ((x >> 4) & 0x0fff0000) | ((x & 0x000f0000) << 12);
            r |= ((x >> 8) & 0x000000ff) | ((x & 0x000000ff) <<  8);
            break;
        case 9:  // macro KEY_TRIPLE_UPDATE_4
            r  = ((x >> 6) & 0x03ff0000) | ((x & 0x003f0000) << 10);
            r |= ((x >> 4) & 0x00000fff) | ((x & 0x0000000f) << 12);
            break;
        default:
            printf("FixslicedKeyUpdate: Invalid parameter n = %i !!!\n", n);
            break;
    }

    return r;
}


///////////////////////////////////////////////////////////////////////////////
////////////////////// MACROS FOR (FIX-SLICED) ENCRYPTION /////////////////////
///////////////////////////////////////////////////////////////////////////////


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
        state[3] = NibbleRor(state[3], 1);             \
        state[1] = NibbleRor(state[1], 2);             \
        state[2] = NibbleRor(state[2], 3);             \
        state[1] ^= (rkey)[0];                         \
        state[2] ^= (rkey)[1];                         \
        state[0] ^= (rconst)[0];                       \
        SBOX(state[3], state[1], state[2], state[0]);  \
        state[0] = HalfRor(state[0], 4);               \
        state[1] = HalfRor(state[1], 8);               \
        state[2] = HalfRor(state[2], 12);              \
        state[1] ^= (rkey)[2];                         \
        state[2] ^= (rkey)[3];                         \
        state[3] ^= (rconst)[1];                       \
        SBOX(state[0], state[1], state[2], state[3]);  \
        state[3] = WordRor(state[3], 16);              \
        state[2] = WordRor(state[2], 16);              \
        state[1] = SwapMove(state[1], 0x55555555, 1);  \
        state[2] = SwapMove(state[2], 0x00005555, 1);  \
        state[3] = SwapMove(state[3], 0x55550000, 1);  \
        state[1] ^= (rkey)[4];                         \
        state[2] ^= (rkey)[5];                         \
        state[0] ^= (rconst)[2];                       \
        SBOX(state[3], state[1], state[2], state[0]);  \
        state[0] = ByteRor(state[0], 6);               \
        state[1] = ByteRor(state[1], 4);               \
        state[2] = ByteRor(state[2], 2);               \
        state[1] ^= (rkey)[6];                         \
        state[2] ^= (rkey)[7];                         \
        state[3] ^= (rconst)[3];                       \
        SBOX(state[0], state[1], state[2], state[3]);  \
        state[3] = WordRor(state[3], 24);              \
        state[1] = WordRor(state[1], 16);              \
        state[2] = WordRor(state[2], 8);               \
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
    int i;

    // classical initialization
    rkey[0] = ReverseByteOrder(((uint32_t *) key)[3]);
    rkey[1] = ReverseByteOrder(((uint32_t *) key)[1]);
    rkey[2] = ReverseByteOrder(((uint32_t *) key)[2]);
    rkey[3] = ReverseByteOrder(((uint32_t *) key)[0]);

    // classical key-schedule
    for(i = 0; i < 16; i += 2) {
        rkey[i+4] = rkey[i+1];
        rkey[i+5] = ClassicalKeyUpdate(rkey[i]);
    }

    // transposition to fixsliced representation
    for(i = 0; i < 20; i += 10) {
        rkey[i  ] = RearrangeKey(rkey[i  ], 0);
        rkey[i+1] = RearrangeKey(rkey[i+1], 0);
        rkey[i+2] = RearrangeKey(rkey[i+2], 1);
        rkey[i+3] = RearrangeKey(rkey[i+3], 1);
        rkey[i+4] = RearrangeKey(rkey[i+4], 2);
        rkey[i+5] = RearrangeKey(rkey[i+5], 2);
        rkey[i+6] = RearrangeKey(rkey[i+6], 3);
        rkey[i+7] = RearrangeKey(rkey[i+7], 3);
    }

    // key-schedule according to fixsliced representation
    for(i = 20; i < 80; i += 10) {
        rkey[i  ] = FixslicedKeyUpdate(rkey[i-19], 0);
        rkey[i+1] = FixslicedKeyUpdate(rkey[i-20], 1);
        rkey[i+2] = FixslicedKeyUpdate(rkey[i-17], 2);
        rkey[i+3] = FixslicedKeyUpdate(rkey[i-18], 3);
        rkey[i+4] = FixslicedKeyUpdate(rkey[i-15], 4);
        rkey[i+5] = FixslicedKeyUpdate(rkey[i-16], 5);
        rkey[i+6] = FixslicedKeyUpdate(rkey[i-13], 6);
        rkey[i+7] = FixslicedKeyUpdate(rkey[i-14], 7);
        rkey[i+8] = FixslicedKeyUpdate(rkey[i-11], 8);
        rkey[i+9] = FixslicedKeyUpdate(rkey[i-12], 9);
    }
}


// Alternative approach to compute the round keys. This version generates all
// round keys in classical representation fist and then they get rearranged
// into fixsliced representation.

void precompute_rkeys_v2(uint32_t* rkey, const uint8_t* key)
{
    int i;

    // classical initialization
    rkey[0] = ReverseByteOrder(((uint32_t *) key)[3]);
    rkey[1] = ReverseByteOrder(((uint32_t *) key)[1]);
    rkey[2] = ReverseByteOrder(((uint32_t *) key)[2]);
    rkey[3] = ReverseByteOrder(((uint32_t *) key)[0]);

    // classical key-schedule
    for (i = 4; i < 80; i += 2) {
        rkey[i  ] = rkey[i-3];
        rkey[i+1] = ClassicalKeyUpdate(rkey[i-4]);
    }

    // transposition to fixsliced representation
    for (i = 0; i < 80; i += 10) {
        rkey[i  ] = RearrangeKey(rkey[i  ], 0);
        rkey[i+1] = RearrangeKey(rkey[i+1], 0);
        rkey[i+2] = RearrangeKey(rkey[i+2], 1);
        rkey[i+3] = RearrangeKey(rkey[i+3], 1);
        rkey[i+4] = RearrangeKey(rkey[i+4], 2);
        rkey[i+5] = RearrangeKey(rkey[i+5], 2);
        rkey[i+6] = RearrangeKey(rkey[i+6], 3);
        rkey[i+7] = RearrangeKey(rkey[i+7], 3);
    }
}


// Encryption of a single 128-bit block with GIFTb-128 (used in GIFT-COFB).

void giftb128(uint8_t* ctext, const uint8_t* ptext, const uint32_t* rkey) 
{
    uint32_t state[4];

    // Conversion Big Endian to Little Endian
    state[0] = ReverseByteOrder(((uint32_t *) ptext)[0]);
    state[1] = ReverseByteOrder(((uint32_t *) ptext)[1]);
    state[2] = ReverseByteOrder(((uint32_t *) ptext)[2]);
    state[3] = ReverseByteOrder(((uint32_t *) ptext)[3]);

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
    ((uint32_t *) ptext)[0] = ReverseByteOrder(state[0]);
    ((uint32_t *) ptext)[1] = ReverseByteOrder(state[1]);
    ((uint32_t *) ptext)[2] = ReverseByteOrder(state[2]);
    ((uint32_t *) ptext)[3] = ReverseByteOrder(state[3]);
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


// Simple test function for GIFTb128

void test_giftb128(void)
{
    uint8_t ctext[16];
    uint8_t ptext[16] = { 0 };
    uint32_t key[4] = { 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    uint32_t rkey[80];

    print_bytes("plaintext : ", ptext, 16);
    print_bytes("masterkey : ", (uint8_t *) key, 16);
    // precompute_rkeys(rkey, (uint8_t *) key);
    precompute_rkeys_v2(rkey, (uint8_t *) key);
    // print_bytes("roundkeys : ", (uint8_t *) rkey, 80);
    giftb128(ctext, ptext, rkey);
    print_bytes("ciphertext: ", ctext, 16);

    // Expected result:
    // plaintext : 00000000000000000000000000000000
    // masterkey : 0123456789ABCDEFFEDCBA9876543210
    // ciphertext: 0C9B414C744858846A98715ABBCC1AA6
}

