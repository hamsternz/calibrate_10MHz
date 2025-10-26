# Create project
create_project calibrate_10Mhz build -part xc7a35tcpg236-1 -force

set files [list \
 "src/binary_to_decimal.vhd" \
 "src/deserialize.vhd" \
 "src/frequency_counter.vhd" \
 "src/serial_interface.vhd" \
 "src/calibrate_10MHz.vhd" \
]
add_files -norecurse -fileset [get_filesets sources_1] $files

set_property -name "top" -value "calibrate_10MHz" -objects  [get_filesets sources_1]

add_files -norecurse -fileset [get_filesets constrs_1] [ list \
  "constrants/basys3.xdc" \
]

add_files -norecurse -fileset [get_filesets sim_1] [ list \
  "sim/tb_calibrate_10MHz.vhd" \
]

close_project

quit
