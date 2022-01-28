#ifndef TIMING_AEAD_H
#define TIMING_AEAD_H
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include "crypto_hash.h"
#include "api.h"

#ifdef _MSC_VER
unsigned long CurrentProcessorNumber(void);
__inline unsigned long long read_tsc(void);
#endif

#ifdef __GNUC__
inline unsigned long long read_tsc(void);
#endif

void setCPUaffinity();

void block_rndfill(unsigned char *buf, const size_t len);

int time_base(double *av, double *sig);

int time_enc16(double *av, double *sig, unsigned long long dataLengthInBytes);

double enc_cycles(unsigned long long dataLengthInBytes);

void timing();

#endif  //TIMING_AEAD_H