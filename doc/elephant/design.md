# `${ALG} = "elephant"`

<!--- -------------------------------------------------------------------- --->

## Notation

- define

  ```
  SWAPMOVE32(x,  m,n) {
    t = x ^ ( x >> n )
    t = t & m
    t = t ^ ( t << n )
    x = t ^ x

    return x
  }
  ```
  
  i.e., a 32-bit version of some more general `SWAPMOVE`.

<!--- -------------------------------------------------------------------- --->

## Discussion

SWAPMOVE *seems* to have been first defined in [Sec. 3.1, 2], although
even that cites prior art (e.g., libdes).  Either way, that definition
is (with some cosmetic alterations) as follows:

  ```
  SWAPMOVE(x,y,m,n) {
    t = y ^ ( x >> n )
    t = t & m
    x = x ^ ( t << n )
    y = y ^ ( t      )

    return ( x, y )
  }
  ```

The basic idea is that
the bits in  `y` masked by `m`
are swapped with
the bits in  `x` masked by `m << n`.
Or put even more simply,
some bits in `y`
are swapped with
some bits in `x`
with the bits in question controlled by `n` and `m`.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE1` | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE2` | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE3` | select 32-bit RISC-V baseline ISA plus custom ISE: option 3, per description below                             |
|           | `elephant` | `rv64`    | `ELEPHANT_RV64_TYPE1` | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `elephant` | `rv64`    | `ELEPHANT_RV64_TYPE2` | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ELEPHANT_RV32_TYPE1`: baseline ISA.

- `ELEPHANT_RV32_TYPE2`: baseline ISA plus custom ISE.

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

- `ELEPHANT_RV32_TYPE3`: baseline ISA plus custom ISE.

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

## `${IMP} = "rv64"`

- `ELEPHANT_RV64_TYPE1`: baseline ISA.

- `ELEPHANT_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] T. Beyne, Y. L. Chen, C. Dobraunig, and B. Mennink.
    [Elephant](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/elephant-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.
    
[2] M. Lemmen.
    [Optimizing Elephant for RISC-V](https://www.cs.ru.nl/bachelors-theses/2020/Mauk_Lemmen___4798937___Optimizing_Elephant_for_RISC-V.pdf).
    BSc Thesis, Radboud University, 2020.

<!--- -------------------------------------------------------------------- --->
