.cpu cortex-m33
.thumb
.syntax unified

.equ BIT_IO_BANK0, 6
.equ BIT_PADS_BANK0, 9
.equ BIT_SPI0, 18
.equ BIT_SPI1, 19
.equ BIT_IO_UART0, 26

.equ RESET_DONE_OFFSET, 0x08

.section .text
.global main
.align 4
.type main, %function
.thumb_func
main:
        push    {lr}

        @ Reset GPIO
        movs    r0, BIT_IO_BANK0
        bl      hw_reset

        @ Reset PADS
        movs    r0, BIT_PADS_BANK0
        bl      hw_reset

        @ Set up LED pad
        mov     r0, #11                 @ GPIO11 for LED
        mov     r1, #5                  @ 5 - SIO
        bl      GPIO_function_select

        mov     r0, #11
        bl      output_enable_pin

        mov     r0, #11
        bl      set_pin

        mov     r0, #11
        bl      clr_pin

        pop     {pc}
.size main, .-main


.thumb_func
.align 4
hw_reset:
        movs    r3, #1
        lsls    r3, r3, r0

        ldr     r1, RESETS_BASE
        ldr     r2, =0x3000             @ Atomic register access
        str     r3, [r1, r2]

        .reset:
                ldr     r2, [r1, RESET_DONE_OFFSET]
                tst     r2, r3
                beq     .reset

        bx      lr

.align 4
RESETS_BASE:            .word 0x40020000
