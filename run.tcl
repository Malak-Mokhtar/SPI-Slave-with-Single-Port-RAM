create_project project_6 C:/Users/MALAK/Desktop/Digital_Design_Course/SPI_Slave_with_Single_Port_RAM/SPI-Slave-with-Single-Port-RAM -part xc7a35ticpg236-1L -force

add_files SPI_Slave.v RAM.v SPI_constraints.xdc

synth_design -rtl -top SPI_Slave > elab.log

write_schematic elaborated_schematic.pdf -format pdf -force 

launch_runs synth_1 > synth.log

wait_on_run synth_1
open_run synth_1

write_schematic synthesized_schematic.pdf -format pdf -force 

write_verilog -force SPI_netlist.v

launch_runs impl_1 -to_step write_bitstream 

wait_on_run impl_1
open_run impl_1

open_hw

connect_hw_server