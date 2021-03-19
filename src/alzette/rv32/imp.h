/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __IMP_H
#define __IMP_H

#define ROL32(x,n) (((x) << (n)) | ((x) >> (32 - (n))))
#define ROR32(x,n) (((x) >> (n)) | ((x) << (32 - (n))))

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

#if  defined( DRIVER_MEASURE )
#define measure_prologue(id)                                            \
  uint32_t id ## _cycle_b;                                              \
  uint32_t id ## _cycle_a;                                              \
  uint32_t id ## _cycle_t;                                              \
                                                                        \
  uint32_t id ##  _iret_b;                                              \
  uint32_t id ##  _iret_a;                                              \
  uint32_t id ##  _iret_t;
#define measure_step(id,...)                                            \
  __asm__ __volatile__( "rdcycle   %0 ;"                                \
                        "rdinstret %1 ;"                                \
                        : "=r"(id ## _cycle_b),                         \
                          "=r"(id ##  _iret_b) );                       \
                                                                        \
  id( __VA_ARGS__ );                                                    \
                                                                        \
  __asm__ __volatile__( "rdcycle   %0 ;"                                \
                        "rdinstret %1 ;"                                \
                        : "=r"(id ## _cycle_a),                         \
                          "=r"(id ##  _iret_a) );                       \
                                                                        \
  id ## _cycle_t += ( id ## _cycle_a - id ## _cycle_b );                \
  id ##  _iret_t += ( id ##  _iret_a - id ##  _iret_b );
#define measure_epilogue(id)                                            \
  printf( "cycle : %s => %f\n", #id, ( float )( id ## _cycle_t ) / n ); \
  printf( "iret  : %s => %f\n", #id, ( float )( id ##  _iret_t ) / n );
#endif

#endif
