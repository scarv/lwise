/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __SHARE_H
#define __SHARE_H

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <string.h>

#define ROL32(x,n) (((x) << (n)) | ((x) >> (32 - (n))))
#define ROR32(x,n) (((x) >> (n)) | ((x) << (32 - (n))))
#define ROL64(x,n) (((x) << (n)) | ((x) >> (64 - (n))))
#define ROR64(x,n) (((x) >> (n)) | ((x) << (64 - (n))))

#define ALZETTE_ENC(xi,yi,ci)                       \
  (xi) += ROR32((yi), 31); (yi) ^= ROR32((xi), 24); \
  (xi) ^= (ci);                                     \
  (xi) += ROR32((yi), 17); (yi) ^= ROR32((xi), 17); \
  (xi) ^= (ci);                                     \
  (xi) +=       (yi)     ; (yi) ^= ROR32((xi), 31); \
  (xi) ^= (ci);                                     \
  (xi) += ROR32((yi), 24); (yi) ^= ROR32((xi), 16); \
  (xi) ^= (ci);

#define ALZETTE_DEC(xi,yi,ci)                       \
  (xi) ^= (ci);                                     \
  (yi) ^= ROR32((xi), 16); (xi) -= ROR32((yi), 24); \
  (xi) ^= (ci);                                     \
  (yi) ^= ROR32((xi), 31); (xi) -=       (yi)     ; \
  (xi) ^= (ci);                                     \
  (yi) ^= ROR32((xi), 17); (xi) -= ROR32((yi), 17); \
  (xi) ^= (ci);                                     \
  (yi) ^= ROR32((xi), 24); (xi) -= ROR32((yi), 31);

#define ELL(x) ( ROR32( ( (x) ^ ( (x) << 16 ) ), 16 ) )

#endif
