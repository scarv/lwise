// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( GIFT_RV32_TYPE2 )
.macro gift.swapmove        rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm

.macro gift.rori.n          rd, rs1,      imm
.insn r CUSTOM_0, 6, \imm+( 1*32), \rd, \rs1,   x0
.endm
.macro gift.rori.b          rd, rs1,      imm
.insn r CUSTOM_0, 6, \imm+( 2*32), \rd, \rs1,   x0
.endm
.macro gift.rori.h          rd, rs1,      imm
.insn r CUSTOM_0, 6, \imm+( 3*32), \rd, \rs1,   x0
.endm

.macro gift.key.reorg       rd, rs1,      imm
.insn r CUSTOM_1, 6, \imm+( 0*32), \rd, \rs1,   x0
.endm
.macro gift.key.updstd      rd, rs1
.insn r CUSTOM_1, 6,      ( 1*32), \rd, \rs1,   x0
.endm
.macro gift.key.updfix      rd, rs1,      imm
.insn r CUSTOM_1, 6, \imm+( 2*32), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( GIFT_RV32_TYPE3 )
.macro gift.key.updstd      rd, rs1
.insn r CUSTOM_1, 6,      ( 1*32), \rd, \rs1,   x0
.endm

.macro gift.permbits.step   rd, rs1,      imm
.insn r CUSTOM_1, 6, \imm+( 3*32), \rd, \rs1,   x0
.endm
#endif

// ============================================================================
