// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ALZETTE_RV32B )
.macro ROR32 r, x, n, t0, t1
  alzette.rori  \r,  \x,      \n
.endm
#else
.macro ROR32 r, x, n, t0, t1
  srli          \t0, \x,      \n
  slli          \t1, \x,   32-\n
  or            \r,  \t0, \t1
.endm
#endif

// ============================================================================

#if ( ALZETTE_RV32B )
.macro alzette.rori         rd, rs1,      imm          
.insn r CUSTOM_0, 6, \imm+( 0*32), \rd, \rs1,   x0 
.endm                                              
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV32_ELL )
.macro alzette.ell          rd, rs1, rs2                    
.insn r CUSTOM_3, 7,      ( 2* 1), \rd, \rs1, \rs2
.endm         
#endif                                     

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV32_RCON )
.macro alzette.rcon         rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+( 0* 8), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV32_TYPE2 )
.macro alzette.addrori      rd, rs1, rs2, imm          
.insn r CUSTOM_1, 7, \imm+( 0*32), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.subrori      rd, rs1, rs2, imm          
.insn r CUSTOM_1, 7, \imm+( 1*32), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.xorrori      rd, rs1, rs2, imm          
.insn r CUSTOM_1, 7, \imm+( 2*32), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV32_TYPE3 )
.macro alzette.addror.31    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (32* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.addror.17    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (33* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.addror.24    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (34* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.subror.31    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (35* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.subror.17    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (36* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.subror.24    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (37* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.xorror.31    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (38* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.xorror.17    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (39* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.xorror.24    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (40* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.xorror.16    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (41* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------
	
#if ( ALZETTE_RV32_TYPE4 )
.macro alzette.whole.enci.x rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 8* 8), \rd, \rs1, \rs2
.endm
.macro alzette.whole.enci.y rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 9* 8), \rd, \rs1, \rs2
.endm
.macro alzette.whole.deci.x rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+(10* 8), \rd, \rs1, \rs2
.endm
.macro alzette.whole.deci.y rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+(11* 8), \rd, \rs1, \rs2
.endm
#endif

// ============================================================================
