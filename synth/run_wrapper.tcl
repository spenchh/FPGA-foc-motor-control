# Run from any working directory:
# vivado -mode batch -source synth/run_wrapper.tcl
# Optional arguments: -tclargs <part> <output-directory>
# This script implements the reduced-I/O wrapper. It does not write a bitstream.
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file dirname $script_dir]
set part_name xc7z010clg400-1
set out_dir [file join $project_dir build vivado-wrapper]
if {[llength $argv] > 2} {
    error "Usage: -tclargs ?part? ?output-directory?"
}
if {[llength $argv] >= 1} {set part_name [lindex $argv 0]}
if {[llength $argv] == 2} {set out_dir [file normalize [lindex $argv 1]]}
file mkdir $out_dir

read_verilog -sv [lsort [glob [file join $project_dir rtl design *.sv]]]
read_verilog -sv [file join $script_dir foc_synth_wrapper.sv]
read_xdc [file join $script_dir wrapper_clock.xdc]
synth_design -top foc_synth_wrapper -part $part_name
write_checkpoint -force [file join $out_dir post_synth.dcp]
report_utilization -file [file join $out_dir post_synth_utilization.rpt]
report_timing_summary -file [file join $out_dir post_synth_timing_summary.rpt]
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force [file join $out_dir post_route.dcp]
report_utilization -hierarchical -file [file join $out_dir post_route_utilization_hierarchical.rpt]
report_timing_summary -file [file join $out_dir post_route_timing_summary.rpt]
report_timing -max_paths 10 -sort_by slack -file [file join $out_dir critical_paths.rpt]
check_timing -verbose -file [file join $out_dir check_timing.rpt]
puts "Wrapper implementation complete: $out_dir"
puts "Inspect setup, hold, unconstrained paths, and I/O warnings before interpreting results."
