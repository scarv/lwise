#ifndef ASCON_H
#define ASCON_H

void Ascon_Initialize(void *state);
void Ascon_AddBytes(void *state, const unsigned char *data, unsigned int offset, unsigned int length);
void Ascon_OverwriteBytes(void *state, const unsigned char *data, unsigned int offset, unsigned int length);
void Ascon_Permute_Nrounds(void *state, unsigned int nrounds);
void Ascon_ExtractBytes(const void *state, unsigned char *data, unsigned int offset, unsigned int length);

#if defined( LWISE )
extern void P_sB(void *state);
extern void P_sE(void *state);
extern void P_sK(void *state);
#endif

#endif
