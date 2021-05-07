// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( RV64B )
.macro ROR32 r, x, n
  alz.roriw \r, \x,    \n
.endm
#else
.macro ROR32 r, x, n
  srliw     t5, \x,    \n
  slliw     t6, \x, 32-\n
  or        \r, t5, t6
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64B )
.macro PACK r, x0, x1
  alz.pack  \r,  \x0, \x1
.endm

#else
.macro PACK r, x0, x1
  slli      \x1, \x1,  32
  or        \r,  \x0, \x1
.endm
#endif

// ============================================================================

#if ( RV64B )
.macro alz.roriw        rd, rs1,      imm
.insn r CUSTOM_2,    0, \imm, \rd, \rs1,   x0
.endm
.macro alz.pack         rd, rs1, rs2
.insn r CUSTOM_2,    1,    0, \rd, \rs1, \rs2
.endm
.macro alz.packu        rd, rs1, rs2
.insn r CUSTOM_2,    2,    0, \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64_TYPE2 )
.macro alz.block.enci   rd, rs1, rs2, imm
.insn r CUSTOM_2,    3, \imm, \rd, \rs1, \rs2
.endm
.macro alz.block.deci   rd, rs1, rs2, imm
.insn r CUSTOM_2,    4, \imm, \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64_TYPE3 )
.macro alz.block.enc.0  rd, rs1, rs2
.insn r CUSTOM_3,    0,    0, \rd, \rs1, \rs2
.endm
.macro alz.block.enc.1  rd, rs1, rs2
.insn r CUSTOM_3,    0,    1, \rd, \rs1, \rs2
.endm
.macro alz.block.enc.2  rd, rs1, rs2
.insn r CUSTOM_3,    0,    2, \rd, \rs1, \rs2
.endm
.macro alz.block.enc.3  rd, rs1, rs2
.insn r CUSTOM_3,    0,    3, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.0  rd, rs1, rs2
.insn r CUSTOM_3,    0,    4, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.1  rd, rs1, rs2
.insn r CUSTOM_3,    0,    5, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.2  rd, rs1, rs2
.insn r CUSTOM_3,    0,    6, \rd, \rs1, \rs2
.endm
.macro alz.block.dec.3  rd, rs1, rs2
.insn r CUSTOM_3,    0,    7, \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64_TYPE4 )
.macro alz.whole.enci   rd, rs1,      imm
.insn r CUSTOM_2,    5, \imm, \rd, \rs1,   x0
.endm
.macro alz.whole.deci   rd, rs1,      imm
.insn r CUSTOM_2,    6, \imm, \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV64_TYPE5 )
.macro alz.whole.enc    rd, rs1, rs2
.insn r CUSTOM_3,    0,    8, \rd, \rs1, \rs2
.endm
.macro alz.whole.dec    rd, rs1, rs2
.insn r CUSTOM_3,    0,    9, \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
