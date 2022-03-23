<!--- -------------------------------------------------------------------- --->

## Notation

- define the function

  ```
  SWAPMOVE32(x,m,n) {
    t = x ^ ( x >> n )
    t = t & m
    t = t ^ ( t << n )
    x = t ^ x

    return x
  }
  ```
  
  i.e., a 32-bit version of some more general `SWAPMOVE`.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE1`  | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE2`  | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE3`  | select 32-bit RISC-V base ISA plus ISE: option 3, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ELEPHANT_RV32_TYPE1`: base ISA.

- `ELEPHANT_RV32_TYPE2`: base ISA plus ISE.

  ```
  elephant.bsllxor   rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( (   y         & 0xFF ) << imm )
    GPR[rd] <- r
  }

  elephant.bup       rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- ( x << ( imm - y     ) ) & ( 1 << imm )
    GPR[rd] <- r
  }

  elephant.pstep1    rd, rs1           {
    x       <- GPR[rs1]
    r       <- SWAPMOVE32( x, 0x0A0A0A0AUL,  3 )
    r       <- SWAPMOVE32( r, 0x00CC00CCUL,  6 )
    r       <- SWAPMOVE32( r, 0x0000F0F0UL, 12 )
    r       <- SWAPMOVE32( r, 0x000000FFUL, 24 ) 
    GPR[rd] <- r
  }
  ```

- `ELEPHANT_RV32_TYPE3`: base ISA plus ISE.

  ```
  elephant.bupd      rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r_0     <- ( x << ( imm - y     ) ) & ( 1 << imm )
    r_1     <- ( x << ( imm - y - 3 ) ) & ( 2 << imm )
    r       <- r_0 ^ r_1
    GPR[rd] <- r
  }

  elephant.pstep1    rd, rs1           {
    x       <- GPR[rs1]
    r       <- SWAPMOVE32( x, 0x0A0A0A0AUL,  3 )
    r       <- SWAPMOVE32( r, 0x00CC00CCUL,  6 )
    r       <- SWAPMOVE32( r, 0x0000F0F0UL, 12 )
    r       <- SWAPMOVE32( r, 0x000000FFUL, 24 ) 
    GPR[rd] <- r
  }

  elephant.pstep2.0  rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( ( ( y >>  0 ) & 0xFF ) << imm )
    GPR[rd] <- r
  }

  elephant.pstep2.8  rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( ( ( y >>  8 ) & 0xFF ) << imm )
    GPR[rd] <- r
  }

  elephant.pstep2.16 rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( ( ( y >> 16 ) & 0xFF ) << imm )
    GPR[rd] <- r
  }

  elephant.pstep2.24  rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( ( ( y >> 24 ) & 0xFF ) << imm )
    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->
