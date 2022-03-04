#ifndef __ISE_H
#define __ISE_H

#include <stdint.h>

// shared by v1, v2
uint32_t spongent_pLayer_step1(uint32_t rs1);

// v1
uint32_t spongent_BUP(uint32_t rs1, uint32_t rs2, uint32_t imm);
uint32_t spongent_BSLLXOR(uint32_t rs1, uint32_t rs2, uint32_t imm);

// v2
uint32_t spongent_DBUP(uint32_t rs1, uint32_t rs2, uint32_t imm);
uint32_t spongent_pLayer_step2_24(uint32_t rs1, uint32_t rs2, uint32_t imm);
uint32_t spongent_pLayer_step2_16(uint32_t rs1, uint32_t rs2, uint32_t imm);
uint32_t spongent_pLayer_step2_8 (uint32_t rs1, uint32_t rs2, uint32_t imm);
uint32_t spongent_pLayer_step2_0 (uint32_t rs1, uint32_t rs2, uint32_t imm);

// Discussion
// 1. If we go for 5x32b, then BUP and DBUP are not needed. 
// 2. BUP and DBUP are correct or not? 
// 3. Compared to BSLLXOR, step2 just additionally integrates the right shift.

#endif
