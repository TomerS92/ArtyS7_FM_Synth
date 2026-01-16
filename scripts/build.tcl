# Find the project file in the root or /vivado folder
set project_name "ArtyS7_DDS_Gen"
set origin_dir "."

# Open the project
open_project [glob ${origin_dir}/*.xpr]

# Update compile order
update_compile_order -fileset sources_1

# Run Synthesis
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Run Implementation and Generate Bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

puts "Workflow Complete: Bitstream generated."