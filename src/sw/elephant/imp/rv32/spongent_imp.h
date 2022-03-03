#ifndef __SPONGENT_IMP_H
#define __SPONGENT_IMP_H

extern void Spongent160_4x40b(void *state);
extern void Spongent160_5x32b(void *state);

#define Spongent_160 Spongent160_5x32b

// Info 
// 4x40b asm: AddRC(table) + pLayer(swapmove) + sBoxLayer(bitsliced) -> doesn't need  ZBKX -> also useful for cortex-M 
// 5x32b asm: AddRC(table) + sBoxLayer(table) + pLayer(swapmove)     ->         needs ZBKX


// Cycles: 
// 4x40b asm: 143257
// 5x32b asm:  89082


// Discussion:
// 1. 4x40b seems to be relatively more eifficent on rv64 compared to 4x40b on 
//    rv32, and compared to 5x32b (i.e. 3x64b) on rv64? Also, 4x40b has a 
//    straightforward extension to Spongent-176 (i.e. 4x44b).
// 2. Is it always better to use a bitsliced SBox in our case? 
// 3. When ZBKB and ZBKX are disabled, of course 4x40b is better.

#endif
