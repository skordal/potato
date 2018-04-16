# System-On-Chip Design using the Potato Processor

This folder contains an SoC design using the Potato processor. The design
has been synthesized using Vivado 2018.1 and tested on an Arty board from
Digilent.

## Quick Start

In order to test the design yourself, first import all source files from the
`src/`, `soc/` and `example/` directories into your project. Some of the added
files may not be used by the design; in the hierarchy view in Vivado you can
remove any file that is not included under the `toplevel` entity. Make sure
that the "Target language" in the project settings is set to VHDL.

In addition to the source files, a couple of IP modules are needed to take
advantage of the FPGAs builtin resources - the following sections deal with
adding and configuring these.

### Clock Generator

The processor cannot (currently) run on the native 100 MHz clock signal provided
by the development board. Therefore it is necessary to use a clock management
tile to synthesize the necessary system clock as well as other necessary clocks.

Add a clock generator to the design using the Clocking Wizard. Name the generated
component "clock_generator". Make sure the following options are selected in the
"Clocking Options" tab:

* Frequency synthesis - Enables synthesis of clock frequencies we need.
* Safe clock startup - Waits with starting the output clocks until the clock is stable.

Go to the "Output Clocks" tab and enable `clk_out1` and `clk_out2`. Set the frequency
of `clk_out1` to 50 MHz. This will be the main system clock. Set the frequency of
`clk_out2` to 10 MHz - this clock will be used to run the 10 MHz system timer.

If you have peripherals that require additional clocks, you can enable more clock
outputs here.

Rename `clk_out1` to `system_clk` and `clk_out2` to `timer_clk` to match the port
names expected by the toplevel entity. Set the name of the input clock to be `clk`.

At the bottom of the "Output Clocks" tab, find the "Enable Optional Inputs/Outputs"
section and select `reset` and `locked` signals. The `locked` signal is used to
release the system reset signal when the clock signal is stable.

Set the "Reset Type" to "Active low" - this makes it possible to connect the reset
signal for the clock generator directly to the processor reset button on the development
board.

### PAEE ROM

The PAEE ROM is a read-only memory intended to store the Potato Application Execution
Environment, a BIOS-like firmware providing a simple boot-loader and hardware abstraction
layer. However, since the PAEE is still in development and has not been released yet,
this ROM is where you can put your application.

Add a block RAM IP to use as the ROM using the Block Memory Generator. Name the component
"aee_rom". In the "Basic" tab choose a "Native" interface type and set "Memory Type" to
"Single-Port ROM".

Go to the "Port A Options" tab and set the following settings:

* Port A Width: 32
* Port A depth: 4096

Do not enable the use of the enable pin or reset functionality, as these are not currently
supported by the ROM wrapper module. Uncheck the "Primitives Output Register" box register.

Under "Other Options", check the "Load Init File" option and give the location
of the coefficient file for the application to store in the ROM. To test the
basic functionality of the chip, you can use the `hello` application from the
`software/` directory.

Optionally, fill the remaining memory locations with no-ops by entering `00000013` in the
correct field.

### Test it!

You should now be able to synthesize and test the design. Connect to the board and see if
you can get some UART output. Hopefully it works :-)

