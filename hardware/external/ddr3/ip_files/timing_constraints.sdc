derive_pll_clocks
derive_clock_uncertainty

# 50MHz board input clock
#create_clock -name {clk_50m_fpga} -period 20.000 [get_ports {clk_50m_fpga}]


# to make the design robost, setting frequency higher thatn what actually in use.
# the actual input frequency is 100Mhz/10ns

#create_clock -period 10.0 [get_ports clkin_r_p]

#set sys_clock_smc {u0|smc_0|mem_if_ddr3_emif_0|pll0|pll1_phy~PLL_OUTPUT_COUNTER|divclk}


# JTAG Signal Constraints constrain the TCK port, assuming a 10MHz JTAG clock and 3ns delays
create_clock -name {altera_reserved_tck} -period 41.667 [get_ports { altera_reserved_tck }]
#set_input_delay -clock altera_reserved_tck -clock_fall -max 5 [get_ports altera_reserved_tdi]
#set_input_delay -clock altera_reserved_tck -clock_fall -max 5 [get_ports altera_reserved_tms]
#set_output_delay -clock altera_reserved_tck 5 [get_ports altera_reserved_tdo]


# Qsys will synchronize the reset input
set_false_path -from [get_ports cpu_resetn] -to *


# LED switching will be slow
set_false_path -from * -to [get_ports user_led[*]]


#set_false_path -from * -to {sld_signaltap:auto_signaltap_0*}

# data[38] will be created by the system clk
#create_generated_clock -name unused_b_38 -source $sys_clock_smc -divide_by 1 {q_sys:u0|q_sys_smc_0:smc_0|q_sys_smc_0_mSGDMA_0:msgdma_0|altera_avalon_st_pipeline_stage:agent_pipeline_006|altera_avalon_st_pipeline_base:core|data1[38]}
#create_clock -name unused_a_38 -period 10.0 -waveform {0 5.0}  q_sys:u0|q_sys_mSGDMA_0:msgdma_0|altera_avalon_st_pipeline_stage:agent_pipeline_006|altera_avalon_st_pipeline_base:core|data1[38]


#set_false_path -from {unused_a_38} -to {clk_50m_fpga}
#set_false_path -from {clk_50m_fpga} -to {unused_a_38}
#set_false_path -from $sys_clock  -to [get_clocks {unused_a_38}]
#set_false_path -from [get_clocks {unused_a_38}] -to $sys_clock 
#set_multicycle_path -from $sys_clock -to [get_clocks {unused_a_38}] -setup -end 2
#set_multicycle_path -from $sys_clock -to [get_clocks {unused_a_38}] -hold -end 1
#set_multicycle_path -from [get_clocks {unused_a_38}] -to $sys_clock-setup -end 2
#set_multicycle_path -from [get_clocks {unused_a_38}] -to $sys_clock -hold -end 2

#set pll_afi_clock $pins(pll_afi_clock)

#create_generated_clock -name slow_clk_b -source $sys_clock_smc  -divide_by 32 {q_sys:u0|q_sys_smc_0:smc_0|master_driver_msgdma:master_driver_msgdma_0|slow_clk_int[4]}


#set_false_path -from [get_clocks {u0|fpga_sdram|pll0|pll_write_clk}] -to [get_clocks {fpga_clk_50}]
#set_false_path -from [get_clocks {u0|fpga_sdram|pll0|pll_write_clk}] -to $sys_clock

#set_false_path -from [get_clocks {clk_50m_fpga}] -to $sys_clock
#set_false_path -from $sys_clock -to [get_clocks {clk_50m_fpga}]


#set_false_path -from {q_sys:u0|q_sys_mSGDMA_0:msgdma_0|freq_counter:freq_counter_0|count_1ms[*]} -to {q_sys:u0|q_sys_mSGDMA_0:msgdma_0|freq_counter:freq_counter_0|pls_1sec_int1}
#set_false_path -from {q_sys:u0|q_sys_mSGDMA_0:msgdma_0|altera_reset_controller:rst_controller_002|altera_reset_synchronizer:alt_rst_sync_uq1|altera_reset_synchronizer_int_chain_out} -to {q_sys:u0|q_sys_mSGDMA_0:msgdma_0|freq_counter:freq_counter_0|freq*}
#set_false_path -from {q_sys:u0|q_sys_mSGDMA_0:msgdma_0|altera_reset_controller:rst_controller_002|altera_reset_synchronizer:alt_rst_sync_uq1|altera_reset_synchronizer_int_chain_out} -to {q_sys:u0|q_sys_mSGDMA_0:msgdma_0|freq_counter:freq_counter_0|pls_1sec*}


