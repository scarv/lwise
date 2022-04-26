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

.macro grain.fln0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 0* 8), \rd, \rs1, \rs2
.endm
.macro grain.fln2           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 1* 8), \rd, \rs1, \rs2
.endm
.macro grain.gnn0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 2* 8), \rd, \rs1, \rs2
.endm
.macro grain.gnn1           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 3* 8), \rd, \rs1, \rs2
.endm
.macro grain.gnn2           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 4* 8), \rd, \rs1, \rs2
.endm
.macro grain.hnn0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 5* 8), \rd, \rs1, \rs2
.endm
.macro grain.hnn1           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 6* 8), \rd, \rs1, \rs2
.endm
.macro grain.hnn2           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 7* 8), \rd, \rs1, \rs2
.endm
.macro grain.hln0           rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 8* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
