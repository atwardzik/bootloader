.PHONY: all clean

CC := arm-none-eabi-gcc
AS := arm-none-eabi-as
LD := arm-none-eabi-ld

CC_ARGS = -Wall -Wextra -Wpedantic -Werror \
	  -Wno-unused-variable -Wno-unused-parameter \
	  -Wno-discarded-qualifiers -Wno-missing-field-initializers \
	  -std=c23 -mcpu=cortex-m33 -mfpu=fpv5-sp-d16 -ffreestanding -mthumb -fPIC -c -g -O0

AS_ARGS = --warn --fatal-warnings -mcpu=cortex-m33 -mthumb -g
LD_ARGS = -nostdlib

all: start.o gpio.o main.o bootloader

start.o: start.s
	$(AS) $(AS_ARGS) $< -o $@

gpio.o: gpio.s
	$(AS) $(AS_ARGS) $< -o $@

main.o: main.s
	$(AS) $(AS_ARGS) $< -o $@

bootloader: start.o gpio.o main.o
	$(LD) $(LD_ARGS) -T linker.ld $^ -o $@
