# `${ALG} = "jambu"`

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROL32` (resp. `ROL64`) to denote a 32-bit (resp. 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate.

<!--- -------------------------------------------------------------------- --->

## Discussion

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `jambu`    | `rv32`    | `JAMBU_RV32_TYPE1`    | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `jambu`    | `rv32`    | `JAMBU_RV32_TYPE2`    | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `jambu`    | `rv32`    | `JAMBU_RV32_TYPE3`    | select 32-bit RISC-V baseline ISA plus custom ISE: option 3, per description below                             |
|           | `jambu`    | `rv64`    | `JAMBU_RV64_TYPE1`    | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `jambu`    | `rv64`    | `JAMBU_RV64_TYPE2`    | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `JAMBU_RV32_TYPE1`: baseline ISA.

- `JAMBU_RV32_TYPE2`: baseline ISA plus custom ISE.

  ```
  jambu.fsri    rd, rs1, rs2, imm {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]
    r       <- ROR64( x_hi || x_lo, imm )
    GPR[rd] <- r_{31.. 0}
  }                                             
  ```

  Note that this operation overlaps with, or is at least similar to one 
  which exists for the
  `ascon`
  case: there it is called `ascon.rori.lo`.

- `JAMBU_RV32_TYPE3`: baseline ISA plus custom ISE.

  ```
  jambu.fsr.15  rd, rs1, rs2      {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]                                             
    r       <- ROR64( x_hi || x_lo, 15 )
    GPR[rd] <- r_{31.. 0}
  }

  jambu.fsr.6   rd, rs1, rs2      {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]                                             
    r       <- ROR64( x_hi || x_lo,  6 )
    GPR[rd] <- r_{31.. 0}
  }

  jambu.fsr.21  rd, rs1, rs2      {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]                                             
    r       <- ROR64( x_hi || x_lo, 21 )
    GPR[rd] <- r_{31.. 0}
  }

  jambu.fsr.27  rd, rs1, rs2      {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]                                             
    r       <- ROR64( x_hi || x_lo, 27 )
    GPR[rd] <- r_{31.. 0}
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `JAMBU_RV64_TYPE1`: baseline ISA.

- `JAMBU_RV64_TYPE2`: baseline ISA plus custom ISE.

  ```
  jambu.block.0 rd, rs1, rs2      { 
    s_0     <- GPR[rs1]_{31.. 0}
    s_1     <- GPR[rs1]_{64..32}
    s_2     <- GPR[rs2]_{31.. 0}
    s_3     <- GPR[rs2]_{64..32}
    t_0     <- ROR64( s_2 || s_1, 15 )
    t_1     <- ROR64( s_3 || s_2,  6 )
    t_2     <- ROR64( s_3 || s_2, 21 )
    t_3     <- ROR64( s_3 || s_2, 27 )
    r       <- t0 ^ ~( t1 & t2 ) ^ t3
    GPR[rd] <- r_{31.. 0}
  }

  jambu.block.1 rd, rs1, rs2      {
    s_0     <- GPR[rs1]_{31.. 0}
    s_1     <- GPR[rs1]_{64..32}
    s_2     <- GPR[rs2]_{31.. 0}
    s_3     <- GPR[rs2]_{64..32}
    t_0     <- ROR64( s_3 || s_2, 15 )
    t_1     <- ROR64( s_0 || s_3,  6 )
    t_2     <- ROR64( s_0 || s_3, 21 )
    t_3     <- ROR64( s_0 || s_3, 27 )
    r       <- t0 ^ ~( t1 & t2 ) ^ t3
    GPR[rd] <- r_{31.. 0}
  }

  jambu.block.2 rd, rs1, rs2      {
    s_0     <- GPR[rs1]_{31.. 0}
    s_1     <- GPR[rs1]_{64..32}
    s_2     <- GPR[rs2]_{31.. 0}
    s_3     <- GPR[rs2]_{64..32}
    t_0     <- ROR64( s_0 || s_3, 15 )
    t_1     <- ROR64( s_1 || s_0,  6 )
    t_2     <- ROR64( s_1 || s_0, 21 )
    t_3     <- ROR64( s_1 || s_0, 27 )
    r       <- t0 ^ ~( t1 & t2 ) ^ t3
    GPR[rd] <- r_{31.. 0}
  }

  jambu.block.3 rd, rs1, rs2      {
    s_0     <- GPR[rs1]_{31.. 0}
    s_1     <- GPR[rs1]_{64..32}
    s_2     <- GPR[rs2]_{31.. 0}
    s_3     <- GPR[rs2]_{64..32}
    t_0     <- ROR64( s_1 || s_0, 15 )
    t_1     <- ROR64( s_2 || s_1,  6 )
    t_2     <- ROR64( s_2 || s_1, 21 )
    t_3     <- ROR64( s_2 || s_1, 27 )
    r       <- t0 ^ ~( t1 & t2 ) ^ t3
    GPR[rd] <- r_{31.. 0}
  }
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] H. Wu and T. Huang
    [TinyJAMBU](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/tinyjambu-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.

<!--- -------------------------------------------------------------------- --->
