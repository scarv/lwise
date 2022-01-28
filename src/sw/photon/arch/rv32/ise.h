// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( PHOTON_RV32_TYPE2 )
.macro photon.step         rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 0* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
