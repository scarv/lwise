// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( RV64_ELL )
.macro ELL32 r, x, t0, t1
  alz.ell   \r,  \x
.endm
#else
.macro ELL32 r, x, t0, t1
  slliw     \t0, \x,  16
  xor       \x,  \x, \t0
  ROR32     \r,  \x,  16, \t0, \t1
.endm
#endif

#if ( RV64_ELL )
.macro ELL64 r, x, t0, t1, t2
  alz.ell   \r,  \x
.endm
#else
.macro ELL64 r, x, t0, t1, t2
#if ( RV64B )
  slliw       \t0, \x,   16                // 	t0 <= tmpx 
  xor         \t0, \t0, \x
#else
  slli        \t1, \x,   32                  
  srli        \t1, \t1,  32              
  slliw       \t0, \t1,  16                // 	t0 <= tmpx 
  xor         \t0, \t0, \t1
#endif
  srli        \x,  \x,   32                //   t1 <= tmpy   
  slliw       \t1, \x,   16                    
  xor         \t1, \t1, \x

  mv          \x,  \t0
  ROR32       \x,  \x,   16, \t0, \t2
  ROR32       \t1, \t1,  16, \t0, \t2


#if ( RV64B )
   PACK       \r,  \t1, \x
#else
   slli       \t1, \t1, 32                  
   srli       \t1, \t1, 32   
   PACK       \r,  \t1, \x
#endif
.endm
#endif

#if ( RV64_TYPE1 )
.macro ELL   r, x, t0, t1
  ELL32     \r,  \x, \t0, \t1
.endm
#endif
#if ( RV64_TYPE2 ) || ( RV64_TYPE3 ) || ( RV64_TYPE4 ) || ( RV64_TYPE5 )
.macro ELL   r, x, t0, t1, t2
  ELL64     \r,  \x, \t0, \t1, \t2
.endm
#endif

// ============================================================================
