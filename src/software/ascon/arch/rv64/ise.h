// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ALZETTE_RV64B )
.macro ascon.rori           rd, rs1,      imm
.insn r CUSTOM_0, 6, \imm+( 2*32), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_TYPE2 )
.macro ascon.sigma          rd, rs1, rs2, imm
.insn r CUSTOM_1, 6, \imm+( 2*32), \rd, \rs1,   x0
.endm
#endif

// ============================================================================
