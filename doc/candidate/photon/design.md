# `${ALG} = "photon"`

<!--- -------------------------------------------------------------------- --->

## Notation

- use `GF2N_MUL` to denote multiplication in the Proton finite field.

- define various look-up tables, namely

  ```
  SBOX = {
    0xC, 0x5, 0x6, 0xB, 0x9, 0x0, 0xA, 0xD,
    0x3, 0xE, 0xF, 0x8, 0x4, 0x7, 0x1, 0x2
  }

  M    = {
    { 0x2, 0x4, 0x2, 0xB, 0x2, 0x8, 0x5, 0x6 },
    { 0xC, 0x9, 0x8, 0xD, 0x7, 0x7, 0x5, 0x2 },
    { 0x4, 0x4, 0xD, 0xD, 0x9, 0x4, 0xD, 0x9 },
    { 0x1, 0x6, 0x5, 0x1, 0xC, 0xD, 0xF, 0xE },
    { 0xF, 0xC, 0x9, 0xD, 0xE, 0x5, 0xE, 0xD },
    { 0x9, 0xE, 0x5, 0xF, 0x4, 0xC, 0x9, 0x6 },
    { 0xC, 0x2, 0x2, 0xA, 0x3, 0x1, 0x1, 0xE },
    { 0xF, 0x1, 0xD, 0xA, 0x5, 0xA, 0x2, 0x3 },
  }
  ```

  which respectively capture the 4-bit Proton S-box, and a matrix 
  which drives the `MixColumnsSerial` round function.

<!--- -------------------------------------------------------------------- --->

## Context

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `photon`   |           | `PHOTON_UNROLL`       | use fully (vs. partially, by a factor of two) unrolled implementation                                          |
|           | `photon`   | `rv32`    | `PHOTON_RV32_TYPE1`   | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `photon`   | `rv32`    | `PHOTON_RV32_TYPE2`   | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `photon`   | `rv64`    | `PHOTON_RV64_TYPE1`   | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `photon`   | `rv64`    | `PHOTON_RV64_TYPE2`   | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `PHOTON_RV32_TYPE1`: baseline ISA.

- `PHOTON_RV32_TYPE2`: baseline ISA plus custom ISE.

  ```
  photon.step rd, rs1, rs2, imm {
    x       <- GPR[rs1]
    y       <- GPR[rs2]

    t       <- SBOX[ ( y >> ( 4 * imm ) ) & 0xF ]
    r       <- 0

    for( int i = 0; i < 8; i++ ) {
      r <- r | ( ( GF2N_MUL( M[ i ][ imm ], t ) ) << ( 4 * i ) )
    }

    r       <- r ^ x

    GPR[rd] <- r
  }
  ```

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `PHOTON_RV64_TYPE1`: baseline ISA.

- `PHOTON_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] Z. Bao, A. Chakraborti, N. Datta, J. Guo, M. Nandi, T. Peyrin, and K. Yasuda.
    [PHOTON-Beetle Authenticated Encryption and Hash Family](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/photon-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.
[2] J. Guo, Thomas Peyrin, and A. Poschmann.
    [The PHOTON Family of Lightweight Hash Functions](https://eprint.iacr.org/2011/609.pdf).
    Cryptology ePrint Archive, Report 2011/609, 2011.

<!--- -------------------------------------------------------------------- --->
