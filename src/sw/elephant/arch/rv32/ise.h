// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ISE_H
#define __ISE_H

// ============================================================================

#if ( ELEPHANT_RV32_TYPE2 )
.macro elephant.pstep2.x    rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 0* 8), \rd, \rs1, \rs2
.endm
.macro elephant.pstep2.y    rd, rs1, rs2, imm
.insn r CUSTOM_0, 7, \imm+( 1* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================

#endif
