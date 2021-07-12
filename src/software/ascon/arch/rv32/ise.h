// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ASCON_RV32B )
.macro ascon.orn            rd, rs1, rs2
.insn r CUSTOM_2, 7,      ( 0* 1), \rd, \rs1, \rs2
.endm
.macro ascon.andn           rd, rs1, rs2
.insn r CUSTOM_2, 7,      ( 1* 1), \rd, \rs1, \rs2
.endm
.macro ascon.rori.lo        rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
.macro ascon.rori.hi        rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 1*32), \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ASCON_RV32_TYPE2 )
.macro ascon.sigma.lo       rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 0*32), \rd, \rs1, \rs2
.endm
.macro ascon.sigma.hi       rd, rs1, rs2, imm
.insn r CUSTOM_1, 7, \imm+( 1*32), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
