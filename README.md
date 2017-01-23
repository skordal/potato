# The Potato Processor

**Note that the master branch may be in an unstable state. Use one of the releases to avoid problems when compiling the code.**

![Processor architecture overview diagramme](https://github.com/skordal/potato/blob/master/docs/diagram.png?raw=true)

The Potato Processor is a simple RISC-V processor for use in FPGAs. It implements the 32-bit integer subset
of the RISC-V specification version 2.0 and supports the machine mode and the Mbare addressing environment of
the RISC-V privileged architecture, version 1.7.

The processor has been tested on a Arty board using the example SoC design provided in the `example/` directory
and the Hello World application available in `software/hello`. Synthesis and implementation has been tested on
various versions of Xilinx' Vivado, most recently version 2016.4.

## Features

* Supports the complete 32-bit RISC-V base integer ISA (RV32I) version 2.0.
* Supports machine mode and the Mbare addressing environment defined in the RISC-V privileged architecture version 1.7.
* Supports up to 8 individually maskable external interrupts (IRQs).
* 5-stage "classic" pipeline.
* Supports the Wishbone bus, version B4.

## Peripherals

The project includes a variety of Wishbone-compatible peripherals for use in system-on-chip designs based on the Potato processor. The main peripherals are:

* Timer - a 32-bit timer with compare interrupt
* GPIO - a configurable-width generic GPIO module
* Memory - a block RAM memory module
* UART - a UART module with hardware FIFOs and configurable baudrate

## Quick Start/Instantiating

To instantiate the processor, add the source files from the `src/` folder to your project. Use the `pp_potato`
entity to instantiate a processor with a wishbone interface. Some generics are provided to configure the processor core.

An example System-on-Chip for the Arty development board can be found in the `example/` directory of the source repository.

## Compiler Toolchain

To program the processor, you need an appropriate compiler toolchain. Follow the instructions on the [RISCV tools repository](https://github.com/riscv/riscv-tools)
to build and install a toolchain.

## Reporting bugs and issues

Bugs and issues related to the Potato processor can be reported on the project's [GitHub page](https://github.com/skordal/potato).

