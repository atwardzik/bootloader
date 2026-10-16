.cpu cortex-m33
.thumb
.syntax unified

.equ BIT_IO_BANK0, 6
.equ BIT_PADS_BANK0, 9
.equ BIT_PLL_SYS, 14
.equ BIT_SPI0, 18
.equ BIT_SPI1, 19
.equ BIT_IO_UART0, 26

.equ RESET_DONE_OFFSET, 0x08

.section .text
.global main
.align 4
.thumb_func
main:
        push    {lr}

        .Lsubsystem_reset:
                // Reset PLL
                movs    r0, BIT_PLL_SYS
                bl      hw_reset

                // Reset GPIO
                movs    r0, BIT_IO_BANK0
                bl      hw_reset

                // Reset PADS
                movs    r0, BIT_PADS_BANK0
                bl      hw_reset

                // Reset SPI1 for SD CARD
                movs    r0, BIT_SPI1
                bl      hw_reset

        bl      setup_internal_clk

        // Set up LED pad
        mov     r0, #11                 // GPIO11 for LED
        mov     r1, #5                  // 5 - SIO
        bl      GPIO_function_select

        mov     r0, #11
        bl      output_enable_pin

        bl      init_sd_card

        mov     r0, #0                  // block number
        ldr     r1, =0x20000000         // buffer
        bl      sd_card_read512_block

        1:
                mov     r0, #11
                bl      set_pin

                mov     r0, #1
                lsls    r0, r0, #10
                bl      delay_ms

                mov     r0, #11
                bl      clr_pin

                mov     r0, #1
                lsls    r0, r0, #10
                bl      delay_ms

                b       1b

        pop     {pc}
.size main, .-main


.thumb_func
.global hw_reset
.align 4
hw_reset:
        movs    r3, #1
        lsls    r3, r3, r0

        ldr     r1, RESETS_BASE
        ldr     r2, ATOMIC_BITMASK_CLR
        str     r3, [r1, r2]

        .Lreset:
                ldr     r2, [r1, RESET_DONE_OFFSET]
                tst     r2, r3
                beq     .Lreset

        bx      lr
.size hw_reset, .-hw_reset

.align 4
RESETS_BASE:            .word 0x40020000

ATOMIC_BITMASK_XOR:     .word 0x1000
ATOMIC_BITMASK_SET:     .word 0x2000
ATOMIC_BITMASK_CLR:     .word 0x3000
