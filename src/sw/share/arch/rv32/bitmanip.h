// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

// ============================================================================

.macro  ORN rd, rs1, rs2
   orn \rd, \rs1, \rs2
.endm
.macro ANDN rd, rs1, rs2
  andn \rd, \rs1, \rs2
.endm
.macro XNOR rd, rs1, rs2
  xnor \rd, \rs1, \rs2
.endm
.macro RORI rd, rs1, imm
  rori \rd, \rs1,    \imm
.endm
.macro ROLI rd, rs1,  imm
  rori \rd, \rs1, 32-\imm
.endm
.macro REV8 rd, rs1
  rev8 \rd, \rs1
.endm

// ============================================================================
