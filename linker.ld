MEMORY
{
/*        code (rx)               : ORIGIN = 0x20031700, LENGTH = 4K*/
        code (rx)               : ORIGIN = 0x10000000, LENGTH = 4K
        stack (rw)              : ORIGIN = 0x20032700, LENGTH = 4K
}

SECTIONS
{
        .text : {
                . = ALIGN(4);
                KEEP(*(.vectors))
                KEEP(*(.magic_image_def))
                __text_start__ = .;
                *(.reset*)
                *(.text*)
                *(.rodata*)
                __text_end__ = .;
        } > code

        __stack_start__                 = ORIGIN(stack);
        __stack_end__                   = ORIGIN(stack) + LENGTH(stack);
}
