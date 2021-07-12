# `${ALG} = "alzette"`

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROL32` (resp. `ROL64`) to denote a 32-bit (resp. 64-bit)  left-rotate,
- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate,
- define various look-up tables:

  ```
  ROT_0 = { 31, 17,  0, 24 }
  ROT_1 = { 24, 17, 31, 16 }

  RCON  = { 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D }
  ```

- define 
 
  ```
  ELL( x ) = ROR32( x ^ ( x << 16 ), 16 )
  ```

<!--- -------------------------------------------------------------------- --->

## Context

Focusing on encryption, the Alzette function is described in [Appx. C, 1] 
as follows

```
.macro ALZETTE xi:req, yi:req, ci:req
  add \xi, \xi, \yi, ror #31
  eor \yi, \yi, \xi, ror #24
  eor \xi, \xi, \ci
  add \xi, \xi, \yi, ror #17
  eor \yi, \yi, \xi, ror #17
  eor \xi, \xi, \ci
  add \xi, \xi, \yi
  eor \yi, \yi, \xi, ror #31
  eor \xi, \xi, \ci
  add \xi, \xi, \yi, ror #24
  eor \yi, \yi, \xi, ror #16
  eor \xi, \xi, \ci
.endm
```

or, as more C-like pseudo-code

```
ALZETTE( xi, yi, ci ) {
  xi = xi + ROR32( yi, 31 )
  yi = yi ^ ROR32( xi, 24 )
  xi = xi ^        ci

  xi = xi + ROR32( yi, 17 )
  yi = yi ^ ROR32( xi, 17 )
  xi = xi ^        ci

  xi = xi + ROR32( yi,  0 )
  yi = yi ^ ROR32( xi, 31 )
  xi = xi ^        ci

  xi = xi + ROR32( yi, 24 )
  yi = yi ^ ROR32( xi, 16 )
  xi = xi ^        ci
}
```

intentionally typeset to stress repeated use of an `add-xor-xor` block.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`  | `${IMP}`  | Symbol               | Meaning                                                                                                        |
| :-------- | :-------- | :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `alzette` |           | `CRAXS10_ENC_EXTERN` | don't include implementation of CRAX encryption in driver, i.e., allow an architecture-specific implementation |
|           | `alzette` |           | `CRAXS10_DEC_EXTERN` | don't include implementation of CRAX decryption in driver, i.e., allow an architecture-specific implementation |
|           | `alzette` |           | `CRAXS10_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX encryption                       |
|           | `alzette` |           | `CRAXS10_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX decryption                       |
|           | `alzette` |           | `TRAXL17_ENC_EXTERN` | don't include implementation of TRAX encryption in driver, i.e., allow an architecture-specific implementation |
|           | `alzette` |           | `TRAXL17_DEC_EXTERN` | don't include implementation of TRAX decryption in driver, i.e., allow an architecture-specific implementation |
|           | `alzette` |           | `TRAXL17_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX encryption                       |
|           | `alzette` |           | `TRAXL17_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX decryption                       |
|           | `alzette` |           | `SPARKLE_FWD_EXTERN` | don't include implementation of forward SPARKLE in driver, i.e., allow an architecture-specific implementation |
|           | `alzette` |           | `SPARKLE_REV_EXTERN` | don't include implementation of reverse SPARKLE in driver, i.e., allow an architecture-specific implementation |
|           | `alzette` |           | `SPARKLE_FWD_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of forward SPARKLE                       |
|           | `alzette` |           | `SPARKLE_REV_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of reverse SPARKLE                       |
|           | `alzette` | `rv32`    | `ALZETTE_RV32B`      | enable BitManip-like ISE for 32-bit RISC-V                                                                     |
|           | `alzette` | `rv32`    | `ALZETTE_RV32_ELL`   | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
|           | `alzette` | `rv32`    | `ALZETTE_RV32_RCON`  | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
|           | `alzette` | `rv32`    | `ALZETTE_RV32_TYPE1` | select 32-bit RISC-V base ISA:                 option 1, per description below                                 |
|           | `alzette` | `rv32`    | `ALZETTE_RV32_TYPE2` | select 32-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
|           | `alzette` | `rv32`    | `ALZETTE_RV32_TYPE3` | select 32-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
|           | `alzette` | `rv32`    | `ALZETTE_RV32_TYPE4` | select 32-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
|           | `alzette` | `rv64`    | `ALZETTE_RV64B`      | enable BitManip-like ISE for 64-bit RISC-V                                                                     |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_ELL`   | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_RCON`  | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_TYPE1` | select 64-bit RISC-V base ISA:                 option 1, per description below                                 |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_TYPE2` | select 64-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_TYPE3` | select 64-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_TYPE4` | select 64-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
|           | `alzette` | `rv64`    | `ALZETTE_RV64_TYPE5` | select 64-bit RISC-V base ISA plus custom ISE: option 5, per description below                                 |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- The (optional) BitManip-like ISE:

  ```
  alzette.rori          rd, rs1,      imm => x       <- GPR[rs1]
                                             r       <- ROR32( x, imm )
                                             GPR[rd] <- r
  ```

- The (optional) ISE for `\ell` function:

  ```
  alzette.ell           rd, rs1, rs2      => x       <- GPR[rs1] ^ GPR[rs2]
                                             r       <- ELL( x  )
                                             GPR[rd] <- r
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  alzette.rcon          rd, rs1,      imm => x       <- GPR[rs1]
                                             r       <- x  ^ RCON[imm]
                                             GPR[rd] <- r 
  ```

- `ALZETTE_RV32_TYPE1`: base ISA.

- `ALZETTE_RV32_TYPE2`: base ISA plus custom   ISE.

  ```
  alzette.addrori       rd, rs1, rs2, imm => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x + ROR32( y, imm )
                                             GPR[rd] <- r

  alzette.subrori       rd, rs1, rs2, imm => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x - ROR32( y, imm )
                                             GPR[rd] <- r

  alzette.xorrori       rd, rs1, rs2, imm => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x ^ ROR32( y, imm )
                                             GPR[rd] <- r
  ```

- `ALZETTE_RV32_TYPE3`: base ISA plus custom   ISE.

  ```
  alzette.addror.31     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x + ROR32( y, 31 )
                                             GPR[rd] <- r

  alzette.addror.17     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x + ROR32( y, 17 )
                                             GPR[rd] <- r

  alzette.addror.24     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x + ROR32( y, 24 )
                                             GPR[rd] <- r

  alzette.subror.31     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x - ROR32( y, 31 )
                                             GPR[rd] <- r

  alzette.subror.17     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x - ROR32( y, 17 )
                                             GPR[rd] <- r

  alzette.subror.24     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x - ROR32( y, 24 )
                                             GPR[rd] <- r

  alzette.xorror.31     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x ^ ROR32( y, 31 )
                                             GPR[rd] <- r

  alzette.xorror.17     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x ^ ROR32( y, 17 )
                                             GPR[rd] <- r

  alzette.xorror.24     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x ^ ROR32( y, 24 )
                                             GPR[rd] <- r

  alzette.xorror.16     rd, rs1, rs2      => x       <-  GPR[rs1]
                                             y       <-  GPR[rs2]
                                             r       <- x ^ ROR32( y, 16 )
                                             GPR[rd] <- r
  ```
     
- `ALZETTE_RV32_TYPE4`: base ISA plus custom   ISE.
   
  ```
  alzette.whole.enci.x  rd, rs1, rs2, imm => xi      <- GPR[rs1]
                                             yi      <- GPR[rs2]
                                             ci      <- RCON[imm]
                                             xi      <- xi + ROR32( yi, 31 )
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 17 )
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi,  0 )
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 24 )
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- xi

  alzette.whole.enci.y  rd, rs1, rs2, imm => xi      <- GPR[rs1]
                                             yi      <- GPR[rs2]
                                             ci      <- RCON[imm]
                                             xi      <- xi + ROR32( yi, 31 )
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 17 )
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi,  0 )
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 24 )
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi

  alzette.whole.deci.x  rd, rs1, rs2, imm => xi      <- GPR[rs1]
                                             yi      <- GPR[rs2]
                                             ci      <- RCON[imm]
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi - ROR32( yi, 24 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi - ROR32( yi,  0 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi - ROR32( yi, 17 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi - ROR32( yi, 31 )
                                             GPR[rd] <- xi

  alzette.whole.deci.y  rd, rs1, rs2, imm => xi      <- GPR[rs1]
                                             yi      <- GPR[rs2]
                                             ci      <- RCON[imm]
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi - ROR32( yi, 24 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi - ROR32( yi,  0 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi - ROR32( yi, 17 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi - ROR32( yi, 31 )
                                             GPR[rd] <- yi
    ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- The (optional) BitManip-like ISE:

  ```
  alzette.rori          rd, rs1,      imm => x       <- GPR[rs1]_{63.. 0}
                                             r       <- ROR64( x, imm )
                                             GPR[rd] <- r

  alzette.roriw         rd, rs1,      imm => x       <- GPR[rs1]_{31.. 0}
                                             r       <- ROR32( x, imm )
                                             GPR[rd] <- r

  alzette.pack          rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r_hi    <-   y << 32
                                             r_lo    <- ( x << 32 ) >> 32
                                             r       <- r_hi | r_lo
                                             GPR[rd] <- r

  alzette.packu         rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r_hi    <- ( y >> 32 ) << 32
                                             r_lo    <-   x >> 32
                                             r       <- r_hi | r_lo
                                             GPR[rd] <- r
  ```

- The (optional) ISE for `\ell` function:

  ```
  alzette.ell           rd, rs1, rs2      => x       <- GPR[rs1] ^ GPR[rs2]
                                             x_hi    <- x_{63..32}
                                             x_lo    <- x_{31.. 0}
                                             r_hi    <- ELL( x_hi )
                                             r_lo    <- ELL( x_lo )
                                             r       <- r_hi || r_lo
                                             GPR[rd] <- r

  alzette.ellrev        rd, rs1, rs2      => x       <- GPR[rs1] ^ GPR[rs2]
                                             x_hi    <- x_{63..32}
                                             x_lo    <- x_{31.. 0}
                                             r_hi    <- ELL( x_hi )
                                             r_lo    <- ELL( x_lo )
                                             r       <- r_lo || r_hi
                                             GPR[rd] <- r
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  alzette.rcon          rd, rs1,      imm => x_hi    <- GPR[rs1]_{63..32}
                                             x_lo    <- GPR[rs1]_{31.. 0}
                                             r_hi    <- x_hi ^ RCON[imm]
                                             r_lo    <- x_lo ^ RCON[imm]
                                             r       <- r_hi || r_lo
                                             GPR[rd] <- r

  alzette.rconw         rd, rs1,      imm => x       <- GPR[rs1]_{31.. 0}
                                             r       <- x    ^ RCON[imm]
                                             GPR[rd] <- r
  ```

- `ALZETTE_RV64_TYPE1`: base ISA.

- `ALZETTE_RV64_TYPE2`: base ISA plus custom   ISE.

  ```
  alzette.block.enci    rd, rs1, rs2, imm => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, ROT_0[imm] )
                                             yi      <- yi ^ ROR32( xi, ROT_1[imm] )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi
    
  alzette.block.deci    rd, rs1, rs2, imm => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^   ci
                                             yi      <- yi ^ ROR32( xi, ROT_1[imm] )
                                             xi      <- xi - ROR32( yi, ROT_0[imm] )
                                             GPR[rd] <- yi || xi
  ```

- `ALZETTE_RV64_TYPE3`: base ISA plus custom   ISE.

  ```
  alzette.block.enc.0   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 31 )
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  alzette.block.enc.1   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 17 )
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  alzette.block.enc.2   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi,  0 )
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  alzette.block.enc.3   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 24 )
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  alzette.block.dec.0   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi - ROR32( yi, 31 )
                                             GPR[rd] <- yi || xi

  alzette.block.dec.1   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi - ROR32( yi, 17 )
                                             GPR[rd] <- yi || xi
    
  alzette.block.dec.2   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi - ROR32( yi,  0 )
                                             GPR[rd] <- yi || xi

  alzette.block.dec.3   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi - ROR32( yi, 24 )
                                             GPR[rd] <- yi || xi
    ```

- `ALZETTE_RV64_TYPE4`: base ISA plus custom   ISE.

  ```
  alzette.whole.enci    rd, rs1,      imm => xi      <- GPR[rs1]_{63..32}
                                             yi      <- GPR[rs1]_{31.. 0}
                                             ci      <- RCON[imm]
                                             xi      <- xi + ROR32( yi, 31 )
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 17 )
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi,  0 )
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 24 )
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  alzette.whole.deci    rd, rs1,      imm => xi      <- GPR[rs1]_{63..32}
                                             yi      <- GPR[rs1]_{31.. 0}
                                             ci      <- RCON[imm]
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi - ROR32( yi, 24 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi - ROR32( yi,  0 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi - ROR32( yi, 17 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi - ROR32( yi, 31 )
                                             GPR[rd] <- yi || xi
  ```

- `ALZETTE_RV64_TYPE5`: base ISA plus custom   ISE.

  ```
  alzette.whole.enc     rd, rs1, rs2      => xi      <- GPR[rs1]_{63..32}
                                             yi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 31 )
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 17 )
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi,  0 )
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi ^        ci
                                             xi      <- xi + ROR32( yi, 24 )
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  alzette.whole.dec     rd, rs1, rs2      => xi      <- GPR[rs1]_{63..32}
                                             yi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi - ROR32( yi, 24 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi - ROR32( yi,  0 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi - ROR32( yi, 17 )
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi - ROR32( yi, 31 )
                                             GPR[rd] <- yi || xi
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Alzette: a 64-bit ARX-box (feat. CRAX and TRAX)](https://link.springer.com/chapter/10.1007/978-3-030-56877-1_15).
    Advances in Cryptology (CRYPTO), Springer-Verlag LNCS 12172, 419--448, 2020.
    See also [Cryptology ePrint Archive, Report 2019/1378](https://eprint.iacr.org/2019/1378).

[2] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Lightweight AEAD and Hashing using the Sparkle Permutation Family](https://tosc.iacr.org/index.php/ToSC/article/view/8627)
    IACR Transactions on Symmetric Cryptology, 2020(S1), 208--261, 2020.

[3] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, A. Moradi, L. Perrin, A.R. Shahmirzadi, A. Udovenko, V. Velichkov, and Q. Wang.
    [Schwaemm and Esch: Lightweight Authenticated Encryption and Hashing using the Sparkle Permutation Family](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/sparkle-spec-final.pdf)
    Submission to NIST (version 1.2), 2021.

<!--- -------------------------------------------------------------------- --->
