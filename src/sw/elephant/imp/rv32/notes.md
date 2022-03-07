# Notes on Spongent-160 rv32 pure-sw ASM implementations

### Comparison between 4x40b and 5x32b for Elephant

| `state`    | `imp`                               | `cycles`   | `notes` |
| :--------: |  :---------------------------------:|  ---------:|:--------|
| `4x40b`    | pLayer(swapmove) + SBox(bitsliced)  |  143257    |         |
| `4x40b`    | pLayer(unzip+rev8) + SBox(bitsliced)|  109657    | <ul><li>pros: also efficient for other MCUs e.g. Cortex-M; more friendly for rv64; straightforward extension to Spongent-176; possible without `ZBKB` </li><li>cons: needs more custom instructions for ISE-supported imp </li></ul>     |
| `5x32b`    | SBox(LUT) + pLayer(swapmove)        |   89082    |         |
| `5x32b`    | SBox(LUT) + pLayer(unzip+rev8)      |   47082    | <ul><li>pros: much faster; needs only one or two custom instructions for ISE-supported imp </li><li>cons: needs `xperm4` from `ZBKB` for SBox </li></ul>     |