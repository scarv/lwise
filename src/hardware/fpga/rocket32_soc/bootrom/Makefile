bootrom_img = bootrom.img
bootrom_hex = bootrom.hex
bootrom_dum = bootrom.dum

GCC=$(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY=$(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP=$(RISCV)/bin/riscv64-unknown-elf-objdump

all: $(bootrom_img) $(bootrom_hex) $(bootrom_dum) 

%.hex: %.bin
	od -t x4 -An -w4 -v $< > $@	
%.dum: %.elf
	$(OBJDUMP) -Dt $< > $@
%.img: %.bin
	dd if=$< of=$@ bs=128 count=1

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf: %.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -Wl,--no-gc-sections -o $@
