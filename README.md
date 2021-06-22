# `lwise`: ISEs for NIST lightweight candidates

<!--- ==================================================================== --->

## Overview

...

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
    │   ├── alzette             - source code for alzette 
    │   │   ├── arch              -   architecture-specific resources
    │   │   │   ├── generic         - generic, i.e., vanilla C
    │   │   │   ├── rv32            - 32-bit RISC-V
    │   │   │   └── rv64            - 64-bit RISC-V
    │   │   └── imp               - implementation-specific resources
    │   │       ├── generic         - generic, i.e., vanilla C
    │   │       ├── rv32            - 32-bit RISC-V
    │   │       └── rv64            - 64-bit RISC-V
    │   └── ascon               - source code for ascon
    │       ├── arch              -   architecture-specific resources
    │       │   ├── generic         - generic, i.e., vanilla C
    │       │   ├── rv32            - 32-bit RISC-V
    │       │   └── rv64            - 64-bit RISC-V
    │       └── imp               - implementation-specific resources
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
    - role: specifies the algorithm
    - values: `alzette`, `ascon`
    - default: `alzette`

  - `${ARCH}`
    - role: specifies the architecture
    - values: `generic`, `rv32`, `rv64`
    - default: `generic`

  - `${IMP}`
    - role: specifies the implementation
    - values: `generic`, `rv32`, `rv64`
    - default: `generic`

- The idea is basically that:

  - `${REPO_HOME}/src/software/${ALG}`,
    houses anything algorithm-specific:

    - `${REPO_HOME}/src/software/${ALG}/arch/${ARCH}`,
      contains any   architecture-specific resources, 
    - `${REPO_HOME}/src/software/${ALG}/imp/${IMP}`
      contains any implementation-specific resources.

  - `${REPO_HOME}/src/software/share`,
    houses anything algorithm-agnostic:

    - `${REPO_HOME}/src/software/share/arch/${ARCH}`,
      contains any   architecture-specific resources, 
    - `${REPO_HOME}/src/software/share/imp/${IMP}`
      contains any implementation-specific resources.

  Note that the separation of `${ARCH}` and `${IMP}` allows, for example, 
  the generic C implementation to be compiled for the RV32I architecture.

- The `${CONF}` environment variable allows options to be passed to GCC:

  | `${ARCH}` | `${ALG}`  | `${IMP}`  | Symbol                         | Meaning                                                                                                   |
  | :-------- | :-------- | :-------- | :----------------------------- | :-------------------------------------------------------------------------------------------------------- |
  |           |           |           | `DRIVER_TRIALS_WARM`           | number of verification trials performed by the driver during "warm-up" (i.e., non-measured) phase         |
  |           |           |           | `DRIVER_TRIALS_REAL`           | number of verification trials performed by the driver during "real"    (i.e.,     measured) phase         |
  |           |           |           | `DRIVER_RANDOM`                | use `/dev/random` as a source of randomness, rather than `rand`                                           |
  |           |           |           | `DRIVER_MEASURE`               | take and dump cycle count measurements etc. (`0` means average, `1` means minimum, and `2` means maximum) |
  |           | `alzette` |           |                                | see [documentation](./doc/alzette/README.md)                                                              |
  |           | `ascon`   |           |                                | see [documentation](./doc/ascon/README.md)                                                                |

- Options which use a RISC-V base ISA plus custom ISE do so via the
  [`.insn`](https://www.sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html)
  directive, rather than an invasive change to `binutils` itself.

<!--- -------------------------------------------------------------------- --->

### Software-specific

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

  or use the test script provided

  ```sh
  python3 ${REPO_HOME}/bin/test.py --rv32 --rv64 --trials=10
  ```

  to automatically scan through various different configurations, e.g., 
  ISEs, unrolling strategies, etc.

- Note that since the RISC-V tool-chain is 
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

### Hardware-specific


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
   
