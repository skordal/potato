# The Potato Processor - Applications
# (c) Kristian Klomsten Skordal 2018-2023 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

# Tools used to build applications:
TARGET_PREFIX ?= riscv32-unknown-elf
TARGET_CC := $(TARGET_PREFIX)-gcc
TARGET_LD := $(TARGET_PREFIX)-gcc
TARGET_SIZE := $(TARGET_PREFIX)-size
TARGET_OBJCOPY := $(TARGET_PREFIX)-objcopy
HEXDUMP ?= hexdump

TARGET_CFLAGS +=  -march=rv32i_zicsr -Wall -Wextra -Os -fomit-frame-pointer \
	-ffreestanding -fno-builtin -fanalyzer -I../.. -I../../libsoc -std=gnu99 \
	-Wall -Werror=implicit-function-declaration -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -march=rv32i_zicsr -nostartfiles -L../libsoc \
	-Wl,-m,elf32lriscv --specs=nosys.specs -Wl,--no-relax -Wl,--gc-sections

# Rule for converting an ELF file to a binary file:
%.bin: %.elf
	$(TARGET_OBJCOPY) -j .text -j .data -j .rodata -O binary $< $@

# Rule for generating coefficient files for initializing block RAM resources
# from binary files:
%.coe: %.bin
	echo "memory_initialization_radix=16;" > $@
	echo "memory_initialization_vector=" >> $@
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $< >> $@
	echo ";" >> $@

