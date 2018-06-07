# Bootloader

A trivial bootloader has been created so to ease software development and testing.
The bootloader emits a welcome message over the UART (115200 baud, 8N1) and waits
for a 128 kB binary image to be received.

Once the image has been received, the booloader jumps to address 0x00000000 to begin
executing the new application.

To use the bootloader, build an application and upload it to the board with the following
command:

```
cat image.bin /dev/zero | head -c128k | pv -s 128k -L 14400 > /dev/ttyUSB1
```

