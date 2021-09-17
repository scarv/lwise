bootrom_img = bootrom.img
bootrom_dum = bootrom.dum

GCC=$(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY=$(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP=$(RISCV)/bin/riscv64-unknown-elf-objdump

all: $(bootrom_img) $(bootrom_dum) 

%.dum: %.elf
	$(OBJDUMP) -Dt $< > $@
%.img: %.bin
	dd if=$< of=$@ bs=2048 count=1

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf : %.S bootloader.c linker.ld
	$(GCC) -march=rv64imc -mabi=lp64 -Tlinker.ld $< bootloader.c -nostdlib -static -Wl,--no-gc-sections -o $@
