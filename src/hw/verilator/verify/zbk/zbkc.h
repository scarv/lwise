// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ZBKC_H
#define __ZBKC_H

// ============================================================================

// 000 0101 | rs2   | rs1 | 001 | rd | 011 0011
.macro clmul rd, rs1, rs2
.insn r 0x33, 0x1, 0x05, \rd, \rs1, \rs2
.endm
// 000 0101 | rs2   | rs1 | 011 | rd | 011 0011
.macro clmulh rd, rs1, rs2
.insn r 0x33, 0x3, 0x05, \rd, \rs1, \rs2
.endm

// ============================================================================

#endif
