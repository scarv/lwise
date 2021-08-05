
/*!
@file boot.S
@brief The basic boot script used to initialise the RISC-V core post reset.
*/

#.section .text
#.section .text.riscv_reset
#riscv_reset_vector_landing:
#    j riscv_reset_handler

#.section .text.riscv_irq_handler
#riscv_irq_vector_landing:
#    j riscv_irq_handler

/* ------------------------------------------------------------*/

.section .text

#
# Whenever the core is reset, we end up here from riscy_reset_vector_landing
#
.section .text.riscv_reset
riscv_reset_handler:
    addi  sp,sp,-16
    sd    ra,8(sp)                      # Push current return address

    # Jump to main.
    call   main

    ld    ra,8(sp)                      # get back return address
    addi  sp,sp,16
    ret

#
# We land here after any environment call
#
#.global riscv_irq_handler
#riscv_irq_handler:
#    sw    ra,4(sp)                      # Push current return address
#    addi  sp, sp, 0x4                   # to the stack before call.

#    call  riscv_irq_delegated_handler   # Jump to the delegated handler.

#    mret

