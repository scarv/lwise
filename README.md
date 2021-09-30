# ISEs for NIST lightweight candidates

<!--- ==================================================================== --->

## Overview

The NIST
[lightweight cryptography process](https://csrc.nist.gov/projects/lightweight-cryptography)
is an attempt to
"solicit, evaluate, and standardize lightweight cryptographic algorithms that are suitable for use in constrained environments",
e.g., where even 
[AES](https://en.wikipedia.org/wiki/Advanced_)
might be deemed (too) heavyweight.  From an initial 57 submissions, 10 
[final-round candidates](https://csrc.nist.gov/Projects/lightweight-cryptography/finalists) 
were selected.  This repo. captures an exploration of 
Instruction Set Extensions (ISEs)
for (a subset of) these candidates, based on the use of 
[RISC-V](https://en.wikipedia.org/wiki/RISC-V).
the goal is to add understanding to and so inform selection 
of any resulting standard, with respect to implementation-related criteria
such as execution latency.  

- We consider the RISC-V baseline ISA as being
  RV32GCB (or RV32IMAFDCB) in the 32-bit case
  or 
  RV64GCB (or RV64IMAFDCB) in the 64-bit case,
  meaning that the following standard extensions
  
  - M (multiplication)
  - A (atomic)
  - F (single-precision floating-point)
  - D (double-precision floating-point)
  - C (compressed)
  - Zbkb (a subset of K: bit manipulation instructions for cryptography)

  are available by default.

- Our strategy for each candidate is roughly

  1. do some (manual) analysis, 
  2. produce an ISE design (including instruction semantics, encoding, and so on),
  3. develop a simulator-supported implementation of the ISE,
  4. develop an ISE-assisted software implementation,
  5. develop a  hardware-supported implementation of the ISE,

  with progress so far summarised as follows

  | Algorithm                                                                                                                                                  | Identifier | Design                       | Encoding                        | Toolchain | Software | Hardware |
  | :--------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------: | :--------------------------: | :-----------------------------: | :-------: | :------: | :------: |
  | [Ascon](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/ascon-spec-final.pdf)                 | `ascon`    | [o](./doc/ascon/design.md)   | [o](./doc/ascon/encoding.txt)   | o         |          | o        |
  | [Elephant](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/elephant-spec-final.pdf)           | `elephant` |                              |                                 |           |          |          |
  | [GIFT-COFB](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/gift-cofb-spec-final.pdf)         | `gift`     | [o](./doc/gift/design.md)    | [o](./doc/gift/encoding.txt)    | o         |          |          |
  | [Grain128-AEAD](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/grain-128aead-spec-final.pdf) | `grain`    |                              |                                 |           |          |          |
  | [ISAP](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/isap-spec-final.pdf)                   | `isap`     |  x                           |  x                              | x         | x        | x        |
  | [Photon-Beetle](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/photon-beetle-spec-final.pdf) | `photon`   |                              |                                 |           |          |          |
  | [Romulus](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/romulus-spec-final.pdf)             | `romulus`  |                              |                                 |           |          |          |
  | [Sparkle](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/sparkle-spec-final.pdf)             | `sparkle`  | [o](./doc/sparkle/design.md) | [o](./doc/sparkle/encoding.txt) | o         | o        | o        |
  | [TinyJambu](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/tinyjambu-spec-final.pdf)         | `jambu`    | [o](./doc/jambu/design.md)   | [o](./doc/jambu/encoding.txt)   | o         |          | o        |
  | [Xoodyak](https://csrc.nist.gov/CSRC/media/Projects/lightweight-cryptography/documents/finalist-round/updated-spec-doc/xoodyak-spec-final.pdf)             | `xoodyak`  | [o](./doc/xoodyak/design.md) | [o](./doc/xoodyak/encoding.txt) | o         |          | o        |
  
  noting that we ignore ISAP: this construction is more like a generic mode
  of operation, so there *seems* less scope for use of ISEs.

<!--- ==================================================================== --->

## Organisation

```
├── bin                     - scripts (e.g., environment configuration)
├── doc                     - documentation
├── build                   - working directory for build
└── src                     - source code
    ├── hw                    - source code for hardware
    │   ├── fpga                - source code for the FPGA implementation using Vivado
    │   │   ├── board             - source for supporting a specific board (e.g., sakura-x)
    │   │   ├── script            - scripts for handling the FPGA bitstream on Vivado
    │   │   ├── soc               - the Vivado projects based on the Rocket Chip SoC.
    │   │   └── software          - build algorithm-specific sofware running on the FPGA.
    │   ├── rocketchip          - source code for ISE-enabled Rocket Chip
    │   ├── rtl                 - rtl implementation
    │   │   ├── rv32              - 32-bit implementation
    │   │   └── rv64              - 64-bit implementation
    │   ├── verilator         - source code for emulator for use with Rocket Chip
    │   └── yosys_synth       - synthesise hardware implementation using yosys
    ├── hw-toolchain        - source code for hardware toolchain
    │
    ├── sw                  - source code for software
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
    └── sw-toolchain        - source code for software tool-chain
```

<!--- ==================================================================== --->

## Notes: software

### Build system

- The build system is controlled by several environment variables:

  - `${ALG}`
    - role: specifies the      algorithm, i.e., select `${REPO_HOME}/src/sw/${ALG}`
    - values: `ascon`, `elephant`, `gift`, `grain`, `photon`, `romulus`, `jambu`, `sparkle`, `xoodyak`
    - default: `sparkle`

  - `${ARCH}`
    - role: specifies the   architecture, i.e., select `${REPO_HOME}/src/sw/${ALG}/arch/${ARCH}`
    - values: `generic`, `rv32`, `rv64`
    - default: `generic`

  - `${IMP}`
    - role: specifies the implementation, i.e., select `${REPO_HOME}/src/sw/${ALG}/imp/${IMP}`
    - values: `generic`, `rv32`, `rv64`
    - default: `generic`

- The `${CONF}` environment variable allows options to be passed to GCC,
  e.g.,

  | Symbol               | Meaning                                                                                                               |
  | :------------------- | :-------------------------------------------------------------------------------------------------------------------- |
  | `DRIVER_TRIALS_WARM` | number of verification trials performed by the driver during "warm-up" (i.e., non-measured) phase (default is   `10`) |
  | `DRIVER_TRIALS_REAL` | number of verification trials performed by the driver during "real"    (i.e.,     measured) phase (default is `1000`) |
  | `DRIVER_TRIALS_KAT`  | enable verification trials based on Known Answer Tests   (KATs) if available                                          |
  | `DRIVER_TRIALS_BIST` | enable verification trials based on Built-In Self Tests (BISTs) if available                                          |
  | `DRIVER_RANDOM`      | use `/dev/random` as a source of randomness, rather than `rand`                                                       |
  | `DRIVER_MEASURE`     | take and dump cycle count measurements etc. (`0` means average, `1` means minimum, and `2` means maximum)             |

  plus various algorithm-, architecture-, and/or implementation-specific
  cases documented elsewhere.

### Toolchain

- Options which use a RISC-V baseline ISA plus custom ISE do so via the
  [`.insn`](https://www.sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html)
  directive, rather than an invasive change to `binutils` itself.

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
  ./configure --prefix="${RISCV}" --enable-multilib --with-multilib-generator="rv32gc_zbb-ilp32--;rv64gc_zbb-lp64--"
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
  for each algorithm, 
  e.g.,
  
  ```sh
  make ALG="sparkle" sw-toolchain-build
  ```

- Build and execute implementation, 
  e.g.,

  ```sh
  make ALG="sparkle" sw-build
  make ALG="sparkle" sw-run
  ```

  or use the script provided, 
  e.g.,

  ```sh
  make ALG="sparkle" sw-scan
  ```

  to automatically scan through various different configurations
  (such as those with respect to ISEs options, unrolling strategies, and so on).

- Note that since the tool-chain is 
  [patch](https://savannah.gnu.org/projects/patch)-based,
  making changes to it is somewhat tricky.  The idea, for each component,
  (i.e., `pk` and `spike`) referred to as `${COMPONENT}` is as follows:

  - perform a fresh clone of the component repository,
  - apply the existing patch to the cloned component repository,
  - implement the change in the cloned component repository,
  - stage the change via `git add`, but do *not* commit it, in the cloned component repository,
  - execute `${REPO_HOME}/src/sw-toolchain/${COMPONENT}-update.sh` to produce an updated patch,
  - optionally commit and push the updated patch.

<!--- -------------------------------------------------------------------- --->

## Notes: hardware

### Build system

- ISE supporting hardware is implemented in Verilog and integrated into a Rocket Chip. 
  The build hardware system is controlled by two environment variables, 
  namely `${ARCH}` and `${ISE}`.

  - The base Rocket Chip can be configured with a 32-bit or 64-bit architecture (i.e., `ARCH=rv32` or `ARCH=rv64`, respectively).
    `${ARCH}` is consistent with the build software system. 
  - The ISE supporting hardware can be integrated into the base processor 
    as a co-processor via a RoCC interface or 
    as a functional module, i.e., extended ALU, inside the processor pipeline 
    by configuring `ISE=cop` or `ISE=xalu`, respectively. 

### Toolchain

- Fix path for the installed Vivado Design Suite, e.g., 
  
  ```sh
  export VIVADO_TOOL_DIR="/opt/Xilinx/Vivado/2018.2"
  source ./bin/Vivado-conf.sh
  ```

- Fix paths for the Rocket Chip toolchain, e.g., 
  
  ```sh
  export RISCV_ROCKET="/opt/riscv-rocket"
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

- The build system in

  ```sh
  ${REPO_HOME}/src/hw/Makefile
  ```
  
  includes 
  - ISE-enabled Rocket Chip implementation, 
  - hardware synthesis flow,
  - an emulator for the implementation, 
  - an FPGA implementation using Vivado.

- Get an ISE-enabled
  [Rocket-Chip](https://github.com/chipsalliance/rocket-chip.git)
  implementation

  ```sh
  make -f ${REPO_HOME}/src/hw/Makefile rocketchip-clone
  make -f ${REPO_HOME}/src/hw/Makefile rocketchip-apply
  ```

- Run hardware synthesis flow using
  [yosys](https://github.com/YosysHQ/yosys)

  ```sh
  make -f ${REPO_HOME}/src/hw/Makefile synthesise ARCH="rv32" ISE="xalu"
  ```

- Build the emulator of the implementation using 
  [verilator](https://www.veripool.org/verilator): 

  ```sh
  make -f ${REPO_HOME}/src/hw/Makefile ARCH="rv32" ISE="xalu" emulator
  ```

  - Build and execute software on the emulator of the hardware implementation, e.g.,

    ```sh
    make --directory="${REPO_HOME}/src/hardware" ARCH="rv32" IMP="rv32" ISE="xalu" CONF="-DDRIVER_TRIALS_REAL='10'" emu-clean emulate
    ```

- Build the bitstream of the Xilinx FPGA and run a software on the FPGA using Vivado:

  ```sh
  make -f ${REPO_HOME}/src/hw/Makefile ARCH="rv32" ISE="xalu" fpga-verilog
  make -f ${REPO_HOME}/src/hw/Makefile ARCH="rv32" ISE="xalu" program-fpga
  ```

  - Build and execute software on the hardware implementation on the FPGA, e.g.,

    ```sh
    make --directory="${REPO_HOME}/src/hw" ARCH="rv32" IMP="rv32" ISE="xalu" fpga-clean fpga-run
    ```

<!--- -------------------------------------------------------------------- --->
   
