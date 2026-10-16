MEMORY
{
        code (rx)               : ORIGIN = 0x20031700, LENGTH = 4K
        stack (rw)              : ORIGIN = 0x20032700, LENGTH = 4K
}

SECTIONS
{
        .text : {
                __text_start__ = .;
                *(.reset*)
                *(.text*)
                *(.data*)
                *(.bss*)
                *(.rodata*)
                __text_end__ = .;
        } > code

        .vectors : {
                . = ALIGN(256);
                __vectors_start = .;
                *(.vectors*)
        } > code

        __stack_start__                 = ORIGIN(stack);
        __stack_end__                   = ORIGIN(stack) + LENGTH(stack);
}
