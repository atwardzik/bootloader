MEMORY
{
        code (rx)               : ORIGIN = 0x20080000, LENGTH = 4K
        stack (rw)              : ORIGIN = 0x20081000, LENGTH = 4K
}

SECTIONS
{
        .text : {
                __text_start__ = .;
                *(.reset*)
                *(.text*)
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
