.cpu cortex-m33
.thumb
.syntax unified

.section .magic_image_def, "a"
.align 2
IMAGE_DEF_BLOCK:        .word 0xffffded3
                        .word 0x10210142
                        .word 0x000001ff
                        .word 0x00000000
                        .word 0xab123579
