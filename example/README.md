# System-On-Chip Design using the Potato Processor

This folder contains an SoC design using the Potato processor. The design
has been synthesized using Vivado 2018.2 and tested on an Arty board from
Digilent.

## Quick Start

In order to test the example design, start by creating a new project in
Vivado. In the "Project Type" screen, select "RTL Project". Make sure
the "Do not specify source at this time" box is *unchecked*.

### Adding Source Files

In the "Add Sources" screen, add all source files from the `src/`, `soc/`
and `example/` directories, *except* `tb_toplevel.vhd`. Some of the added
files may not be used by the design; after the project has been created,
you can remove everything that is not included under the `toplevel` entity
in the hierarchy view.

Before clicking "Next", make sure that the "Target language" is set to VHDL.

In the "Add Constraints" screen, add the `arty.xdc` file from the `example/`
directory. If you are not synthesizing the design for the Arty board, you
will have to modify this file to make the design work.

After creating the project, verify that the toplevel entity in your project
is called `toplevel` (from the `toplevel.vhd` file).

In addition to the source files, a couple of IP modules are needed to take
advantage of the FPGAs builtin resources - the following sections deal with
adding and configuring these.

### Clock Generator

The processor cannot run on the native 100 MHz clock signal provided
by the development board. Therefore, it is necessary to use a clock management
tile to synthesize the necessary system clock as well as other necessary clocks.

Add a clock generator to the design using the Clocking Wizard. Name the generated
component "clock_generator". Make sure the following options are selected in the
"Clocking Options" tab:

* Frequency synthesis - Enables synthesis of clock frequencies we need.
* Safe clock startup - Waits with starting the output clocks until the clock is stable.

Set the name of the primary input clock to be `clk`, and verify that the input
frequency is set to 100 MHz.

Go to the "Output Clocks" tab and enable `clk_out1` and `clk_out2`. Set the frequency
of `clk_out1` to 50 MHz. This will be the main system clock. Set the frequency of
`clk_out2` to 10 MHz - this clock will be used to run the 10 MHz system timer.

If you have peripherals that require additional clocks, you can enable more clock
outputs here.

Rename `clk_out1` to `system_clk` and `clk_out2` to `timer_clk` to match the port
names expected by the toplevel entity.

At the bottom of the "Output Clocks" tab, find the "Enable Optional Inputs/Outputs"
section and select `reset` and `locked` signals. The `locked` signal is used to
release the system reset signal when the clock signal is stable.

Set the "Reset Type" to "Active low" - this makes it possible to connect the reset
signal for the clock generator directly to the processor reset button on the development
board.

### PAEE ROM

The PAEE ROM is a read-only memory intended to store bootloaders. Before continuing,
build the bootloader application, located in the `software/` directory.

Add a block RAM IP to use as the ROM using the Block Memory Generator. Name the component
"aee_rom". In the "Basic" tab choose a "Native" interface type and set "Memory Type" to
"Single-Port ROM".

Go to the "Port A Options" tab and set the following settings:

* Port A Width: 32
* Port A depth: 4096

Do not enable the use of the enable pin or reset functionality, as these are not currently
supported by the ROM wrapper module. Uncheck the "Primitives Output Register" box register.

Under "Other Options", check the "Load Init File" option and give the location
of the coefficient file for the bootloader application.

### Test it!

You should now be able to synthesize and test the design. Connect to the board and see if
you can get some UART output. Hopefully it works :-)

If you get any output from the bootloader, you can build one of the other applications
and upload it to the board using the following command (substitute image.bin for the
application's .bin file and `/dev/ttyUSB1` for your serial port):

`cat image.bin /dev/zero | head -c128k | pv -s 128k -L 14400 > /dev/ttyUSB1`

