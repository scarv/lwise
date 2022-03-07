// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ISE_H
#define __ISE_H

// ============================================================================

#if ( ELEPHANT_RV32_TYPE2 )
.macro elephant.bsllxor     rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
.macro elephant.bup         rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 2*32), \rd, \rs1, \rs2
.endm

.macro elephant.pstep1      rd, rs1
.insn r CUSTOM_1, 6,      ( 0*32), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ELEPHANT_RV32_TYPE3 )
.macro elephant.bupd        rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 3*32), \rd, \rs1, \rs2
.endm

.macro elephant.pstep1      rd, rs1
.insn r CUSTOM_1, 6,      ( 0*32), \rd, \rs1,   x0
.endm

.macro elephant.pstep2.0    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
.macro elephant.pstep2.8    rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 1*32), \rd, \rs1, \rs2
.endm
.macro elephant.pstep2.16   rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 2*32), \rd, \rs1, \rs2
.endm
.macro elephant.pstep2.24   rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 3*32), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================

#endif
