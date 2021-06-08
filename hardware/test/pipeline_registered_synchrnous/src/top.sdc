create_clock -name clock_i -period 20.000 [get_ports {clock_i}]

set_false_path -to [get_ports {led_o*}]
set_false_path -from [get_ports {resetn_i}]
set_false_path -from [get_ports {pb_i*}]

derive_pll_clocks
derive_clock_uncertainty