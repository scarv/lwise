# Notes on GIFT-COFB rv32 pure-sw ASM implementations

### Comparison between bitslicing and fixslicing for GIFT-COFB

| `imp`        | `cycles`   | `notes` |
| :--------:   | :---------:|:--------|
| `bitslicing` |   5980     | <ul><li>pros: easy to implement; needs only one custom instruction for ISE-supported imp </li><li>cons: needs `unzip` and `rev8` from `ZBKB`; `unzip` is only available on `rv32`</li></ul>    |
| `fixslicing` |   6154     | <ul><li>pros: still efficient without `ZBKB` </li><li>cons: large code size; needs many custom instructions for ISE-supported imp</li></ul>        |