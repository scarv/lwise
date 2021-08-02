# `${ALG} = "xoodyak"`

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROL32` (resp. `ROL64`) to denote a 32-bit (resp. 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate.

<!--- -------------------------------------------------------------------- --->

## Context

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`  | `${IMP}`  | Symbol               | Meaning                                                                                                        |
| :-------- | :-------- | :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `xoodyak` | `rv32`    | `XOODYAK_RV32B`      | enable BitManip-like ISE for 32-bit RISC-V                                                                     |
|           | `xoodyak` | `rv32`    | `XOODYAK_RV32_TYPE1` | select 32-bit RISC-V base ISA:                 option 1, per description below                                 |
|           | `xoodyak` | `rv32`    | `XOODYAK_RV32_TYPE2` | select 32-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
|           | `xoodyak` | `rv64`    | `XOODYAK_RV64B`      | enable BitManip-like ISE for 64-bit RISC-V                                                                     |
|           | `xoodyak` | `rv64`    | `XOODYAK_RV64_TYPE1` | select 64-bit RISC-V base ISA:                 option 1, per description below                                 |
|           | `xoodyak` | `rv64`    | `XOODYAK_RV64_TYPE2` | select 64-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- The (optional) BitManip-like ISE:

  ```
  xoodyak.roli          rd, rs1,      imm => x       <- GPR[rs1]
                                             r       <- ROL32( x, imm )
                                             GPR[rd] <- r

  xoodyak.andn          rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x & ~y
                                             GPR[rd] <- r
  ```

- `XOODYAK_RV32_TYPE1`: base ISA.

- `XOODYAK_RV32_TYPE2`: base ISA plus custom   ISE.

  ```
  xoodyak.xorrol        rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- ROL32( x, 5 ) ^ ROL32( y, 14 )
                                             GPR[rd] <- r
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- The (optional) BitManip-like ISE:

  ```
  xoodyak.roriw         rd, rs1,      imm => x       <- GPR[rs1]_{31.. 0}
                                             r       <- ROR32( x, imm )
                                             GPR[rd] <- r

  xoodyak.andn          rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x & ~y
                                             GPR[rd] <- r
  ```

- `XOODYAK_RV64_TYPE1`: base ISA.

- `XOODYAK_RV64_TYPE2`: base ISA plus custom   ISE.

  ```
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] J. Daemen, S. Hoffert, S. Mella, M. Peeters, G. Van Assche, and Ronny Van Keer.
    [Xoodyak, a lightweight cryptographic scheme](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/xoodyak-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.
   
<!--- -------------------------------------------------------------------- --->
