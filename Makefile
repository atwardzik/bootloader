.PHONY: all clean

CC := arm-none-eabi-gcc
AS := arm-none-eabi-as
LD := arm-none-eabi-ld

CC_ARGS = -Iinclude -Wall -Wextra -Wpedantic -Werror \
	  -Wno-unused-variable -Wno-unused-parameter \
	  -Wno-discarded-qualifiers -Wno-missing-field-initializers \
	  -Wno-unused-function \
	  -std=c23 -mcpu=cortex-m33 -mfpu=fpv5-sp-d16 -ffreestanding -mthumb -fPIC -c -g -Os

AS_ARGS = --warn --fatal-warnings -mcpu=cortex-m33 -mthumb -g
LD_ARGS = -nostdlib


SRCDIR = src
OBJDIR = obj

ASM_SOURCES = $(wildcard $(SRCDIR)/*.s)
C_SOURCES   = $(wildcard $(SRCDIR)/*.c)

ASM_OBJECTS = $(patsubst $(SRCDIR)/%.s,$(OBJDIR)/%.o,$(ASM_SOURCES))
C_OBJECTS   = $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.o,$(C_SOURCES))

OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)



all: bootloader.elf

$(OBJDIR):
	mkdir -p $@

$(OBJDIR)/%.o: $(SRCDIR)/%.s | $(OBJDIR)
	$(AS) $(AS_ARGS) $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CC_ARGS) $< -o $@

bootloader.elf: $(OBJECTS)
	$(LD) $(LD_ARGS) -T linker.ld $^ -o $@

clean:
	rm -rf $(OBJDIR) bootloader.*
