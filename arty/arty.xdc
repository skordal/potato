# The Potato Processor - A simple processor for FPGAs
# (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

# Set operating conditions to improve temperature estimation:
set_operating_conditions -airflow 0
set_operating_conditions -heatsink low

# Clock signal:
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {clk}];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

# Reset button:
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports {reset_n}];

# GPIOs (Buttons):
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[0]}];
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[1]}];
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[2]}];
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[3]}];

# GPIO (Switches):
set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {gpio_pins[4]}];
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[5]}];
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[6]}];
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[7]}];

# GPIOs (LEDs):
set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports {gpio_pins[8]}];
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports {gpio_pins[9]}];
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {gpio_pins[10]}];
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[11]}];

# UART0:
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports {uart0_txd}];
set_property -dict {PACKAGE_PIN A9  IOSTANDARD LVCMOS33} [get_ports {uart0_rxd}];

# UART1 (pin 5 and 6 on JA, to match the pins on the PMOD-GPS):
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {uart1_txd}];
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {uart1_rxd}];
