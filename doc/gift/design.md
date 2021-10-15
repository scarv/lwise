# `${ALG} = "gift"`

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROL32` (resp. `ROL4`, `ROL8`, `ROL16`, and `ROL64`) to denote a 32-bit (resp. 4-bit, 8-bit, 16-bit, and 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR4`, `ROR8`, `ROR16`, and `ROR64`) to denote a 32-bit (resp. 4-bit, 8-bit, 16-bit, and 64-bit) right-rotate,
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

## Context

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
|           | `gift`     | `rv32`    | `GIFT_RV32_TYPE1`     | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `gift`     | `rv32`    | `GIFT_RV32_TYPE2`     | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `gift`     | `rv64`    | `GIFT_RV64_TYPE1`     | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `GIFT_RV32_TYPE1`: base ISA.

- `GIFT_RV32_TYPE2`: base ISA plus custom ISE.

  ```
  gift.swapmove   rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    m       <- GPR[rs2]
    r       <- SWAPMOVE32( x, m, imm )
    GPR[rd] <- r
  }
  ```

  Note that this operation is *already* more special-purpose than the
  original definition of `SWAPMOVE`, in the sense it moves bits in an
  intra-word vs. inter-word manner.  It is at least possible to think
  about a *further* specialisation, because GIFT-COFB uses a fairly
  small set of masks (`m`) and distances (`imm`).

  ```
  gift.rori.n     rd, rs1,      imm {
    x_7     <- GPR[rs1]_{31..28}
    x_6     <- GPR[rs1]_{27..24}
    x_5     <- GPR[rs1]_{23..20}
    x_4     <- GPR[rs1]_{19..16}
    x_3     <- GPR[rs1]_{15..12}
    x_2     <- GPR[rs1]_{11.. 8}
    x_1     <- GPR[rs1]_{ 7.. 4}
    x_0     <- GPR[rs1]_{ 3.. 0}
    r       <- ROR4 ( x_7, imm ) | ROR4 ( x_6, imm ) | 
               ROR4 ( x_5, imm ) | ROR4 ( x_4, imm ) | 
               ROR4 ( x_3, imm ) | ROR4 ( x_2, imm ) | 
               ROR4 ( x_1, imm ) | ROR4 ( x_0, imm ) 
    GPR[rd] <- r
  }
  
  gift.rori.b     rd, rs1,      imm {
    x_3     <- GPR[rs1]_{31..24}
    x_2     <- GPR[rs1]_{23..16}
    x_1     <- GPR[rs1]_{15.. 8}
    x_0     <- GPR[rs1]_{ 7.. 0}
    r       <- ROR8 ( x_3, imm ) | ROR8 ( x_2, imm ) | 
               ROR8 ( x_1, imm ) | ROR8 ( x_0, imm ) 
    GPR[rd] <- r
  }
  
  gift.rori.h     rd, rs1,      imm {
    x_1     <- GPR[rs1]_{31..16}
    x_0     <- GPR[rs1]_{15.. 0}
    r       <- ROR16( x_1, imm ) | ROR16( x_0, imm )
    GPR[rd] <- r
  }
    
  gift.key.reorg  rd, rs1,      imm {
    x       <- GPR[rs1]  

    if      ( imm = 0 ) {
      r <- SWAPMOVE32( x, 0x00550055,  9 )
      r <- SWAPMOVE32( r, 0x00003333, 18 )
      r <- SWAPMOVE32( r, 0x000F000F, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    }
    else if ( imm = 1 ) {
      r <- SWAPMOVE32( x, 0x11111111,  3 )
      r <- SWAPMOVE32( r, 0x03030303,  6 )
      r <- SWAPMOVE32( r, 0x000F000F, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    else if ( imm = 2 ) {
      r <- SWAPMOVE32( x, 0x0000AAAA, 15 )
      r <- SWAPMOVE32( r, 0x00003333, 18 )
      r <- SWAPMOVE32( r, 0x0000F0F0, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    else if ( imm = 3 ) {
      r <- SWAPMOVE32( x, 0x0A0A0A0A,  3 )
      r <- SWAPMOVE32( r, 0x00CC00CC,  6 )
      r <- SWAPMOVE32( r, 0x0000F0F0, 12 )
      r <- SWAPMOVE32( r, 0x000000FF, 24 )
    }

    GPR[rd] <- r
  }
  
  gift.key.updstd rd, rs1           {
    x       <- GPR[rs1]

      r <-     ( ( x >> 12 ) & 0x0000000F ) 
      r <- r | ( ( x & 0x00000FFF ) <<  4 )
      r <- r | ( ( x >>  2 ) & 0x3FFF0000 ) 
      r <- r | ( ( x & 0x00030000 ) << 14 )

    GPR[rd] <- r
  }
  
  gift.key.updfix rd, rs1,      imm {
    x       <- GPR[rs1]

    if      ( imm = 0 ) {
      r <- SWAPMOVE32( x, 0x00003333, 16 )
      r <- SWAPMOVE32( r, 0x55554444,  1 )
    }
    else if ( imm = 1 ) {
      r <-     ROR32( x & 0x33333333, 24 )
      r <- r | ROR32( x & 0xCCCCCCCC, 16 )
      r <- SWAPMOVE32( r, 0x55551100,  1 )
    }
    else if ( imm = 2 ) {
      r <-     ( ( x >>  4 ) & 0x0F000F00 ) 
      r <- r | ( ( x & 0x0F000F00 ) <<  4 )
      r <- r | ( ( x >>  6 ) & 0x00030003 )
      r <- r | ( ( x & 0x003F003F ) <<  2 )
    }
    else if ( imm = 3 ) { 
      r <-     ( ( x >>  6 ) & 0x03000300 )
      r <- r | ( ( x & 0x3F003F00 ) <<  2 )
      r <- r | ( ( x >>  5 ) & 0x00070007 )
      r <- r | ( ( x & 0x001F001F ) <<  3 )
    }
    else if ( imm = 4 ) {
      r <-     ROR32( x & 0xAAAAAAAA, 24 )
      r <- r | ROR32( x & 0x55555555, 16 )
    }
    else if ( imm = 5 ) {
      r <-     ROR32( x & 0x55555555, 24 )
      r <- r | ROR32( x & 0xAAAAAAAA, 20 )
    }
    else if ( imm = 6 ) {
      r <-     ( ( x >>  2 ) & 0x03030303 ) 
      r <- r | ( ( x & 0x03030303 ) <<  2 )
      r <- r | ( ( x >>  1 ) & 0x70707070 )
      r <- r | ( ( x & 0x10101010 ) <<  3 )
    }
    else if ( imm = 7 ) {
      r <-     ( ( x >> 18 ) & 0x00003030 )
      r <- r | ( ( x & 0x01010101 ) <<  3 )
      r <- r | ( ( x >> 14 ) & 0x0000C0C0 )
      r <- r | ( ( x & 0x0000E0E0 ) << 15 )
      r <- r | ( ( x >>  1 ) & 0x07070707 )
      r <- r | ( ( x & 0x00001010 ) << 19 )
    }
    else if ( imm = 8 ) {
      r <-     ( ( x >>  4 ) & 0x0FFF0000 )
      r <- r | ( ( x & 0x000F0000 ) << 12 )
      r <- r | ( ( x >>  8 ) & 0x000000FF )
      r <- r | ( ( x & 0x000000FF ) <<  8 )
    }
    else if ( imm = 9 ) {
      r <-     ( ( x >>  6 ) & 0x03FF0000 ) 
      r <- r | ( ( x & 0x003F0000 ) << 10 )
      r <- r | ( ( x >>  4 ) & 0x00000FFF ) 
      r <- r | ( ( x & 0x0000000F ) << 12 )
    }

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `GIFT_RV64_TYPE1`: baseline ISA.

<!--- -------------------------------------------------------------------- --->

## References

[1] S. Banik, A. Chakraborti, T. Iwata, K. Minematsu, M. Nandi, T. Peyrin, Y. Sasaki, S.M. Sim, Y. Todo.
    [GIFT-COFB](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/gift-cofb-spec-final.pdf).
    Submission to NIST (version 1.1), 2021.

[2] L. May and L. Penna and A. Clark.
    [An Implementation of Bitsliced DES on the Pentium MMX Processor](https://link.springer.com/chapter/10.1007/10718964_10).
    Australasian Conference on Information Security and Privacy (ACISP). Springer-Verlag, LNCS 1841, 112--122, 2000.

<!--- -------------------------------------------------------------------- --->
