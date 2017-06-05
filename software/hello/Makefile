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
	-Wl,-m,elf32lriscv --specs=nosys.specs -Wl,-T../potato.ld \
	-Wl,--gc-sections

OBJECTS := main.o start.o

all: hello.coe

hello.elf: $(OBJECTS)
	$(TARGET_LD) -o hello.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) hello.elf

hello.bin: hello.elf
	$(TARGET_OBJCOPY) -j .text -j .data -O binary hello.elf hello.bin

hello.coe: hello.bin
	echo "memory_initialization_radix=16;" > hello.coe
	echo "memory_initialization_vector=" >> hello.coe
	for i in $$(seq 0 63); do echo 00000013 >> hello.coe; done
	$(HEXDUMP) -v -e '1/4 "%08x\n"' hello.bin >> hello.coe
	echo ";" >> hello.coe

clean:
	-$(RM) $(OBJECTS)
	-$(RM) hello.elf hello.bin hello.coe

# Object file rules:

main.o: main.c ../../potato.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

