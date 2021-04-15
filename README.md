# A "zoo" of Alzette implementations (development repository)

<!--- -------------------------------------------------------------------- --->
 
- This is the private, development repository associated with the main 
  repository
  [`scarv/alzette`](https://github.com/scarv/alzette).
  The reason *everything* isn't in the main repository is because there
  is a student project using it, and we didn't want to "give away" some 
  of the implementations we were working on.  Ideally we'll merge them
  once the project concludes.

- As such, using the development repository needs specific care:

  - Follow the instructions in the main repository, which will produce

    - the
      environment variable
      `REPO_HOME`
      which points at the main        repository
    - the
      environment variables
      `RISC`
      and
      `RISC_ALZETTE`
      which points at the 2-part tool-chain.

  - Export
      the
      environment variable
      `REPO_DEV`
      to    point  at the development repository.

  -  Now, whereas you'd use `ARCH` to select some architecture-specific 
     implementation in
     `${REPO_HOME}/src/alzette`,
     we can instead select one in
     `${REPO_DEV}/src/alzette`.
     For example:

     - using

       ```sh
       make --directory="${REPO_HOME}/src/alzette" ARCH="rv32"                         CONF="-DDRIVER_TRIALS='10' -DDRIVER_MEASURE -DRV32_TYPE1 -DCRAXS10_ENC_EXTERN -DCRAXS10_DEC_EXTERN" clean all run
       ```

       selects the `rv32` implementation in 
       `${REPO_HOME}/src/alzette/rv32`,

     - using

       ```sh
       make --directory="${REPO_HOME}/src/alzette" ARCH="${REPO_DEV}/src/alzette/rv32" CONF="-DDRIVER_TRIALS='10' -DDRIVER_MEASURE -DRV32_TYPE1 -DCRAXS10_ENC_EXTERN -DCRAXS10_DEC_EXTERN" clean all run
       ```

       selects the `rv32` implementation in 
       `${REPO_DEV}/src/alzette/rv32`.

  - Or, there's a test script in 
    `${REPO_DEV}/bin/test.py`
    which automates an evaluation scan through various configurations, 
    e.g., various ISEs, unrolling strategies, etc.

<!--- -------------------------------------------------------------------- --->
