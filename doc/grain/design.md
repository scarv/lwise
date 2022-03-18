# `${ALG} = "grain"`

<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Discussion

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `grain`    | `rv32`    | `GRAIN_RV32_TYPE1`    | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `grain`    | `rv32`    | `GRAIN_RV32_TYPE2`    | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `grain`    | `rv64`    | `GRAIN_RV64_TYPE1`    | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `grain`    | `rv64`    | `GRAIN_RV64_TYPE2`    | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `GRAIN_RV32_TYPE1`: baseline ISA.

- `GRAIN_RV32_TYPE2`: baseline ISA plus custom ISE.

  ```
  grain.extr rd, rs1, rs2, imm {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- x >> imm
    GPR[rd] <- r_{31.. 0}
  }

  grain.fln2 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 6 ) ^ ( x >> 17 )
    GPR[rd] <- r
  }

  grain.gnn0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x ) ^ ( x >> 26 ) ^ ( ( x >> 11 ) & ( x >> 13 ) ) ^ ( ( x >> 17 ) & ( x >> 18 ) ) ^ ( ( x >> 22 ) & ( x >> 24 ) & ( x >> 25 ) )
    GPR[rd] <- r
  }

  grain.gnn1 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 24 ) ^ ( ( x >> 8 ) & ( x >> 16 ) )
    GPR[rd] <- r
  }

  grain.gnn2 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( ( x >> 4 ) & ( x >> 20 ) ) ^ ( ( x >> 24 ) & ( x >> 28 ) & ( x >> 29 ) & ( x >> 31 ) ) ^ ( ( x >> 6 ) & ( x >> 14 ) & ( x >> 18 ) ) ^ ( x >> 27 )
    GPR[rd] <- r
  }

  grain.onn0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 2 ) ^ ( x >> 15 )
    GPR[rd] <- r
  }

  grain.onn1 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 4 ) ^ ( x >> 13 )
    GPR[rd] <- r
  }

  grain.onn2 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x ) ^ ( x >> 9 ) ^ ( x >> 25 )
    GPR[rd] <- r
  }

  grain.oln0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 13 ) & ( x >> 20 )
    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `GRAIN_RV64_TYPE1`: baseline ISA.

- `GRAIN_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] M. Hell, T. Johansson, A. Maximov, W. Meier, J. Sönnerup, and H. Yoshida.
    [Grain-128AEADv2 - A lightweight AEAD stream cipher](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/grain-128aead-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.

<!--- -------------------------------------------------------------------- --->
