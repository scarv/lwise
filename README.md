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
   - ARM+NEON/SVE
4. x86
   - x86
   - x86+SSE/AVX
5. RISC-V
   - RV32I
   - RV32IB, i.e., with [BitManip](https://github.com/riscv/riscv-bitmanip) ISE
   - RV32IV, i.e., with [vector](https://github.com/riscv/riscv-v-spec)     ISE
   - RV32I         with  custom                                             ISE (see below)
   - RV64I
   - RV64IB, i.e., with [BitManip](https://github.com/riscv/riscv-bitmanip) ISE
   - RV64IV, i.e., with [vector](https://github.com/riscv/riscv-v-spec)     ISE
   - RV64I         with  custom                                             ISE (see below)
6. ...

<!--- -------------------------------------------------------------------- --->

## Organisation

```
├── bin                     - scripts (e.g., environment configuration)
├── build                   - working directory for build
└── src                     - source code
    ├── hardware              - source code for hardware
    ├── software              - source code for software
    │   ├── arch                - architecture-specific support
    │   │   ├── generic           - generic, i.e., vanilla C
    │   │   ├── rv32              - 32-bit RISC-V
    │   │   └── rv64              - 64-bit RISC-V
    │   └── imp                 - implementation
    │       ├── generic           - generic, i.e., vanilla C
    │       ├── rv32              - 32-bit RISC-V
    │       └── rv64              - 64-bit RISC-V
    └── toolchain             - source code for tool-chain
```

<!--- -------------------------------------------------------------------- --->

## Quickstart

- For RISC-V implementations:

  - Fix paths, e.g., 
  
    ```sh
    export RISCV="/opt/riscv"
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
  
- Build and execute implementation, e.g.,

  ```sh
  make --directory="${REPO_HOME}/src/software" ARCH="generic" IMP="generic" CONF="-DDRIVER_TRIALS='10'" clean all run
  ```

  or use the test script provided

  ```sh
  python3 ${REPO_HOME}/bin/test.py
  ```

  to automatically scan through various different configurations, e.g., 
  ISEs, unrolling strategies, etc.

<!--- -------------------------------------------------------------------- --->

## Notes

### Hardware

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
  |           | `CRAXS10_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of CRAX encryption                       |
  |           | `TRAXL17_ENC_EXTERN` | don't include implementation of TRAX encryption in driver, i.e., allow an architecture-specific implementation |
  |           | `TRAXL17_DEC_EXTERN` | don't include implementation of TRAX decryption in driver, i.e., allow an architecture-specific implementation |
  |           | `TRAXS10_ENC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX encryption                       |
  |           | `TRAXS10_DEC_UNROLL` | use fully (vs. partially, by a factor of two) unrolled implementation of TRAX encryption                       |
  | `rv32`    | `RV32B`              | enable BitManip-like ISE for 32-bit RISC-V                                                                     |
  | `rv32`    | `RV32_TYPE1`         | select 32-bit RISC-V base ISA:                 option 1, per description below                                 |
  | `rv32`    | `RV32_TYPE2`         | select 32-bit RISC-V base ISA plus custom ISE: option 2, per description below                                 |
  | `rv32`    | `RV32_TYPE3`         | select 32-bit RISC-V base ISA plus custom ISE: option 3, per description below                                 |
  | `rv32`    | `RV32_TYPE4`         | select 32-bit RISC-V base ISA plus custom ISE: option 4, per description below                                 |
  | `rv64`    | `RV64B`              | enable BitManip-like ISE for 64-bit RISC-V                                                                     |
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
  - stage the change via git add, but do *not* commit it, in the cloned component repository,
  - execute `${REPO_HOME}/src/toolchain/${COMPONENT}-update.sh` to produce an updated patch,
  - optionally commit and push the updated patch.
  
<!--- -------------------------------------------------------------------- --->

## RISC-V related implementation options

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
ALZETTE(xi,yi,ci) {
  xi = xi + ( yi >>> 31 )
  yi = yi ^ ( xi >>> 24 )
  xi = xi ^   ci

  xi = xi + ( yi >>> 17 )
  yi = yi ^ ( xi >>> 17 )
  xi = xi ^   ci

  xi = xi + ( yi >>>  0 )
  yi = yi ^ ( xi >>> 31 )
  xi = xi ^   ci

  xi = xi + ( yi >>> 24 )
  yi = yi ^ ( xi >>> 16 )
  xi = xi ^   ci
}
```

intentionally typeset to stress repeat use of a `add-xor-xor` block.

### RV32I(B): 32-bit

#### Instructions

- The (optional) BitManip-like ISE:

  ```
  alz.rori          rd, rs1,      imm => GPR[rd] <-              GPR[rs1] >>> imm
  ```

- `RV32_TYPE1`: base ISA.

- `RV32_TYPE2`: base ISA plus custom   ISE.

  ```
  alz.addrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] + ( GPR[rs2] >>> imm )
  alz.subrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] - ( GPR[rs2] >>> imm )
  alz.xorrori       rd, rs1, rs2, imm => GPR[rd] <- GPR[rs1] ^ ( GPR[rs2] >>> imm )
  ```

- `RV32_TYPE3`: base ISA plus custom   ISE.

  ```
  alz.addror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ( GPR[rs2] >>> 31 )
  alz.addror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ( GPR[rs2] >>> 17 )
  alz.addror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] + ( GPR[rs2] >>> 24 )
  alz.subror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ( GPR[rs2] >>> 31 )
  alz.subror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ( GPR[rs2] >>> 17 )
  alz.subror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] - ( GPR[rs2] >>> 24 )
  alz.xorror.24     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ( GPR[rs2] >>> 24 )
  alz.xorror.17     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ( GPR[rs2] >>> 17 )
  alz.xorror.31     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ( GPR[rs2] >>> 31 )
  alz.xorror.16     rd, rs1, rs2      => GPR[rd] <- GPR[rs1] ^ ( GPR[rs2] >>> 16 )
  ```
     
- `RV32_TYPE4`: base ISA plus custom   ISE.
   
  ```
  alz.whole.enci.x  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- DEC[imm]
                                         xi <- xi + ( yi >>> 31 )
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 17 )
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>>  0 )
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 24 )
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- xi

  alz.whole.enci.y  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- DEC[imm]
                                         xi <- xi + ( yi >>> 31 )
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 17 )
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>>  0 )
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 24 )
                                         yi <- yi ^ ( xi >>> 16 )
                                         GPR[rd] <- yi

  alz.whole.deci.x  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- DEC[imm]
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi - ( yi >>> 24 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi - ( yi >>>  0 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi - ( yi >>> 17 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi - ( yi >>> 31 )
                                         GPR[rd] <- xi

  alz.whole.deci.y  rd, rs1, rs2, imm => xi <- GPR[rs1]
                                         yi <- GPR[rs2]
                                         ci <- DEC[imm]
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi - ( yi >>> 24 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi - ( yi >>>  0 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi - ( yi >>> 17 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi - ( yi >>> 31 )
                                         GPR[rd] <- yi
    ```

    such that

    ```
    DEC = { 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, 0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D }
    ```

#### Encodings

- The (optional) BitManip-like ISE:

  ```
  .macro alz.rori         rd, rs1,      imm     // alz.rori         => iiii iii0 0000 rrrr r000 rrrr r000 1011
  .insn r CUSTOM_0,    0, \imm, \rd, \rs1,   x0 //                  => #define MATCH_ALZ_RORI         0x0000000B
  .endm                                         //                  => #define  MASK_ALZ_RORI         0x0000707F
  ```

- `RV32_TYPE1`: base ISA.

- `RV32_TYPE2`: base ISA plus custom   ISE.

  ```
  .macro alz.addrori      rd, rs1, rs2, imm     // alz.addrori      => iiii iiir rrrr rrrr r001 rrrr r000 1011
  .insn r CUSTOM_0,    1, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_ADDRORI      0x0000100B
  .endm                                         //                  => #define  MASK_ALZ_ADDRORI      0x0000707F
  .macro alz.subrori      rd, rs1, rs2, imm     // alz.subrori      => iiii iiir rrrr rrrr r010 rrrr r000 1011
  .insn r CUSTOM_0,    2, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_SUBRORI      0x0000200B
  .endm                                         //                  => #define  MASK_ALZ_SUBRORI      0x0000707F
  .macro alz.xorrori      rd, rs1, rs2, imm     // alz.xorrori      => iiii iiir rrrr rrrr r011 rrrr r000 1011 
  .insn r CUSTOM_0,    3, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_XORRORI      0x0000300B
  .endm                                         //                  => #define  MASK_ALZ_XORRORI      0x0000707F
  ```

- `RV32_TYPE3`: base ISA plus custom   ISE.

  ```
  .macro alz.addror.31    rd, rs1, rs2          // alz.addror.31    => 0000 000r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    0, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_ADDROR_31    0x0000002B
  .endm                                         //                  => #define  MASK_ALZ_ADDROR_31    0xFE00007F
  .macro alz.addror.17    rd, rs1, rs2          // alz.addror.17    => 0000 001r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    1, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_ADDROR_17    0x0200002B
  .endm                                         //                  => #define  MASK_ALZ_ADDROR_17    0xFE00007F
  .macro alz.addror.24    rd, rs1, rs2          // alz.addror.24    => 0000 010r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    2, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_ADDROR_24    0x0400002B
  .endm                                         //                  => #define  MASK_ALZ_ADDROR_24    0xFE00007F
  .macro alz.subror.31    rd, rs1, rs2          // alz.subror.31    => 0000 011r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    3, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_SUBROR_31    0x0600002B
  .endm                                         //                  => #define  MASK_ALZ_SUBROR_31    0xFE00007F
  .macro alz.subror.17    rd, rs1, rs2          // alz.subror.17    => 0000 100r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    4, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_SUBROR_17    0x0800002B
  .endm                                         //                  => #define  MASK_ALZ_SUBROR_17    0xFE00007F
  .macro alz.subror.24    rd, rs1, rs2          // alz.subror.24    => 0000 101r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    5, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_SUBROR_24    0x0A00002B
  .endm                                         //                  => #define  MASK_ALZ_SUBROR_24    0xFE00007F
  .macro alz.xorror.31    rd, rs1, rs2          // alz.xorror.31    => 0000 110r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    6, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_XORROR_31    0x0C00002B
  .endm                                         //                  => #define  MASK_ALZ_XORROR_31    0xFE00007F
  .macro alz.xorror.17    rd, rs1, rs2          // alz.xorror.17    => 0000 111r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,     7,\rd, \rs1, \rs2 //                  => #define MATCH_ALZ_XORROR_17    0x0E00002B
  .endm                                         //                  => #define  MASK_ALZ_XORROR_17    0xFE00007F
  .macro alz.xorror.24    rd, rs1, rs2          // alz.xorror.24    => 0001 000r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    8, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_XORROR_24    0x1000002B
  .endm                                         //                  => #define  MASK_ALZ_XORROR_24    0xFE00007F
  .macro alz.xorror.16    rd, rs1, rs2          // alz.xorror.16    => 0001 001r rrrr rrrr r000 rrrr r010 1011 
  .insn r CUSTOM_1,    0,    9, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_XORROR_16    0x1200002B
  .endm                                         //                  => #define  MASK_ALZ_XORROR_16    0xFE00007F
  ```
     
- `RV32_TYPE4`: base ISA plus custom   ISE.
   
  ```
  .macro alz.whole.enci.x rd, rs1, rs2, imm     // alz.whole.enci.x => iiii iiir rrrr rrrr r100 rrrr r000 1011 
  .insn r CUSTOM_0,    4, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_WHOLE_ENCI_X 0x0000400B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_ENCI_X 0x0000707F
  .macro alz.whole.enci.y rd, rs1, rs2, imm     // alz.whole.enci.y => iiii iiir rrrr rrrr r101 rrrr r000 1011 
  .insn r CUSTOM_0,    5, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_WHOLE_ENCI_Y 0x0000500B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_ENCI_Y 0x0000707F
  .macro alz.whole.deci.x rd, rs1, rs2, imm     // alz.whole.deci.x => iiii iiir rrrr rrrr r110 rrrr r000 1011 
  .insn r CUSTOM_0,    6, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_WHOLE_DECI_X 0x0000600B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_DECI_X 0x0000707F
  .macro alz.whole.deci.y rd, rs1, rs2, imm     // alz.whole.deci.y => iiii iiir rrrr rrrr r111 rrrr r000 1011 
  .insn r CUSTOM_0,    7, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_WHOLE_DECI_Y 0x0000700B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_DECI_Y 0x0000707F
  ```

### RV64I(B): 64-bit

#### Instructions

- The (optional) BitManip-like ISE:

  ```
  alz.roriw         rd, rs1,      imm => GPR[rd] <- ( ( GPR[rs1] >> imm ) | ( GPR[rs1] << ( 32 - imm ) )

  alz.pack          rd, rs1, rs2      => lo <- ( GPR[rs1] << 32 ) >> 32
                                         hi <-   GPR[rs2] << 32
                                         GPR[rd] <- lo | hi

  alz.packu         rd, rs1, rs2      => lo <-   GPR[rs1] >> 32
                                         hi <- ( GPR[rs2] >> 32 ) << 32
                                         GPR[rd] <- lo | hi
  ```

- `RV64_TYPE1`: base ISA.

- `RV64_TYPE2`: base ISA plus custom   ISE.

  ```
  alz.block.enci    rd, rs1, rs2, imm => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ( yi >>> DEC0[imm] )
                                         yi <- yi ^ ( xi >>> DEC1[imm] )
                                         xi <- xi ^   ci
                                         GPR[rd] <- xi || yi

  alz.block.deci    rd, rs1, rs2, imm => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> DEC1[imm] )
                                         xi <- xi - ( yi >>> DEC0[imm] )
                                         GPR[rd] <- xi || yi
  ```

  such that

  ```
  DEC0 = { 31, 17,  0, 24 }
  DEC1 = { 24, 17, 31, 16 }
  ```

- `RV64_TYPE3`: base ISA plus custom   ISE.

  ```
  alz.block.enc.0   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ( yi >>> 31 )
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.1   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ( yi >>> 17 )
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.2   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ( yi >>>  0 )
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- yi || xi

  alz.block.enc.3   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ( yi >>> 24 )
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- yi || xi

  alz.block.dec.0   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi - ( yi >>> 31 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.1   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi - ( yi >>> 17 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.2   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi - ( yi >>>  0 )
                                         GPR[rd] <- yi || xi

  alz.block.dec.3   rd, rs1, rs2      => yi <- GPR[rs1]_{63..32}
                                         xi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi - ( yi >>> 24 )
                                         GPR[rd] <- yi || xi
    ```

- `RV64_TYPE4`: base ISA plus custom   ISE.

  ```
  alz.whole.enci    rd, rs1,      imm => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- DEC[imm]
                                         xi <- xi + ( yi >>> 31 )
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 17 )
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>>  0 )
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 24 )
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- yi || xi

  alz.whole.deci    rd, rs1,      imm => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- DEC[imm]
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi - ( yi >>> 24 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi - ( yi >>>  0 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi - ( yi >>> 17 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi - ( yi >>> 31 )
                                         GPR[rd] <- yi || xi
  ```

- `RV64_TYPE5`: base ISA plus custom   ISE.

  ```
  alz.whole.enc     rd, rs1, rs2      => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi + ( yi >>> 31 )
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 17 )
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>>  0 )
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi ^   ci
                                         xi <- xi + ( yi >>> 24 )
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi ^   ci
                                         GPR[rd] <- yi || xi

  alz.whole.dec     rd, rs1, rs2      => xi <- GPR[rs1]_{63..32}
                                         yi <- GPR[rs1]_{31.. 0}
                                         ci <- GPR[rs2]_{31.. 0}
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 16 )
                                         xi <- xi - ( yi >>> 24 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 31 )
                                         xi <- xi - ( yi >>>  0 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 17 )
                                         xi <- xi - ( yi >>> 17 )
                                         xi <- xi ^   ci
                                         yi <- yi ^ ( xi >>> 24 )
                                         xi <- xi - ( yi >>> 31 )
                                         GPR[rd] <- yi || xi
  ```

#### Encodings

- The (optional) BitManip-like ISE:

  ```
  .macro alz.roriw        rd, rs1,      imm     // alz.roriw        => iiii iii0 0000 rrrr r000 rrrr r101 1011
  .insn r CUSTOM_2,    0, \imm, \rd, \rs1,   x0 //                  => #define MATCH_ALZ_RORIW        0x0000005B
  .endm                                         //                  => #define  MASK_ALZ_RORIW        0x0000707F
  .macro alz.pack         rd, rs1, rs2          // alz.pack         => 0000 000r rrrr rrrr r001 rrrr r101 1011
  .insn r CUSTOM_2,    1,    0, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_PACK         0x0000105B
  .endm                                         //                  => #define  MASK_ALZ_PACK         0x0000707F
  .macro alz.packu        rd, rs1, rs2          // alz.packu        => 0000 000r rrrr rrrr r010 rrrr r101 1011
  .insn r CUSTOM_2,    2,    0, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_PACKU        0x0000205B
  .endm                                         //                  => #define  MASK_ALZ_PACKU        0x0000707F
  ```

- `RV64_TYPE1`: base ISA.

- `RV64_TYPE2`: base ISA plus custom   ISE.

  ```
  .macro alz.block.enci   rd, rs1, rs2, imm     // alz.block.enci   => iiii iiir rrrr rrrr r011 rrrr r101 1011
  .insn r CUSTOM_2,    3, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_ENCI   0x0000305B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_ENCI   0x0000707F
  .macro alz.block.deci   rd, rs1, rs2, imm     // alz.block.deci   => iiii iiir rrrr rrrr r100 rrrr r101 1011
  .insn r CUSTOM_2,    4, \imm, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_DECI   0x0000405B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_DECI   0x0000707F
  ```

- `RV64_TYPE3`: base ISA plus custom   ISE.

  ```
  .macro alz.block.enc.0  rd, rs1, rs2          // alz.block.enc.0  => 0000 000r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    0, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_ENC_0  0x0000007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_ENC_0  0xFE00007F
  .macro alz.block.enc.1  rd, rs1, rs2          // alz.block.enc.1  => 0000 001r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    1, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_ENC_1  0x0200007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_ENC_1  0xFE00007F
  .macro alz.block.enc.2  rd, rs1, rs2          // alz.block.enc.2  => 0000 010r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    2, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_ENC_2  0x0400007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_ENC_2  0xFE00007F
  .macro alz.block.enc.3  rd, rs1, rs2          // alz.block.enc.3  => 0000 011r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    3, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_ENC_3  0x0600007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_ENC_3  0xFE00007F
  .macro alz.block.dec.0  rd, rs1, rs2          // alz.block.dec.0  => 0000 100r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    4, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_DEC_0  0x0800007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_DEC_0  0xFE00007F
  .macro alz.block.dec.1  rd, rs1, rs2          // alz.block.dec.1  => 0000 101r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    5, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_DEC_1  0x0A00007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_DEC_1  0xFE00007F
  .macro alz.block.dec.2  rd, rs1, rs2          // alz.block.dec.2  => 0000 110r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    6, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_DEC_2  0x0C00007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_DEC_2  0xFE00007F
  .macro alz.block.dec.3  rd, rs1, rs2          // alz.block.dec.3  => 0000 111r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    7, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_BLOCK_DEC_3  0x0E00007B
  .endm                                         //                  => #define  MASK_ALZ_BLOCK_DEC_3  0xFE00007F
  ```

- `RV64_TYPE4`: base ISA plus custom   ISE.

  ```
  .macro alz.whole.enci   rd, rs1,      imm     // alz.whole.enci   => iiii iii0 0000 rrrr r101 rrrr r101 1011
  .insn r CUSTOM_2,    5, \imm, \rd, \rs1,   x0 //                  => #define MATCH_ALZ_WHOLE_ENCI   0x0000505B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_ENCI   0x0000707F
  .macro alz.whole.deci   rd, rs1,      imm     // alz.whole.deci   => iiii iii0 0000 rrrr r110 rrrr r101 1011
  .insn r CUSTOM_2,    6, \imm, \rd, \rs1,   x0 //                  => #define MATCH_ALZ_WHOLE_DECI   0x0000605B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_DECI   0x0000707F
  ```

- `RV64_TYPE5`: base ISA plus custom   ISE.

  ```
  .macro alz.whole.enc    rd, rs1, rs2          // alz.whole.enc    => 0001 000r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    8, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_WHOLE_ENC    0x1000007B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_ENC    0xFE00007F
  .macro alz.whole.dec    rd, rs1, rs2          // alz.whole.dec    => 0001 001r rrrr rrrr r000 rrrr r111 1011 
  .insn r CUSTOM_3,    0,    9, \rd, \rs1, \rs2 //                  => #define MATCH_ALZ_WHOLE_DEC    0x1200007B
  .endm                                         //                  => #define  MASK_ALZ_WHOLE_DEC    0xFE00007F
  ```

<!--- -------------------------------------------------------------------- --->

## References

[1] C. Beierle, A. Biryukov, L. Cardoso dos Santos, J. Großschädl, L. Perrin, A. Udovenko, V. Velichkov, and Q. Wang.
    [Alzette: a 64-bit ARX-box (feat. CRAX and TRAX)](https://eprint.iacr.org/2019/1378).
    Cryptology ePrint Archive, Report 2019/1378, 2019.

[2] D. Dinu.
    [Efficient and Secure Implementations of Lightweight Symmetric Cryptographic Primitives](https://orbilu.uni.lu/handle/10993/33803).
    PhD, University of Luxembourg, 2017.

<!--- -------------------------------------------------------------------- --->
   
