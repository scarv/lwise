<!--- -------------------------------------------------------------------- --->

## Notation

- define the look-up tables

  ```
  ROT_0 = { 19, 61,  1, 10,  7 }
  ROT_1 = { 28, 39,  6, 17, 41 }
  ```

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `ascon`    | `rv32`    | `ASCON_RV32_UNROLL`    | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `ascon`    | `rv32`    | `ASCON_RV32_TYPE1`     | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `ascon`    | `rv32`    | `ASCON_RV32_TYPE2`     | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `ascon`    | `rv64`    | `ASCON_RV64_UNROLL`    | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `ascon`    | `rv64`    | `ASCON_RV64_TYPE1`     | select 64-bit RISC-V base ISA:          option 1, per description below |
|           | `ascon`    | `rv64`    | `ASCON_RV64_TYPE2`     | select 64-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ASCON_RV32_TYPE1`: base ISA.

- `ASCON_RV32_TYPE2`: base ISA plus ISE.

  ```
  ascon.sigma.lo rd, rs1, rs2, imm {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]
    x       <- x_hi || x_lo
    r       <- x ^ ( x >>> ROT_0[ imm ] ) ^ ( x >>> ROT_1[ imm ] )
    GPR[rd] <- r_{31.. 0}
  }

  ascon.sigma.hi rd, rs1, rs2, imm {
    x_hi    <- GPR[rs2]
    x_lo    <- GPR[rs1]
    x       <- x_hi || x_lo
    r       <- x ^ ( x >>> ROT_0[ imm ] ) ^ ( x >>> ROT_1[ imm ] )
    GPR[rd] <- r_{63..32}
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ASCON_RV64_TYPE1`: base ISA.

- `ASCON_RV64_TYPE2`: base ISA plus ISE.

  ```
  ascon.sigma    rd, rs1,      imm {
    x       <- GPR[rs1]
    r       <- x ^ ( x >>> ROT_0[ imm ] ) ^ ( x >>> ROT_1[ imm ] )
    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->
