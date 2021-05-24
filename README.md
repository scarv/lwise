# A "zoo" of Alzette-based implementations

<!--- -------------------------------------------------------------------- --->

## Overview

This is a repository to support a project on efficient implementation
of Alzette [1] (and so also, e.g., CRAXS10 and TRAXL17).  The goal is 
to consider a wide range of different platforms, e.g., some subset of

1. AVR
2. MSP430
3. ARM
   - ARM
   - ARM+NEON
   - ARM+SVE
   - ...
4. x86
   - x86
   - x86+SSE
   - x86+AVX
   - ...
5. RISC-V
   - RV32I
   - RV32IB, i.e., with [BitManip](https://github.com/riscv/riscv-bitmanip) ISE
   - RV32IV, i.e., with [vector](https://github.com/riscv/riscv-v-spec)     ISE
   - RV32I         with  custom                                             ISEs (see below)
   - RV64I
   - RV64IB, i.e., with [BitManip](https://github.com/riscv/riscv-bitmanip) ISE
   - RV64IV, i.e., with [vector](https://github.com/riscv/riscv-v-spec)     ISE
   - RV64I         with  custom                                             ISEs (see below)
6. ...

but focused on RISC-V in particular.

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
    │   │   ├── rv32              - 32-bit RISC-V
    │   │   ├── rv64              - 64-bit RISC-V
    │   ├── verilator         - source code for emulator for use with Rocket
    │   └── yosys_synth       - synthesize hardware implementation using yosys
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

## Quickstart

- For RISC-V implementations:

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
  make --directory="${REPO_HOME}/src/software" ARCH="generic" IMP="generic" CONF="-DDRIVER_TRIALS='10'" clean all run
  ```

  or use the test script provided

  ```sh
  python3 ${REPO_HOME}/bin/test.py --rv32 --rv64 --trials=10
  ```

  to automatically scan through various different configurations, e.g., 
  ISEs, unrolling strategies, etc.

<!--- -------------------------------------------------------------------- --->

## Notes

### Hardware

- The build system in

  ```sh
  ${REPO_HOME}/src/hardware/Makefile
  ```
  
  includes 
  - ISE-enabled Rocket-Chip implementation, 
  - An emulator for the implementation, 
  - Hardware synthesis flow

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
  make --directory="${REPO_HOME}/src/hardware" ARCH="generic" IMP="generic" CONF="-DDRIVER_TRIALS='10'" clean all emulate
  ```

### Software

- The build system in

  ```sh
  ${REPO_HOME}/src/software/Makefile
  ```

  is controlled by three environment variables, namely

  - `${ARCH}`
  - `${IMP}` 
  - `${CONF}`

- The idea is that

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

  | `${ARCH}` | Symbol               | Meaning                                                                                                        |
  | :-------- | :------------------- | :------------------------------------------------------------------------------------------------------------- |
  |           | `DRIVER_TRIALS`      | number of verification trials performed by the driver                                                          |
  |           | `DRIVER_RANDOM`      | use `/dev/random` as a source of randomness, rather than `rand`                                                |
  |           | `DRIVER_MEASURE`     | take and dump cycle count measurements etc.                                                                    |
  |           | `CRAXS10_ENC_EXTERN` | don't include implementation of CRAX encryption in driver, i.e., allow an architecture-specific implementation |
  |           | `CRAXS10_DEC_EXTERN` | don't include implementation of CRAX decryption in driver, i.e., allow an architecture-specific implementation |
  |           | `CRAXS10_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX encryption                       |
  |           | `CRAXS10_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX decryption                       |
  |           | `TRAXL17_ENC_EXTERN` | don't include implementation of TRAX encryption in driver, i.e., allow an architecture-specific implementation |
  |           | `TRAXL17_DEC_EXTERN` | don't include implementation of TRAX decryption in driver, i.e., allow an architecture-specific implementation |
  |           | `TRAXL17_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX encryption                       |
  |           | `TRAXL17_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX decryption                       |
  |           | `SPARKLE_FWD_EXTERN` | don't include implementation of forward SPARKLE in driver, i.e., allow an architecture-specific implementation |
  |           | `SPARKLE_REV_EXTERN` | don't include implementation of reverse SPARKLE in driver, i.e., allow an architecture-specific implementation |
  |           | `SPARKLE_FWD_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of forward SPARKLE                       |
  |           | `SPARKLE_REV_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of reverse SPARKLE                       |
  | `rv32`    | `RV32B`              | enable BitManip-like ISE for 32-bit RISC-V                                                                     |
  | `rv32`    | `RV32_ELL`           | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
  | `rv32`    | `RV32_RCON`          | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
  | `rv32`    | `RV32_TYPE1`         | select 32-bit RISC-V base ISA:                 option 1, per description below                                 |
  | `rv32`    | `RV32_TYPE2`         | select 32-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
  | `rv32`    | `RV32_TYPE3`         | select 32-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
  | `rv32`    | `RV32_TYPE4`         | select 32-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
  | `rv64`    | `RV64B`              | enable BitManip-like ISE for 64-bit RISC-V                                                                     |
  | `rv64`    | `RV64_ELL`           | enable ISE for `\ell` function                (as used in, e.g., TRAXL17, SPARKLE)                             |
  | `rv64`    | `RV64_RCON`          | enable ISE for round constant look-up and XOR (as used in, e.g.,          SPARKLE)                             |
  | `rv64`    | `RV64_TYPE1`         | select 64-bit RISC-V base ISA:                 option 1, per description below                                 |
  | `rv64`    | `RV64_TYPE2`         | select 64-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
  | `rv64`    | `RV64_TYPE3`         | select 64-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
  | `rv64`    | `RV64_TYPE4`         | select 64-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
  | `rv64`    | `RV64_TYPE5`         | select 64-bit RISC-V base ISA plus custom ISE: option 5, per description below                                 |

### Tool-chain

- The RISC-V plus custom ISE options make use of the ISE via the
  [`.insn`](https://www.sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html)
  directive, rather than an invasive change to `binutils` itself.

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

## RISC-V related implementation options

### Notation

Throughout the following, we

- use `ROR32` (resp. `ROR64`) to denote a 32-bit (resp. 64-bit) right-rotate,
- define 
 
  ```
  ELL( x ) = ROR32( x  ^ ( x  << 16 ), 16 )
  ```

- define a look-up table such that

  ```
  RCON  = { 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D }
  ```

- define a look-up table such that

  ```
  ROT_X = { 31, 17,  0, 24 }
  ROT_Y = { 24, 17, 31, 16 }
  ```

### Context

Focusing on encryption, the Alzette function is described in [Appx. C, 1] 
as follows

```
.macro ALZETTE xi:req, yi:req, ci:req
  add \xi, \xi, \yi, ror #31
  eor \yi, \yi, \xi, ror #24
  eor \xi, \xi, \ci
  add \xi, \xi, \yi, ror #17
  eor \yi, \yi, \xi, ror #17
  eor \xi, \xi, \ci
  add \xi, \xi, \yi
  eor \yi, \yi, \xi, ror #31
  eor \xi, \xi, \ci
  add \xi, \xi, \yi, ror #24
  eor \yi, \yi, \xi, ror #16
  eor \xi, \xi, \ci
.endm
```

or, as more C-like pseudo-code

```
ALZETTE( xi, yi, ci ) {
  xi = xi + ROR32( yi, 31 )
  yi = yi ^ ROR32( xi, 24 )
  xi = xi ^        ci

  xi = xi + ROR32( yi, 17 )
  yi = yi ^ ROR32( xi, 17 )
  xi = xi ^        ci

  xi = xi + ROR32( yi,  0 )
  yi = yi ^ ROR32( xi, 31 )
  xi = xi ^        ci

  xi = xi + ROR32( yi, 24 )
  yi = yi ^ ROR32( xi, 16 )
  xi = xi ^        ci
}
```

intentionally typeset to stress repeated use of an `add-xor-xor` block.

### RV32 (see also [`doc/encoding.txt`](./doc/encoding.txt))

- The (optional) BitManip-like ISE:

  ```
  alz.rori          rd, rs1,      imm => ROR32( GPR[rs1], imm )
  ```

- The (optional) ISE for `\ell` function:

  ```
  alz.ell           rd, rs1, rs2      => x    <- GPR[rs1] ^ GPR[rs2]
                                         r    <- ELL( x  )
                                         GPR[rd] <- r
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  alz.rcon          rd, rs1,      imm => x    <- GPR[rs1]
                                         r    <- x  ^ RCON[imm]
                                         GPR[rd] <- r 
  ```

- `RV32_TYPE1`: base ISA.

- `RV32_TYPE2`: base ISA plus custom   ISE.

  ```
  alz.addrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], imm )
  alz.subrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], imm )
  alz.xorrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], imm )
  ```

- `RV32_TYPE3`: base ISA plus custom   ISE.

  ```
  alz.addror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], 31 )
  alz.addror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], 17 )
  alz.addror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ROR32( GPR[rs2], 24 )
  alz.subror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], 31 )
  alz.subror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], 17 )
  alz.subror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ROR32( GPR[rs2], 24 )
  alz.xorror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 31 )
  alz.xorror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 17 )
  alz.xorror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 24 )
  alz.xorror.16     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ROR32( GPR[rs2], 16 )
  ```
     
- `RV32_TYPE4`: base ISA plus custom   ISE.
   
  ```
  alz.whole.enci.x  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- xi

  alz.whole.enci.y  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi

  alz.whole.deci.x  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- xi

  alz.whole.deci.y  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- RCON[imm]
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi
    ```

### RV64 (see also [`doc/encoding.txt`](./doc/encoding.txt))

- The (optional) BitManip-like ISE:

  ```
  alz.rori          rd, rs1,      imm => GPR[rd] <- ROR64( GPR[rs1], imm )
  alz.roriw         rd, rs1,      imm => GPR[rd] <- ROR32( GPR[rs1], imm )

  alz.pack          rd, rs1, rs2      => hi <-   GPR[rs2] << 32
                                         lo <- ( GPR[rs1] << 32 ) >> 32
                                         GPR[rd] <- hi || lo

  alz.packu         rd, rs1, rs2      => hi <- ( GPR[rs2] >> 32 ) << 32
                                         lo <-   GPR[rs1] >> 32
                                         GPR[rd] <- hi || lo
  ```

- The (optional) ISE for `\ell` function:

  ```
  alz.ell           rd, rs1, rs2      => x    <- GPR[rs1] ^ GPR[rs2]
                                         xh   <- x_{63..32}
                                         xl   <- x_{31.. 0}
                                         rh   <- ELL( xh )
                                         rl   <- ELL( xl )
                                         GPR[rd] <- rh || rl

  alz.ellrev        rd, rs1, rs2      => x    <- GPR[rs1] ^ GPR[rs2]
                                         xh   <- x_{63..32}
                                         xl   <- x_{31.. 0}
                                         rh   <- ROR32( xh ^ ( xh << 16 ), 16 )
                                         rl   <- ROR32( xl ^ ( xl << 16 ), 16 )
                                         GPR[rd] <- rl || rh
  ```

- The (optional) ISE for round constant look-up and XOR:

  ```
  alz.rcon          rd, rs1,      imm => xh   <- GPR[rs1]_{63..32}
                                         xl   <- GPR[rs1]_{31.. 0}
                                         rh   <- xl ^ RCON[imm]
                                         rl   <- xl ^ RCON[imm]
                                         GPR[rd] <- rh || rl 

  alz.rconw         rd, rs1,      imm => xl   <- GPR[rs1]_{31.. 0}
                                         rl   <- xl ^ RCON[imm]
                                         GPR[rd] <- rh || rl
  ```

- `RV64_TYPE1`: base ISA.

- `RV64_TYPE2`: base ISA plus custom   ISE.

  ```
  alz.block.enci    rd, rs1, rs2, imm => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, ROT_X[imm] )
                                         yi <- yi ^ ROR32( xi, ROT_Y[imm] )
                                         xi <- xi ^        ci
                                         GPR[rd] <- xi || yi

  alz.block.deci    rd, rs1, rs2, imm => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ROR32( xi, ROT_Y[imm] )
                                         xi <- xi - ROR32( yi, ROT_X[imm] )
                                         GPR[rd] <- xi || yi
  ```

- `RV64_TYPE3`: base ISA plus custom   ISE.

  ```
  alz.block.enc.0   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.1   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.2   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.3   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.block.dec.0   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.1   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.2   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.3   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         GPR[rd] <- yi || xi
    ```

- `RV64_TYPE4`: base ISA plus custom   ISE.

  ```
  alz.whole.enci    rd, rs1,      imm => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- RCON[imm]
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.whole.deci    rd, rs1,      imm => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- RCON[imm]
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi || xi
  ```

- `RV64_TYPE5`: base ISA plus custom   ISE.

  ```
  alz.whole.enc     rd, rs1, rs2      => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ROR32( yi, 31 )
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 17 )
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi,  0 )
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi ^        ci
                                         xi <- xi + ROR32( yi, 24 )
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi ^        ci
                                         GPR[rd] <- yi || xi

  alz.whole.dec     rd, rs1, rs2      => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 16 )
                                         xi <- xi - ROR32( yi, 24 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 31 )
                                         xi <- xi - ROR32( yi,  0 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 17 )
                                         xi <- xi - ROR32( yi, 17 )
                                         xi <- xi ^        ci
                                         yi <- yi ^ ROR32( xi, 24 )
                                         xi <- xi - ROR32( yi, 31 )
                                         GPR[rd] <- yi || xi
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Alzette: a 64-bit ARX-box (feat. CRAX and TRAX)](https://link.springer.com/chapter/10.1007/978-3-030-56877-1_15).
    Advances in Cryptology (CRYPTO), Springer-Verlag LNCS 12172, 419--448, 2020.
    See also [Cryptology ePrint Archive, Report 2019/1378](https://eprint.iacr.org/2019/1378).

[2] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Lightweight AEAD and Hashing using the Sparkle Permutation Family](https://tosc.iacr.org/index.php/ToSC/article/view/8627)
    IACR Transactions on Symmetric Cryptology, 2020(S1), 208--261, 2020.

<!--- -------------------------------------------------------------------- --->
   
