// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( XOODYAK_RV64B )
.macro xoodyak.roli         rd, rs1,      imm
.insn r CUSTOM_0, 6, \imm+( 0*32), \rd, \rs1,   x0
.endm
.macro xoodyak.roliw        rd, rs1,      imm
.insn r CUSTOM_0, 6, \imm+( 1*32), \rd, \rs1,   x0
.endm

.macro xoodyak.andn         rd, rs1, rs2
.insn r CUSTOM_1, 7,      ( 0*32), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
