# `${ALG} = "photon"`

<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Context

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                | Meaning                                                                                                        |
| :-------- | :--------- | :-------- | :-------------------- | :------------------------------------------------------------------------------------------------------------- |
|           | `photon`   | `rv32`    | `PHOTON_RV32_TYPE1`   | select 32-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `photon`   | `rv32`    | `PHOTON_RV32_TYPE2`   | select 32-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |
|           | `photon`   | `rv64`    | `PHOTON_RV64_TYPE1`   | select 64-bit RISC-V baseline ISA:                 option 1, per description below                             |
|           | `photon`   | `rv64`    | `PHOTON_RV64_TYPE2`   | select 64-bit RISC-V baseline ISA plus custom ISE: option 2, per description below                             |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `PHOTON_RV32_TYPE1`: baseline ISA.

- `PHOTON_RV32_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv64"`

- `PHOTON_RV64_TYPE1`: baseline ISA.

- `PHOTON_RV64_TYPE2`: baseline ISA plus custom ISE.

<!--- -------------------------------------------------------------------- --->

## References

[1] Z. Bao, A. Chakraborti, N. Datta, J. Guo, M. Nandi, T. Peyrin, and K. Yasuda.
    [PHOTON-Beetle Authenticated Encryption and Hash Family](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/photon-spec-final.pdf).
    Submission to NIST (version 2.0), 2021.

<!--- -------------------------------------------------------------------- --->
