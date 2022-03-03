#ifndef __SPONGENT_IMP_H
#define __SPONGENT_IMP_H

extern void Spongent160_4x40b(void *state);
extern void Spongent160_5x32b(void *state);

#define Spongent_160 Spongent160_5x32b

// Discussions 
// 4x40b asm: AddRC(table) + pLayer(swapmove) + sBoxLayer(bitsliced) -> doesn't need  ZBKX -> also useful for cortex-M 
// 5x32b asm: AddRC(table) + sBoxLayer(table) + pLayer(swapmove)     ->         needs ZBKX


// Cycles: 
// 4x40b asm: 143257
// 5x32b asm:  89082


#endif
