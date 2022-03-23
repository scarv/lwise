<!--- -------------------------------------------------------------------- --->

## Notation

- define the look-up tables

  ```
  ROT_0 = { 31, 17,  0, 24 }
  ROT_1 = { 24, 17, 31, 16 }

  RCON  = { 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D }
  ```

- define the function
 
  ```
  ELL( x ) {
    return ( x ^ ( x << 16 ) ) >>> 16
  }
  ```

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_ELL`     | enable ISE for `\ell` function                                          |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_RCON`    | enable ISE for round constant look-up and XOR                           |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_TYPE1`   | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_TYPE2`   | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_TYPE3`   | select 32-bit RISC-V base ISA plus ISE: option 3, per description below |
|           | `sparkle`  | `rv32`    | `SPARKLE_RV32_TYPE4`   | select 32-bit RISC-V base ISA plus ISE: option 4, per description below |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_ELL`     | enable ISE for `\ell` function                                          |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_RCON`    | enable ISE for round constant look-up and XOR                           |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_TYPE1`   | select 64-bit RISC-V base ISA:          option 1, per description below |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_TYPE2`   | select 64-bit RISC-V base ISA plus ISE: option 2, per description below |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_TYPE3`   | select 64-bit RISC-V base ISA plus ISE: option 3, per description below |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_TYPE4`   | select 64-bit RISC-V base ISA plus ISE: option 4, per description below |
|           | `sparkle`  | `rv64`    | `SPARKLE_RV64_TYPE5`   | select 64-bit RISC-V base ISA plus ISE: option 5, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- The (optional) ISE for `\ell` function:

  ```
  sparkle.ell          rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- ELL( x ^ y )
    GPR[rd] <- r
  }
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  sparkle.rcon         rd, rs1,      imm {
    x       <- GPR[rs1]
    r       <- x  ^ RCON[ imm ]
    GPR[rd] <- r 
  }
  ```

- `SPARKLE_RV32_TYPE1`: base ISA.

- `SPARKLE_RV32_TYPE2`: base ISA plus ISE.

  ```
  sparkle.addrori      rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x + ( y >>> imm )
    GPR[rd] <- r
  }

  sparkle.subrori      rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x - ( y >>> imm )
    GPR[rd] <- r
  }

  sparkle.xorrori      rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( y >>> imm )
    GPR[rd] <- r
  }
  ```

- `SPARKLE_RV32_TYPE3`: base ISA plus ISE.

  ```
  sparkle.addror.31    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x + ( y >>> 31 )
    GPR[rd] <- r
  }

  sparkle.addror.17    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x + ( y >>> 17 )
    GPR[rd] <- r
  }

  sparkle.addror.24    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x + ( y >>> 24 )
    GPR[rd] <- r
  }

  sparkle.subror.31    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x - ( y >>> 31 )
    GPR[rd] <- r
  }

  sparkle.subror.17    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x - ( y >>> 17 )
    GPR[rd] <- r
  }

  sparkle.subror.24    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x - ( y >>> 24 )
    GPR[rd] <- r
  }

  sparkle.xorror.31    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( y >>> 31 )
    GPR[rd] <- r
  }

  sparkle.xorror.17    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( y >>> 17 )
    GPR[rd] <- r
  }

  sparkle.xorror.24    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( y >>> 24 )
    GPR[rd] <- r
  }

  sparkle.xorror.16    rd, rs1, rs2      {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- x ^ ( y >>> 16 )
    GPR[rd] <- r
  }
  ```
     
- `SPARKLE_RV32_TYPE4`: base ISA plus ISE.
   
  ```
  sparkle.whole.enci.x rd, rs1, rs2, imm {
    xi      <- GPR[rs1]
    yi      <- GPR[rs2]
    ci      <- RCON[ imm ]
    xi      <- xi + ( yi >>> 31 )
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 17 )
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>>  0 )
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 24 )
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi ^   ci
    GPR[rd] <- xi
  }

  sparkle.whole.enci.y rd, rs1, rs2, imm {
    xi      <- GPR[rs1]
    yi      <- GPR[rs2]
    ci      <- RCON[ imm ]
    xi      <- xi + ( yi >>> 31 )
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 17 )
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>>  0 )
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 24 )
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi ^   ci
    GPR[rd] <- yi
  }

  sparkle.whole.deci.x rd, rs1, rs2, imm {
    xi      <- GPR[rs1]
    yi      <- GPR[rs2]
    ci      <- RCON[ imm ]
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi - ( yi >>> 24 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi - ( yi >>>  0 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi - ( yi >>> 17 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi - ( yi >>> 31 )
    GPR[rd] <- xi
  }

  sparkle.whole.deci.y rd, rs1, rs2, imm {
    xi      <- GPR[rs1]
    yi      <- GPR[rs2]
    ci      <- RCON[ imm ]
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi - ( yi >>> 24 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi - ( yi >>>  0 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi - ( yi >>> 17 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi - ( yi >>> 31 )
    GPR[rd] <- yi
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- The (optional) ISE for `\ell` function:

  ```
  sparkle.ell          rd, rs1, rs2      {
    x       <- GPR[rs1] ^ GPR[rs2]
    x_hi    <- x_{63..32}
    x_lo    <- x_{31.. 0}
    r_hi    <- ELL( x_hi )
    r_lo    <- ELL( x_lo )
    r       <- r_hi || r_lo
    GPR[rd] <- r
  }

  sparkle.ellrev       rd, rs1, rs2      {
    x       <- GPR[rs1] ^ GPR[rs2]
    x_hi    <- x_{63..32}
    x_lo    <- x_{31.. 0}
    r_hi    <- ELL( x_hi )
    r_lo    <- ELL( x_lo )
    r       <- r_lo || r_hi
    GPR[rd] <- r
  }
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  sparkle.rcon         rd, rs1,      imm {
    x_hi    <- GPR[rs1]_{63..32}
    x_lo    <- GPR[rs1]_{31.. 0}
    r_hi    <- x_hi ^ RCON[ imm ]
    r_lo    <- x_lo ^ RCON[ imm ]
    r       <- r_hi || r_lo
    GPR[rd] <- r
  }

  sparkle.rconw        rd, rs1,      imm {
    x       <- GPR[rs1]_{31.. 0}
    r       <- x    ^ RCON[ imm ]
    GPR[rd] <- r
  }
  ```

- `SPARKLE_RV64_TYPE1`: base ISA.

- `SPARKLE_RV64_TYPE2`: base ISA plus ISE.

  ```
  sparkle.block.enci   rd, rs1, rs2, imm {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi + ( yi >>> ROT_0[ imm ] )
    yi      <- yi ^ ( xi >>> ROT_1[ imm ] )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }
    
  sparkle.block.deci   rd, rs1, rs2, imm {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> ROT_1[ imm ] )
    xi      <- xi - ( yi >>> ROT_0[ imm ] )
    GPR[rd] <- yi || xi
  }
  ```

- `SPARKLE_RV64_TYPE3`: base ISA plus ISE.

  ```
  sparkle.block.enc.0  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi + ( yi >>> 31 )
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }

  sparkle.block.enc.1  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi + ( yi >>> 17 )
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }

  sparkle.block.enc.2  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi + ( yi >>>  0 )
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }

  sparkle.block.enc.3  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi + ( yi >>> 24 )
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }

  sparkle.block.dec.0  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi - ( yi >>> 31 )
    GPR[rd] <- yi || xi
  }

  sparkle.block.dec.1  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi - ( yi >>> 17 )
    GPR[rd] <- yi || xi
  }   
 
  sparkle.block.dec.2  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi - ( yi >>>  0 )
    GPR[rd] <- yi || xi
  }

  sparkle.block.dec.3  rd, rs1, rs2      {
    yi      <- GPR[rs1]_{63..32}
    xi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi - ( yi >>> 24 )
    GPR[rd] <- yi || xi
  }
  ```

- `SPARKLE_RV64_TYPE4`: base ISA plus ISE.

  ```
  sparkle.whole.enci   rd, rs1,      imm {
    xi      <- GPR[rs1]_{63..32}
    yi      <- GPR[rs1]_{31.. 0}
    ci      <- RCON[ imm ]
    xi      <- xi + ( yi >>> 31 )
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 17 )
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>>  0 )
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 24 )
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }

  sparkle.whole.deci   rd, rs1,      imm {
    xi      <- GPR[rs1]_{63..32}
    yi      <- GPR[rs1]_{31.. 0}
    ci      <- RCON[ imm ]
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi - ( yi >>> 24 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi - ( yi >>>  0 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi - ( yi >>> 17 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi - ( yi >>> 31 )
    GPR[rd] <- yi || xi
  }
  ```

- `SPARKLE_RV64_TYPE5`: base ISA plus ISE.

  ```
  sparkle.whole.enc    rd, rs1, rs2      {
    xi      <- GPR[rs1]_{63..32}
    yi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi + ( yi >>> 31 )
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 17 )
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>>  0 )
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi ^   ci
    xi      <- xi + ( yi >>> 24 )
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi ^   ci
    GPR[rd] <- yi || xi
  }

  sparkle.whole.dec    rd, rs1, rs2      {
    xi      <- GPR[rs1]_{63..32}
    yi      <- GPR[rs1]_{31.. 0}
    ci      <- GPR[rs2]_{31.. 0}
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 16 )
    xi      <- xi - ( yi >>> 24 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 31 )
    xi      <- xi - ( yi >>>  0 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 17 )
    xi      <- xi - ( yi >>> 17 )
    xi      <- xi ^   ci
    yi      <- yi ^ ( xi >>> 24 )
    xi      <- xi - ( yi >>> 31 )
    GPR[rd] <- yi || xi
  }
  ```

<!--- -------------------------------------------------------------------- --->
