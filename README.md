# `lwise`: ISEs for NIST lightweight candidates

<!--- -------------------------------------------------------------------- --->

## Overview

...

<!--- -------------------------------------------------------------------- --->

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
    │   ├── arch                - architecture-specific support
    │   │   ├── generic           - generic, i.e., vanilla C
    │   │   ├── rv32              - 32-bit RISC-V
    │   │   └── rv64              - 64-bit RISC-V
    │   └── imp                 - implementation
    │       ├── generic           - generic, i.e., vanilla C
    │       ├── rv32              - 32-bit RISC-V
    │       └── rv64              - 64-bit RISC-V
    ├── toolchain             - source code for tool-chain
    └── toolchain-rocket      - source code for tool-chain for use with Rocket
```

<!--- -------------------------------------------------------------------- --->

## Notes

### Generic

- The build system is controlled by three environment variables, namely
  `${ARCH}`, `${IMP}`, and `${CONF}`.  The idea is that

  - there's one set of generic driver source code located in
    `${REPO_HOME}/src/software`,
  - `${REPO_HOME}/src/software/arch/${ARCH}`,
    contains any architecture-specific resources, e.g.,
    a `Makefile.in` to support the build system, definitions allowing use of any ISEs,
  - `${REPO_HOME}/src/software/imp/${IMP}`
    contains any architecture-specific implementations, e.g.,
    an implementation of `craxs10_enc`.

  Note that the separation of `${ARCH}` and `${IMP}` allows, for example, the generic
  C implementation to be compiled and simulated on an RV32I architecture.

- `${CONF}` allows a set of options passed to GCC:

  | Symbol               | Meaning                                                                                                   |
  | :------------------- | :-------------------------------------------------------------------------------------------------------- |
  | `DRIVER_TRIALS_WARM` | number of verification trials performed by the driver during "warm-up" (i.e., non-measured) phase         |
  | `DRIVER_TRIALS_REAL` | number of verification trials performed by the driver during "real"    (i.e.,     measured) phase         |
  | `DRIVER_RANDOM`      | use `/dev/random` as a source of randomness, rather than `rand`                                           |
  | `DRIVER_MEASURE`     | take and dump cycle count measurements etc. (`0` means average, `1` means minimum, and `2` means maximum) |

- The RISC-V plus custom ISE options make use of the ISE via the
  [`.insn`](https://www.sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html)
  directive, rather than an invasive change to `binutils` itself.

### Software-specific

- Build a toolchain:

  - Fix paths, e.g., 
  
    ```sh
    export RISCV="/opt/riscv"
    export RISCV_ROCKET="/opt/riscv-rocket"
    export RISCV_ALZETTE="/opt/riscv-alzette"
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
  - Build an ISE-enabled 
    [`spike`](https://github.com/riscv/riscv-isa-sim)
    and associated
    [`pk`](https://github.com/riscv/riscv-pk) 
    into `${RISCV_ALZETTE}`:
  
    ```sh
    git clone https://github.com/scarv/alzette.git ./alzette
    cd ./alzette
    git submodule update --init --recursive
    source ./bin/conf.sh
    make -f ${REPO_HOME}/src/toolchain/Makefile clone 
    make -f ${REPO_HOME}/src/toolchain/Makefile apply 
    make -f ${REPO_HOME}/src/toolchain/Makefile build
    ```
  - Build a
    [toolchain](https://github.com/riscv/riscv-gnu-toolchain)
    for use with
    [Rocket-Chip](https://github.com/chipsalliance/rocket-chip.git)
    into `${RISCV_ROCKET}`:

    ```sh
    make -f ${REPO_HOME}/src/toolchain-rocket/Makefile clone
    make -f ${REPO_HOME}/src/toolchain-rocket/Makefile build
    ```
  
- Build and execute implementation, e.g.,

  ```sh
  make --directory="${REPO_HOME}/src/software" ARCH="generic" IMP="generic" CONF="-DDRIVER_TRIALS_REAL='1000'" clean all run
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

### Hardware-specific

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

<!--- -------------------------------------------------------------------- --->  
   
