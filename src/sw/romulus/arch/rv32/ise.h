// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ROMULUS_RV32_TYPE1 )
.macro romulus.rstep.enc    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0* 8), \rd, \rs1, \rs2
.endm
#endif 

#if ( ROMULUS_RV32_TYPE2 )
.macro romulus.rc.upd.enc   rd, rs1
.insn r CUSTOM_0, 6,      ( 0* 8), \rd, \rs1,   x0
.endm
.macro romulus.rc.upd.dec   rd, rs1
.insn r CUSTOM_0, 6,      ( 8* 8), \rd, \rs1,   x0
.endm

.macro romulus.rc.use.enc.0 rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 2* 8), \rd, \rs1, \rs2
.endm
.macro romulus.rc.use.dec.0 rd, rs1, rs2
.insn r CUSTOM_0, 7,      (10* 8), \rd, \rs1, \rs2
.endm
.macro romulus.rc.use.enc.1 rd, rs1, rs2
.insn r CUSTOM_0, 7,      ( 3* 8), \rd, \rs1, \rs2
.endm
.macro romulus.rc.use.dec.1 rd, rs1, rs2
.insn r CUSTOM_0, 7,      (11* 8), \rd, \rs1, \rs2
.endm

.macro romulus.tk.upd.enc.0 rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 1* 8), \rd, \rs1, \rs2
.endm
.macro romulus.tk.upd.dec.0 rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 9* 8), \rd, \rs1, \rs2
.endm
.macro romulus.tk.upd.enc.1 rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 2* 8), \rd, \rs1, \rs2
.endm
.macro romulus.tk.upd.dec.1 rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+(10* 8), \rd, \rs1, \rs2
.endm

.macro romulus.rstep.enc    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0* 8), \rd, \rs1, \rs2
.endm
.macro romulus.rstep.dec    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 8* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
