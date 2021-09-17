# `${ALG} = "sparkle"`

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

Focusing on encryption, the Alzette function is described in [Appx. C, 2] 
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
|           | `sparkle` |           | `CRAXS10_ENC_EXTERN` | don't include implementation of CRAX encryption in driver, i.e., allow an architecture-specific implementation |
|           | `sparkle` |           | `CRAXS10_DEC_EXTERN` | don't include implementation of CRAX decryption in driver, i.e., allow an architecture-specific implementation |
|           | `sparkle` |           | `CRAXS10_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX encryption                       |
|           | `sparkle` |           | `CRAXS10_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX decryption                       |
|           | `sparkle` |           | `TRAXL17_ENC_EXTERN` | don't include implementation of TRAX encryption in driver, i.e., allow an architecture-specific implementation |
|           | `sparkle` |           | `TRAXL17_DEC_EXTERN` | don't include implementation of TRAX decryption in driver, i.e., allow an architecture-specific implementation |
|           | `sparkle` |           | `TRAXL17_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX encryption                       |
|           | `sparkle` |           | `TRAXL17_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX decryption                       |
|           | `sparkle` |           | `SPARKLE_FWD_EXTERN` | don't include implementation of forward SPARKLE in driver, i.e., allow an architecture-specific implementation |
|           | `sparkle` |           | `SPARKLE_REV_EXTERN` | don't include implementation of reverse SPARKLE in driver, i.e., allow an architecture-specific implementation |
|           | `sparkle` |           | `SPARKLE_FWD_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of forward SPARKLE                       |
|           | `sparkle` |           | `SPARKLE_REV_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of reverse SPARKLE                       |
|           | `sparkle` | `rv32`    | `SPARKLE_RV32_ELL`   | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
|           | `sparkle` | `rv32`    | `SPARKLE_RV32_RCON`  | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
|           | `sparkle` | `rv32`    | `SPARKLE_RV32_TYPE1` | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `sparkle` | `rv32`    | `SPARKLE_RV32_TYPE2` | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `sparkle` | `rv32`    | `SPARKLE_RV32_TYPE3` | select 32-bit RISC-V baseline ISA plus custom ISE: option 3, per description below                             |
|           | `sparkle` | `rv32`    | `SPARKLE_RV32_TYPE4` | select 32-bit RISC-V baseline ISA plus custom ISE: option 4, per description below                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_ELL`   | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_RCON`  | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_TYPE1` | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_TYPE2` | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_TYPE3` | select 64-bit RISC-V baseline ISA plus custom ISE: option 3, per description below                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_TYPE4` | select 64-bit RISC-V baseline ISA plus custom ISE: option 4, per description below                             |
|           | `sparkle` | `rv64`    | `SPARKLE_RV64_TYPE5` | select 64-bit RISC-V baseline ISA plus custom ISE: option 5, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- The (optional) ISE for `\ell` function:

  ```
  sparkle.ell           rd, rs1, rs2      => x       <- GPR[rs1] ^ GPR[rs2]
                                             r       <- ELL( x  )
                                             GPR[rd] <- r
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  sparkle.rcon          rd, rs1,      imm => x       <- GPR[rs1]
                                             r       <- x  ^ RCON[imm]
                                             GPR[rd] <- r 
  ```

  Note that this option is required because of the 32-bit round constant:
  otherwise, we could just use `xori` (which allows a 12-bit immediate).

- `SPARKLE_RV32_TYPE1`: baseline ISA.

- `SPARKLE_RV32_TYPE2`: baseline ISA plus custom ISE.

  ```
  sparkle.addrori       rd, rs1, rs2, imm => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x + ROR32( y, imm )
                                             GPR[rd] <- r

  sparkle.subrori       rd, rs1, rs2, imm => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x - ROR32( y, imm )
                                             GPR[rd] <- r

  sparkle.xorrori       rd, rs1, rs2, imm => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x ^ ROR32( y, imm )
                                             GPR[rd] <- r
  ```

- `SPARKLE_RV32_TYPE3`: baseline ISA plus custom ISE.

  ```
  sparkle.addror.31     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x + ROR32( y, 31 )
                                             GPR[rd] <- r

  sparkle.addror.17     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x + ROR32( y, 17 )
                                             GPR[rd] <- r

  sparkle.addror.24     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x + ROR32( y, 24 )
                                             GPR[rd] <- r

  sparkle.subror.31     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x - ROR32( y, 31 )
                                             GPR[rd] <- r

  sparkle.subror.17     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x - ROR32( y, 17 )
                                             GPR[rd] <- r

  sparkle.subror.24     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x - ROR32( y, 24 )
                                             GPR[rd] <- r

  sparkle.xorror.31     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x ^ ROR32( y, 31 )
                                             GPR[rd] <- r

  sparkle.xorror.17     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x ^ ROR32( y, 17 )
                                             GPR[rd] <- r

  sparkle.xorror.24     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x ^ ROR32( y, 24 )
                                             GPR[rd] <- r

  sparkle.xorror.16     rd, rs1, rs2      => x       <- GPR[rs1]
                                             y       <- GPR[rs2]
                                             r       <- x ^ ROR32( y, 16 )
                                             GPR[rd] <- r
  ```
     
- `SPARKLE_RV32_TYPE4`: baseline ISA plus custom ISE.
   
  ```
  sparkle.whole.enci.x  rd, rs1, rs2, imm => xi      <- GPR[rs1]
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

  sparkle.whole.enci.y  rd, rs1, rs2, imm => xi      <- GPR[rs1]
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

  sparkle.whole.deci.x  rd, rs1, rs2, imm => xi      <- GPR[rs1]
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

  sparkle.whole.deci.y  rd, rs1, rs2, imm => xi      <- GPR[rs1]
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

- The (optional) ISE for `\ell` function:

  ```
  sparkle.ell           rd, rs1, rs2      => x       <- GPR[rs1] ^ GPR[rs2]
                                             x_hi    <- x_{63..32}
                                             x_lo    <- x_{31.. 0}
                                             r_hi    <- ELL( x_hi )
                                             r_lo    <- ELL( x_lo )
                                             r       <- r_hi || r_lo
                                             GPR[rd] <- r

  sparkle.ellrev        rd, rs1, rs2      => x       <- GPR[rs1] ^ GPR[rs2]
                                             x_hi    <- x_{63..32}
                                             x_lo    <- x_{31.. 0}
                                             r_hi    <- ELL( x_hi )
                                             r_lo    <- ELL( x_lo )
                                             r       <- r_lo || r_hi
                                             GPR[rd] <- r
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  sparkle.rcon          rd, rs1,      imm => x_hi    <- GPR[rs1]_{63..32}
                                             x_lo    <- GPR[rs1]_{31.. 0}
                                             r_hi    <- x_hi ^ RCON[imm]
                                             r_lo    <- x_lo ^ RCON[imm]
                                             r       <- r_hi || r_lo
                                             GPR[rd] <- r

  sparkle.rconw         rd, rs1,      imm => x       <- GPR[rs1]_{31.. 0}
                                             r       <- x    ^ RCON[imm]
                                             GPR[rd] <- r
  ```

  Note that this option is required because of the 32-bit round constant:
  otherwise, we could just use `xori` (which allows a 12-bit immediate).

- `SPARKLE_RV64_TYPE1`: baseline ISA.

- `SPARKLE_RV64_TYPE2`: baseline ISA plus custom ISE.

  ```
  sparkle.block.enci    rd, rs1, rs2, imm => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, ROT_0[imm] )
                                             yi      <- yi ^ ROR32( xi, ROT_1[imm] )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi
    
  sparkle.block.deci    rd, rs1, rs2, imm => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^   ci
                                             yi      <- yi ^ ROR32( xi, ROT_1[imm] )
                                             xi      <- xi - ROR32( yi, ROT_0[imm] )
                                             GPR[rd] <- yi || xi
  ```

- `SPARKLE_RV64_TYPE3`: baseline ISA plus custom ISE.

  ```
  sparkle.block.enc.0   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 31 )
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  sparkle.block.enc.1   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 17 )
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  sparkle.block.enc.2   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi,  0 )
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  sparkle.block.enc.3   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi + ROR32( yi, 24 )
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi ^        ci
                                             GPR[rd] <- yi || xi

  sparkle.block.dec.0   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 24 )
                                             xi      <- xi - ROR32( yi, 31 )
                                             GPR[rd] <- yi || xi

  sparkle.block.dec.1   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 17 )
                                             xi      <- xi - ROR32( yi, 17 )
                                             GPR[rd] <- yi || xi
    
  sparkle.block.dec.2   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 31 )
                                             xi      <- xi - ROR32( yi,  0 )
                                             GPR[rd] <- yi || xi

  sparkle.block.dec.3   rd, rs1, rs2      => yi      <- GPR[rs1]_{63..32}
                                             xi      <- GPR[rs1]_{31.. 0}
                                             ci      <- GPR[rs2]_{31.. 0}
                                             xi      <- xi ^        ci
                                             yi      <- yi ^ ROR32( xi, 16 )
                                             xi      <- xi - ROR32( yi, 24 )
                                             GPR[rd] <- yi || xi
    ```

- `SPARKLE_RV64_TYPE4`: baseline ISA plus custom ISE.

  ```
  sparkle.whole.enci    rd, rs1,      imm => xi      <- GPR[rs1]_{63..32}
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

  sparkle.whole.deci    rd, rs1,      imm => xi      <- GPR[rs1]_{63..32}
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

- `SPARKLE_RV64_TYPE5`: baseline ISA plus custom ISE.

  ```
  sparkle.whole.enc     rd, rs1, rs2      => xi      <- GPR[rs1]_{63..32}
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

  sparkle.whole.dec     rd, rs1, rs2      => xi      <- GPR[rs1]_{63..32}
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

[1] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, A. Moradi, L. Perrin, A.R. Shahmirzadi, A. Udovenko, V. Velichkov, and Q. Wang.
    [Schwaemm and Esch: Lightweight Authenticated Encryption and Hashing using the Sparkle Permutation Family](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/sparkle-spec-final.pdf)
    Submission to NIST (version 1.2), 2021.

[2] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Alzette: a 64-bit ARX-box (feat. CRAX and TRAX)](https://link.springer.com/chapter/10.1007/978-3-030-56877-1_15).
    Advances in Cryptology (CRYPTO), Springer-Verlag, LNCS 12172, 419--448, 2020.
    See also [Cryptology ePrint Archive, Report 2019/1378](https://eprint.iacr.org/2019/1378).

[3] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Lightweight AEAD and Hashing using the Sparkle Permutation Family](https://tosc.iacr.org/index.php/ToSC/article/view/8627)
    IACR Transactions on Symmetric Cryptology, 2020(S1), 208--261, 2020.

<!--- -------------------------------------------------------------------- --->
