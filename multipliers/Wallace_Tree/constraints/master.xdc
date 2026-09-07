## =====================================================================
## Constraints file for top_all_multipliers_demo
## Target board : Digilent Basys3 (Xilinx Artix-7, xc7a35tcpg236-1)
## Only the pins actually used by the demo are un-commented below.
## Cross-check against Digilent's official Basys3 Master.xdc if you
## are using a different board revision.
## =====================================================================

## ---- Clock signal : 100 MHz onboard oscillator ----
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

## ---- Reset button (BTNC - center button) ----
set_property PACKAGE_PIN U18 [get_ports btn_rst]
set_property IOSTANDARD LVCMOS33 [get_ports btn_rst]

## ---- Start button (BTNU - up button) ----
set_property PACKAGE_PIN T18 [get_ports btn_start]
set_property IOSTANDARD LVCMOS33 [get_ports btn_start]

## ---- LEDs ----
## LD0 : lit once both sequential multipliers (Booth + Sequential) finish
set_property PACKAGE_PIN U16 [get_ports led_done]
set_property IOSTANDARD LVCMOS33 [get_ports led_done]

## LD1 : lit when array / wallace / vedic results all agree (live self-check)
set_property PACKAGE_PIN E19 [get_ports led_match]
set_property IOSTANDARD LVCMOS33 [get_ports led_match]

## =====================================================================
## Config options (recommended defaults for Basys3 programming)
## =====================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
