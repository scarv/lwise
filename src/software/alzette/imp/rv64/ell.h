// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ALZETTE_RV64_ELL )
.macro ELL32 r, x0, x1, t0, t1
  alz.ell              \r,  \x0, \x1
.endm
#else
.macro ELL32 r, x0, x1, t0, t1
  xor                  \t0, \x0, \x1
  slliw                \t1, \t0,  16
  xor                  \r,  \t0,  \t1
  ROR32                \r,  \r,   16, \t0, \t1
.endm
#endif

#if ( ALZETTE_RV64_ELL )
.macro ELL64 r, x0, x1, t0, t1, t2
  alz.ellrev           \r,  \x0, \x1
.endm
#else
.macro ELL64 r, x0, x1, t0, t1, t2
  xor                  \t0, \x0, \x1 
#if ( ALZETTE_RV64B )
  slliw                \t1, \t0,  16 // t0 <= tmpx 
  xor                  \t2, \t0, \t1
#else
  slli                 \t1, \t0,  32                  
  srli                 \t1, \t1,  32              
  slliw                \t2, \t1,  16 // t2 <= tmpx 
  xor                  \t2, \t2, \t1
#endif
  srli                 \t0, \t0,  32 // t1 <= tmpy   
  slliw                \t1, \t0,  16                    
  xor                  \t1, \t1, \t0
  mv                   \r,  \t2
  ROR32                \r,  \r,   16, \t0, \t2
  ROR32                \t1, \t1,  16, \t0, \t2
#if ( ALZETTE_RV64B )
  PACK                 \r,  \t1, \r
#else
  slli                 \t1, \t1,  32                  
  srli                 \t1, \t1,  32   
  PACK                 \r,  \t1, \r
#endif
.endm
#endif

// ============================================================================
