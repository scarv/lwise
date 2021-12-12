#ifndef __XOODOO_H
#define __XOODOO_H

#include "share.h"

#include "xoodoo_imp.h"

#define MAXROUNDS 12
#define NROWS 3
#define NCOLUMS 4
#define NLANES (NCOLUMS * NROWS)

#define index(__x, __y)((((__y) % NROWS) * NCOLUMS) + ((__x) % NCOLUMS))

typedef uint32_t tXoodooLane;

extern const uint32_t RC[MAXROUNDS];

void Xoodoo_Permute_Nrounds(void * state, uint32_t nr);

#endif
