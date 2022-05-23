module eviction_status_tracker #(
	parameter COUNTER_BW = 0
)(
	input 					clock_i, 			// controller updates on this clock (90 deg phase - so that it can stall the cache controller)
	input 					clock_memory_i, 	// embedded memories updates on this clock (180 deg phase - so that it updates prior to eviction bit update)
	input 					resetn_i,
	input 	[31:0]			config_i, 			// comm_i
	input 					request_i,
	input                 en_i, //if we are using the sampler or the standard cache metrics.
	input 	multi_expiry_flag_i,
	input 	random_evict_flag_i,
	input 	expiry_flag_i,
	input   [COUNTER_BW-1:0] reference_counter_i,
	output 					stall_o,
	output 	[31:0]			count_o,	 		// number of buffer entries to pull	

	// ports to performance controller comm_o switch
	output 	[COUNTER_BW-1:0]			trace_o,
	output 	[1:0] 	eviction_status_o
	
);

// parameterizations
// --------------------------------------------------------------------------------------------------
//localparam BUFFER_LIMIT = 256*(2^10) / (50 / 8); 	// buffer capacity (B) divided by size of one sample
localparam BUFFER_LIMIT = `EVICTION_TRACKER_BUFFER_LIMIT;
localparam BW_BUFFER 	= `CLOG2(BUFFER_LIMIT);


// port mapping
// --------------------------------------------------------------------------------------------------
reg 	stall_reg;

assign stall_o 			= stall_reg;
assign count_o 			= buffer_addr_next_reg;
assign trace_o 			= trace_data_bus;

assign eviction_status_o = eviction_data_bus;

assign trace_data=reference_counter_i-1; //reference counter should be zero-indexed

// internal signals
// --------------------------------------------------------------------------------------------------

// buffer control logic
// --------------------------------------
reg 				buffer_rw_bus,
					buffer_rw_reg;
reg [BW_BUFFER-1:0] buffer_addr_bus,
					buffer_addr_reg;

reg [BW_BUFFER:0]	buffer_addr_next_reg;

reg 				stall_delay_flag; 			// need a flag to stall the address switch so that last entry gets recorded
reg  miss_reg,miss_reg1;


always @(posedge clock_memory_i) begin
	if (!resetn_i) begin
		buffer_rw_bus 	= 1'b0;
		buffer_addr_bus = 1'b0;
		stall_delay_flag = 1'b0;
	end
	else begin

		// access control
		// hardware has normal access to the buffer - can only be externally pulled from if
		// - no longer tracking (config[24] == 1'b0)
		// - is full (so that the host can read it and then clear it)
		if (config_i[24]) begin

			// if the buffer is not full then sampler has access to the buffer
			if (!stall_reg) begin
				stall_delay_flag = 1'b0;
				buffer_rw_bus 	= buffer_rw_reg;
				buffer_addr_bus = buffer_addr_reg;
			end

			else if (stall_reg & !stall_delay_flag) begin
				stall_delay_flag = 1'b1;
				buffer_rw_bus 	= buffer_rw_reg;
				buffer_addr_bus = buffer_addr_reg;
			end

			else begin
				buffer_rw_bus 	= 1'b0;
				buffer_addr_bus = config_i[BW_BUFFER-1+`TRACKER_OUT_SEL_WIDTH: `TRACKER_OUT_SEL_WIDTH];
			end
		end
		else begin
			buffer_rw_bus 	= 1'b0;
			buffer_addr_bus = config_i[BW_BUFFER-1+`TRACKER_OUT_SEL_WIDTH: `TRACKER_OUT_SEL_WIDTH];
		end
	end
end

always @(posedge clock_memory_i)begin 
	miss_reg=1'b0;
	if(random_evict_flag_i)begin
		eviction_data_reg 	= 2'b10;
		miss_reg=1'b1;
	end 
	else if(multi_expiry_flag_i)begin
		eviction_data_reg 	= 2'b00;
		miss_reg=1'b1;
	end
	else if(!multi_expiry_flag_i&expiry_flag_i)begin 
		eviction_data_reg 	= 2'b01;
		miss_reg=1'b1;
	end
end


// tracker logic
// --------------------------------------


always @(posedge clock_i) begin
	if (!resetn_i) begin
		stall_reg 				= 1'b0;
		buffer_addr_reg 		= 'b0;
		buffer_addr_next_reg 	= 'b0;
		buffer_rw_reg 			= 1'b0;
	end
	else begin

		// defaults 
		buffer_rw_reg = 1'b0;

		// stall clear control
		if (config_i[23]) begin
			stall_reg 				= 1'b0;
			buffer_addr_reg 		= 'b0;
			buffer_addr_next_reg 	= 'b0;
		end

		// enable
		//
		// ---------------------------------
		if (config_i[24] & !stall_reg & en_i) begin

			

			// if the counter is up then store the expired bit trace
			if (miss_reg) begin

				// reset counter

				// store into memory
				buffer_addr_reg 		= buffer_addr_next_reg[BW_BUFFER-1:0];
				buffer_addr_next_reg 	= buffer_addr_next_reg + 1'b1;

				buffer_rw_reg 			= 1'b1;

				// if buffer is full then stall the cache until it gets pulled
				if (buffer_addr_next_reg == BUFFER_LIMIT) begin
					stall_reg 			= 1'b1;
				end
			end
		end
	end
end

// memory instantiations
// --------------------------------------------------------------------------------------------------
wire 	[1:0]	eviction_data_bus;
				
reg 	[1:0]	eviction_data_reg;

memory_embedded #(
	.N_ENTRIES 	(BUFFER_LIMIT			), 	
	.BW_DATA 	(2				),
	.DEBUG 		(1						)
)mem_eviction_status_bits_inst(
	.clock_i 	(clock_memory_i 		),
	.wren_i 	(buffer_rw_bus 			),
	.addr_i 	(buffer_addr_bus 		),
	.data_i 	(eviction_data_reg 	),
	.data_o 	(eviction_data_bus 	)
);

wire 	[COUNTER_BW-1:0]	trace_data_bus,trace_data;


memory_embedded #(
	.N_ENTRIES 	(BUFFER_LIMIT			),
	.BW_DATA 	(COUNTER_BW				),
	.DEBUG 		(1						)
)mem_trace_inst(
	.clock_i 	(clock_memory_i 		),
	.wren_i 	(buffer_rw_bus 			),
	.addr_i 	(buffer_addr_bus 		),
	.data_i 	(trace_data 			),
	.data_o 	(trace_data_bus 		)
);

endmodule