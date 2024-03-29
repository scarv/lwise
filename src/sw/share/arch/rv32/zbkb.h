// Copyright (C) 2021 SCARV project <info@scarv.org>
//
// Use of this source code is restricted per the MIT license, a copy of which 
// can be found at https://opensource.org/licenses/MIT (or should be included 
// as LICENSE.txt within the associated archive or repository).

#ifndef __ZBKB_H
#define __ZBKB_H

// ============================================================================

// 011 0000 | rs2   | rs1 | 101 | rd | 0110011
.macro ror    rd, rs1, rs2
.insn r 0x33, 0x5, 0x30, \rd, \rs1, \rs2
.endm
// 011 0000 | rs2   | rs1 | 001 | rd | 0110011
.macro rol    rd, rs1, rs2
.insn r 0x33, 0x1, 0x30, \rd, \rs1, \rs2
.endm
// 011 0000 | shamt | rs1 | 101 | rd | 0010011 (32-bit)
.macro rori   rd, rs1, shamt
.insn i 0x13, 0x5, \rd, \rs1, \shamt + ( 0x30 << 5 )
.endm
// 010 0000 | rs2 | rs1   | 111 | rd | 0110011
.macro andn   rd, rs1, rs2
.insn r 0x33, 0x7, 0x20, \rd, \rs1, \rs2
.endm
// 010 0000 | rs2 | rs1   | 111 | rd | 0110011
.macro  orn   rd, rs1, rs2
.insn r 0x33, 0x6, 0x20, \rd, \rs1, \rs2
.endm
// 010 0000 | rs2 | rs1   | 111 | rd | 0110011
.macro xnor   rd, rs1, rs2
.insn r 0x33, 0x4, 0x20, \rd, \rs1, \rs2
.endm
// 000 0100 | rs2 | rs1   | 100 | rd | 0110011
.macro pack   rd, rs1, rs2
.insn r 0x33, 0x4, 0x04, \rd, \rs1, \rs2
.endm
// 000 0100 | rs2 | rs1   | 100 | rd | 0110011
.macro packh  rd, rs1, rs2
.insn r 0x33, 0x7, 0x04, \rd, \rs1, \rs2
.endm
// 0110 1000 0111 | rs1   | 101 | rd | 0010011
.macro brev8  rd, rs1
.insn i 0x13, 0x5, \rd, \rs1, 0x687
.endm
// 0110 1001 1000 | rs1   | 101 | rd | 0010011 (32-bit)
.macro  rev8  rd, rs1
.insn i 0x13, 0x5, \rd, \rs1, 0x698
.endm
// 0000 1000 1111 | rs1   | 001 | rd | 0010011
.macro   zip rd, rs1
.insn i 0x13, 0x1, \rd, \rs1, 0x08F
.endm
// 0000 1000 1111 | rs1   | 101 | rd | 0010011
.macro unzip rd, rs1
.insn i 0x13, 0x5, \rd, \rs1, 0x08F
.endm

// ============================================================================

#endif
