#ifndef __SPONGENT_IMP_H
#define __SPONGENT_IMP_H

void Spongent160_4x40b_Cv1(void *state);
void Spongent160_4x40b_ISEv1(void *state);
void Spongent160_4x40b_ISEv2(void *state);

void Spongent160_5x32b_Cv1(void *state);
void Spongent160_5x32b_Cv2(void *state);
void Spongent160_5x32b_ISEv1(void *state);
void Spongent160_5x32b_ISEv2(void *state);

#define Spongent_160 Spongent160_5x32b_Cv2

#endif
