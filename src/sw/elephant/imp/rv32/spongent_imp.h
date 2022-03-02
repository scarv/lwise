#ifndef __SPONGENT_IMP_H
#define __SPONGENT_IMP_H

extern void Spongent160_4x40b(void *state);
extern void Spongent160_5x32b(void *state);

#define Spongent_160 Spongent160_5x32b

#endif
