// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ASCON_RV32_TYPE2 )
.macro romulus.rc.upd       rd, rs1
.insn r CUSTOM_0, 6,      ( 0*32), \rd, \rs1,   x0
.endm
.macro romulus.rc.use.0     rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 1*32), \rd, \rs1, \rs2
.endm
.macro romulus.rc.use.1     rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 2*32), \rd, \rs1, \rs2
.endm

.macro romulus.tk.upd.0     rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
.macro romulus.tk.upd.1     rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 1*32), \rd, \rs1, \rs2
.endm

.macro romulus.rstep        rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
