<!--- -------------------------------------------------------------------- --->

## Notation

- define the function

  ```
  SWAPMOVE32(x,m,n) {
    t <- x ^ ( x >> n )
    t <- t & m
    t <- t ^ ( t << n )
    x <- t ^ x

    return x
  }
  ```
  
  i.e., a 32-bit variant of `SWAPMOVE`.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `gift`     | `rv32`    | `GIFT_RV32_UNROLL`     | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `gift`     | `rv32`    | `GIFT_RV32_TYPE1`      | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `gift`     | `rv32`    | `GIFT_RV32_TYPE2`      | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `gift`     | `rv32`    | `GIFT_RV32_TYPE3`      | select 32-bit RISC-V base ISA plus ISE: option 3, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `GIFT_RV32_TYPE1`: base ISA.

- `GIFT_RV32_TYPE2`: base ISA plus ISE.

  ```
  gift.swapmove   rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    m       <- GPR[rs2]
    r       <- SWAPMOVE32( x, m, imm )
    GPR[rd] <- r
  }

  gift.rori.n     rd, rs1,      imm {
    x_7     <- GPR[rs1]_{31..28}
    x_6     <- GPR[rs1]_{27..24}
    x_5     <- GPR[rs1]_{23..20}
    x_4     <- GPR[rs1]_{19..16}
    x_3     <- GPR[rs1]_{15..12}
    x_2     <- GPR[rs1]_{11.. 8}
    x_1     <- GPR[rs1]_{ 7.. 4}
    x_0     <- GPR[rs1]_{ 3.. 0}
    r       <- ( x_7 >>> imm ) || ( x_6 >>> imm ) || 
               ( x_5 >>> imm ) || ( x_4 >>> imm ) || 
               ( x_3 >>> imm ) || ( x_2 >>> imm ) || 
               ( x_1 >>> imm ) || ( x_0 >>> imm ) 
    GPR[rd] <- r
  }
  
  gift.rori.b     rd, rs1,      imm {
    x_3     <- GPR[rs1]_{31..24}
    x_2     <- GPR[rs1]_{23..16}
    x_1     <- GPR[rs1]_{15.. 8}
    x_0     <- GPR[rs1]_{ 7.. 0}
    r       <- ( x_3 >>> imm ) || ( x_2 >>> imm ) || 
               ( x_1 >>> imm ) || ( x_0 >>> imm ) 
    GPR[rd] <- r
  }
  
  gift.rori.h     rd, rs1,      imm {
    x_1     <- GPR[rs1]_{31..16}
    x_0     <- GPR[rs1]_{15.. 0}
    r       <- ( x_1 >>> imm ) || ( x_0 >>> imm )
    GPR[rd] <- r
  }
    
  gift.key.reorg  rd, rs1,      imm {
    x       <- GPR[rs1]  

    if      ( imm == 0 ) {
      r <- SWAPMOVE32( x, 0x00550055,  9 )
      r <- SWAPMOVE32( r, 0x00003333, 18 )
      r <- SWAPMOVE32( r, 0x000F000F, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    }
    else if ( imm == 1 ) {
      r <- SWAPMOVE32( x, 0x11111111,  3 )
      r <- SWAPMOVE32( r, 0x03030303,  6 )
      r <- SWAPMOVE32( r, 0x000F000F, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    else if ( imm == 2 ) {
      r <- SWAPMOVE32( x, 0x0000AAAA, 15 )
      r <- SWAPMOVE32( r, 0x00003333, 18 )
      r <- SWAPMOVE32( r, 0x0000F0F0, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    else if ( imm == 3 ) {
      r <- SWAPMOVE32( x, 0x0A0A0A0A,  3 )
      r <- SWAPMOVE32( r, 0x00CC00CC,  6 )
      r <- SWAPMOVE32( r, 0x0000F0F0, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    }

    GPR[rd] <- r
  }
  
  gift.key.updstd rd, rs1           {
    x       <- GPR[rs1]

    r       <-     ( ( x >> 12 ) & 0x0000000F ) 
    r       <- r | ( ( x & 0x00000FFF ) <<  4 )
    r       <- r | ( ( x >>  2 ) & 0x3FFF0000 ) 
    r       <- r | ( ( x & 0x00030000 ) << 14 )

    GPR[rd] <- r
  }
  
  gift.key.updfix rd, rs1,      imm {
    x       <- GPR[rs1]

    if      ( imm == 0 ) {
      r <- SWAPMOVE32( x, 0x00003333, 16 )
      r <- SWAPMOVE32( r, 0x55554444,  1 )
    }
    else if ( imm == 1 ) {
      r <-     ( ( x & 0x33333333 ) >>> 24 )
      r <- r | ( ( x & 0xCCCCCCCC ) >>> 16 )
      r <- SWAPMOVE32( r, 0x55551100,  1 )
    }
    else if ( imm == 2 ) {
      r <-     ( ( x >>  4 ) & 0x0F000F00 ) | ( ( x & 0x0F000F00 ) <<  4 )
      r <- r | ( ( x >>  6 ) & 0x00030003 ) | ( ( x & 0x003F003F ) <<  2 )
    }
    else if ( imm == 3 ) { 
      r <-     ( ( x >>  6 ) & 0x03000300 ) | ( ( x & 0x3F003F00 ) <<  2 )
      r <- r | ( ( x >>  5 ) & 0x00070007 ) | ( ( x & 0x001F001F ) <<  3 )
    }
    else if ( imm == 4 ) {
      r <-     ( ( x & 0xAAAAAAAA ) >>> 24 )
      r <- r | ( ( x & 0x55555555 ) >>> 16 )
    }
    else if ( imm == 5 ) {
      r <-     ( ( x & 0x55555555 ) >>> 24 )
      r <- r | ( ( x & 0xAAAAAAAA ) >>> 20 )
    }
    else if ( imm == 6 ) {
      r <-     ( ( x >>  2 ) & 0x03030303 ) | ( ( x & 0x03030303 ) <<  2 )
      r <- r | ( ( x >>  1 ) & 0x70707070 ) | ( ( x & 0x10101010 ) <<  3 )
    }
    else if ( imm == 7 ) {
      r <-     ( ( x >> 18 ) & 0x00003030 ) | ( ( x & 0x01010101 ) <<  3 )
      r <- r | ( ( x >> 14 ) & 0x0000C0C0 ) | ( ( x & 0x0000E0E0 ) << 15 )
      r <- r | ( ( x >>  1 ) & 0x07070707 ) | ( ( x & 0x00001010 ) << 19 )
    }
    else if ( imm == 8 ) {
      r <-     ( ( x >>  4 ) & 0x0FFF0000 ) | ( ( x & 0x000F0000 ) << 12 )
      r <- r | ( ( x >>  8 ) & 0x000000FF ) | ( ( x & 0x000000FF ) <<  8 )
    }
    else if ( imm == 9 ) {
      r <-     ( ( x >>  6 ) & 0x03FF0000 ) | ( ( x & 0x003F0000 ) << 10 )
      r <- r | ( ( x >>  4 ) & 0x00000FFF ) | ( ( x & 0x0000000F ) << 12 )
    }

    GPR[rd] <- r
  }
  ```

- `GIFT_RV32_TYPE3`: base ISA plus ISE.

  ```
  gift.permbits.step rd, rs1, imm   {
    x       <- GPR[rs1]  

    r       <- SWAPMOVE32( x, 0x0A0A0A0A,  3 )
    r       <- SWAPMOVE32( r, 0x00CC00CC,  6 )
    r       <- SWAPMOVE32( r, 0x0000F0F0, 12 )
    r       <- SWAPMOVE32( r, 0x000000FF, 24 )
    r       <- r >>> imm

    GPR[rd] <- r
  }

  gift.key.updstd rd, rs1           {
    x       <- GPR[rs1]

    r       <-     ( ( x >> 12 ) & 0x0000000F ) 
    r       <- r | ( ( x & 0x00000FFF ) <<  4 )
    r       <- r | ( ( x >>  2 ) & 0x3FFF0000 ) 
    r       <- r | ( ( x & 0x00030000 ) << 14 )

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->
