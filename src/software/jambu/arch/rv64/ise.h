// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( JAMBU_RV64_TYPE2 )
.macro jambu.block.0        rd, rs1, rs2
.insn r CUSTOM_3, 7,      (32* 1), \rd, \rs1, \rs2
.endm
.macro jambu.block.1        rd, rs1, rs2
.insn r CUSTOM_3, 7,      (33* 1), \rd, \rs1, \rs2
.endm
.macro jambu.block.2        rd, rs1, rs2
.insn r CUSTOM_3, 7,      (34* 1), \rd, \rs1, \rs2
.endm
.macro jambu.block.3        rd, rs1, rs2
.insn r CUSTOM_3, 7,      (35* 1), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
