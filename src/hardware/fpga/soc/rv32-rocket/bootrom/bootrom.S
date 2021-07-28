.section .text.start, "ax", @progbits
.globl _start
_start:
  # Zero all of the registers
  mv  x1 , x0
  mv  x2 , x0
  mv  x3 , x0
  mv  x4 , x0
  mv  x5 , x0
  mv  x6 , x0
  mv  x7 , x0
  mv  x8 , x0
  mv  x9 , x0
  mv  x10, x0
  mv  x11, x0
  mv  x12, x0
  mv  x13, x0
  mv  x14, x0
  mv  x15, x0
  mv  x16, x0
  mv  x17, x0
  mv  x18, x0
  mv  x19, x0
  mv  x20, x0
  mv  x21, x0
  mv  x22, x0
  mv  x23, x0
  mv  x24, x0
  mv  x25, x0
  mv  x26, x0
  mv  x27, x0
  mv  x28, x0
  mv  x29, x0
  mv  x30, x0
  mv  x31, x0

  #enable co-processor interface    
  #li t0, 0x0000C000;   
  li  t0, 0x00018000 
  csrs mstatus, t0

  // Setup the stack pointer to the top of the shared memory.
  li   sp, 0x80018000
  la   s0, bootloader
  csrr a0, mhartid
  la   a1, _dtb
  jr   s0

.section .text.hang, "ax", @progbits
.globl _hang
_hang:
  csrr a0, mhartid
  la a1, _dtb
1:
  wfi
  j 1b

.section .rodata.dtb, "a", @progbits
.globl _dtb
.align 5, 0
_dtb:
.ascii "DTB goes here" 
