# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -Wl,-T../potato.ld -Wl,--Map,hello.map

OBJECTS := main.o start.o

all: hello.elf hello.bin hello.coe

hello.elf: $(OBJECTS)
	$(TARGET_LD) -o hello.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) hello.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) hello.elf hello.bin hello.coe

# Object file rules:

main.o: main.c ../../potato.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

