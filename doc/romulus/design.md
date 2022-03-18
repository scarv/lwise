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
  for example, are the 8-bit Skinny encryption and decryption S-boxes.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE1`   | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE2`   | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE1`   | select 64-bit RISC-V base ISA:          option 1, per description below |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE2`   | select 64-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ROMULUS_RV32_TYPE1`: base ISA.

- `ROMULUS_RV32_TYPE2`: base ISA plus ISE.

  ```
  romulus.rstep.enc    rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm = 2 ) {
      y <- 2
    }
    else if( imm = 3 ) {
      y <- 0
    }

    t       <- SBOX_ENC[ x_{31..24} ] || SBOX_ENC[ x_{23..16} ] ||
               SBOX_ENC[ x_{15.. 8} ] || SBOX_ENC[ x_{ 7.. 0} ]

    t       <- t ^ y

    if     ( imm = 0 ) {
      r <- ROL32( t,  0 )
    }
    else if( imm = 1 ) {
      r <- ROL32( t,  8 )
    }
    else if( imm = 2 ) {
      r <- ROL32( t, 16 )
    }
    else if( imm = 3 ) {
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

    if     ( imm = 1 ) {
      r <-           y_{15.. 8}   ||           x_{ 7.. 0}   ||
                     y_{31..24}   ||           x_{15.. 8}  
    }
    else if( imm = 2 ) {
      r <- LFSR_TK2( y_{15.. 8} ) || LFSR_TK2( x_{ 7.. 0} ) ||
           LFSR_TK2( y_{31..24} ) || LFSR_TK2( x_{15.. 8} )
    }
    else if( imm = 3 ) {
      r <- LFSR_TK3( y_{15.. 8} ) || LFSR_TK3( x_{ 7.. 0} ) ||
           LFSR_TK3( y_{31..24} ) || LFSR_TK3( x_{15.. 8} )
    }

    GPR[rd] <- r
  }

  romulus.tk.upd.enc.1 rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm = 1 ) {
      r <-           x_{31..24}   ||           y_{ 7.. 0}   ||
                     y_{23..16}   ||           x_{23..16}  
    }
    else if( imm = 2 ) {
      r <- LFSR_TK2( x_{31..24} ) || LFSR_TK2( y_{ 7.. 0} ) ||
           LFSR_TK2( y_{23..16} ) || LFSR_TK2( x_{23..16} )
    }
    else if( imm = 3 ) {
      r <- LFSR_TK3( x_{31..24} ) || LFSR_TK3( y_{ 7.. 0} ) ||
           LFSR_TK3( y_{23..16} ) || LFSR_TK3( x_{23..16} )
    }

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ROMULUS_RV64_TYPE1`: base ISA.

- `ROMULUS_RV64_TYPE2`: base ISA plus ISE.

  ```
  romulus.rstep.enc    rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    if     ( imm = 1 ) {
      y <- 2
    }

    t       <- SBOX_ENC[ x_{63..56} ] || SBOX_ENC[ x_{55..48} ] ||
               SBOX_ENC[ x_{47..40} ] || SBOX_ENC[ x_{39..32} ] ||
               SBOX_ENC[ x_{31..24} ] || SBOX_ENC[ x_{23..16} ] ||
               SBOX_ENC[ x_{15.. 8} ] || SBOX_ENC[ x_{ 7.. 0} ]

    t       <- t ^ y

    if     ( imm = 0 ) {
      r <- ROL32( t_{63..32},  8 ) || ROL32( t_{31.. 0},  0 )
    }
    else if( imm = 1 ) {
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

    if     ( imm = 0 ) {
      r <- t_3_{15.. 8} || t_2_{15.. 8} || t_1_{15.. 8} || t_0_{15.. 8} ||
           t_3_{ 7.. 0} || t_2_{ 7.. 0} || t_1_{ 7.. 0} || t_0_{ 7.. 0}
    }
    else if( imm = 1 ) {
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

    if     ( imm = 2 ) {
      r <- LFSR_TK2( x_{16.. 8} ) || LFSR_TK2( x_{61..56} ) ||
           LFSR_TK2( x_{ 7.. 0} ) || LFSR_TK2( x_{47..40} ) ||
           LFSR_TK2( x_{24..16} ) || LFSR_TK2( x_{55..48} ) ||
           LFSR_TK2( x_{39..32} ) || LFSR_TK2( x_{31..24} )
    }
    else if( imm = 3 ) {
      r <- LFSR_TK3( x_{16.. 8} ) || LFSR_TK3( x_{61..56} ) ||
           LFSR_TK3( x_{ 7.. 0} ) || LFSR_TK3( x_{47..40} ) ||
           LFSR_TK3( x_{24..16} ) || LFSR_TK3( x_{55..48} ) ||
           LFSR_TK3( x_{39..32} ) || LFSR_TK3( x_{31..24} )
    }

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->
