#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"

.section .text
.balign 4


///////////////////////////////////////////////////////////////////////////////
//////////////////////// REGISTER NAMES AND CONSTANTS /////////////////////////
///////////////////////////////////////////////////////////////////////////////

// register sptr holds the address of struct `grain`
#define sptr a0
// register out holds the 32-bit word to output
#define out a0
// registers ln0 to ln4 hold words from the LFSR
#define ln0 a1
#define ln1 a2
#define ln2 a3
#define ln3 a4
#define ln4 a5
// registers nn0 to nn4 hold words from the NFSR
#define nn0 a6
#define nn1 a7
#define nn2 t0
#define nn3 t1
#define nn4 t2
// registers tr0 to tr4 are temporary registers
#define tr0 t3
#define tr1 t4
#define tr2 t5
#define tr3 t6
#define tr4 s1
// register trr serves as temporary register for rotations
#define trr s2


///////////////////////////////////////////////////////////////////////////////
///////////////////////// MACROS FOR GRAIN KEYSTREAM32 ////////////////////////
///////////////////////////////////////////////////////////////////////////////


.macro GRAIN_PROLOGUE
    // allocate space on stack
    addi    sp, sp, -8 
    // push two callee-saved registers
    sw      s1, 0(sp)
    sw      s2, 4(sp)
.endm

.macro GRAIN_EPILOGUE
    // pop two callee-saved registers
    lw      s1, 0(sp)
    lw      s2, 4(sp)
    // deallocate space on stack
    addi    sp, sp, 8
.endm

.macro GRAIN_LDSTATE
    // load words from LFSR and NFSR
    lw      ln0, 0(sptr)
    lw      ln1, 4(sptr)
    lw      ln2, 8(sptr)
    lw      ln3, 12(sptr)
    lw      nn0, 16(sptr)
    lw      nn1, 20(sptr)
    lw      nn2, 24(sptr)
    lw      nn3, 28(sptr)
.endm

.macro GRAIN_STSTATE
    // store words to LFSR and NFSR (incl rotation!)
    sw      ln1, 0(sptr)
    sw      ln2, 4(sptr)
    sw      ln3, 8(sptr)
    sw      ln4, 12(sptr)
    sw      nn1, 16(sptr)
    sw      nn2, 20(sptr)
    sw      nn3, 24(sptr)
    sw      nn4, 28(sptr)
.endm

// extract a 32-bit word from a 64-bit word
.macro GRAIN_EXTR res:req, hi:req, lo:req, imm:req
#if   (GRAIN_RV32_TYPE1)
    srli        trr, \lo, \imm
    slli        \res, \hi, 32-(\imm)
    or          \res, \res, trr
#elif (GRAIN_RV32_TYPE2)
    grain.extr  \res, \hi, \lo, \imm
#endif
.endm

// operations of f-function that use ln0 as input
.macro GRAIN_FLN0 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    GRAIN_EXTR  tr4, \hi, \lo, 7
    xor         \res, \lo, tr4
#elif (GRAIN_RV32_TYPE2)
    grain.fln0  \res, \hi, \lo
#endif
.endm

// operations of f-function that use ln2 as input
.macro GRAIN_FLN2 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    GRAIN_EXTR  tr4, \hi, \lo, 6
    GRAIN_EXTR  \res, \hi, \lo, 17
    xor         \res, \res, tr4
    xor         \res, \res, \hi
#elif (GRAIN_RV32_TYPE2)
    grain.fln2  \res, \hi, \lo
#endif    
.endm

// operations of g-function that use nn0 as input
.macro GRAIN_GNN0 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // ((nn0 >> 22) & (nn0 >> 24) & (nn0 >> 25))
    GRAIN_EXTR  tr4, \hi, \lo, 22
    GRAIN_EXTR  tr3, \hi, \lo, 24
    and         tr4, tr4, tr3
    GRAIN_EXTR  tr3, \hi, \lo, 25
    and         tr4, tr4, tr3
    // ((nn0 >> 17) & (nn0 >> 18))
    GRAIN_EXTR  tr3, \hi, \lo, 17
    GRAIN_EXTR  tr2, \hi, \lo, 18
    and         tr3, tr3, tr2
    xor         tr4, tr4, tr3
    // ((nn0 >> 11) & (nn0 >> 13))
    GRAIN_EXTR  tr3, \hi, \lo, 11
    GRAIN_EXTR  tr2, \hi, \lo, 13
    and         tr3, tr3, tr2
    xor         tr4, tr4, tr3
    // res = nn0 ^ (nn0 >> 26) ^ ...
    GRAIN_EXTR  tr3, \hi, \lo, 26
    xor         tr4, tr4, tr3
    xor         \res, \lo, tr4
#elif (GRAIN_RV32_TYPE2)
    grain.gnn0  \res, \hi, \lo
#endif
.endm

// operations of g-function that use nn1 as input
.macro GRAIN_GNN1 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // ((nn1 >> 8) & (nn1 >> 16))
    GRAIN_EXTR  tr4, \hi, \lo, 8
    GRAIN_EXTR  tr3, \hi, \lo, 16
    and         tr4, tr4, tr3
    // res = (nn1 >> 24) ^ ...
    GRAIN_EXTR  tr3, \hi, \lo, 24
    xor         \res, tr4, tr3
#elif (GRAIN_RV32_TYPE2)
    grain.gnn1  \res, \hi, \lo
#endif
.endm

// operations of g-function that use nn2 as input
.macro GRAIN_GNN2 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // ((nn2 >> 24) & (nn2 >> 28) & (nn2 >> 29) & (nn2 >> 31))
    GRAIN_EXTR  tr4, \hi, \lo, 24
    GRAIN_EXTR  tr3, \hi, \lo, 28
    and         tr4, tr4, tr3
    GRAIN_EXTR  tr3, \hi, \lo, 29
    and         tr4, tr4, tr3
    GRAIN_EXTR  tr3, \hi, \lo, 31
    and         tr4, tr4, tr3
    // ((nn2 >> 6) & (nn2 >> 14) & (nn2 >> 18))
    GRAIN_EXTR  tr3, \hi, \lo, 6
    GRAIN_EXTR  tr2, \hi, \lo, 14
    and         tr3, tr3, tr2
    GRAIN_EXTR  tr2, \hi, \lo, 18
    and         tr3, tr3, tr2
    xor         tr4, tr4, tr3
    // ((nn2 >> 4) & (nn2 >> 20))
    GRAIN_EXTR  tr3, \hi, \lo, 4
    GRAIN_EXTR  tr2, \hi, \lo, 20
    and         tr3, tr3, tr2
    xor         tr4, tr4, tr3
    // res = nn2hi ^ (nn2 >> 27) ^ ...
    GRAIN_EXTR  tr3, \hi, \lo, 27
    xor         tr3, tr3, \hi
    xor         \res, tr3, tr4
#elif (GRAIN_RV32_TYPE2)
   grain.gnn2  \res, \hi, \lo
#endif
.endm

// operations of h-function that use nn0 as input
.macro GRAIN_HNN0 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // res = ((nn0 >> 2) ^ (nn0 >> 15))
    GRAIN_EXTR  tr4, \hi, \lo, 2
    GRAIN_EXTR  tr3, \hi, \lo, 15
    xor         \res, tr4, tr3
#elif (GRAIN_RV32_TYPE2)
   grain.hnn0  \res, \hi, \lo
#endif 
.endm

// operations of h-function that use nn1 as input
.macro GRAIN_HNN1 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // res = ((nn1 >> 4) ^ (nn1 >> 13))
    GRAIN_EXTR  tr4, \hi, \lo, 4
    GRAIN_EXTR  tr3, \hi, \lo, 13
    xor         \res, tr4, tr3
#elif (GRAIN_RV32_TYPE2)
    grain.hnn1  \res, \hi, \lo
#endif
.endm

// operations of h-function that use nn2 as input
.macro GRAIN_HNN2 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // res = nn2 ^ (nn2 >> 9) ^ (nn2 >> 25)
    GRAIN_EXTR  tr4, \hi, \lo, 9
    GRAIN_EXTR  tr3, \hi, \lo, 25
    xor         tr4, tr4, tr3
    xor         \res, \lo, tr4
#elif (GRAIN_RV32_TYPE2)
    grain.hnn2  \res, \hi, \lo
#endif
.endm

// operations of h-function that use ln0 as input
.macro GRAIN_HLN0 res:req, hi:req, lo:req
#if   (GRAIN_RV32_TYPE1)
    // res = ((ln0 >> 13) & (ln0 >> 20))
    GRAIN_EXTR  tr4, \hi, \lo, 13
    GRAIN_EXTR  tr3, \hi, \lo, 20
    and         \res, tr4, tr3
#elif (GRAIN_RV32_TYPE2)
    grain.hln0  \res, \hi, \lo
#endif
.endm

// f-function to compute a word of the LFSR
.macro GRAIN_FFUNCT
    // ln4 = grain_fln0(ln1, ln0)
    GRAIN_FLN0  ln4, ln1, ln0
    // ln4 ^= grain_extr(ln2, ln1, 6)
    GRAIN_EXTR  tr0, ln2, ln1, 6
    xor         ln4, ln4, tr0
    // ln4 ^= grain_fln2(ln3, ln2)
    GRAIN_FLN2  tr0, ln3, ln2
    xor         ln4, ln4, tr0
.endm

// g-function to compute a word of the NFSR
.macro GRAIN_GFUNCT
    // nn4 = ln0 ^ grain_gnn0(nn1, nn0)
    GRAIN_GNN0  tr0, nn1, nn0
    xor         nn4, ln0, tr0
    // nn4 ^= grain_gnn1(nn2, nn1) ^ grain_gnn2(nn3, nn2)
    GRAIN_GNN1  tr0, nn2, nn1
    xor         nn4, nn4, tr0
    GRAIN_GNN2  tr0, nn3, nn2
    xor         nn4, nn4, tr0
    // nn4 ^= (grain_extr(nn1, nn0, 3) & grain_extr(nn3, nn2, 3))
    GRAIN_EXTR  tr0, nn1, nn0, 3
    GRAIN_EXTR  tr1, nn3, nn2, 3
    and         tr0, tr0, tr1
    xor         nn4, nn4, tr0
    // nn4 ^= (grain_extr(nn2, nn1, 29) & grain_extr(nn3, nn2, 1))
    GRAIN_EXTR  tr0, nn2, nn1, 29
    GRAIN_EXTR  tr1, nn3, nn2, 1
    and         tr0, tr0, tr1
    xor         nn4, nn4, tr0
    // nn4 ^= (grain_extr(nn1, nn0, 27) & grain_extr(nn2, nn1, 27));
    GRAIN_EXTR  tr0, nn1, nn0, 27
    GRAIN_EXTR  tr1, nn2, nn1, 27
    and         tr0, tr0, tr1
    xor         nn4, nn4, tr0
.endm

// h-function to compute an output-word
.macro GRAIN_HFUNCT
    // rval = grain_hnn0(nn1, nn0) ^ grain_hnn1(nn2, nn1) ^ grain_hnn2(nn3, nn2)
    GRAIN_HNN0  tr0, nn1, nn0
    GRAIN_HNN1  tr1, nn2, nn1
    xor         out, tr0, tr1
    GRAIN_HNN2  tr0, nn3, nn2
    xor         out, out, tr0
    // rval ^=  grain_hln0(ln1, ln0) ^ grain_extr(ln3, ln2, 29)
    GRAIN_HLN0  tr0, ln1, ln0
    xor         out, out, tr0
    GRAIN_EXTR  tr0, ln3, ln2, 29
    xor         out, out, tr0
    // rval ^= (grain_extr(nn1, nn0, 12) & grain_extr(ln1, ln0, 8))
    GRAIN_EXTR  tr0, nn1, nn0, 12
    GRAIN_EXTR  tr1, ln1, ln0, 8
    and         tr0, tr0, tr1
    xor         out, out, tr0
    // rval ^= (grain_extr(nn3, nn2, 31) & grain_extr(ln2, ln1, 10))
    GRAIN_EXTR  tr0, nn3, nn2, 31
    GRAIN_EXTR  tr1, ln2, ln1, 10
    and         tr0, tr0, tr1
    xor         out, out, tr0
    // rval ^= (grain_extr(ln2, ln1, 28) & grain_extr(ln3, ln2, 15))
    GRAIN_EXTR  tr0, ln2, ln1, 28
    GRAIN_EXTR  tr1, ln3, ln2, 15
    and         tr0, tr0, tr1
    xor         out, out, tr0
    // rval ^= (grain_extr(nn1, nn0, 12) & grain_extr(nn3, nn2, 31) & grain_extr(ln3, ln2, 30))
    GRAIN_EXTR  tr0, nn1, nn0, 12
    GRAIN_EXTR  tr1, nn3, nn2, 31
    and         tr0, tr0, tr1
    GRAIN_EXTR  tr1, ln3, ln2, 30
    and         tr0, tr0, tr1
    xor         out, out, tr0
.endm


///////////////////////////////////////////////////////////////////////////////
////////////////////////// GRAIN KEYSTREAM32 FUNCTION /////////////////////////
///////////////////////////////////////////////////////////////////////////////

.global grain_keystream32_rv32
.type grain_keystream32_rv32, %function
.func grain_keystream32_rv32
grain_keystream32_rv32:
    GRAIN_PROLOGUE          // push callee-saved registers
    GRAIN_LDSTATE           // load words from LFSR and NFSR
    GRAIN_FFUNCT            // f-function: compute a word of the LFSR
    GRAIN_GFUNCT            // g-function: compute a word of the NFSR
    GRAIN_STSTATE           // store words to LFSR and NFSR (incl. rotation!)
    GRAIN_HFUNCT            // h-function: compute the output-word
    GRAIN_EPILOGUE          // pop callee-saved registers
    ret
.endfunc


.size grain_keystream32_rv32, .-grain_keystream32_rv32


.end
