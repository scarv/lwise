.section .text
.balign 4


///////////////////////////////////////////////////////////////////////////////
//////////////////////// REGISTER NAMES AND CONSTANTS /////////////////////////
///////////////////////////////////////////////////////////////////////////////

// register sptr holds the address of struct `grain`
#define sptr a0
// register out holds the 32-bit word to output
#define out a0
// registers ln0 to ln4 hold words from the LSFR
#define ln0 a1
#define ln1 a2
#define ln2 a3
#define ln3 a4
#define ln4 a5
// registers nn0 to nn4 hold words from the NSFR
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


.macro PROLOGUE
    // allocate space on stack
    addi    sp, sp, -8 
    // push two callee-saved registers
    sw      s1, 0(sp)
    sw      s2, 4(sp)
.endm

.macro LDLNFSR
    // load words from LSFR and NSFR
    lw      ln0, 0(sptr)
    lw      ln1, 4(sptr)
    lw      ln2, 8(sptr)
    lw      ln3, 12(sptr)
    lw      nn0, 16(sptr)
    lw      nn1, 20(sptr)
    lw      nn2, 24(sptr)
    lw      nn3, 28(sptr)
.endm

.macro STLNFSR
    // store words to LSFR and NSFR (incl rotation!)
    sw      ln1, 0(sptr)
    sw      ln2, 4(sptr)
    sw      ln3, 8(sptr)
    sw      ln4, 12(sptr)
    sw      nn1, 16(sptr)
    sw      nn2, 20(sptr)
    sw      nn3, 24(sptr)
    sw      nn4, 28(sptr)
.endm

.macro EPILOGUE
    // pop two callee-saved registers
    lw      s1, 0(sp)
    lw      s2, 4(sp)
    // deallocate space on stack
    addi    sp, sp, 8
.endm

// extract a 32-bit word from a 64-bit word
.macro EXTR res:req, hi:req, lo:req, imm:req
    srli    trr, \lo, \imm
    slli    \res, \hi, 32-(\imm)
    or      \res, \res, trr
.endm

// operations of f-function that use ln2 as input
.macro FLN2 res:req, hi:req, lo:req
    EXTR    tr4, \hi, \lo, 6
    EXTR    \res, \hi, \lo, 17
    xor     \res, \res, tr4
.endm

// operations of g-function that use nn0 as input
.macro GNN0 res:req, hi:req, lo:req
    // ((nn0 >> 22) & (nn0 >> 24) & (nn0 >> 25))
    EXTR    tr4, \hi, \lo, 22
    EXTR    tr3, \hi, \lo, 24
    and     tr4, tr4, tr3
    EXTR    tr3, \hi, \lo, 25
    and     tr4, tr4, tr3
    // ((nn0 >> 17) & (nn0 >> 18))
    EXTR    tr3, \hi, \lo, 17
    EXTR    tr2, \hi, \lo, 18
    and     tr3, tr3, tr2
    xor     tr4, tr4, tr3
    // ((nn0 >> 11) & (nn0 >> 13))
    EXTR    tr3, \hi, \lo, 11
    EXTR    tr2, \hi, \lo, 13
    and     tr3, tr3, tr2
    xor     tr4, tr4, tr3
    // res = nn0 ^ (nn0 >> 26) ^ ...
    EXTR    tr3, \hi, \lo, 26
    xor     tr4, tr4, tr3
    xor     \res, \lo, tr4
.endm

// operations of g-function that use nn1 as input
.macro GNN1 res:req, hi:req, lo:req
    // ((nn1 >> 8) & (nn1 >> 16))
    EXTR    tr4, \hi, \lo, 8
    EXTR    tr3, \hi, \lo, 16
    and     tr4, tr4, tr3
    // res = (nn1 >> 24) ^ ...
    EXTR    tr3, \hi, \lo, 24
    xor     \res, tr4, tr3
.endm

// operations of g-function that use nn2 as input
.macro GNN2 res:req, hi:req, lo:req
    // ((nn2 >> 24) & (nn2 >> 28) & (nn2 >> 29) & (nn2 >> 31))
    EXTR    tr4, \hi, \lo, 24
    EXTR    tr3, \hi, \lo, 28
    and     tr4, tr4, tr3
    EXTR    tr3, \hi, \lo, 29
    and     tr4, tr4, tr3
    EXTR    tr3, \hi, \lo, 31
    and     tr4, tr4, tr3
    // ((nn2 >> 6) & (nn2 >> 14) & (nn2 >> 18))
    EXTR    tr3, \hi, \lo, 6
    EXTR    tr2, \hi, \lo, 14
    and     tr3, tr3, tr2
    EXTR    tr2, \hi, \lo, 18
    and     tr3, tr3, tr2
    xor     tr4, tr4, tr3
    // ((nn2 >> 4) & (nn2 >> 20))
    EXTR    tr3, \hi, \lo, 4
    EXTR    tr2, \hi, \lo, 20
    and     tr3, tr3, tr2
    xor     tr4, tr4, tr3
    // res = (nn2 >> 27) ^ ...
    EXTR    tr3, \hi, \lo, 27
    xor     \res, tr3, tr4
.endm

// operations of output-computation that use nn0 as input
.macro ONN0 res:req, hi:req, lo:req
    // res = ((nn0 >> 2) ^ (nn0 >> 15))
    EXTR    tr4, \hi, \lo, 2
    EXTR    tr3, \hi, \lo, 15
    xor     \res, tr4, tr3
.endm

// operations of output-computation that use nn1 as input
.macro ONN1 res:req, hi:req, lo:req
    // res = ((nn1 >> 4) ^ (nn1 >> 13))
    EXTR    tr4, \hi, \lo, 4
    EXTR    tr3, \hi, \lo, 13
    xor     \res, tr4, tr3
.endm

// operations of output-computation that use nn2 as input
.macro ONN2 res:req, hi:req, lo:req
    // res = nn2 ^ (nn2 >> 9) ^ (nn2 >> 25)
    EXTR    tr4, \hi, \lo, 9
    EXTR    tr3, \hi, \lo, 25
    xor     tr4, tr4, tr3
    xor     \res, \lo, tr4
.endm

// operations of output-computation that use ln0 as input
.macro OLN0 res:req, hi:req, lo:req
    // res = ((ln0 >> 13) & (ln0 >> 20))
    EXTR    tr4, \hi, \lo, 13
    EXTR    tr3, \hi, \lo, 20
    and     \res, tr4, tr3
.endm

// f-function to compute a word of the LFSR
.macro FFUNCT
    // ln4 = ln0 ^ ln3 ^ grain_extr(ln2, ln1, 6)
    xor     ln4, ln0, ln3
    EXTR    tr0, ln2, ln1, 6
    xor     ln4, ln4, tr0
    // ln4 ^= grain_fln2(ln3, ln2) ^ grain_extr(ln1, ln0, 7)
    FLN2    tr0, ln3, ln2
    xor     ln4, ln4, tr0
    EXTR    tr0, ln1, ln0, 7
    xor     ln4, ln4, tr0
.endm

// g-function to compute a word of the NFSR
.macro GFUNCT
    // nn4 = ln0 ^ grain_gnn0(nn1, nn0)
    GNN0    tr0, nn1, nn0
    xor     nn4, ln0, tr0
    // nn4 ^= grain_gnn1(nn2, nn1) ^ grain_gnn2(nn3, nn2) ^ nn3
    GNN1    tr0, nn2, nn1
    xor     nn4, nn4, tr0
    GNN2    tr0, nn3, nn2
    xor     nn4, nn4, tr0
    xor     nn4, nn4, nn3
    // nn4 ^= (grain_extr(nn1, nn0, 3) & grain_extr(nn3, nn2, 3))
    EXTR    tr0, nn1, nn0, 3
    EXTR    tr1, nn3, nn2, 3
    and     tr0, tr0, tr1
    xor     nn4, nn4, tr0
    // nn4 ^= (grain_extr(nn2, nn1, 29) & grain_extr(nn3, nn2, 1))
    EXTR    tr0, nn2, nn1, 29
    EXTR    tr1, nn3, nn2, 1
    and     tr0, tr0, tr1
    xor     nn4, nn4, tr0
    // nn4 ^= (grain_extr(nn1, nn0, 27) & grain_extr(nn2, nn1, 27));
    EXTR    tr0, nn1, nn0, 27
    EXTR    tr1, nn2, nn1, 27
    and     tr0, tr0, tr1
    xor     nn4, nn4, tr0
.endm

// o-function to compute the output-word
.macro OFUNCT
    // rval = grain_onn0(nn1, nn0) ^ grain_onn1(nn2, nn1)
    ONN0    tr0, nn1, nn0
    ONN1    tr1, nn2, nn1
    xor     out, tr0, tr1
    // rval ^= grain_onn2(nn3, nn2) ^ grain_oln0(ln1, ln0)
    ONN2    tr0, nn3, nn2
    xor     out, out, tr0
    OLN0    tr0, ln1, ln0
    xor     out, out, tr0
    // rval ^= (grain_extr(nn1, nn0, 12) & grain_extr(ln1, ln0, 8))
    EXTR    tr0, nn1, nn0, 12
    EXTR    tr1, ln1, ln0, 8
    and     tr0, tr0, tr1
    xor     out, out, tr0
    // rval ^= (grain_extr(nn3, nn2, 31) & grain_extr(ln2, ln1, 10))
    EXTR    tr0, nn3, nn2, 31
    EXTR    tr1, ln2, ln1, 10
    and     tr0, tr0, tr1
    xor     out, out, tr0
    // rval ^= (grain_extr(ln2, ln1, 28) & grain_extr(ln3, ln2, 15))
    EXTR    tr0, ln2, ln1, 28
    EXTR    tr1, ln3, ln2, 15
    and     tr0, tr0, tr1
    xor     out, out, tr0
    // rval ^= (grain_extr(nn1, nn0, 12) & grain_extr(nn3, nn2, 31) & grain_extr(ln3, ln2, 30))
    EXTR    tr0, nn1, nn0, 12
    EXTR    tr1, nn3, nn2, 31
    and     tr0, tr0, tr1
    EXTR    tr1, ln3, ln2, 30
    and     tr0, tr0, tr1
    xor     out, out, tr0
    // rval ^= grain_extr(ln3, ln2, 29);
    EXTR    tr0, ln3, ln2, 29
    xor     out, out, tr0
.endm


///////////////////////////////////////////////////////////////////////////////
////////////////////////// GRAIN KEYSTREAM32 FUNCTION /////////////////////////
///////////////////////////////////////////////////////////////////////////////

.global grain_keystream32_rv32
.type grain_keystream32_rv32, %function
.func grain_keystream32_rv32
grain_keystream32_rv32:
    PROLOGUE                // push callee-saved registers
    LDLNFSR                 // load words from LSFR and NSFR
    FFUNCT                  // f-function: compute a word of the LSFR
    GFUNCT                  // g-function: compute a word of the NSFR
    STLNFSR                 // store words to LSFR and NSFR (incl. rotation!)
    OFUNCT                  // o-function: compute the output-word
    EPILOGUE                // pop callee-saved registers
    ret
.endfunc


.size grain_keystream32_rv32, .-grain_keystream32_rv32


.end
