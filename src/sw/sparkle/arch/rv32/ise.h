// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ISE_H
#define __ISE_H

// ============================================================================

#if ( SPARKLE_RV32_ELL   )
.macro sparkle.ell          rd, rs1, rs2                    
.insn r CUSTOM_3, 7,      ( 2* 1), \rd, \rs1, \rs2
.endm         
#endif                                     

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_RCON  )
.macro sparkle.rcon         rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+( 0* 8), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_TYPE2 )
.macro sparkle.addrori      rd, rs1, rs2, imm          
.insn r CUSTOM_1, 7, \imm+( 0*32), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.subrori      rd, rs1, rs2, imm          
.insn r CUSTOM_1, 7, \imm+( 1*32), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.xorrori      rd, rs1, rs2, imm          
.insn r CUSTOM_1, 7, \imm+( 2*32), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------

#if ( SPARKLE_RV32_TYPE3 )
.macro sparkle.addror.31    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (32* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.addror.17    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (33* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.addror.24    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (34* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.subror.31    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (35* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.subror.17    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (36* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.subror.24    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (37* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.xorror.31    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (38* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.xorror.17    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (39* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.xorror.24    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (40* 1), \rd, \rs1, \rs2 
.endm                                              
.macro sparkle.xorror.16    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (41* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------
	
#if ( SPARKLE_RV32_TYPE4 )
.macro sparkle.whole.enci.x rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 8* 8), \rd, \rs1, \rs2
.endm
.macro sparkle.whole.enci.y rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 9* 8), \rd, \rs1, \rs2
.endm
.macro sparkle.whole.deci.x rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+(10* 8), \rd, \rs1, \rs2
.endm
.macro sparkle.whole.deci.y rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+(11* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================

#endif
