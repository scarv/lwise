<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `grain`    | `rv32`    | `GRAIN_RV32_UNROLL`    | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `grain`    | `rv32`    | `GRAIN_RV32_TYPE1`     | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `grain`    | `rv32`    | `GRAIN_RV32_TYPE2`     | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `GRAIN_RV32_TYPE1`: base ISA.

- `GRAIN_RV32_TYPE2`: base ISA plus ISE.

  ```
  grain.extr rd, rs1, rs2, imm {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- x >> imm
    GPR[rd] <- r_{31.. 0}
  }

  grain.fln0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x_lo ) ^ ( x >> 7 )
    GPR[rd] <- r_{31.. 0}
  }

  grain.fln2 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x_hi ) ^ ( x >> 6 ) ^ ( x >> 17 )
    GPR[rd] <- r_{31.. 0}
  }

  grain.gnn0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x_lo ) ^ ( x >> 26 ) ^ ( ( x >> 11 ) & ( x >> 13 ) ) ^ ( ( x >> 17 ) & ( x >> 18 ) ) ^ ( ( x >> 22 ) & ( x >> 24 ) & ( x >> 25 ) )
    GPR[rd] <- r_{31.. 0}
  }

  grain.gnn1 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 24 ) ^ ( ( x >> 8 ) & ( x >> 16 ) )
    GPR[rd] <- r_{31.. 0}
  }

  grain.gnn2 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x_hi ) ^ ( x >> 27 ) ^ ( ( x >> 4 ) & ( x >> 20 ) ) ^ ( ( x >> 24 ) & ( x >> 28 ) & ( x >> 29 ) & ( x >> 31 ) ) ^ ( ( x >> 6 ) & ( x >> 14 ) & ( x >> 18 ) )
    GPR[rd] <- r_{31.. 0}
  }

  grain.hnn0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 2 ) ^ ( x >> 15 )
    GPR[rd] <- r_{31.. 0}
  }

  grain.hnn1 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 4 ) ^ ( x >> 13 )
    GPR[rd] <- r_{31.. 0}
  }

  grain.hnn2 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x_lo ) ^ ( x >> 9 ) ^ ( x >> 25 )
    GPR[rd] <- r_{31.. 0}
  }

  grain.hln0 rd, rs1, rs2      {
    x_hi    <- GPR[rs1]
    x_lo    <- GPR[rs2]
    x       <- x_hi || x_lo
    r       <- ( x >> 13 ) & ( x >> 20 )
    GPR[rd] <- r_{31.. 0}
  }
  ```

<!--- -------------------------------------------------------------------- --->
