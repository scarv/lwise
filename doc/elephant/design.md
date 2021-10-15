# `${ALG} = "elephant"`

<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Context

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE1` | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `elephant` | `rv32`    | `ELEPHANT_RV32_TYPE2` | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `elephant` | `rv64`    | `ELEPHANT_RV64_TYPE1` | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `elephant` | `rv64`    | `ELEPHANT_RV64_TYPE2` | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `ELEPHANT_RV32_TYPE1`: baseline ISA.

- `ELEPHANT_RV32_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `ELEPHANT_RV64_TYPE1`: baseline ISA.

- `ELEPHANT_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] T. Beyne, Y. L. Chen, C. Dobraunig, and B. Mennink.
    [Elephant](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/elephant-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.

<!--- -------------------------------------------------------------------- --->
