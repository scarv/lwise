# `${ALG} = "romulus"`

<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Context

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE1`  | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `romulus`  | `rv32`    | `ROMULUS_RV32_TYPE2`  | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE1`  | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `romulus`  | `rv64`    | `ROMULUS_RV64_TYPE2`  | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ROMULUS_RV32_TYPE1`: baseline ISA.

- `ROMULUS_RV32_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ROMULUS_RV64_TYPE1`: baseline ISA.

- `ROMULUS_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] C. Guo, T. Iwata, M. Khairallah, K. Minematsu, and Thomas Peyrin.
    [Romulus](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/romulus-spec-final.pdf).
    Submission to NIST (version 1.3), 2021.

<!--- -------------------------------------------------------------------- --->
