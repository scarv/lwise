// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ASCON_RV64_TYPE2 )
.macro romulus.rc.upd.enc   rd, rs1
.insn r CUSTOM_0, 6,      ( 0* 8), \rd, \rs1,   x0
.endm
.macro romulus.rc.upd.dec   rd, rs1
.insn r CUSTOM_0, 6,      ( 8* 8), \rd, \rs1,   x0
.endm

.macro romulus.rc.use.enc   rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 1* 8), \rd, \rs1, \rs2
.endm
.macro romulus.rc.use.dec   rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 9* 8), \rd, \rs1, \rs2
.endm

.macro romulus.tk.upd.enc   rd, rs1,      imm
.insn r CUSTOM_1, 6, \imm+( 0* 8), \rd, \rs1,   x0
.endm
.macro romulus.tk.upd.dec   rd, rs1,      imm
.insn r CUSTOM_1, 6, \imm+( 8* 8), \rd, \rs1,   x0
.endm

.macro romulus.rstep.enc    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0* 8), \rd, \rs1, \rs2
.endm
.macro romulus.rstep.dec    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 8* 8), \rd, \rs1, \rs2
.endm
.macro romulus.cstep.enc    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 1* 8), \rd, \rs1, \rs2
.endm
.macro romulus.cstep.dec    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 9* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
