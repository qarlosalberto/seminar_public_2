# Create a Vivado project to suit the needs of this example
# the reader of this example could generate his vivado project in a similar maner or
# have a manually maintained project.

set root [lindex ${argv} 0]
set project_name [lindex ${argv} 1]

# Create project
create_project -force myproject ${root}/${project_name}

# Configure general project settings
set obj [get_projects myproject]
set_property "default_lib" "xil_defaultlib" $obj
set_property "part" "xc7z010clg400-1" $obj

set_property "simulator_language" "Mixed" $obj
set_property "source_mgmt_mode" "DisplayOnly" $obj
set_property "target_language" "VHDL" $obj

# Create ip directory
set ip_dir ${root}/${project_name}_ip
file mkdir ${ip_dir}

create_ip -name cordic -vendor xilinx.com -library ip -version 6.0 -module_name cordic_0 -dir ${ip_dir}
set_property -dict [list \
  CONFIG.Data_Format {SignedFraction} \
  CONFIG.Functional_Selection {Sin_and_Cos} \
] [get_ips cordic_0]