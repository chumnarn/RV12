# RV12 full-chip timing constraints
set CLK_PORT [get_ports clk_PAD]
create_clock -name core_clk -period 20.000 $CLK_PORT

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

# External pad timing budget.
set_input_delay  2.000 -clock core_clk [get_ports {rst_n_PAD input_PAD[*]}]
set_output_delay 4.000 -clock core_clk [get_ports {output_PAD[*]}]

# Reset is asynchronous to functional timing analysis.
set_false_path -from [get_ports rst_n_PAD]
