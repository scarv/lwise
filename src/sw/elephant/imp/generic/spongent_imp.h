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

// Discussions 
// 4x40b Cv1:   AddRC(table) + pLayer(swapmove) + sBoxLayer(bitsliced) -> our generic C imp? 
// 4x40b ISEv1: "general"   custom instructions + based on 4x40b Cv1
// 4x40b ISEv2: "dedicated" custom instructions + based on 4x40b Cv1

// 5x32b Cv1:   AddRC(table) + sBoxLayer(table) + pLayer(macros)
// 5x32b Cv2:   AddRC(table) + sBoxLayer(table) + pLayer(swapmove) 
// 5x32b ISEv1: "general"   custom instructions + based on 5x32b Cv2
// 5x32b ISEv2: "dedicated" custom instructions + based on 5x32b Cv2


// Cycles:
// NIST ref : 960202 
// Rhys:     ~550000
// 4x40b Cv1: 151597
// 5x32b Cv1: 497337
// 5x32b Cv2: 137297


#endif
