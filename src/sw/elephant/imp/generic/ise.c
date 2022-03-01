#include "ise.h"

#define SWAPMOVE32(x, m, n) { \
  uint32_t z = x ^ (x>>n);    \
  z = z & m;                  \
  z = z ^ (z<<n);             \
  x = z ^ x;                  \
}

// permute the 32-bit word bit[31:0] to 
// bit[31:24]  28 24 20 16 12  8  4  0 
// bit[23:16]  29 25 21 17 13  9  5  1 
// bit[15: 8]  30 26 22 18 14 10  6  2 
// bit[ 7: 0]  31 27 23 19 15 11  7  3 

uint32_t spongent_pLayer_step1(uint32_t rs1) 
{
  uint32_t rd = rs1;

  SWAPMOVE32(rd, 0x0A0A0A0AUL,  3); 
  SWAPMOVE32(rd, 0x00CC00CCUL,  6); 
  SWAPMOVE32(rd, 0x0000F0F0UL, 12); 
  SWAPMOVE32(rd, 0x000000FFUL, 24); 
  
  return rd;
}

// -----------------------------------------------------------------------------

// v1

// Q: is it correct that design a custom instruction in the following way? 
//    (especially about rs2)
uint32_t spongent_BUP(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t0 = imm - rs2;
  uint32_t t1 = rs1 << t0;
  uint32_t t2 = (uint32_t) 1 << imm;
  uint32_t rd = t1 & t2;

  return rd;
}

uint32_t spongent_BSLLXOR(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t0 = rs2 & 0xFF;
  uint32_t t1 = t0 << imm;
  uint32_t rd = rs1 ^ t1;

  return rd;
}

// -----------------------------------------------------------------------------

// v2

uint32_t spongent_DBUP(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t0 = imm - rs2;
  uint32_t t1 = rs1 << t0;
  uint32_t t2 = (uint32_t) 1 << imm;
  uint32_t t3 = t1 & t2;
  uint32_t s0 = t0 - 3;
  uint32_t s1 = rs1 << s0;
  uint32_t s2 = (uint32_t) 2 << imm;
  uint32_t s3 = s1 & s2;
  uint32_t rd = t3 ^ s3;

  return rd;
}

uint32_t spongent_pLayer_step2_24(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t0 = rs2 >> 24;
  uint32_t t1 = t0 & 0xFF;  
  uint32_t t2 = t1 << imm;
  uint32_t rd = rs1 ^ t2; 

  return rd;
}

uint32_t spongent_pLayer_step2_16(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t0 = rs2 >> 16;
  uint32_t t1 = t0 & 0xFF;  
  uint32_t t2 = t1 << imm;
  uint32_t rd = rs1 ^ t2; 

  return rd;
}

uint32_t spongent_pLayer_step2_8(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t0 = rs2 >>  8;
  uint32_t t1 = t0 & 0xFF;  
  uint32_t t2 = t1 << imm;
  uint32_t rd = rs1 ^ t2; 

  return rd;
}

uint32_t spongent_pLayer_step2_0(uint32_t rs1, uint32_t rs2, uint32_t imm)
{
  uint32_t t1 = rs2 & 0xFF;  
  uint32_t t2 = t1 << imm;
  uint32_t rd = rs1 ^ t2; 

  return rd;
}
