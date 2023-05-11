<!--- -------------------------------------------------------------------- --->

## Notation

- define the functions

  ```
  SWAPMOVE32  (x,  m,n) {
    t <- x ^ ( x >> n )
    t <- t & m
    t <- t ^ ( t << n )
    x <- t ^ x

    return x
  }

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
  
  i.e., 32-bit variants of `SWAPMOVE`.

- define the functions

  ```
  LFSR_RC( x ) {
    return x_4 || x_3 || x_2 || x_1 || x_0 || ( x_5 ^ x_4 ^ 1 )
  }
  ```

- define the functions

  ```
  LFSR_TK2( x ) {
    return x_6 || x_5 || x_4 || x_3 || x_2 || x_1 || x_0 || ( x_5 ^ x_7 )
  }

  LFSR_TK3( x ) {
    return ( x_6 ^ x_0 ) || x_7 || x_6 || x_5 || x_4 || x_3 || x_2 || x_1
  }
  ```

- define the look-up tables
  `SBOX` 
  to be the Skinny S-box

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE1`   | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE2`   | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE3`   | select 32-bit RISC-V base ISA plus ISE: option 3, per description below |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE1`   | select 64-bit RISC-V base ISA:          option 1, per description below |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE2`   | select 64-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ROMULUS_RV32_TYPE1`: base ISA.

- `ROMULUS_RV32_TYPE2`: base ISA plus ISE.

  ```
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
      r <-           y_{15.. 8}   ||           x_{ 7.. 0}   ||
                     y_{31..24}   ||           x_{15.. 8}  
    }
    else if( imm == 2 ) {
      r <- LFSR_TK2( y_{15.. 8} ) || LFSR_TK2( x_{ 7.. 0} ) ||
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
      r <- t <<<  0
    }
    else if( imm == 1 ) {
      r <- t <<<  8
    }
    else if( imm == 2 ) {
      r <- t <<< 16
    }
    else if( imm == 3 ) {
      r <- t <<< 24
    }

    GPR[rd] <- r
  }
  ```

- `ROMULUS_RV32_TYPE3`: base ISA plus ISE.

  ```
  romulus.mixcolumns rd, rs1,      imm {
    x       <- GPR[rs1]

    if      ( imm == 0 ) { 
      r <- x ^ ( ( ( x >>> 24 ) & 0x0C0C0C0C ) >>> 30 )
      r <- r ^ ( ( ( r >>> 16 ) & 0xC0C0C0C0 ) >>>  4 )
      r <- r ^ ( ( ( r >>>  8 ) & 0x0C0C0C0C ) >>>  2 )
    }
    else if ( imm == 1 ) { 
      r <- x ^ ( ( ( x >>> 16 ) & 0x30303030 ) >>> 30 )
      r <- r ^ ( ( ( r        ) & 0x03030303 ) >>> 28 )
      r <- r ^ ( ( ( r >>> 16 ) & 0x30303030 ) >>>  2 )
    }
    else if ( imm == 2 ) { 
      r <- x ^ ( ( ( x >>>  8 ) & 0xC0C0C0C0 ) >>>  6 )
      r <- r ^ ( ( ( r >>> 16 ) & 0x0C0C0C0C ) >>> 28 )
      r <- r ^ ( ( ( r >>> 24 ) & 0xC0C0C0C0 ) >>>  2 )
    }
    else if ( imm == 3 ) { 
      r <- x ^ ( ( ( x        ) & 0x03030303 ) >>> 30 )
      r <- r ^ ( ( ( r        ) & 0x30303030 ) >>>  4 )
      r <- r ^ ( ( ( r        ) & 0x03030303 ) >>> 26 )
    }

    GPR[rd] <- r
  }

  romulus.swapmove.x rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    
    if      ( imm == 0 ) { 
      r <- SWAPMOVE32_X( x, y, 0x55555555, 1 )
    }
    else if ( imm == 1 ) {
      r <- SWAPMOVE32_X( x, y, 0x30303030, 2 )
    }
    else if ( imm == 2 ) {
      r <- SWAPMOVE32_X( x, y, 0x0C0C0C0C, 4 )
    }
    else if ( imm == 3 ) {
      r <- SWAPMOVE32_X( x, y, 0x03030303, 6 )
    }  
    else if ( imm == 4 ) {
      r <- SWAPMOVE32_X( x, y, 0x0C0C0C0C, 2 )
    }
    else if ( imm == 5 ) {
      r <- SWAPMOVE32_X( x, y, 0x03030303, 4 )
    } 
    else if ( imm == 6 ) {
      r <- SWAPMOVE32_X( x, y, 0x03030303, 2 )
    }
    else if ( imm == 7 ) {
      r <- SWAPMOVE32  ( x,    0x0A0A0A0A, 3 )
    }

    GPR[rd] <- r 
  }

  romulus.swapmove.y rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    
    if      ( imm == 0 ) { 
      r <- SWAPMOVE32_Y( x, y, 0x55555555, 1 )
    }
    else if ( imm == 1 ) {
      r <- SWAPMOVE32_Y( x, y, 0x30303030, 2 )
    }
    else if ( imm == 2 ) {
      r <- SWAPMOVE32_Y( x, y, 0x0C0C0C0C, 4 )
    }
    else if ( imm == 3 ) {
      r <- SWAPMOVE32_Y( x, y, 0x03030303, 6 )
    }  
    else if ( imm == 4 ) {
      r <- SWAPMOVE32_Y( x, y, 0x0C0C0C0C, 2 )
    }
    else if ( imm == 5 ) {
      r <- SWAPMOVE32_Y( x, y, 0x03030303, 4 )
    } 
    else if ( imm == 6 ) {
      r <- SWAPMOVE32_Y( x, y, 0x03030303, 2 )
    }

    GPR[rd] <- r 
  }

  romulus.permtk     rd, rs1,      imm {
    x       <- GPR[rs1]

    if      ( imm == 0 ) { 
      r <-     ( ( ( x >>> 14 ) & 0xCC00CC00 )       )
      r <- r | ( ( ( x        ) & 0x000000FF ) << 16 )
      r <- r | ( ( ( x        ) & 0xCC000000 ) >>  2 )
      r <- r | ( ( ( x        ) & 0x0033CC00 ) >>  8 )
      r <- r | ( ( ( x        ) & 0x00CC0000 ) >> 18 )
    }
    else if ( imm == 1 ) { 
      r <-     ( ( ( x >>> 22 ) & 0xCC0000CC )       )
      r <- r | ( ( ( x >>> 16 ) & 0x3300CC00 )       )
      r <- r | ( ( ( x >>> 24 ) & 0x00CC3300 )       )
      r <- r | ( ( ( x        ) & 0x00CC00CC ) >>  2 )
    }
    else if ( imm == 2 ) { 
      r <-     ( ( ( x >>>  6 ) & 0xCCCC0000 )       )
      r <- r | ( ( ( x >>> 24 ) & 0x330000CC )       )
      r <- r | ( ( ( x >>> 10 ) & 0x00003333 )       )
      r <- r | ( ( ( x          & 0x000000CC ) << 14 )
      r <- r | ( ( ( x          & 0x00003300 ) <<  2 )
    }
    else if ( imm == 3 ) { 
      r <-     ( ( ( x >>> 24 ) & 0xCC000033 )       )
      r <- r | ( ( ( x >>>  8 ) & 0x33CC0000 )       )
      r <- r | ( ( ( x >>> 26 ) & 0x00333300 )       )
      r <- r | ( ( ( x        ) & 0x00333300 ) >>  6 )
    }
    else if ( imm == 4 ) { 
      r <-     ( ( ( x >>>  8 ) & 0xCC330000 )       )
      r <- r | ( ( ( x >>> 26 ) & 0x33000033 )       )
      r <- r | ( ( ( x >>> 22 ) & 0x00CCCC00 )       )
      r <- r | ( ( ( x        ) & 0x00330000 ) >> 14 )
      r <- r | ( ( ( x        ) & 0x0000CC00 ) >>  2 )
    }
    else if ( imm == 5 ) { 
      r <-     ( ( ( x >>>  8 ) & 0x0000CC33 )       )
      r <- r | ( ( ( x >>> 30 ) & 0x00CC00CC )       )
      r <- r | ( ( ( x >>> 10 ) & 0x33330000 )       )
      r <- r | ( ( ( x >>> 16 ) & 0xCC003300 )       )
    }
    else if ( imm == 6 ) { 
      r <-     ( ( ( x >>> 24 ) & 0x0033CC00 )       )
      r <- r | ( ( ( x >>> 14 ) & 0x00CC0000 )       )
      r <- r | ( ( ( x >>> 30 ) & 0xCC000000 )       )
      r <- r | ( ( ( x >>> 16 ) & 0x000000FF )       )
      r <- r | ( ( ( x >>> 18 ) & 0x33003300 )       )
    }

    GPR[rd] <- r     
  }

  romulus.tkupd.0    rd, rs1,      imm {
    x       <- GPR[rs1]

    if      ( imm == 0 ) { 
      r <-     ( ( x >>> 26 ) & 0xC3C3C3C3 )
    }
    else if ( imm == 1 ) { 
      r <-     ( ( x >>> 16 ) & 0xF0F0F0F0 )
    }
    else if ( imm == 2 ) { 
      r <-     ( ( x >>> 10 ) & 0xC3C3C3C3 )
    } 

    GPR[rd] <- r
  }

  romulus.tkupd.1    rd, rs1,      imm {
    x       <- GPR[rs1]
    
    if      ( imm == 0 ) { 
      r <-     ( ( x >>> 28 ) & 0x03030303 )
      r <- r | ( ( x >>> 12 ) & 0x0C0C0C0C )
    }
    else if ( imm == 1 ) { 
      r <-     ( ( x >>> 14 ) & 0x30303030 )
      r <- r | ( ( x >>>  6 ) & 0x0C0C0C0C )
    }  
    else if ( imm == 2 ) { 
      r <-     ( ( x >>> 12 ) & 0x03030303 )
      r <- r | ( ( x >>> 28 ) & 0x0C0C0C0C )
    }  
    else if ( imm == 3 ) { 
      r <-     ( ( x >>> 30 ) & 0x30303030 )
      r <- r | ( ( x >>> 22 ) & 0x0C0C0C0C )
    }     

    GPR[rd] <- r 
  }

  romulus.lfsr2      rd, rs1, rs2        {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( ( y & 0xAAAAAAAA )      )
    r       <- ( ( ( r      ) & 0xAAAAAAAA ) >> 1 ) | 
               ( ( ( r << 1 ) & 0xAAAAAAAA )      )
    GPR[rd] <- r
  }

  romulus.lfsr3      rd, rs1, rs2        {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( ( y & 0xAAAAAAAA ) >> 1 )
    r       <- ( ( ( r      ) & 0xAAAAAAAA ) >> 1 ) | 
               ( ( ( r << 1 ) & 0xAAAAAAAA )      )
    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ROMULUS_RV64_TYPE1`: base ISA.

- `ROMULUS_RV64_TYPE2`: base ISA plus ISE.

  ```
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
      r <- ( t_{63..32} <<<  8 ) || ( t_{31.. 0} <<<  0 )
    }
    else if( imm == 1 ) {
      r <- ( t_{63..32} <<< 16 ) || ( t_{31.. 0} <<< 24 )
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
  ```

<!--- -------------------------------------------------------------------- --->
