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
    { 0xF, 0x1, 0xD, 0xA, 0x5, 0xA, 0x2, 0x3 }
  }
  ```

  which respectively capture the 4-bit Proton S-box, and a matrix 
  which drives the `MixColumnsSerial` round function.

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `photon`   | `rv32`    | `PHOTON_RV32_UNROLL`   | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `photon`   | `rv32`    | `PHOTON_RV32_TYPE1`    | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `photon`   | `rv32`    | `PHOTON_RV32_TYPE2`    | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `PHOTON_RV32_TYPE1`: base ISA.

- `PHOTON_RV32_TYPE2`: base ISA plus ISE.

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
