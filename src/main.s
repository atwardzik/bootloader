.cpu cortex-m33
.thumb
.syntax unified

.equ BIT_DMA, 2
.equ BIT_IO_BANK0, 6
.equ BIT_PADS_BANK0, 9
.equ BIT_PIO0, 11
.equ BIT_PIO1, 12
.equ BIT_PIO2, 13
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

        .Lclocks_setup:
                movs    r0, BIT_PLL_SYS
                bl      hw_reset
                bl      setup_internal_clk


        .Lsubsystem_reset:
                movs    r0, BIT_DMA
                bl      hw_reset

                movs    r0, BIT_PIO0
                bl      hw_reset

                movs    r0, BIT_PIO1
                bl      hw_reset

                movs    r0, BIT_IO_UART0
                bl      hw_reset

                movs    r0, BIT_SPI0
                bl      hw_reset

                movs    r0, BIT_SPI1
                bl      hw_reset

                // 1) Reset GPIO
                movs    r0, BIT_IO_BANK0
                bl      hw_reset

                // 2) Reset PADS
                movs    r0, BIT_PADS_BANK0
                bl      hw_reset

        // Set up LED pad
        mov     r0, #11                 // GPIO11 for LED
        mov     r1, #5                  // 5 - SIO
        bl      GPIO_function_select
        mov     r0, #11
        bl      output_enable_pin

        mov     r0, #28                 // GPIO28 for LED
        mov     r1, #5                  // 5 - SIO
        bl      GPIO_function_select
        mov     r0, #28
        bl      output_enable_pin

        ////////////////////////////
sd_card_boot:
        bl      init_sd_card
        cmn     r0, #1
        ble     .Lcard_init_failure

        /// Read MBR
        sub     sp, sp, #512

        mov     r0, #0                  // block number
        mov     r1, sp                  // buffer
        bl      sd_card_read512_block
        cmn     r0, #1
        ble     .Lno_bootable_partition_found


        /// Find BOOT partition
        mov     r4, sp
        ldr     r5, =0x1be              // first partition entry offset
        add     r5, r5, 0x08            // absolute sector address offset
        adr     r6, bootstr
        sub     sp, sp, #512
        1:
                mov     r0, #1
                lsls    r0, r0, #9                              // 512
                cmp     r5, r0
                bge     .Lno_bootable_partition_found           // out of bounds

                ldr     r0, [r4, r5]                            // first partition entry block number
                cbz     r0, .Lno_bootable_partition_found
                mov     r1, sp
                bl      sd_card_read512_block

                add     r0, sp, #0x2b                           // VOLUME LABEL
                mov     r1, #0                                  // counter
                2:
                        ldrb    r2, [r0, r1]
                        ldrb    r3, [r6, r1]
                        cmp     r2, r3
                        itt     eq
                        addeq   r1, r1, #1
                        beq     2b

        add     r1, r1, #1
        cmp     r1, bootstr_len
        itt     ne
        addne   r5, r5, #16
        bne     1b

        mov     r0, #11
        bl      set_pin

        mov     r0, sp                  // MBR
        ldr     r1, [r4, r5]            // first partition entry block number
        bl      load_img
        b       .Lrun

        .Lcard_init_failure:
                // 00-11 blinking
                mov     r0, #11
                bl      xor_pin
                mov     r0, #28
                bl      xor_pin

                mov     r0, #1
                lsls    r0, r0, #10
                bl      delay_ms

                b       sd_card_boot


        .Lno_bootable_partition_found:
                // 11
                mov     r0, #11
                bl      set_pin
                mov     r0, #28
                bl      set_pin

                b       sd_card_boot


        .Lno_kernel_image_found:
                // 01
                mov     r0, #11
                bl      clr_pin
                mov     r0, #28
                bl      set_pin

                b       sd_card_boot

        ///////////////////////////
        .Lrun:
                mov     r4, r0
                add     r4, r4, #1      // thumb jump
                mov     r0, #11
                bl      clr_pin

                blx     r4


        pop     {pc}
.size main, .-main

.align 4
bootstr:        .ascii "BOOT"
                .word 0x20202020
                .word 0x20202020
.equ bootstr_len, .-bootstr


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
