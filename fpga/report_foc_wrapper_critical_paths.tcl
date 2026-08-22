set script_dir [file dirname [file normalize [info script]]]
set out_dir [file join $script_dir "synth_foc_wrapper_out"]

open_checkpoint [file join $out_dir "post_route.dcp"]
report_timing -max_paths 10 -sort_by slack -file [file join $out_dir "critical_paths.rpt"]
report_utilization -hierarchical -file [file join $out_dir "post_route_utilization_hierarchical.rpt"]

puts "FOC_CRITICAL_PATH_REPORT_DONE"
puts "Timing report: [file join $out_dir "critical_paths.rpt"]"
