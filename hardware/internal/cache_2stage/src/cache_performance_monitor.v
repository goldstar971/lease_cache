`ifndef _CACHE_PERFORMANCE_MONITOR_V_
`define _CACHE_PERFORMANCE_MONITOR_V_

module cache_performance_monitor #(
	parameter CACHE_STRUCTURE 	=  	"",
	parameter CACHE_REPLACEMENT = 	"",
	parameter N_INPUT_FLAGS 	= 	0, 				// {hit,miss,etc.}
	parameter BW_CONFIG_REGS 	= 	0

	`ifdef SIMULATION_SYNTHESIS
	,
	parameter BW_INPUT_FLAGS = `CLOG2(N_INPUT_FLAGS)
	`endif

)(
	input 							clock_i,
	input 							resetn_i,
	input 	[N_INPUT_FLAGS-1:0] 	flags_i,
	input 	[BW_CONFIG_REGS-1:0] 	config0_i, 		// cache control 	[31:16 | 15:0]
	input 	[BW_CONFIG_REGS-1:0] 	config1_i, 		// buffer control
	output 	[BW_CONFIG_REGS-1:0] 	data0_o, 		// cache data
	output 	[BW_CONFIG_REGS-1:0] 	data1_o 		// buffer data
);

// parameterizations
// ----------------------------------------------------------------------------------------------------------------------
`ifndef SIMULATION_SYNTHESIS
localparam BW_INPUT_FLAGS = `CLOG2(N_INPUT_FLAGS);
`endif

// internal signals and controller
// ----------------------------------------------------------------------------------------------------------------------
reg [BW_CONFIG_REGS-1:0] cache_data_reg;

reg [63:0] 	counter_cycle_reg,
			counter_hit_reg,
			counter_miss_reg,
			counter_writeback_reg,
			counter_expired_reg,
			counter_default_reg;


assign data0_o = cache_data_reg;
assign data1_o = 'b0;

always @(posedge clock_i) begin

	if (!resetn_i) begin
		cache_data_reg 			<= 'b0;
		counter_cycle_reg 		<= 'b0;
		counter_hit_reg 		<= 'b0;
		counter_miss_reg 		<= 'b0;
		counter_writeback_reg 	<= 'b0;
		counter_expired_reg 	<= 'b0;
		counter_default_reg 	<= 'b0;
	end
	else begin

		// manage metric counters
		if (config0_i[24]) begin
			counter_cycle_reg 		<= counter_cycle_reg + 1'b1;

			if (flags_i[0]) counter_hit_reg 		<= counter_hit_reg + 1'b1;
			if (flags_i[1]) counter_miss_reg 		<= counter_miss_reg + 1'b1;
			if (flags_i[2]) counter_writeback_reg 	<= counter_writeback_reg + 1'b1;
			if (flags_i[3]) counter_expired_reg 	<= counter_expired_reg + 1'b1;
			if (flags_i[4]) counter_default_reg 	<= counter_default_reg + 1'b1;
		end

		// benchmark metric outputs
		case(config0_i[4:0])

			5'b00000: 	cache_data_reg <= counter_cycle_reg[31:0];
			5'b00001: 	cache_data_reg <= counter_cycle_reg[63:32];
			5'b00010: 	cache_data_reg <= counter_hit_reg[31:0];
			5'b00011: 	cache_data_reg <= counter_hit_reg[63:32];
			5'b00100: 	cache_data_reg <= counter_miss_reg[31:0];
			5'b00101: 	cache_data_reg <= counter_miss_reg[63:32];
			5'b00110: 	cache_data_reg <= counter_writeback_reg[31:0];
			5'b00111: 	cache_data_reg <= counter_writeback_reg[63:32];
			5'b01000: 	cache_data_reg <= counter_expired_reg[31:0];
			5'b01001: 	cache_data_reg <= counter_expired_reg[63:32];
			5'b01010: 	cache_data_reg <= counter_default_reg[31:0];
			5'b01011: 	cache_data_reg <= counter_default_reg[63:32];

			5'b01111: 	cache_data_reg <= CACHE_STRUCTURE | CACHE_REPLACEMENT;

			default: 	cache_data_reg <= 'b0;

		endcase
	end
end

endmodule

`endif