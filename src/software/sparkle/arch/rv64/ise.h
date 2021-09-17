// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( SPARKLE_RV64_ELL   )
.macro sparkle.ell          rd, rs1, rs2                    
.insn r CUSTOM_3, 7,      ( 2* 1), \rd, \rs1, \rs2
.endm           
.macro sparkle.ellrev       rd, rs1, rs2                    
.insn r CUSTOM_3, 7,      ( 3* 1), \rd, \rs1, \rs2 
.endm           
#endif                                   

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_RCON  )
.macro sparkle.rcon         rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+( 0* 8), \rd, \rs1,   x0
.endm
.macro sparkle.rconw        rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+( 1* 8), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE2 )
.macro sparkle.block.enci   rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 4* 8), \rd, \rs1, \rs2
.endm
.macro sparkle.block.deci   rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 5* 8), \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE3 )
.macro sparkle.block.enc.0  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (64* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.enc.1  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (65* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.enc.2  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (66* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.enc.3  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (67* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.dec.0  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (68* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.dec.1  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (69* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.dec.2  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (70* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.block.dec.3  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (71* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE4 )
.macro sparkle.whole.enci   rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+(12* 8), \rd, \rs1,   x0
.endm
.macro sparkle.whole.deci   rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+(13* 8), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV64_TYPE5 )
.macro sparkle.whole.enc    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (96* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.whole.dec    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (97* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ============================================================================
