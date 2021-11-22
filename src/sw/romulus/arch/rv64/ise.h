// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ASCON_RV64_TYPE2 )
.macro romulus.rc.upd       rd, rs1
.insn r CUSTOM_0, 6,      ( 0*32), \rd, \rs1,   x0
.endm
.macro romulus.rc.use       rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 3*32), \rd, \rs1, \rs2
.endm

.macro romulus.tk.upd       rd, rs1,      imm
.insn r CUSTOM_1, 6, \imm+( 2*32), \rd, \rs1,   x0
.endm

.macro romulus.rstep        rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
.macro romulus.cstep        rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 1*32), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
