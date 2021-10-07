// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ZBKX_H
#define __ZBKX_H

// ============================================================================

// 001 0100 | rs2   | rs1 | 010 | rd | 011 0011
.macro xperm4 rd, rs1, rs2
.insn r 0x33, 0x2, 0x14, \rd, \rs1, \rs2
.endm
// 001 0100 | rs2   | rs1 | 100 | rd | 011 0011
.macro xperm8 rd, rs1, rs2
.insn r 0x33, 0x4, 0x14, \rd, \rs1, \rs2
.endm

// ============================================================================

#endif
