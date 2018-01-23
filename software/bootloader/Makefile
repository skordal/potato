# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean

TARGET_PREFIX ?= riscv32-unknown-elf
TARGET_CC := $(TARGET_PREFIX)-gcc
TARGET_LD := $(TARGET_PREFIX)-gcc
TARGET_SIZE := $(TARGET_PREFIX)-size
TARGET_OBJCOPY := $(TARGET_PREFIX)-objcopy
HEXDUMP ?= hexdump

TARGET_CFLAGS +=  -march=rv32i -Wall -Os -fomit-frame-pointer \
	-ffreestanding -fno-builtin -I../.. -I../../libsoc -std=gnu99 \
	-Wall -Werror=implicit-function-declaration
TARGET_LDFLAGS += -march=rv32i -nostartfiles -L../libsoc \
	-Wl,-m,elf32lriscv --specs=nosys.specs -Wl,-Tpotato_boot.ld \
	-Wl,--gc-sections

OBJECTS := main.o start.o

all: boot.coe

boot.elf: $(OBJECTS)
	$(TARGET_LD) -o boot.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) boot.elf

boot.bin: boot.elf
	$(TARGET_OBJCOPY) -j .text -j .data -O binary boot.elf boot.bin

boot.coe: boot.bin
	echo "memory_initialization_radix=16;" > boot.coe
	echo "memory_initialization_vector=" >> boot.coe
	$(HEXDUMP) -v -e '1/4 "%08x\n"' boot.bin >> boot.coe
	echo ";" >> boot.coe

clean:
	-$(RM) $(OBJECTS)
	-$(RM) boot.elf boot.bin boot.coe

# Object file rules:

main.o: main.c ../../potato.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

