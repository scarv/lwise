#include <stdio.h>

#define ROL32(x,n) (((x) << (n)) | ((x) >> (32 - (n))))
#define ROR32(x,n) (((x) >> (n)) | ((x) << (32 - (n))))
#define ROL64(x,n) (((x) << (n)) | ((x) >> (64 - (n))))
#define ROR64(x,n) (((x) >> (n)) | ((x) << (64 - (n))))

static uint32_t lfsr(uint32_t x)
{
  uint32_t bit = (x ^ (x >> 1)) & 1;
  return (x >> 1) | (bit << 30);
}

extern uint32_t test_ror(uint32_t a, uint32_t b);
extern uint32_t test_rol(uint32_t a, uint32_t b);
extern uint32_t test_ror7(uint32_t a);
extern uint32_t test_andn(uint32_t a, uint32_t b);
extern uint32_t test_orn(uint32_t a, uint32_t b);
extern uint32_t test_xnor(uint32_t a, uint32_t b);

extern uint32_t test_pack(uint32_t a, uint32_t b);
extern uint32_t test_packh(uint32_t a, uint32_t b);
extern uint32_t test_brev8(uint32_t a);
extern uint32_t test_rev8(uint32_t a);
extern uint32_t test_zip(uint32_t a);
extern uint32_t test_unzip(uint32_t a);

extern uint32_t test_xperm8(uint32_t a, uint32_t b);
extern uint32_t test_xperm4(uint32_t a, uint32_t b);

extern uint32_t test_clmul(uint32_t a, uint32_t b);
extern uint32_t test_clmulh(uint32_t a, uint32_t b);

uint32_t gold_ror(uint32_t a, uint32_t b){
    return ROR32(a, b & 0x0000001F);
}

uint32_t gold_rol(uint32_t a, uint32_t b){
    return ROL32(a, b & 0x0000001F);
}

uint32_t gold_ror7(uint32_t a){
    return ROR32(a,7);
}

uint32_t gold_andn(uint32_t a, uint32_t b){
    return (a & (~b));
}

uint32_t gold_orn(uint32_t a, uint32_t b){
    return (a | (~b));
}

uint32_t gold_xnor(uint32_t a, uint32_t b){
    return (a ^ (~b));
}

uint32_t gold_pack(uint32_t a, uint32_t b){
    return (b << 16) | (a & 0x0000FFFF);
}

uint32_t gold_packh(uint32_t a, uint32_t b){
    return ((b << 8) | (a & 0x000000FF)) & 0x0000FFFF;
}

uint32_t gold_brev8(uint32_t a){
    uint32_t  x;
    x = ((a & 0x55555555) <<  1) | ((a & 0xAAAAAAAA) >>  1);
    x = ((x & 0x33333333) <<  2) | ((x & 0xCCCCCCCC) >>  2);
    x = ((x & 0x0F0F0F0F) <<  4) | ((x & 0xF0F0F0F0) >>  4);
    return x;
}
uint32_t gold_rev8(uint32_t a){
    uint32_t  x;
    x = ((a & 0x00FF00FF) <<  8) | ((a & 0xFF00FF00) >>  8);
    x = ((x & 0x0000FFFF) << 16) | ((x & 0xFFFF0000) >> 16);
    return x;
}

uint32_t shfl_st(uint32_t src, uint32_t maskL, uint32_t maskR, int N)
{
    uint32_t x = src & ~(maskL | maskR);
    x |= ((src << N) & maskL) | ((src >> N) & maskR);
    return x;
}

uint32_t gold_zip(uint32_t a){
    uint32_t  x=a;
    x = shfl_st(x, 0x44444444, 0x22222222, 1);
    x = shfl_st(x, 0x30303030, 0x0C0C0C0C, 2);
    x = shfl_st(x, 0x0F000F00, 0x00F000F0, 4);
    x = shfl_st(x, 0x00FF0000, 0x0000FF00, 8);
    return x;
}

uint32_t gold_unzip(uint32_t a){
    uint32_t  x=a;
    x = shfl_st(x, 0x00FF0000, 0x0000FF00, 8);
    x = shfl_st(x, 0x0F000F00, 0x00F000F0, 4);
    x = shfl_st(x, 0x30303030, 0x0C0C0C0C, 2);
    x = shfl_st(x, 0x44444444, 0x22222222, 1);
    return x;
}

uint32_t gold_xperm8(uint32_t a,uint32_t b){
    uint32_t  lut[256]={0};
    uint32_t  idx[4];
 
    for (int i =0;i<4;i++){
        lut[i] = (a>>(8*i)) & 0xFF;
        idx[i] = (b>>(8*i)) & 0xFF;
    }
    uint32_t x = (lut[idx[3]] << 24) | (lut[idx[2]] << 16) | (lut[idx[1]] << 8) | lut[idx[0]];
    return x;
}

uint32_t gold_xperm4(uint32_t a,uint32_t b){
    uint32_t  lut[16]={0};
    uint32_t  idx[8];
 
    for (int i =0;i<8;i++){
        lut[i] = (a>>(4*i)) & 0xF;
        idx[i] = (b>>(4*i)) & 0xF;
    }
    uint32_t x = 0;
    for (int i =0;i<8;i++) x |= (lut[idx[i]] << (4*i));
    return x;
}

uint32_t gold_clmul(uint32_t a,uint32_t b){
    uint32_t x = 0;
    for (int i = 0; i < 32; i++)
        if ((b >> i) & 1) x ^= a << i;
    return x;
}

uint32_t gold_clmulh(uint32_t a,uint32_t b){
    uint32_t x = 0;
    for (int i = 1; i < 32; i++)
        if ((b >> i) & 1) x ^= a >> (32-i);
    return x;
}


int fail;
uint32_t expect, result;

int main() {
    
    fail = 0;

    uint32_t lhs = 0x23456789;
    uint32_t rhs = 0xDEADBEAD;

    printf("# RV32ZBK Instruction Test \n");
    rhs = 0x01020304;
    for (int i=0;i<10;i++){
    printf("lhs: %04x, rhs: %04x\n", lhs, rhs);

    // ror    
    result = test_ror(lhs, rhs);
    expect = gold_ror(lhs, rhs);

    if(result != expect) {
        printf("test_ror [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // rol
    result = test_rol(lhs, rhs);
    expect = gold_rol(lhs, rhs);

    if(result != expect) {
        printf("test_rol [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // ror7
    result = test_ror7(lhs);
    expect = gold_ror7(lhs);

    if(result != expect) {
        printf("test_ror7 [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // andn
    result = test_andn(lhs, rhs);
    expect = gold_andn(lhs, rhs);

    if(result != expect) {
        printf("test_andn [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // orn
    result = test_orn(lhs, rhs);
    expect = gold_orn(lhs, rhs);

    if(result != expect) {
        printf("test_orn [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // xnor
    result = test_xnor(lhs, rhs);
    expect = gold_xnor(lhs, rhs);

    if(result != expect) {
        printf("test_chacha_bc_v1 [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // pack
    result = test_pack(lhs, rhs);
    expect = gold_pack(lhs, rhs);

    if(result != expect) {
        printf("test_pack [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // packh
    result = test_packh(lhs, rhs);
    expect = gold_packh(lhs, rhs);

    if(result != expect) {
        printf("test_packh [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // brev8
    result = test_brev8(lhs);
    expect = gold_brev8(lhs);

    if(result != expect) {
        printf("test_brev8 [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // rev8
    result = test_rev8(lhs);
    expect = gold_rev8(lhs);

    if(result != expect) {
        printf("test_rev8 [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // zip
    result = test_zip(lhs);
    expect = gold_zip(lhs);

    if(result != expect) {
        printf("test_zip [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // unzip
    result = test_unzip(lhs);
    expect = gold_unzip(lhs);

    if(result != expect) {
        printf("test_unzip [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // xperm8
    result = test_xperm8(lhs,rhs);
    expect = gold_xperm8(lhs,rhs);

    if(result != expect) {
        printf("test_xperm8 [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }
    // xperm4
    result = test_xperm4(lhs,rhs);
    expect = gold_xperm4(lhs,rhs);

    if(result != expect) {
        printf("test_xperm4 [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    // clmul
    result = test_clmul(lhs,rhs);
    expect = gold_clmul(lhs,rhs);

    if(result != expect) {
        printf("test_clmul [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }
    // clmulh
    result = test_clmulh(lhs,rhs);
    expect = gold_clmulh(lhs,rhs);

    if(result != expect) {
        printf("test_clmulh [FAIL]\n");
        printf("Expected: %04x, got: %04x\n", expect, result);
        fail = 1;
    }

    rhs = lfsr(lhs);
    lhs = lfsr(rhs);
    }
    return fail;

}

