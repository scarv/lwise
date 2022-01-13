#include "xoodoo.h"

/* Round constants */
#define _rc12   0x00000058
#define _rc11   0x00000038
#define _rc10   0x000003C0
#define _rc9    0x000000D0
#define _rc8    0x00000120
#define _rc7    0x00000014
#define _rc6    0x00000060
#define _rc5    0x0000002C
#define _rc4    0x00000380
#define _rc3    0x000000F0
#define _rc2    0x000001A0
#define _rc1    0x00000012

const uint32_t RC[MAXROUNDS] = {
  _rc12, _rc11, _rc10, _rc9, _rc8, _rc7, _rc6, _rc5, _rc4, _rc3, _rc2, _rc1
};
