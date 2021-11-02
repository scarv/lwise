#include <stdio.h>

#define ROL32(x,n) (((x << (n)) & 0x00000000FFFFFFFF) | ((x & 0x00000000FFFFFFFF) >> (32 - (n))))
#define ROR32(x,n) (((x & 0x00000000FFFFFFFF) >> (n)) | ((x << (32 - (n))) & 0x00000000FFFFFFFF))
#define ROL64(x,n) (((x) << (n)) | ((x) >> (64 - (n))))
#define ROR64(x,n) (((x) >> (n)) | ((x) << (64 - (n))))

static uint64_t lfsr(uint64_t x)
{
  uint64_t bit = (x ^ (x >> 1)) & 1;
  return (x >> 1) | (bit << 62);
}

extern uint64_t test_ror(uint64_t a, uint64_t b);
extern uint64_t test_rol(uint64_t a, uint64_t b);
extern uint64_t test_ror7(uint64_t a);
extern uint64_t test_rorw(uint64_t a, uint64_t b);
extern uint64_t test_rolw(uint64_t a, uint64_t b);
extern uint64_t test_ror7w(uint64_t a);

extern uint64_t test_andn(uint64_t a, uint64_t b);
extern uint64_t test_orn(uint64_t a, uint64_t b);
extern uint64_t test_xnor(uint64_t a, uint64_t b);

extern uint64_t test_pack(uint64_t a, uint64_t b);
extern uint64_t test_packh(uint64_t a, uint64_t b);
extern uint64_t test_packw(uint64_t a, uint64_t b);

extern uint64_t test_brev8(uint64_t a);
extern uint64_t test_rev8(uint64_t a);

extern uint64_t test_xperm8(uint64_t a, uint64_t b);
extern uint64_t test_xperm4(uint64_t a, uint64_t b);

extern uint64_t test_clmul(uint64_t a, uint64_t b);
extern uint64_t test_clmulh(uint64_t a, uint64_t b);

uint64_t gold_ror(uint64_t a, uint64_t b){
    return ROR64(a, b & 0x000000000000003F);
}

uint64_t gold_rorw(uint64_t a, uint64_t b){
    return ROR32(a, b & 0x000000000000001F);
}


uint64_t gold_rol(uint64_t a, uint64_t b){
    return ROL64(a, (b & 0x000000000000003F));
}

uint64_t gold_rolw(uint64_t a, uint64_t b){
    return ROL32(a, b & 0x000000000000001F);
}

uint64_t gold_ror7(uint64_t a){
    return ROR64(a,7);
}

uint64_t gold_ror7w(uint64_t a){
    return ROR32(a,7);
}

uint64_t gold_andn(uint64_t a, uint64_t b){
    return (a & (~b));
}

uint64_t gold_orn(uint64_t a, uint64_t b){
    return (a | (~b));
}

uint64_t gold_xnor(uint64_t a, uint64_t b){
    return (a ^ (~b));
}

uint64_t gold_pack(uint64_t a, uint64_t b){
    return (b << 32) | (a & 0x00000000FFFFFFFF);
}

uint64_t gold_packh(uint64_t a, uint64_t b){
    return ((b << 8) | (a & 0x00000000000000FF)) & 0x000000000000FFFF;
}

uint64_t gold_packw(uint64_t a, uint64_t b){
    return ((b << 16) | (a & 0x000000000000FFFF)) & 0x00000000FFFFFFFF;
}

uint64_t gold_brev8(uint64_t a){
    uint64_t  x;
    x = ((a & 0x5555555555555555) <<  1) | ((a & 0xAAAAAAAAAAAAAAAA) >>  1);
    x = ((x & 0x3333333333333333) <<  2) | ((x & 0xCCCCCCCCCCCCCCCC) >>  2);
    x = ((x & 0x0F0F0F0F0F0F0F0F) <<  4) | ((x & 0xF0F0F0F0F0F0F0F0) >>  4);
    return x;
}
uint64_t gold_rev8(uint64_t a){
    uint64_t  x;
    x = ((a & 0x00FF00FF00FF00FF) <<  8) | ((a & 0xFF00FF00FF00FF00) >>  8);
    x = ((x & 0x0000FFFF0000FFFF) << 16) | ((x & 0xFFFF0000FFFF0000) >> 16);
    x = ((x & 0x00000000FFFFFFFF) << 32) | ((x & 0xFFFFFFFF00000000) >> 32);
    return x;
}

uint64_t gold_xperm8(uint64_t a,uint64_t b){
    uint64_t  lut[256]={0};
    uint64_t  idx[8];
 
    for (int i =0;i<8;i++){
        lut[i] = (a>>(8*i)) & 0xFF;
        idx[i] = (b>>(8*i)) & 0xFF;
    }

    uint64_t x = 0;
    for (int i =0;i<8;i++) x |= (lut[idx[i]] << (8*i));

    return x;
}

uint64_t gold_xperm4(uint64_t a,uint64_t b){
    uint64_t  lut[16]={0};
    uint64_t  idx[16];
 
    for (int i =0;i<16;i++){
        lut[i] = (a>>(4*i)) & 0xF;
        idx[i] = (b>>(4*i)) & 0xF;
    }
    uint64_t x = 0;
    for (int i =0;i<16;i++) x |= (lut[idx[i]] << (4*i));

    return x;
}

uint64_t gold_clmul(uint64_t a,uint64_t b){
    uint64_t x = 0;
    for (int i = 0; i < 64; i++)
        if ((b >> i) & 1) x ^= a << i;
    return x;
}

uint64_t gold_clmulh(uint64_t a,uint64_t b){
    uint64_t x = 0;
    for (int i = 1; i < 64; i++)
        if ((b >> i) & 1) x ^= a >> (64-i);
    return x;
}

int main() {
    
    int fail = 0;

    uint64_t lhs = 0xABCDEF0123456789;
    uint64_t rhs = 0xCAFECAFEDEADBEAD;

    printf("# RV32ZBK Instruction Test \n");

    for (int i=0;i<10;i++){

    printf("lhs: %08lx, rhs: %08lx\n", lhs, rhs);
     
    // ror    
    uint64_t result = test_ror(lhs, rhs);
    uint64_t expect = gold_ror(lhs, rhs);

    if(result != expect) {
        printf("test_ror [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // rorw    
    result = test_rorw(lhs, rhs);
    expect = gold_rorw(lhs, rhs);

    if(result != expect) {
        printf("test_rorw [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // rolw
    result = test_rolw(lhs, rhs);
    expect = gold_rolw(lhs, rhs);

    if(result != expect) {
        printf("test_rolw [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // rol
    result = test_rol(lhs, rhs);
    expect = gold_rol(lhs, rhs);

    if(result != expect) {
        printf("test_rol [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // ror7
    result = test_ror7(lhs);
    expect = gold_ror7(lhs);

    if(result != expect) {
        printf("test_ror7 [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // ror7w
    result = test_ror7w(lhs);
    expect = gold_ror7w(lhs);

    if(result != expect) {
        printf("test_ror7w [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // andn
    result = test_andn(lhs, rhs);
    expect = gold_andn(lhs, rhs);

    if(result != expect) {
        printf("test_andn [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // orn
    result = test_orn(lhs, rhs);
    expect = gold_orn(lhs, rhs);

    if(result != expect) {
        printf("test_orn [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // xnor
    result = test_xnor(lhs, rhs);
    expect = gold_xnor(lhs, rhs);

    if(result != expect) {
        printf("test_xnor [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // pack
    result = test_pack(lhs, rhs);
    expect = gold_pack(lhs, rhs);

    if(result != expect) {
        printf("test_pack [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // packh
    result = test_packh(lhs, rhs);
    expect = gold_packh(lhs, rhs);

    if(result != expect) {
        printf("test_packh [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }
    
    // packh
    result = test_packw(lhs, rhs);
    expect = gold_packw(lhs, rhs);

    if(result != expect) {
        printf("test_packw [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }


    // brev8
    result = test_brev8(lhs);
    expect = gold_brev8(lhs);

    if(result != expect) {
        printf("test_brev8 [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // rev8
    result = test_rev8(lhs);
    expect = gold_rev8(lhs);

    if(result != expect) {
        printf("test_rev8 [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // xperm8
    result = test_xperm8(lhs,rhs);
    expect = gold_xperm8(lhs,rhs);

    if(result != expect) {
        printf("test_xperm8 [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }
    // xperm4
    result = test_xperm4(lhs,rhs);
    expect = gold_xperm4(lhs,rhs);

    if(result != expect) {
        printf("test_xperm4 [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    // clmul
    result = test_clmul(lhs,rhs);
    expect = gold_clmul(lhs,rhs);

    if(result != expect) {
        printf("test_clmul [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }
    // clmulh
    result = test_clmulh(lhs,rhs);
    expect = gold_clmulh(lhs,rhs);

    if(result != expect) {
        printf("test_clmulh [FAIL]\n");
        printf("Expected: %08lx, got: %08lx\n", expect, result);
        fail = 1;
    }

    rhs = lfsr(lhs);
    lhs = lfsr(rhs);
    }
    return fail;

}

