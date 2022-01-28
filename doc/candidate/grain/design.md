# `${ALG} = "grain"`

<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Discussion

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `grain`    | `rv32`    | `GRAIN_RV32_TYPE1`    | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `grain`    | `rv32`    | `GRAIN_RV32_TYPE2`    | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `grain`    | `rv64`    | `GRAIN_RV64_TYPE1`    | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `grain`    | `rv64`    | `GRAIN_RV64_TYPE2`    | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `GRAIN_RV32_TYPE1`: baseline ISA.

- `GRAIN_RV32_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `GRAIN_RV64_TYPE1`: baseline ISA.

- `GRAIN_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] M. Hell, T. Johansson, A. Maximov, W. Meier, J. Sönnerup, and H. Yoshida.
    [Grain-128AEADv2 - A lightweight AEAD stream cipher](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/grain-128aead-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.

<!--- -------------------------------------------------------------------- --->
