# ISEs for NIST lightweight candidates

<!--- ==================================================================== --->

## Overview

The NIST
[lightweight cryptography process](https://csrc.nist.gov/projects/lightweight-cryptography)
is an attempt to
"solicit, evaluate, and standardize lightweight cryptographic algorithms that are suitable for use in constrained environments",
e.g., where even 
[AES](https://en.wikipedia.org/wiki/Advanced_)
might be deemed (too) heavyweight.  From an initial 57 submissions, the 10 
[final-round candidates](https://csrc.nist.gov/Projects/lightweight-cryptography/finalists) 
are

1. [ASCON](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/ascon-spec-final.pdf)
1. [Elephant](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/elephant-spec-final.pdf)
1. [GIFT-COFB](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/gift-cofb-spec-final.pdf)
1. [Grain128-AEAD](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/grain-128aead-spec-final.pdf)
1. [ISAP](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/isap-spec-final.pdf)
1. [Photon-Beetle](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/photon-beetle-spec-final.pdf)
1. [Romulus](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/romulus-spec-final.pdf)
1. [Sparkle](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/sparkle-spec-final.pdf)
1. [TinyJambu](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/tinyjambu-spec-final.pdf)
1. [Xoodyak](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/xoodyak-spec-final.pdf)

This repo. captures an exploration of 
Instruction Set Extensions (ISEs)
for (a subset of) these candidates, based on the use of 
[RISC-V](https://en.wikipedia.org/wiki/RISC-V)
as a base ISA: the goal is to add understanding to and so inform selection 
of any resulting standard, with respect to implementation-related criteria
such as execution latency.

<!--- ==================================================================== --->

## Organisation

```
├── bin                     - scripts (e.g., environment configuration)
├── doc                     - documentation
├── build                   - working directory for build
└── src                     - source code
    ├── hardware              - source code for hardware
    │   ├── rocketchip          - source code for ISE-enabled Rocket
    │   ├── rtl                 - rtl implementation
    │   │   ├── rv32              - 32-bit implementation
    │   │   └── rv64              - 64-bit implementation
    │   ├── verilator         - source code for emulator for use with Rocket
    │   └── yosys_synth       - synthesise hardware implementation using yosys
    ├── software              - source code for software
    │   ├── ${ALG}              - anything algorithm-specific
    │   │   ├── arch              -   architecture-specific resources
    │   │   │   ├── generic         - generic, i.e., vanilla C
    │   │   │   ├── rv32            - 32-bit RISC-V
    │   │   │   └── rv64            - 64-bit RISC-V
    │   │   └── imp               - implementation-specific resources
    │   │       ├── generic         - generic, i.e., vanilla C
    │   │       ├── rv32            - 32-bit RISC-V
    │   │       └── rv64            - 64-bit RISC-V
    │   └── share               - anything algorithm-agnostic
    │       └── arch              -   architecture-specific resources
    │           ├── generic         - generic, i.e., vanilla C
    │           ├── rv32            - 32-bit RISC-V
    │           └── rv64            - 64-bit RISC-V
    ├── toolchain             - source code for tool-chain
    └── toolchain-rocket      - source code for tool-chain for use with Rocket
```

<!--- ==================================================================== --->

## Notes

<!--- -------------------------------------------------------------------- --->

### Build system

- The build system is controlled by several environment variables:

  - `${ALG}`
    - role: specifies the      algorithm, i.e., select `${REPO_HOME}/src/software/${ALG}`
    - values: `alzette`, `ascon`
    - default: `alzette`

  - `${ARCH}`
    - role: specifies the   architecture, i.e., select `${REPO_HOME}/src/software/${ALG}/arch/${ARCH}`
    - values: `generic`, `rv32`, `rv64`
    - default: `generic`

  - `${IMP}`
    - role: specifies the implementation, i.e., select `${REPO_HOME}/src/software/${ALG}/imp/${IMP}`
    - values: `generic`, `rv32`, `rv64`
    - default: `generic`

  Note that the separation of `${ARCH}` and `${IMP}` allows, for example, 
  the generic C implementation to be compiled for the RV32I architecture.

- The `${CONF}` environment variable allows options to be passed to GCC:

  | `${ARCH}` | `${ALG}`  | `${IMP}`  | Symbol               | Meaning                                                                                                        |
  | :-------- | :-------- | :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
  |           |           |           | `DRIVER_TRIALS_WARM` | number of verification trials performed by the driver during "warm-up" (i.e., non-measured) phase              |
  |           |           |           | `DRIVER_TRIALS_REAL` | number of verification trials performed by the driver during "real"    (i.e.,     measured) phase              |
  |           |           |           | `DRIVER_RANDOM`      | use `/dev/random` as a source of randomness, rather than `rand`                                                |
  |           |           |           | `DRIVER_MEASURE`     | take and dump cycle count measurements etc. (`0` means average, `1` means minimum, and `2` means maximum)      |
  |           | `alzette` |           |                      | see [documentation](./doc/alzette/ise.md)                                                                      |
  |           | `ascon`   |           |                      | see [documentation](./doc/ascon/ise.md)                                                                        |

- Options which use a RISC-V base ISA plus custom ISE do so via the
  [`.insn`](https://www.sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html)
  directive, rather than an invasive change to `binutils` itself.

<!--- -------------------------------------------------------------------- --->

### Toolchain

- Since the RISC-V tool-chain is 
  [patch](https://savannah.gnu.org/projects/patch)-based,
  making changes to it is somewhat tricky.  The idea, for each component,
  (i.e., `pk` and `spike`) referred to as `${COMPONENT}` is as follows:

  - perform a fresh clone of the component repository,
  - apply the existing patch to the cloned component repository,
  - implement the change in the cloned component repository,
  - stage the change via `git add`, but do *not* commit it, in the cloned component repository,
  - execute `${REPO_HOME}/src/toolchain/${COMPONENT}-update.sh` to produce an updated patch,
  - optionally commit and push the updated patch.

<!--- -------------------------------------------------------------------- --->

### Software

- Fix paths, e.g., 
  
  ```sh
  export RISCV="/opt/riscv"
  ```

- Build a multi-architecture 
  [tool-chain](https://github.com/riscv/riscv-gnu-toolchain)
  into `${RISCV}`:
  
  ```sh
  git clone https://github.com/riscv/riscv-gnu-toolchain.git ./riscv-gnu-toolchain
  cd ./riscv-gnu-toolchain
  git submodule update --init --recursive
  ./configure --prefix="${RISCV}" --enable-multilib --with-multilib-generator="rv32gc-ilp32--;rv64gc-lp64--"
  make
  ```

- Clone the repo.

  ```sh
  git clone https://github.com/scarv/alzette.git ./alzette
  cd ./alzette
  git submodule update --init --recursive
  source ./bin/conf.sh
  ```

- Build an ISE-enabled 
  [`spike`](https://github.com/riscv/riscv-isa-sim)
  and associated
  [`pk`](https://github.com/riscv/riscv-pk) 
  for each algorithm:
  
  ```sh
  make ALG="alzette" toolchain-build
  make ALG="ascon"   toolchain-build
  ```

- Build and execute implementation, e.g.,

  ```sh
  make ALG="alzette"  software-build
  make ALG="alzette"  software-run
  make ALG="ascon"    software-build
  make ALG="ascon"    software-run
  ```

  or use the script provided

  ```sh
  make ALG="alzette"  software-scan
  make ALG="ascon"    software-scan
  ```

  to automatically scan through various different configurations, e.g., 
  ISEs, unrolling strategies, etc.

<!--- -------------------------------------------------------------------- --->

### Hardware


- Build a
  [toolchain](https://github.com/riscv/riscv-gnu-toolchain)
  for use with
  [Rocket-Chip](https://github.com/chipsalliance/rocket-chip.git)
  into `${RISCV_ROCKET}`:

  ```sh
  make -f ${REPO_HOME}/src/toolchain-rocket/Makefile clone
  make -f ${REPO_HOME}/src/toolchain-rocket/Makefile build
  ```

- The build system in

  ```sh
  ${REPO_HOME}/src/hardware/Makefile
  ```
  
  includes 
  - ISE-enabled Rocket-Chip implementation, 
  - an emulator for the implementation, 
  - hardware synthesis flow

- Get an ISE-enabled
  [Rocket-Chip](https://github.com/chipsalliance/rocket-chip.git)
  implementation

  ```sh
  make -f ${REPO_HOME}/src/hardware/Makefile rocketchip-clone
  make -f ${REPO_HOME}/src/hardware/Makefile rocketchip-apply
  ```
- Build the emulator of the implementation using 
  [verilator](https://www.veripool.org/verilator)

  ```sh
  make -f ${REPO_HOME}/src/hardware/Makefile emulator32
  make -f ${REPO_HOME}/src/hardware/Makefile emulator64
  ```
- Run hardware synthesis flow using
  [yosys](https://github.com/YosysHQ/yosys)

  ```sh
  make -f ${REPO_HOME}/src/hardware/Makefile synthesise ARCH=rv32
  make -f ${REPO_HOME}/src/hardware/Makefile synthesise ARCH=rv64
  ```
- Build and execute software on the emulator of the hardware implementation, e.g.,

  ```sh
  make --directory="${REPO_HOME}/src/hardware" ARCH="rv32" IMP="rv32" CONF="-DDRIVER_TRIALS_REAL='1000'" clean all emulate
  ```

<!--- ==================================================================== --->
   
