# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -Wl,-T../potato.ld -Wl,--Map,sha256.map

OBJECTS := main.o sha256.o start.o
LINKER_SCRIPT := ../potato.ld

all: sha256.elf sha256.bin sha256.coe

sha256.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o sha256.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) sha256.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) sha256.elf sha256.bin sha256.coe sha256.map

# Object file rules:

main.o: main.c sha256.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

sha256.o: sha256.c sha256.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S ../../platform.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

