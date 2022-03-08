# Notes on GIFT-COFB rv32 implementations

### Comparison between `bitslicing` and `fixslicing` for pure-sw GIFT-COFB (TYPE1)

| `imp`        | `cycles`   | `notes` |
| :--------:   | :---------:|:--------|
| `bitslicing` |   5980     | <ul><li>pros: easy to implement; needs only one or two custom instructions for ISE-supported imp </li><li>cons: needs `unzip` and `rev8` from `ZBKB`; `unzip` is only available on `rv32`</li></ul>    |
| `fixslicing` |   6154     | <ul><li>pros: still efficient without `ZBKB` </li><li>cons: large code size; needs many custom instructions for ISE-supported imp</li></ul>        |

### Comparison between `bitslicing` and `fixslicing` for ISE-supported GIFT-COFB (TYPE2)

| `imp`        | `cycles`   | `notes` |
| :--------:   | :---------:|:--------|
| `bitslicing` |  3820      |  only two custom instructions `gift.key.reorg (imm = 3)` and `gift.key.updstd` were used |
| `fixslicing` |            |         | 
