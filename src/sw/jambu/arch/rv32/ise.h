// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( JAMBU_RV32_TYPE2 )
.macro jambu.fsri           rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( JAMBU_RV32_TYPE3 )
.macro jambu.fsr.15         rd, rs1, rs2
.insn r CUSTOM_3, 7,      ( 0* 1), \rd, \rs1, \rs2
.endm
.macro jambu.fsr.6          rd, rs1, rs2
.insn r CUSTOM_3, 7,      ( 0* 1), \rd, \rs1, \rs2
.endm
.macro jambu.fsr.21         rd, rs1, rs2
.insn r CUSTOM_3, 7,      ( 0* 1), \rd, \rs1, \rs2
.endm
.macro jambu.fsr.27         rd, rs1, rs2
.insn r CUSTOM_3, 7,      ( 0* 1), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
