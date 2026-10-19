.cpu cortex-m33
.thumb
.syntax unified

.equ TIMER0_CTRL, 0x18
.equ TIMER0_CYCLES, 0x1c
.equ TIMER_TIMERAWL_OFFSET, 0x28

.equ XOSC_CTRL, 0x00
.equ XOSC_STATUS, 0x04
.equ XOSC_STARTUP, 0x0c
.equ STARTUP_DELAY, 47

.equ XOSC_CLKSRC, 0x02

.equ CLK_REF_CTRL, 0x30
.equ CLK_REF_DIV, 0x34
.equ CLK_REF_SELECTED, 0x38
.equ CLK_SYS_CTRL, 0x3c
.equ CLK_SYS_SELECTED, 0x44
.equ CLK_PERI_CTRL, 0x48

.equ PLL_FBDIV_INT, 0x08
.equ PLL_PRIM, 0x0c
.equ PLL_PWR, 0x04

.equ POWMAN_TIMER, 0x88
.equ POWMAN_SET_TIME_63TO48, 0x60
.equ POWMAN_SET_TIME_47TO32, 0x64
.equ POWMAN_SET_TIME_31TO16, 0x68
.equ POWMAN_SET_TIME_15TO0, 0x6c
.equ POWMAN_READ_TIME_UPPER, 0x70
.equ POWMAN_READ_TIME_LOWER, 0x74

.equ CLK_REF_DIV_INT, 16


.thumb_func
.global setup_internal_clk
.align 4
setup_internal_clk:
        push {lr}

        .enable_xosc:
                ldr     r0, XOSC_BASE

                // 1) Startup delay
                movs    r1, STARTUP_DELAY
                str     r1, [r0, XOSC_STARTUP]

                // 2) Set frequency range
                ldr     r1, FREQ_RANGE
                str     r1, [r0, XOSC_CTRL]

                // 3) Enable crystall oscillator
                ldr     r1, XOSC_ENABLE
                ldr     r2, ATOMIC_BITMASK_SET
                str     r1, [r0, r2]

                // 4) Wait for oscillating signal stabilization
                ldr     r1, XOSC_STABLE
                .wait_for_xosc:
                        ldr     r2, [r0, XOSC_STATUS]
                        tst     r2, r1
                        beq     .wait_for_xosc

        .switch_clocks_to_xosc:
                ldr     r0, CLOCKS_BASE

                // 1) CLK REF source = xosc_clksrc
                movs    r1, XOSC_CLKSRC
                str     r1, [r0, CLK_REF_CTRL]

                movs    r2, #4                                          // CLK_REF_SELECTED: XOSC
                .wait_for_clk_ref:
                        ldr     r3, [r0, CLK_REF_SELECTED]
                        tst     r3, r2
                        beq     .wait_for_clk_ref                       // reset state is 0x1

                 // 2) CLK REF Divisor = 1
                movs    r1, #1
                lsls    r1, r1, CLK_REF_DIV_INT
                str     r1, [r0, CLK_REF_DIV]

                // 3) setup PLL; in SDK rp2_common/hardware_pll/pll.c:42-69 also with check for disrupting already working PLL
                // FOUTPOSTDIV = 12[MHz] / refdiv * fbdiv/(postdiv1*postdiv2)
                // 150 = 12/1 * 125/10
                ldr     r0, PLL_SYS_BASE

                movs    r1, #1
                str     r1, [r0]                                        // set refdiv

                movs    r1, #125                                        // fbdiv=125
                str     r1, [r0, PLL_FBDIV_INT]

                movs    r1, #0x52                                       // POSTDIV1=5, POSTDIV2=2
                lsls    r1, #12
                str     r1, [r0, PLL_PRIM]

                // 4) power up PLL
                ldr     r2, ATOMIC_BITMASK_CLR
                adds    r2, r0, r2
                movs    r1, #0x21		                        // clear PD, VCOPD in PLL: PWR
                str     r1, [r2, PLL_PWR]

                // 5) wait for a stable state as in 8.6.5 PLL:CS
                movs    r1, #1
                lsls    r1, r1, #31                                     // bit 31 is LOCK bit, reset on 0x0
                .wait_for_refdiv_lock:
                        ldr     r2, [r0]
                        tst     r2, r1
                        beq     .wait_for_refdiv_lock


                // 5) setup pll divisor?

                // enable the pll_lock
                ldr     r1, ATOMIC_BITMASK_CLR
                adds    r1, r1, r0
                movs    r2, #0x08
                str     r2, [r1, PLL_PWR]

                // 6) switch sys clk to use the pll
                ldr     r0, CLOCKS_BASE
                movs    r1, #1                                          // CLKSRC_CLK_SYS_AUX
                str     r1, [r0, CLK_SYS_CTRL]

                movs    r2, #1
                .wait_for_clk_sys_change:
                        ldr     r1, [r0, CLK_SYS_SELECTED]
                        tst     r1, r2
                        bne     .wait_for_clk_sys_change                // reset on 0x1


                // 7) CLK PERI
                movs    r1, #1
                lsls    r1, r1, #11                                     // ENABLE - Starts and stops the clock generator cleanly

                ////// If clk_peri should run from xosc
                // movs    r2, #4
                // lsls    r2, r2, #5                                      // Bits 7:5 - 0x4 -> xosc_clksrc = 12[MHz]
                //////

                ////// If clk_peri should run from sys_clk
                movs    r2, #0                                          // Bits 7:5 - 0x0 -> clk_sys = 125[MHz]

                orrs    r1, r1, r2
                str     r1, [r0, CLK_PERI_CTRL]

        .init_ticks_timer0:
                ldr     r0, TICKS_BASE
                movs    r1, #0
                str     r1, [r0, TIMER0_CTRL]

                movs    r1, #12                                         // cycles = 12 [MHz]
                str     r1, [r0, TIMER0_CYCLES]

                movs    r1, #1                                          // enable bit
                str     r1, [r0, TIMER0_CTRL]

        .init_aot:
                ldr     r0, POWMAN_BASE
                ldr     r1, =0x5afe
                lsls    r1, r1, #16
                str     r1, [r0, POWMAN_SET_TIME_63TO48]
                str     r1, [r0, POWMAN_SET_TIME_47TO32]
                str     r1, [r0, POWMAN_SET_TIME_31TO16]
                str     r1, [r0, POWMAN_SET_TIME_15TO0]

                mov     r2, #1
                lsls    r2, r2, #9                                      // use_xosc
                orrs    r2, r2, #6                                      // timer run | clear
                orrs    r1, r1, r2                                      // add password
                str     r1, [r0, POWMAN_TIMER]


                pop     {pc}


.align 4
XOSC_BASE:              .word 0x40048000
CLOCKS_BASE:            .word 0x40010000
PLL_SYS_BASE:           .word 0x40050000
POWMAN_BASE:            .word 0x40100000

FREQ_RANGE:             .word 0xaa0
XOSC_STABLE:            .word 0x80000000
XOSC_ENABLE:            .word 0xfab000

/**
 * Delays by the amount of microseconds specified in r0.
 * */
.thumb_func
.global delay_ms
.align 4
delay_ms:
        push    {lr}

        ldr     r1, =1000
        muls    r0, r0, r1
        bl      delay_us

        pop     {pc}


/**
 * Delays by the amount of microseconds specified in r0.
 * */
.thumb_func
.global delay_us
.align 4
delay_us:
        ldr     r3, TIMER_BASE
        ldr     r1, [r3, TIMER_TIMERAWL_OFFSET]        // get TIMERAWL
        add     r1, r1, r0                             // TIMERAWL + desired alarm

        .delay_loop:
                ldr     r2, [r3, TIMER_TIMERAWL_OFFSET]
                cmp     r2, r1
                blt     .delay_loop

        bx      lr

.align 4
TIMER_BASE:             .word 0x400b0000
TICKS_BASE:             .word 0x40108000


ATOMIC_BITMASK_XOR:     .word 0x1000
ATOMIC_BITMASK_SET:     .word 0x2000
ATOMIC_BITMASK_CLR:     .word 0x3000
