# The Potato Processor

**Note that the master branch may be in an unstable state. Use one of the releases to avoid problems when compiling the code.**

![Processor architecture overview diagramme](https://github.com/skordal/potato/blob/master/docs/diagram.png?raw=true)

The Potato Processor is a simple RISC-V processor for use in FPGAs. It implements the 32-bit integer subset
of the RISC-V specification version 2.0 and supports the machine mode and the Mbare addressing environment of
the RISC-V privileged architecture, version 1.7.

The processor has been tested on a Arty board using the example SoC design provided in the `example/` directory.

## Features

* Supports the complete 32-bit RISC-V base integer ISA (RV32I) version 2.0.
* Supports machine mode and the Mbare addressing environment defined in the RISC-V privileged architecture version 1.7.
* Supports up to 8 individually maskable external interrupts (IRQs).
* 5-stage "classic" pipeline.
* Supports the Wishbone bus, version B4.
* Experimental instruction cache support.

## Peripherals

The project includes a variety of Wishbone-compatible peripherals for use in system-on-chip designs based on the Potato processor. The main peripherals are:

* Timer - a 32-bit timer with compare interrupt
* GPIO - a configurable-width generic GPIO module
* Memory - a block RAM memory module
* UART - a UART module with hardware FIFOs and configurable baudrate
* 7-Segment - a 7-segment display module, supporting up to 8 displays

## Quick Start/Instantiating

To instantiate the processor, add the source files from the `src/` folder to your project. Use the `pp_potato`
entity to instantiate a processor with a wishbone interface. Some generics are provided to configure the processor core.

An example System-on-Chip for the Xilinx Arty board can be found in the `example/` directory of the source repository.

