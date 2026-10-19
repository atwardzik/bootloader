.cpu cortex-m33
.thumb
.syntax unified


.extern __stack_end__


////////////////////////////////
//
// Vector table
//
////////////////////////////////
.section .vectors, "ax"

.align 2
.global vector_table
.thumb_func
vector_table:
.word __stack_end__
.word reset
.Lirq_invalid:
        .rept 14
        .word isr_invalid
        .endr
.Lirq_0_51:
        .rept 52
        .word isr_invalid
        .endr


////////////////////////////////
//
// Reset
//
////////////////////////////////
.section .reset, "ax"

.thumb_func
.global reset
.align 4
reset:
        ldr     r0, RESETS_BASE
        ldr     r1, =0x2000             // atomic bitmask set
        ldr     r2, =0xc3a44            // reset peripherals: SPI, PIO, PADS_BANK0, IO_BANK0
        str     r2, [r0, r1]

        1:
                ldr     r3, [r0]
                tst     r3, r2
                beq     1b

clear_bss:
        ldr     r0, =0x20031700
        mov     r1, #1
        lsls    r1, r1, #7
        mov     r2, #0
        1:
                str     r2, [r0, r1]
                subs    r1, r1, #4
                bge     1b

vector_setup:
        ldr     r2, PPB_BASE
        ldr     r1, VTOR_OFFSET
        ldr     r0, =vector_table
        str     r0, [r1, r2]

        ldr     r1, =__stack_end__
        mov     sp, r1

.Lplatform_entry:
        ldr     r1, =main
        blx     r1
        mov     r0, r0
        bkpt    #0                     // should not return
.size reset, .-reset


.type isr_invalid, %function
.thumb_func
isr_invalid:
        bkpt #0


.align 4
PPB_BASE:               .word 0xe0000000
VTOR_OFFSET:            .word 0xed08

RESETS_BASE:            .word 0x40020000
