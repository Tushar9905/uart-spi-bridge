# Synthesize and implement the bridge, then report utilization and timing.
# Usage: vivado -mode batch -source syn/synth.tcl

set root [file normalize [file join [file dirname [info script]] ..]]
set out  [file join $root build syn]
file mkdir $out

set part xc7a35tcpg236-1

read_verilog [glob [file join $root rtl *.v]]
read_xdc [file join $root syn uart_spi_bridge.xdc]

synth_design -top uart_spi_bridge_top -part $part
opt_design
place_design
route_design

report_utilization    -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing.rpt]

set util   [report_utilization -return_string]
regexp {\| Slice LUTs\s+\|\s+(\d+)} $util -> luts
regexp {\| Slice Registers\s+\|\s+(\d+)} $util -> ffs
set wns    [get_property SLACK [get_timing_paths -max_paths 1 -setup]]
set period [get_property PERIOD [get_clocks clk]]

puts "RESULT part=$part LUTs=$luts FFs=$ffs clock=[format %.0f [expr {1000.0 / $period}]]MHz WNS=${wns}ns"
