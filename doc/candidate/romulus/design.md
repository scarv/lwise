# `${ALG} = "romulus"`

<!--- -------------------------------------------------------------------- --->

## Notation

- use `ROL32` (resp. `ROL64`) to denote a 32-bit (resp. 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate,
- capture the 6-bit, round constant LFSR update function using

  ```
  RC_LFSR_FWD( x ) {
    return < x_4, x_3, x_2, x_1, x_0, x_5 ^ x_4 ^ 1 >
  }

  RC_LFSR_REV( x ) {
    return < x_5 ^ x_0 ^ 1, x_4, x_3, x_2, x_1, x_0 >
  }
  ```

- capture the the 8-bit, tweakey    LFSR update function using

  ```
  TK2_LFSR_FWD( x ) {
    return < x_6, x_5, x_4, x_3, x_2, x_1, x_0, x_5 ^ x_7 >
  }

  TK2_LFSR_REV( x ) {
    return < x_6 ^ x_0, x_6, x_5, x_4, x_3, x_2, x_1, x_0 >
  }

  TK3_LFSR_FWD( x ) {
    return < x_6 ^ x_0, x_7, x_6, x_5, x_4, x_3, x_2, x_1 >
  }

  TK3_LFSR_REV( x ) {
    return < x_6, x_5, x_4, x_3, x_2, x_1, x_0, x_5 ^ x_7 >
  }
  ```

- define various look-up tables: 
  `SBOX_ENC` 
  and 
  `SBOX_DEC`, 
  for example, are the 8-bit Skinny encryption and decryption S-boxes defined in
  [Tab. 2.1, 1](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/romulus-spec-final.pdf).

<!--- -------------------------------------------------------------------- --->

## Context

- There are 4 varients of Romulus [1], namely

  1. Romulus-N (nonce-based AE)
  2. Romulus-M (misuse-resistant AE)
  3. Romulus-T (leakage-resilient AE)
  4. Romulus-H (hash function)

  which are all based on the Skinny [2] tweakable block cipher.  More
  specifically, Romulus uses
  Skinny-128-384+, 
  a reduced-round version of 
  Skinny-128-384: 
  it uses 40 rather than 56 rounds, and has a 
  128-bit block   size
  and
  384-bit tweakey size.

- The design of Skinny is SP-like:

  - The state is a $( 4 \times 4 )$-element matrix of $8$-bit cells, which
    means a total size of $128$ bits.

  - The computation involves 40 rounds of

    - `SubCells`
    - `AddConstants`
    - `AddRoundTweakey`
    - `ShiftRows`
    - `MixColumns`

    wherein `SubCells` uses an 8-bit S-box denoted S_8.

- There are some chances to improve or strealine the ISE, e.g.,

  - Romulus only makes use of Skinny-based encryption; clearly it's be
    possible to provide support for decryption, e.g., when aiming for
    an ISA for Skinny itself vs. Romulus.
  - Use of the round constants, once generated is the same for both
    encryption and decryption,
    so there is a chance to reduce the number of instruction encodings.
  - The tweakey LFSRs are inverses of each other, e.g., 
    `TK2_LFSR_FWD`
    is the inverse of 
    `TK3_LFSR_REV`
    so there is a chance to reduce the number of instruction encodings.
  - Probably it'd make sense to adopt a different approach for 64-bit
    instances of Skinny; [3] does so, but it could be viewed as being
    too general purpose (e.g., the Skinny S-box is very light-weight,
    so the generalised S-box instruction might be viewed as overkill).

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `romulus`  |           | `ROMULUS_UNROLL`      | use fully (vs. partially, by a factor of two) unrolled implementation                                          |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE1`  | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE2`  | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE1`  | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE2`  | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ROMULUS_RV32_TYPE1`: baseline ISA.

- `ROMULUS_RV32_TYPE2`: baseline ISA plus custom ISE.

  ```
  romulus.rstep.enc    rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm == 2 ) {
      y <- 2
    }
    else if( imm == 3 ) {
      y <- 0
    }

    t       <- SBOX[ x_{31..24} ] || SBOX[ x_{23..16} ] ||
               SBOX[ x_{15.. 8} ] || SBOX[ x_{ 7.. 0} ]

    t       <- t ^ y

    if     ( imm == 0 ) {
      r <- ROL32( t,  0 )
    }
    else if( imm == 1 ) {
      r <- ROL32( t,  8 )
    }
    else if( imm == 2 ) {
      r <- ROL32( t, 16 )
    }
    else if( imm == 3 ) {
      r <- ROL32( t, 24 )
    }

    GPR[rd] <- r
  }

  romulus.rc.upd.enc   rd, rs1           {
    x       <- GPR[rs1]
    r       <- LFSR_RC( x )
    GPR[rd] <- r
  }

  romulus.rc.use.enc.0 rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- y ^ x_{3..0}
    GPR[rd] <- r
  }

  romulus.rc.use.enc.1 rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- y ^ x_{6..4}
    GPR[rd] <- r
  }

  romulus.tk.upd.enc.0 rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm == 1 ) {
      r <-           x_{31..24}   ||           y_{ 7.. 0}   ||
                     y_{23..16}   ||           x_{23..16}  
    }
    else if( imm == 2 ) {
      r <- LFSR_TK2( y_{16.. 8} ) || LFSR_TK2( x_{ 7.. 0} ) ||
           LFSR_TK2( y_{31..24} ) || LFSR_TK2( x_{15.. 8} )
    }
    else if( imm == 3 ) {
      r <- LFSR_TK3( y_{15.. 8} ) || LFSR_TK3( x_{ 7.. 0} ) ||
           LFSR_TK3( y_{31..24} ) || LFSR_TK3( x_{15.. 8} )
    }

    GPR[rd] <- r
  }

  romulus.tk.upd.enc.1 rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm == 1 ) {
      r <-           x_{31..24}   ||           y_{ 7.. 0}   ||
                     y_{23..16}   ||           x_{23..16}  
    }
    else if( imm == 2 ) {
      r <- LFSR_TK2( x_{31..24} ) || LFSR_TK2( y_{ 7.. 0} ) ||
           LFSR_TK2( y_{23..16} ) || LFSR_TK2( x_{23..16} )
    }
    else if( imm == 3 ) {
      r <- LFSR_TK3( x_{31..24} ) || LFSR_TK3( y_{ 7.. 0} ) ||
           LFSR_TK3( y_{23..16} ) || LFSR_TK3( x_{23..16} )
    }

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ROMULUS_RV64_TYPE1`: baseline ISA.

- `ROMULUS_RV64_TYPE2`: baseline ISA plus custom ISE.

  ```
  romulus.rstep.enc    rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm == 1 ) {
      y <- 2
    }

    t       <- SBOX[ x_{63..56} ] || SBOX[ x_{55..48} ] ||
               SBOX[ x_{47..40} ] || SBOX[ x_{39..32} ] ||
               SBOX[ x_{31..24} ] || SBOX[ x_{23..16} ] ||
               SBOX[ x_{15.. 8} ] || SBOX[ x_{ 7.. 0} ]

    t       <- t ^ y

    if     ( imm == 0 ) {
      r <- ROL32( t_{63..32},  8 ) || ROL32( t_{31.. 0},  0 )
    }
    else if( imm == 1 ) {
      r <- ROL32( t_{63..32}, 16 ) || ROL32( t_{31.. 0}, 24 )
    }

    GPR[rd] <- r
  }

  romulus.cstep.enc    rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    t_0     <- y_{39..32} || y_{ 7.. 0} || x_{30..32} || x_{ 7.. 0}
    t_1     <- y_{47..40} || y_{15.. 8} || x_{47..40} || x_{15.. 8}
    t_2     <- y_{55..48} || y_{23..16} || x_{55..48} || x_{23..16}
    t_3     <- y_{63..56} || y_{31..24} || x_{63..56} || x_{31..24}

    t_0     <- (                t_0_{23..16} ^                t_0_{ 7.. 0} ) ||
               (                t_0_{23..16} ^ t_0_{15.. 8}                ) ||
               (                                              t_0_{ 7.. 0} ) ||
               ( t_0_{31..24} ^ t_0_{23..16} ^                t_0_{ 7.. 0} )
    t_1     <- (                t_1_{23..16} ^                t_1_{ 7.. 0} ) ||
               (                t_1_{23..16} ^ t_1_{15.. 8}                ) ||
               (                                              t_1_{ 7.. 0} ) ||
               ( t_1_{31..24} ^ t_1_{23..16} ^                t_1_{ 7.. 0} )
    t_2     <- (                t_2_{23..16} ^                t_2_{ 7.. 0} ) ||
               (                t_2_{23..16} ^ t_2_{15.. 8}                ) ||
               (                                              t_2_{ 7.. 0} ) ||
               ( t_2_{31..24} ^ t_2_{23..16} ^                t_2_{ 7.. 0} )
    t_3     <- (                t_3_{23..16} ^                t_3_{ 7.. 0} ) ||
               (                t_3_{23..16} ^ t_3_{15.. 8}                ) ||
               (                                              t_3_{ 7.. 0} ) ||
               ( t_3_{31..24} ^ t_3_{23..16} ^                t_3_{ 7.. 0} )

    if     ( imm == 0 ) {
      r <- t_3_{15.. 8} || t_2_{15.. 8} || t_1_{15.. 8} || t_0_{15.. 8} ||
           t_3_{ 7.. 0} || t_2_{ 7.. 0} || t_1_{ 7.. 0} || t_0_{ 7.. 0}
    }
    else if( imm == 1 ) {
      r <- t_3_{31..24} || t_2_{31..24} || t_1_{31..24} || t_0_{31..24} ||
           t_3_{23..16} || t_2_{23..16} || t_1_{23..16} || t_0_{23..16}
    }

    GPR[rd] <- r
  }

  romulus.rc.upd.enc   rd, rs1           {
    x       <- GPR[rs1]
    r       <- LFSR_RC( x )
    GPR[rd] <- r
  }

  romulus.rc.use.enc   rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- y ^ ( x_{3..0} <<  0 ) ^ 
                   ( x_{6..4} << 32 )
    GPR[rd] <- r
  }

  romulus.tk.upd.enc   rd, rs1,      imm {
    x       <- GPR[rs1]

    if     ( imm == 2 ) {
      r <- LFSR_TK2( x_{16.. 8} ) || LFSR_TK2( x_{61..56} ) ||
           LFSR_TK2( x_{ 7.. 0} ) || LFSR_TK2( x_{47..40} ) ||
           LFSR_TK2( x_{24..16} ) || LFSR_TK2( x_{55..48} ) ||
           LFSR_TK2( x_{39..32} ) || LFSR_TK2( x_{31..24} )
    }
    else if( imm == 3 ) {
      r <- LFSR_TK3( x_{16.. 8} ) || LFSR_TK3( x_{61..56} ) ||
           LFSR_TK3( x_{ 7.. 0} ) || LFSR_TK3( x_{47..40} ) ||
           LFSR_TK3( x_{24..16} ) || LFSR_TK3( x_{55..48} ) ||
           LFSR_TK3( x_{39..32} ) || LFSR_TK3( x_{31..24} )
    }

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] C. Guo, T. Iwata, M. Khairallah, K. Minematsu, and Thomas Peyrin.
    [Romulus](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/romulus-spec-final.pdf).
    Submission to NIST (version 1.3), 2021.
[2] C. Beierle, J. Jean, S. Kölbl, G. Leander, A. Moradi,￼T. Peyrin, Y. Sasaki, P. Sasdrich, S.M. Sim.
    [The SKINNY Family of Block Ciphers and its Low-Latency Variant MANTIS](https://link.springer.com/chapter/10.1007/978-3-662-53008-5_5).
    In Advances in Cryptology (CRYPTO), Springer-Verlag LNCS 9815, 123--153, 2016.
[3] E. Tehrani, T. Graba, A.S. Merabet, and J.-L. Danger.
    [RISC-V Extension for Lightweight Cryptography](https://ieeexplore.ieee.org/document/9217866).
    In Digital System Design (DSD), 222--228, 2020.

<!--- -------------------------------------------------------------------- --->
