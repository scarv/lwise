# `${ALG} = "ascon"`

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROL32` (resp. `ROL64`) to denote a 32-bit (resp. 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate,
- define various look-up tables:

  ```
  ROT_0 = { 19, 61,  1, 10,  7 }
  ROT_1 = { 28, 39,  6, 17, 41 }
  ```

<!--- -------------------------------------------------------------------- --->

## Context

The Ascon linear layer is described in [Sec. 2.6.3, 1] in terms of

```
\Sigma_0( x_0 ) = x_0 ^ ROR64( x_0, 19 ) ^ ROR64( x_0, 28 )
\Sigma_1( x_1 ) = x_1 ^ ROR64( x_1, 61 ) ^ ROR64( x_1, 39 )
\Sigma_2( x_2 ) = x_2 ^ ROR64( x_2,  1 ) ^ ROR64( x_2,  6 )
\Sigma_3( x_3 ) = x_3 ^ ROR64( x_3, 10 ) ^ ROR64( x_3, 17 )
\Sigma_4( x_4 ) = x_4 ^ ROR64( x_4,  7 ) ^ ROR64( x_4, 41 )
```

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`  | `${IMP}`  | Symbol               | Meaning                                                                                                        |
| :-------- | :-------- | :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `ascon`   | `rv32`    | `ASCON_RV32_TYPE1`   | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `ascon`   | `rv32`    | `ASCON_RV32_TYPE2`   | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `ascon`   | `rv64`    | `ASCON_RV64_TYPE1`   | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `ascon`   | `rv64`    | `ASCON_RV64_TYPE2`   | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ASCON_RV32_TYPE1`: baseline ISA.

- `ASCON_RV32_TYPE2`: baseline ISA plus custom ISE.

  ```
  ascon.rori.lo         rd, rs1, rs2, imm => x_hi    <- GPR[rs2]
                                             x_lo    <- GPR[rs1]
                                             x       <- x_hi || x_lo
                                             r       <- ROR64( x, imm )
                                             GPR[rd] <- r_{31.. 0}

  ascon.rori.hi         rd, rs1, rs2, imm => x_hi    <- GPR[rs2]
                                             x_lo    <- GPR[rs1]
                                             x       <- x_hi || x_lo
                                             r       <- ROR64( x, imm )
                                             GPR[rd] <- r_{63..32}

  ascon.sigma.lo        rd, rs1, rs2, imm => x_hi    <- GPR[rs2]
                                             x_lo    <- GPR[rs1]
                                             x       <- x_hi || x_lo
                                             r       <- x ^ ROR64( x, ROT_0[ imm ] ) ^ ROR64( x, ROT_1[ imm ] )
                                             GPR[rd] <- r_{31.. 0}

  ascon.sigma.hi        rd, rs1, rs2, imm => x_hi    <- GPR[rs2]
                                             x_lo    <- GPR[rs1]
                                             x       <- x_hi || x_lo
                                             r       <- x ^ ROR64( x, ROT_0[ imm ] ) ^ ROR64( x, ROT_1[ imm ] )
                                             GPR[rd] <- r_{63..32}
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ASCON_RV64_TYPE1`: baseline ISA.

- `ASCON_RV64_TYPE2`: baseline ISA plus custom ISE.

  ```
  ascon.sigma           rd, rs1,      imm => x       <- GPR[rs1]
                                             r       <- x ^ ROR64( x, ROT_0[ imm ] ) ^ ROR64( x, ROT_1[ imm ] )
                                             GPR[rd] <- r
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] C. Dobraunig, M. Eichlseder, F. Mendel, and M. Schläffer.
    [Ascon](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/ascon-spec-final.pdf).
    Submission to NIST (version 1.2), 2021.

<!--- -------------------------------------------------------------------- --->
