<!--- -------------------------------------------------------------------- --->

## Notation

<!--- -------------------------------------------------------------------- --->

## Options

| `${ARCH}` | `${ALG}`   | `${IMP}`  | Symbol                 | Meaning                                                                 |
| :-------- | :--------- | :-------- | :--------------------- | :---------------------------------------------------------------------- |
|           | `xoodyak`  | `rv32`    | `XOODYAK_RV32_UNROLL`  | use fully (vs. partially, by a factor of two) unrolled implementation   |
|           | `xoodyak`  | `rv32`    | `XOODYAK_RV32_TYPE1`   | select 32-bit RISC-V base ISA:          option 1, per description below |
|           | `xoodyak`  | `rv32`    | `XOODYAK_RV32_TYPE2`   | select 32-bit RISC-V base ISA plus ISE: option 2, per description below |

<!--- -------------------------------------------------------------------- --->

## `${IMP} = "rv32"`

- `XOODYAK_RV32_TYPE1`: base ISA.

- `XOODYAK_RV32_TYPE2`: base ISA plus ISE.

  ```
  xoodyak.xorrol rd, rs1, rs2 {
    x       <- GPR[rs1]
    y       <- GPR[rs2]
    r       <- ( x <<< 5 ) ^ ( y <<< 14 )
    GPR[rd] <- r
  }
  ```
   
<!--- -------------------------------------------------------------------- --->
