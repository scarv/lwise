# `${ALG} = "alzette"`

Alzette [1], e.g., CRAXS10 [1], TRAXL17 [1], and SPARKLE [2].

<!--- -------------------------------------------------------------------- --->

## Notation

Throughout the following, we

- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate,
- define 
 
  ```
  ELL( x ) = ROR32( x ^ ( x << 16 ), 16 )
  ```

- define a look-up table such that

  ```
  RCON  = { 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D }
  ```

- define a look-up table such that

  ```
  ROT_X = { 31, 17,  0, 24 }
  ROT_Y = { 24, 17, 31, 16 }
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

| `${ARCH}` | Symbol               | Meaning                                                                                                        |
| :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `CRAXS10_ENC_EXTERN` | don't include implementation of CRAX encryption in driver, i.e., allow an architecture-specific implementation |
|           | `CRAXS10_DEC_EXTERN` | don't include implementation of CRAX decryption in driver, i.e., allow an architecture-specific implementation |
|           | `CRAXS10_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX encryption                       |
|           | `CRAXS10_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX decryption                       |
|           | `TRAXL17_ENC_EXTERN` | don't include implementation of TRAX encryption in driver, i.e., allow an architecture-specific implementation |
|           | `TRAXL17_DEC_EXTERN` | don't include implementation of TRAX decryption in driver, i.e., allow an architecture-specific implementation |
|           | `TRAXL17_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX encryption                       |
|           | `TRAXL17_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX decryption                       |
|           | `SPARKLE_FWD_EXTERN` | don't include implementation of forward SPARKLE in driver, i.e., allow an architecture-specific implementation |
|           | `SPARKLE_REV_EXTERN` | don't include implementation of reverse SPARKLE in driver, i.e., allow an architecture-specific implementation |
|           | `SPARKLE_FWD_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of forward SPARKLE                       |
|           | `SPARKLE_REV_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of reverse SPARKLE                       |
| `rv32`    | `RV32B`              | enable BitManip-like ISE for 32-bit RISC-V                                                                     |
| `rv32`    | `RV32_ELL`           | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
| `rv32`    | `RV32_RCON`          | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
| `rv32`    | `RV32_TYPE1`         | select 32-bit RISC-V base ISA:                 option 1, per description below                                 |
| `rv32`    | `RV32_TYPE2`         | select 32-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
| `rv32`    | `RV32_TYPE3`         | select 32-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
| `rv32`    | `RV32_TYPE4`         | select 32-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
| `rv64`    | `RV64B`              | enable BitManip-like ISE for 64-bit RISC-V                                                                     |
| `rv64`    | `RV64_ELL`           | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
| `rv64`    | `RV64_RCON`          | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
| `rv64`    | `RV64_TYPE1`         | select 64-bit RISC-V base ISA:                 option 1, per description below                                 |
| `rv64`    | `RV64_TYPE2`         | select 64-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
| `rv64`    | `RV64_TYPE3`         | select 64-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
| `rv64`    | `RV64_TYPE4`         | select 64-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
| `rv64`    | `RV64_TYPE5`         | select 64-bit RISC-V base ISA plus custom ISE: option 5, per description below                                 |

<!--- -------------------------------------------------------------------- --->

## `${ARCH} = "rv32"`

- The (optional) BitManip-like ISE:

  ```
  alz.rori          rd, rs1,      imm => ROR32( GPR[rs1], imm )
  ```

- The (optional) ISE for `\ell` function:

  ```
  alz.ell           rd, rs1, rs2      => x    <- GPR[rs1] ^ GPR[rs2]
                                         r    <- ELL( x  )
                                         GPR[rd] <- r
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  alz.rcon          rd, rs1,      imm => x    <- GPR[rs1]
                                         r    <- x  ^ RCON[imm]
                                         GPR[rd] <- r 
  ```

- `RV32_TYPE1`: base ISA.

- `RV32_TYPE2`: base ISA plus custom   ISE.

  ```
  alz.addrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], imm )
  alz.subrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], imm )
  alz.xorrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], imm )
  ```

- `RV32_TYPE3`: base ISA plus custom   ISE.

  ```
  alz.addror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], 31 )
  alz.addror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], 17 )
  alz.addror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], 24 )
  alz.subror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], 31 )
  alz.subror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], 17 )
  alz.subror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], 24 )
  alz.xorror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 31 )
  alz.xorror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 17 )
  alz.xorror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 24 )
  alz.xorror.16     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 16 )
  ```
     
- `RV32_TYPE4`: base ISA plus custom   ISE.
   
  ```
  alz.whole.enci.x  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- xi

  alz.whole.enci.y  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi

  alz.whole.deci.x  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- xi

  alz.whole.deci.y  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi
    ```

<!--- -------------------------------------------------------------------- --->

## `${ARCH} = "rv64"`

- The (optional) BitManip-like ISE:

  ```
  alz.rori          rd, rs1,      imm => GPR[rd] <- ROR64( GPR[rs1], imm )
  alz.roriw         rd, rs1,      imm => GPR[rd] <- ROR32( GPR[rs1], imm )

  alz.pack          rd, rs1, rs2      => hi <-   GPR[rs2] << 32
                                         lo <- ( GPR[rs1] << 32 ) >> 32
                                         GPR[rd] <- hi || lo

  alz.packu         rd, rs1, rs2      => hi <- ( GPR[rs2] >> 32 ) << 32
                                         lo <-   GPR[rs1] >> 32
                                         GPR[rd] <- hi || lo
  ```

- The (optional) ISE for `\ell` function:

  ```
  alz.ell           rd, rs1, rs2      => x    <- GPR[rs1] ^ GPR[rs2]
                                         xh   <- x_{63..32}
                                         xl   <- x_{31.. 0}
                                         rh   <- ELL( xh )
                                         rl   <- ELL( xl )
                                         GPR[rd] <- rh || rl

  alz.ellrev        rd, rs1, rs2      => x    <- GPR[rs1] ^ GPR[rs2]
                                         xh   <- x_{63..32}
                                         xl   <- x_{31.. 0}
                                         rh   <- ROR32( xh ^ ( xh << 16 ), 16 )
                                         rl   <- ROR32( xl ^ ( xl << 16 ), 16 )
                                         GPR[rd] <- rl || rh
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  alz.rcon          rd, rs1,      imm => xh   <- GPR[rs1]_{63..32}
                                         xl   <- GPR[rs1]_{31.. 0}
                                         rh   <- xl ^ RCON[imm]
                                         rl   <- xl ^ RCON[imm]
                                         GPR[rd] <- rh || rl 

  alz.rconw         rd, rs1,      imm => xl   <- GPR[rs1]_{31.. 0}
                                         rl   <- xl ^ RCON[imm]
                                         GPR[rd] <- rh || rl
  ```

- `RV64_TYPE1`: base ISA.

- `RV64_TYPE2`: base ISA plus custom   ISE.

  ```
  alz.block.enci    rd, rs1, rs2, imm => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, ROT_X[imm] )
                                         yi <- yi ^ ROR32( xi, ROT_Y[imm] )
                                         xi <- xi ^        ci
                                         GPR[rd] <- xi || yi

  alz.block.deci    rd, rs1, rs2, imm => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ROR32( xi, ROT_Y[imm] )
                                         xi <- xi - ROR32( yi, ROT_X[imm] )
                                         GPR[rd] <- xi || yi
  ```

- `RV64_TYPE3`: base ISA plus custom   ISE.

  ```
  alz.block.enc.0   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.1   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.2   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.3   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.dec.0   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.1   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.2   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.3   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         GPR[rd] <- yi || xi
    ```

- `RV64_TYPE4`: base ISA plus custom   ISE.

  ```
  alz.whole.enci    rd, rs1,      imm => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- RCON[imm]
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.whole.deci    rd, rs1,      imm => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- RCON[imm]
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi || xi
  ```

- `RV64_TYPE5`: base ISA plus custom   ISE.

  ```
  alz.whole.enc     rd, rs1, rs2      => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.whole.dec     rd, rs1, rs2      => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
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

<!--- -------------------------------------------------------------------- --->
