MEMORY
{
/*        code (rx)               : ORIGIN = 0x20031700, LENGTH = 4K*/
        code (rx)               : ORIGIN = 0x10000000, LENGTH = 8K
        bss (rw)                : ORIGIN = 0x20031700, LENGTH = 4K
        stack (rw)              : ORIGIN = 0x20032700, LENGTH = 4K
        vidram (w)              : ORIGIN = 0x20035000, LENGTH = 307200
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

        .bss    : {
                *(.bss*)
        } > bss

        __stack_start__                 = ORIGIN(stack);
        __stack_end__                   = ORIGIN(stack) + LENGTH(stack);

        __data_start__                  = ORIGIN(data);
        __data_end__                    = ORIGIN(data) + LENGTH(data);

        __vidram_start__                = ORIGIN(vidram);
        __vidram_length__               = LENGTH(vidram);
}
