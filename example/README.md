# Demo design for the Nexys 4 board

This folder contains a design for a simple demo design using the Potato
processor. It has been tested using Vivado 2015.3.

## Quick Start

In order to use the design, first import all source files from the folders
`src/`, `soc/` and `example/` into your project. Make sure the testbench files
(the files starting with "tb_") is added as simulation-only files.

### Clocking

Add a clock generator using the Clocking Wizard. To seamlessly integrate
it into the design, name it "clock_generator". Choose the following options:

* Frequency Synthesis
* Safe Clock Startup

Set up two output clocks, `clk_out1` with frequency 60 MHz, and `clk_out2` with
a frequency of 10 MHz. Rename the corresponding ports to `system_clk` and
`timer_clk` respectively. Name the input clock `clk`.

### Instruction memory

Add a block RAM to use as instruction ROM using the Block Memory Generator.
Choose "Single Port ROM" as memory type, name it "instruction_rom" and set
port A width to 32 bits and port A depth to 2048. Initialize it with your
application binary. Ensure that the "Primitives Output Register" checkbox
is not checked.

### Test it!

Now you can test it and hopefully it works. This design can be used as a
basis for your own designs or just to evaluate the processor.

