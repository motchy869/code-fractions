## This file is a general .xdc for the Zybo Z7 Rev. B
## It is compatible with the Zybo Z7-20 and Zybo Z7-10
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports i_clk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports i_clk]

## Buttons
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports i_async_rst]
set_input_delay -clock sys_clk_pin -max 1.000 [get_ports i_async_rst]
set_input_delay -clock sys_clk_pin -min 0.000 [get_ports i_async_rst]
set_false_path -from [get_ports i_async_rst] -to [get_clocks sys_clk_pin]

##RGB LED 6
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {o_led[2]}]
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS33} [get_ports {o_led[1]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports {o_led[0]}]
set_output_delay -clock sys_clk_pin -max 1.000 [get_ports o_led]
set_output_delay -clock sys_clk_pin -min 0.000 [get_ports o_led]
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports o_led]

