/* Valid physical memory regions which can be used by the linker */

SECTIONS
{
    ROM_BASE = 0x10000; /* ... but actually position independent */

    . = ROM_BASE;
    .text.start : { *(.text.hang) }
    . = ROM_BASE + 0x40;
    .text.hang : { *(.text.start) }
    . = ROM_BASE + 0x600;
    .rodata.dtb : { *(.rodata.dtb) }
}
