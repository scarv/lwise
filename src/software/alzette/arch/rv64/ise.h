// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

#if ( ALZETTE_RV64B )
.macro ROR32 r, x, n, t0, t1
  alzette.roriw \r,  \x,      \n
.endm
.macro ROR64 r, x, n, t0, t1
  alzette.rori  \r,  \x,      \n
.endm
#else
.macro ROR32 r, x, n, t0, t1
  srliw         \t0, \x,      \n
  slliw         \t1, \x,   32-\n
  or            \r,  \t0, \t1
.endm
.macro ROR64 r, x, n, t0, t1
  srli          \t0, \x,      \n
  slli          \t1, \x,   64-\n
  or            \r,  \t0, \t1
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64B )
.macro PACK r, x0, x1
  alzette.pack  \r,  \x0, \x1
.endm
#else
.macro PACK r, x0, x1
  slli          \x1, \x1,  32
  or            \r,  \x0, \x1
.endm
#endif

// ============================================================================

#if ( ALZETTE_RV64B )
.macro alzette.rori         rd, rs1,      imm          
.insn r CUSTOM_0, 6, \imm+( 0*32), \rd, \rs1,   x0
.endm
.macro alzette.roriw        rd, rs1,      imm          
.insn r CUSTOM_0, 6, \imm+( 1*32), \rd, \rs1,   x0 
.endm        
.macro alzette.pack         rd, rs1, rs2               
.insn r CUSTOM_3, 7,      ( 0* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.packu        rd, rs1, rs2               
.insn r CUSTOM_3, 7,      ( 1* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_ELL )
.macro alzette.ell          rd, rs1, rs2                    
.insn r CUSTOM_3, 7,      ( 2* 1), \rd, \rs1, \rs2
.endm           
.macro alzette.ellrev       rd, rs1, rs2                    
.insn r CUSTOM_3, 7,      ( 3* 1), \rd, \rs1, \rs2 
.endm           
#endif                                   

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_RCON )
.macro alzette.rcon         rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+( 0* 8), \rd, \rs1,   x0
.endm
.macro alzette.rconw        rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+( 1* 8), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_TYPE2 )
.macro alzette.block.enci   rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 4* 8), \rd, \rs1, \rs2
.endm
.macro alzette.block.deci   rd, rs1, rs2, imm
.insn r CUSTOM_2, 7, \imm+( 5* 8), \rd, \rs1, \rs2
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_TYPE3 )
.macro alzette.block.enc.0  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (64* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.enc.1  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (65* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.enc.2  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (66* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.enc.3  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (67* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.dec.0  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (68* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.dec.1  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (69* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.dec.2  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (70* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.block.dec.3  rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (71* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_TYPE4 )
.macro alzette.whole.enci   rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+(12* 8), \rd, \rs1,   x0
.endm
.macro alzette.whole.deci   rd, rs1,      imm
.insn r CUSTOM_2, 6, \imm+(13* 8), \rd, \rs1,   x0
.endm
#endif

// ----------------------------------------------------------------------------

#if ( ALZETTE_RV64_TYPE5 )
.macro alzette.whole.enc    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (96* 1), \rd, \rs1, \rs2 
.endm                                              
.macro alzette.whole.dec    rd, rs1, rs2               
.insn r CUSTOM_3, 7,      (97* 1), \rd, \rs1, \rs2 
.endm                                              
#endif

// ============================================================================
