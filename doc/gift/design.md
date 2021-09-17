# `${ALG} = "gift"`

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROL32` (resp. `ROL4`, `ROL8`, `ROL16`, and `ROL64`) to denote a 32-bit (resp. 4-bit, 8-bit, 16-bit, and 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR4`, `ROR8`, `ROR16`, and `ROR64`) to denote a 32-bit (resp. 4-bit, 8-bit, 16-bit, and 64-bit) right-rotate,
- define

  ```
  SWAPMOVE(x,m,n) => r  = x ^ ( x >> n )
                     r &= m
                     r ^= x ^ ( r << n )
  ```

<!--- -------------------------------------------------------------------- --->

## Context

The SWAPMOVE operation originates from [2].

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`  | `${IMP}`  | Symbol               | Meaning                                                                                                        |
| :-------- | :-------- | :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `gift`    | `rv32`    | `GIFT_RV32_TYPE1`    | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `gift`    | `rv32`    | `GIFT_RV32_TYPE2`    | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `gift`    | `rv64`    | `GIFT_RV64_TYPE1`    | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `XOODYAK_RV32_TYPE1`: base ISA.

- `XOODYAK_RV32_TYPE2`: base ISA plus custom ISE.


gift.rori           rd, rs1,      imm => x       <- GPR[rs1]
                                         r       <- ROR32( x,   imm )
                                         GPR[rd] <- r

gift.rev8           rd, rs1           => x_3     <- GPR[rs1]_{31..24}
                                         x_2     <- GPR[rs1]_{23..16}
                                         x_1     <- GPR[rs1]_{15.. 8}
                                         x_0     <- GPR[rs1]_{ 7.. 0}
                                         r       <- x_0 | x_1 | x_2 | x_3
                                         GPR[rd] <- r



gift.rori.n         rd, rs1,      imm => x_7     <- GPR[rs1]_{31..28}
                                         x_6     <- GPR[rs1]_{27..24}
                                         x_5     <- GPR[rs1]_{23..20}
                                         x_4     <- GPR[rs1]_{19..16}
                                         x_3     <- GPR[rs1]_{15..12}
                                         x_2     <- GPR[rs1]_{11.. 8}
                                         x_1     <- GPR[rs1]_{ 7.. 4}
                                         x_0     <- GPR[rs1]_{ 3.. 0}
                                         r       <- ROT4 ( x_7, imm ) | ROT4 ( x_6, imm ) | 
                                                    ROT4 ( x_5, imm ) | ROT4 ( x_4, imm ) | 
                                                    ROT4 ( x_3, imm ) | ROT4 ( x_2, imm ) | 
                                                    ROT4 ( x_1, imm ) | ROT4 ( x_0, imm ) 
                                         GPR[rd] <- r

gift.rori.b         rd, rs1,      imm => x_3     <- GPR[rs1]_{31..24}
                                         x_2     <- GPR[rs1]_{23..16}
                                         x_1     <- GPR[rs1]_{15.. 8}
                                         x_0     <- GPR[rs1]_{ 7.. 0}
                                         r       <- ROT8 ( x_3, imm ) | ROT8 ( x_2, imm ) | 
                                                    ROT8 ( x_1, imm ) | ROT8 ( x_0, imm ) 
                                         GPR[rd] <- r

gift.rori.h         rd, rs1,      imm => x_1     <- GPR[rs1]_{31..16}
                                         x_0     <- GPR[rs1]_{15.. 0}
                                         r       <- ROT16( x_1, imm ) | ROT16( x_0, imm )
                                         GPR[rd] <- r

gift.swapmove       rd, rs1, rs2, imm => x       <- GPR[rs1]
                                         m       <- GPR[rs2]
                                         r       <- SWAPMOVE( x, m, imm )
                                         GPR[rd] <- r

gift.key.reorg      rd, rs1,      imm =>

gift.key.update.std rd, rs1           =>

gift.key.update.fix rd, rs1,      imm =>

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `XOODYAK_RV64_TYPE1`: baseline ISA.

<!--- -------------------------------------------------------------------- --->

## References

[1] S. Banik, A. Chakraborti, T. Iwata, K. Minematsu, M. Nandi, T. Peyrin, Y. Sasaki, S.M. Sim, Y. Todo.
    [GIFT-COFB](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/gift-cofb-spec-final.pdf).
    Submission to NIST (version 1.1), 2021.

[2] L. May and L. Penna and A. Clark.
    [An Implementation of Bitsliced DES on the Pentium MMX Processor](https://link.springer.com/chapter/10.1007/10718964_10).
    Australasian Conference on Information Security and Privacy (ACISP). Springer-Verlag, LNCS 1841, 112--122, 2000.

<!--- -------------------------------------------------------------------- --->
