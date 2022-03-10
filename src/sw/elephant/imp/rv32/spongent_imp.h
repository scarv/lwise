#ifndef __SPONGENT_IMP_H
#define __SPONGENT_IMP_H

extern void Spongent160_4x40b(void *state);
extern void Spongent160_5x32b(void *state);

#if (ELEPHANT_STATE_5X32B)
#define Spongent_160 Spongent160_5x32b
#else
// Use 4x40b state representation by default
#define Spongent_160 Spongent160_4x40b
#endif 

#endif
