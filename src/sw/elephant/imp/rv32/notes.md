# Notes on Spongent-160 rv32 implementations

### Comparison between `4x40b` and `5x32b` for pure-sw Elephant (TYPE1 only)

| `state`    | `imp`                               | `cycles`   | `notes` |
| :--------: |  :---------------------------------:|  ---------:|:--------|
| `4x40b`    | pLayer(swapmove) + SBox(bitsliced)  |  146877    |         |
| `4x40b`    | pLayer(unzip+rev8) + SBox(bitsliced)|  113677    | <ul><li>pros: also possible for other MCUs e.g. Cortex-M; more friendly for rv64; straightforward extension to Spongent-176; possible without `ZBKB` </li><li>cons: needs more custom instructions for ISE-supported imp </li></ul>     |
| `5x32b`    | SBox(LUT) + pLayer(swapmove)        |   89082    |         |
| `5x32b`    | SBox(LUT) + pLayer(unzip+rev8)      |   47082    | <ul><li>pros: much faster; needs only one or two custom instructions for ISE-supported imp </li><li>cons: needs `xperm4` from `ZBKB` for SBox </li></ul>     |

### Comparison between 4x40b and 5x32b for ISE-supported Elephant 

| `state`   | `imp`                         |   `type` | `cycles`   |
| :--------:| :----------------------------:|  :------:|  ---------:|
| `4x40b`   | pLayer(ISE) + SBox(bitsliced) |  `TYPE2` |  71677     | 
| `4x40b`   | pLayer(ISE) + SBox(bitsliced) |  `TYPE3` |  51677     | 
| `5x32b`   | SBox(LUT) + pLayer(ISE)       |  `TYPE2` |  27082     |         
| `5x32b`   | SBox(LUT) + pLayer(ISE)       |  `TYPE3` |  21082     | 