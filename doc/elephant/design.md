<!--- -------------------------------------------------------------------- --->

## Notation

- define the functions

  ```
  SWAPMOVE32_X(x,y,m,n) {
    t <- y ^ ( x >> n )
    t <- t & m
    x <- x ^ ( t << n )

    return x
  }

  SWAPMOVE32_Y(x,y,m,n) {
    t <- y ^ ( x >> n )
    t <- t & m
    y <- y ^ ( t      )

    return y
  }
  ```
  
  i.e., a 32-bit variants of `SWAPMOVE`.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE1`  | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE2`  | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ELEPHANT_RV32_TYPE1`: base ISA.

- `ELEPHANT_RV32_TYPE2`: base ISA plus ISE.

  ```
  elephant.xoricr  rd, rs1,      imm {
    x       <- GPR[rs1]

    r       <- x ^ ( imm << 24 )

    GPR[rd] <- r
  }  

  elephant.sstep   rd, rs1           {
    x       <- GPR[rs1]

    r       <- SBOX[ x_{31..28} ] || SBOX[ x_{27..24} ] ||
               SBOX[ x_{23..20} ] || SBOX[ x_{19..16} ] ||
               SBOX[ x_{15..12} ] || SBOX[ x_{11.. 8} ] ||
               SBOX[ x_{ 7.. 4} ] || SBOX[ x_{ 3.. 0} ] 
               
    r       <- SWAPMOVE32( r, 0x0A0A0A0A,  3 )
    r       <- SWAPMOVE32( r, 0x00CC00CC,  6 )
    r       <- SWAPMOVE32( r, 0x0000F0F0, 12 )
    r       <- SWAPMOVE32( r, 0x0000FF00,  8 )

    GPR[rd] <- r
  }

  elephant.pstep.x rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if      ( imm == 0 ) { 
      r <- SWAPMOVE32_X( x, y, 0x000000FF,  8 )
    }
    else if ( imm == 1 ) {
      r <- SWAPMOVE32_X( x, y, 0x000000FF, 16 )
    }
    else if ( imm == 2 ) {
      r <- SWAPMOVE32_X( x, y, 0x000000FF, 24 )
    }
    else if ( imm == 3 ) {
      r <- SWAPMOVE32_X( x, y, 0x0000FF00,  8 )
    }
    else if ( imm == 4 ) {
      r <- SWAPMOVE32_X( x, y, 0x000000FF, 24 ) >>> 24
    }
    else if ( imm == 5 ) {
      r <- SWAPMOVE32_X( x, y, 0x0000FF00, 16 ) >>> 16
    }
    else if ( imm == 6 ) {
      r <- SWAPMOVE32_X( x, y, 0x00FF0000,  8 ) >>>  8
    }

    GPR[rd] <- r
  }

  elephant.pstep.y rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if      ( imm == 0 ) { 
      r <- SWAPMOVE32_Y( x, y, 0x000000FF,  8 )
    }
    else if ( imm == 1 ) {
      r <- SWAPMOVE32_Y( x, y, 0x000000FF, 16 )
    }
    else if ( imm == 2 ) {
      r <- SWAPMOVE32_Y( x, y, 0x000000FF, 24 )
    }
    else if ( imm == 3 ) {
      r <- SWAPMOVE32_Y( x, y, 0x0000FF00,  8 )
    }
    else if ( imm == 4 ) {
      r <- SWAPMOVE32_Y( x, y, 0x000000FF, 24 )
    }
    else if ( imm == 5 ) {
      r <- SWAPMOVE32_Y( x, y, 0x0000FF00, 16 )
    }
    else if ( imm == 6 ) {
      r <- SWAPMOVE32_Y( x, y, 0x00FF0000,  8 )
    }

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->
