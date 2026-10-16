.cpu cortex-m33
.thumb
.syntax unified

.equ GPIO_OE, 0x30
.equ GPIO_OE_SET, 0x38
.equ GPIO_OE_CLR, 0x40
.equ GPIO_IN, 0x04
.equ GPIO_OUT, 0x10
.equ GPIO_OUT_SET, 0x18
.equ GPIO_OUT_CLR, 0x20
.equ GPIO_OUT_XOR, 0x28

/**
 * Connects selected GPIO pin to selected peripherial by using GPIO CTRL register.
 * r0 - GPIO Pin
 * r1 - GPIO Function (cf. RP2040 Datasheet 1.4.3)
 * */
.thumb_func
.global GPIO_function_select
.align 4
GPIO_function_select:
        push    {r4, r5}
        // calculate offset for PADS_GPIO_n
        ldr     r4, PADS_BANK0_BASE
        lsls    r3, r0, #2
        adds    r3, #0x04
        add     r5, r3, r4              // store pads GPIO_n offset

        // setup pads
        ldr     r2, [r5]		// read current state of pad
        movs    r4, #0x40		// PADS_BANK0_GPIO0_IE_BITS
        eors    r2, r2, r4
        movs    r4, 0xc0		// IE_BITS, OD_BITS
        ands    r2, r2, r4
        str     r2, [r5]

        // function select
        ldr     r3, IO_BANK0_BASE
        lsls    r2, r0, #3              // calculate offset for GPIO_N_CTRL (minus 0x04)
        adds    r2, r2, #0x04           // GPIO0_CTRL offset
        str     r1, [r3, r2]            // write specfied function


        movs    r1, #1
        lsls    r1, r1, #8
        ldr     r3, =0x3000		// atomic register clear
        str     r1, [r5, r3]            // pads atomic

        pop     {r4, r5}
        bx      lr
.size GPIO_function_select, .-GPIO_function_select

/**
 * Enables output to the pin specified in r0.
 * */
.thumb_func
.global output_enable_pin
.align 4
output_enable_pin:
        ldr     r1, SIO_BASE
        movs    r2, #1
        lsls    r2, r2, r0              // set enable on n-th pin
        str     r2, [r1, GPIO_OE_SET]   // atomic operation GPIO_OE |= data

        bx      lr
.size output_enable_pin, .-output_enable_pin

/**
 * Sets boolean true to the pin specified in r0.
 * */
.thumb_func
.global set_pin
.align 4
set_pin:
        ldr     r2, SIO_BASE
        movs    r1, #1
        lsls    r1, r1, r0             // set on n-th pin
        str     r1, [r2, GPIO_OUT_SET]

        bx      lr
.size set_pin, .-set_pin


/**
 * Sets boolean false to the pin specified in r0.
 * */
.thumb_func
.global clr_pin
.align 4
clr_pin:
        ldr     r2, SIO_BASE
        movs    r1, #1
        lsls    r1, r1, r0             // reset on n-th pin
        str     r1, [r2, GPIO_OUT_CLR]

        bx      lr
.size clr_pin, .-clr_pin


.align 4
IO_BANK0_BASE:          .word 0x40028000
PADS_BANK0_BASE:        .word 0x40038000
SIO_BASE:               .word 0xd0000000
