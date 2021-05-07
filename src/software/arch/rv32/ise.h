// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( RV32B )
.macro ROR32 r, x, n
  alz.rori  \r, \x,    \n
.endm
#else
.macro ROR32 r, x, n
  srli      t5, \x,    \n
  slli      t6, \x, 32-\n
  or        \r, t5, t6
.endm
#endif

// ============================================================================

#if ( RV32B )
.macro alz.rori         rd, rs1,      imm
.insn r CUSTOM_0,    0, \imm, \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV32_TYPE2 )
.macro alz.addrori      rd, rs1, rs2, imm
.insn r CUSTOM_0,    1, \imm, \rd, \rs1, \rs2
.endm
.macro alz.subrori      rd, rs1, rs2, imm
.insn r CUSTOM_0,    2, \imm, \rd, \rs1, \rs2
.endm
.macro alz.xorrori      rd, rs1, rs2, imm
.insn r CUSTOM_0,    3, \imm, \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( RV32_TYPE3 )
.macro alz.addror.31    rd, rs1, rs2
.insn r CUSTOM_1,    0,    0, \rd, \rs1, \rs2
.endm
.macro alz.addror.17    rd, rs1, rs2
.insn r CUSTOM_1,    0,    1, \rd, \rs1, \rs2
.endm
.macro alz.addror.24    rd, rs1, rs2
.insn r CUSTOM_1,    0,    2, \rd, \rs1, \rs2
.endm
.macro alz.subror.31    rd, rs1, rs2
.insn r CUSTOM_1,    0,    3, \rd, \rs1, \rs2
.endm
.macro alz.subror.17    rd, rs1, rs2
.insn r CUSTOM_1,    0,    4, \rd, \rs1, \rs2
.endm
.macro alz.subror.24    rd, rs1, rs2
.insn r CUSTOM_1,    0,    5, \rd, \rs1, \rs2
.endm
.macro alz.xorror.31    rd, rs1, rs2
.insn r CUSTOM_1,    0,    6, \rd, \rs1, \rs2
.endm
.macro alz.xorror.17    rd, rs1, rs2
.insn r CUSTOM_1,    0,     7,\rd, \rs1, \rs2
.endm
.macro alz.xorror.24    rd, rs1, rs2
.insn r CUSTOM_1,    0,    8, \rd, \rs1, \rs2
.endm
.macro alz.xorror.16    rd, rs1, rs2
.insn r CUSTOM_1,    0,    9, \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------
	
#if ( RV32_TYPE4 )
.macro alz.whole.enci.x rd, rs1, rs2, imm
.insn r CUSTOM_0,    4, \imm, \rd, \rs1, \rs2
.endm
.macro alz.whole.enci.y rd, rs1, rs2, imm
.insn r CUSTOM_0,    5, \imm, \rd, \rs1, \rs2
.endm
.macro alz.whole.deci.x rd, rs1, rs2, imm
.insn r CUSTOM_0,    6, \imm, \rd, \rs1, \rs2
.endm
.macro alz.whole.deci.y rd, rs1, rs2, imm
.insn r CUSTOM_0,    7, \imm, \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
