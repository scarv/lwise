// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( GRAIN_RV32_TYPE2 )
.macro grain.extr           rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm

.macro grain.fln2           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 0*16), \rd, \rs1, \rs2
.endm
.macro grain.gnn0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 1*16), \rd, \rs1, \rs2
.endm
.macro grain.gnn1           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 2*16), \rd, \rs1, \rs2
.endm
.macro grain.gnn2           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 3*16), \rd, \rs1, \rs2
.endm
.macro grain.onn0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 4*16), \rd, \rs1, \rs2
.endm
.macro grain.onn1           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 5*16), \rd, \rs1, \rs2
.endm
.macro grain.onn2           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 6*16), \rd, \rs1, \rs2
.endm
.macro grain.oln0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 7*16), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
