module cache_fa_lease_controller #(
	parameter INIT_DONE = 1'b1,
	parameter CACHE_BLOCK_CAPACITY = 0,
	parameter BW_TAG = 0,
	parameter BW_CACHE_FULL = 0, 			// [BW_BLOCK_CAPACITY | BW_BLOCK]
	parameter BW_CACHE_PART = 0, 			// [BW_BLOCK_CAPACITY] - references addresses in cam memory, or block-wise address in cache
	parameter LEASE_LLT_ENTRIES = 0,
	parameter LEASE_CONFIG_ENTRIES = 0
)(

	input 						clock_i,
	input 						clock_lease_i,
	input 						resetn_i,
	input 						enable_i,

	// core/hart signals
	input 						core_req_i,
	input 	[`BW_WORD_ADDR-1:0]	core_ref_addr_i, 	// unused
	input 						core_rw_i,
	input 	[BW_TAG-1:0]		core_tag_i,
	input 	[`BW_BLOCK-1:0]	 	core_word_i,
	input 	[31:0]				core_data_i,
	output						core_done_o,
	output 						core_hit_o,

	// tag memory signals
	input 						cam_hit_i,
	output 						cam_wren_o,
	output 						cam_rmen_o,
	input 	[BW_TAG-1:0]		cam_tag_i, 				// tag <- addr
	input 	[BW_CACHE_PART-1:0] cam_addr_i, 			// addr <- tag
	output 	[BW_CACHE_PART-1:0] cam_addr_o, 			// tag -> addr

	// cache memory signals
	input 	[31:0]				cache_mem_data_i,
	output 	[BW_CACHE_FULL-1:0]	cache_mem_add_o,
	output 						cache_mem_rw_o,
	output 	[31:0]				cache_mem_data_o,

	// data buffer signals
	input 						buffer_read_ready_i, 	// mem -> cache buffer signals
	input  	[31:0]				buffer_data_i,
	output 						buffer_read_ack_o,
	input 						buffer_write_ready_i, 	// mem <- cache buffer signals
	output	[31:0] 				buffer_data_o,
	output 						buffer_write_ack_o,

	// command ports
	input 						mem_ready_i,
	output 						mem_req_o, 			// must be at least one item in the buffer before driving high
	output 						mem_req_block_o,
	output 						mem_rw_o,
	output 	[`BW_WORD_ADDR-1:0]	mem_addr_o,

	// performance ports
	output 						flag_hit_o,
	output 						flag_miss_o,
	output 						flag_writeback_o,
	output 						flag_expired_o,
	output 						flag_defaulted_o
);

// local parameterizations
localparam ST_REQUEST_LLT_DATA 		= 3'b000;
localparam ST_TRANSFER_LLT_DATA 	= 3'b001;
localparam ST_NORMAL 				= 3'b010; 		// check for hit/miss
localparam ST_WAIT_READY 			= 3'b011; 		// upon miss request a block be brought in - if ext. mem not ready then idle
localparam ST_WRITE_BUFFER 			= 3'b100; 		// read in block from cache and write to buffer
localparam ST_READ_BUFFER  			= 3'b101; 		// read in from buffer and write block to cache
localparam ST_WAIT_REPLACEMENT_GEN 	= 3'b110;


// internal signals - registered ports
// ---------------------------------------------------------------------------------------------------------------------

// core/hart
reg core_done_o_reg;

assign core_done_o = core_done_o_reg;
// core_hit_o assigned below

// tag memory
reg 					cam_wren_reg;
reg [BW_CACHE_PART-1:0]	cam_addr_reg;

assign cam_wren_o = cam_wren_reg;
assign cam_rmen_o = 1'b0; 				// not used but allocated for
assign cam_addr_o = cam_addr_reg;

// cache memory
reg 					cache_mem_rw_reg;
reg [BW_CACHE_FULL-1:0] cache_mem_add_reg;
reg [31:0] 				cache_mem_data_reg;

assign cache_mem_rw_o = cache_mem_rw_reg;
assign cache_mem_add_o = cache_mem_add_reg;
assign cache_mem_data_o = cache_mem_data_reg;

// data buffer
reg 					buffer_read_ack_reg,
						buffer_write_ack_reg;
reg [31:0]				buffer_data_reg;

assign buffer_read_ack_o = buffer_read_ack_reg;
assign buffer_write_ack_o = buffer_write_ack_reg;
assign buffer_data_o = buffer_data_reg;

// command out ports
reg 					mem_req_reg, 			// must be at least one item in the buffer before driving high
						mem_req_block_reg,
						mem_rw_reg;
reg [`BW_WORD_ADDR-1:0]	mem_addr_reg;

assign mem_req_o = mem_req_reg;
assign mem_req_block_o = mem_req_block_reg;
assign mem_rw_o = mem_rw_reg;
assign mem_addr_o = mem_addr_reg;

// performance controller
reg 					flag_hit_reg,
						flag_miss_reg,
						flag_writeback_reg;

assign flag_hit_o	= flag_hit_reg;
assign flag_miss_o = flag_miss_reg;
assign flag_writeback_o = flag_writeback_reg;


// lease controller logic
// ---------------------------------------------------------------------------
localparam BW_LLT_ENTRIES = `CLOG2(LEASE_LLT_ENTRIES);
localparam BW_CONFIG_ADDR = `CLOG2(LEASE_CONFIG_ENTRIES);

// lease lookup table signals
reg 	[BW_LLT_ENTRIES-1:0] 		llt_addr_reg;
reg 								llt_wren_ref_addr_reg,
									llt_wren_lease_reg;
reg 	[`LEASE_REF_ADDR_BW-1:0] 	llt_ref_addr_reg;
reg 	[`LEASE_REGISTER_BW-1:0]	llt_ref_lease_reg;

// lease controller signals
reg 	[1:0] 						lease_initialization_base_reg;  	// counter used to manage which parts of lease hardware
																		// are being configured
reg 	[5:0] 						lease_initialization_counter_reg; 	// address increment counter

reg 								config_wren_reg;
reg 	[BW_CONFIG_ADDR-1:0]  		config_addr_reg;
reg 	[`LEASE_CONFIG_VAL_BW-1:0] 	config_data_reg;

wire 								lease_replacement_done;
wire 	[BW_CACHE_PART-1:0] 		lease_replacement_addr;
wire 								lease_expired_reg,
									lease_default_reg;


assign flag_expired_o = lease_expired_reg;
assign flag_defaulted_o = lease_default_reg;

lease_policy_controller #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	),
	.N_LEASE_CONFIGS 		(LEASE_CONFIG_ENTRIES 	),
	.N_ENTRIES 				(LEASE_LLT_ENTRIES 		),
	.BW_LEASE_REGISTER 		(`LEASE_REGISTER_BW 	),
	.BW_REF_ADDR 			(`LEASE_REF_ADDR_BW 	)
) lease_controller_inst(
	// system ports
	.clock_i 				(clock_lease_i			), 	// llt and controller clocked with same clock
	.resetn_i 				(resetn_i 				),

	// cache to llt ports (ignore logic/structure of the controller)
	.llt_addr_i 			(llt_addr_reg 			),
	.wren_ref_addr_i 		(llt_wren_ref_addr_reg	),	// write to addr_i
	.wren_lease_i 			(llt_wren_lease_reg		), 	// write to addr_i
	.rmen_i  				(1'b0 					), 	// remove addr_i from table
	.ref_addr_i 			(llt_ref_addr_reg		), 	// ref address to write to table
	.ref_lease_i 			(llt_ref_lease_reg		), 	// lease value to write to table
	.search_addr_i 			(core_ref_addr_i		), 	// address of the ld/st making the memory request (for lease lookup)

	// controller - lease config ports
	.config_wren_i 			(config_wren_reg		), 	// when high write data to config addr
	.config_addr_i 			(config_addr_reg		), 	// which config reg to write to
	.config_data_i 			(config_data_reg		), 	// what to write to the specified config reg

	// controller - lease ports
	.cache_addr_i 			(cam_addr_i 			), 	// translated cache address - so that lease controller can update lease value
	.hit_i 					(flag_hit_reg			), 	// when high, adjust lease register values (strobe trigger)
	.miss_i 				(flag_miss_reg			), 	// when high, generate a replacement address (strobe trigger)
	.done_o 				(lease_replacement_done	), 	// logic high when controller generates replacement addr
	.addr_o 				(lease_replacement_addr	),
	.expired_o 				(lease_expired_reg		), 	// logic high if the replaced cache addr.'s lease expired
	.default_o 				(lease_default_reg		) 	// logic high if upon a hit the line is renewed with the default lease value
);


// cache controller logic
// ---------------------------------------------------------------------------------------------------------------------
reg 	[2:0] 						state_reg; 					// controller state machine
reg 	[`BW_BLOCK:0]				n_transfer_reg;				// number of words read/written
reg 	[CACHE_BLOCK_CAPACITY-1:0]	dirtybits_reg;				// dirty bit set on store (cache write by processor)

reg 	[`BW_WORD_ADDR-1:0]			add_writeback_reg; 			// registered replacement address (to prevent tag overwrite issue)
reg 	[BW_CACHE_PART-1:0]			replacement_ptr_reg;
reg 								req_flag_reg,  				// status/operation flags
									rw_flag_reg, 
									writeback_flag_reg;

assign core_hit_o = (core_req_i | req_flag_reg) ? cam_hit_i : 1'b1; 	// to prevent stall cycle if no request

always @(posedge clock_i) begin

	// reset state
	// ----------------------------------------------------
	if (!resetn_i) begin

		// internal control
		state_reg = 			ST_REQUEST_LLT_DATA;
		//state_reg = ST_NORMAL;
		n_transfer_reg = 		'b0; 
		dirtybits_reg = 		'b0;
		add_writeback_reg = 	'b0;
		req_flag_reg =  		1'b0; 
		rw_flag_reg =  			1'b0;
		writeback_flag_reg =  	1'b0;
		replacement_ptr_reg = 	{BW_CACHE_PART{1'b1}}; 	// start at max so first replacement rolls over into first cache line location 

		// core/hart
		//core_done_o_reg = 		INIT_DONE;
		core_done_o_reg = 		1'b0;

		// tag memory
		cam_wren_reg = 			1'b0;
		cam_addr_reg =  		'b0;

		// cache memory
		cache_mem_rw_reg = 		1'b0;
		cache_mem_add_reg = 	'b0;
		cache_mem_data_reg = 	'b0;

		// data buffer
		buffer_read_ack_reg = 	1'b0;
		buffer_write_ack_reg = 	1'b0;
		buffer_data_reg = 		'b0;

		// command signals
		mem_req_reg = 			1'b0;
		mem_req_block_reg = 	1'b0;
		mem_rw_reg =  			1'b0;
		mem_addr_reg =  		'b0;

		// performance flags
		flag_hit_reg = 			1'b0;
		flag_miss_reg = 		1'b0;
		flag_writeback_reg = 	1'b0;

		// lease signals
		// -----------------------------------------------
		lease_initialization_base_reg = 'b0;
		lease_initialization_counter_reg = 'b0;
		llt_addr_reg = 			'b0;
		llt_wren_ref_addr_reg = 1'b0;
		llt_wren_lease_reg =  	1'b0;
		llt_ref_addr_reg = 		'b0;
		llt_ref_lease_reg = 	'b0;

		config_wren_reg = 		1'b0;
		config_addr_reg = 		'b0;
		config_data_reg = 		'b0;

	end

	// active sequencing
	// ----------------------------------------------------------------------------
	else begin

		// default control signals
		cam_wren_reg = 			1'b0;
		cache_mem_rw_reg = 		1'b0;

		buffer_read_ack_reg = 	1'b0;
		buffer_write_ack_reg = 	1'b0;

		mem_req_reg = 			1'b0;
		mem_req_block_reg = 	1'b0;
		mem_rw_reg =  			1'b0;

		flag_hit_reg = 			1'b0;
		flag_miss_reg = 		1'b0;
		flag_writeback_reg = 	1'b0;

		// lease default control signals
		config_wren_reg =  		1'b0;
		llt_wren_ref_addr_reg = 1'b0;
		llt_wren_lease_reg = 	1'b0;


		// only sequence if enabled
		if(enable_i) begin

			// cache state sequencing
			// --------------------------------------------------------------------
			case(state_reg)

				// upon cold start need to populate the LLT and configuration registers
				ST_REQUEST_LLT_DATA: begin

					// wait until controller ready for data
					if (mem_ready_i) begin

						case(lease_initialization_base_reg)

							2'b00: mem_addr_reg = `LEASE_CONFIG_BASE_W; 	// lease controller configurations
							2'b01: mem_addr_reg = `LEASE_ADDR_BASE_W + lease_initialization_counter_reg;
							2'b10: mem_addr_reg = `LEASE_VALUE_BASE_W + lease_initialization_counter_reg;
							default: mem_addr_reg = 'b0;

						endcase

						// request full block of data
						mem_req_reg = 1'b1;
						mem_req_block_reg = 1'b1;
						mem_rw_reg = 1'b0;

						// transition
						state_reg = ST_TRANSFER_LLT_DATA;
					end
				end


				ST_TRANSFER_LLT_DATA: begin

					// read out data from buffer and write it to the lease hardware
					if (buffer_read_ready_i) begin

						// rotate fifo to next entry
						buffer_read_ack_reg = 1'b1;

						case(lease_initialization_base_reg)

							// write to configuration registers
							2'b00: begin
								if (n_transfer_reg < LEASE_CONFIG_ENTRIES) begin
									config_wren_reg = 1'b1;
									config_addr_reg = n_transfer_reg[BW_CONFIG_ADDR-1:0];
									config_data_reg = buffer_data_i[`LEASE_CONFIG_VAL_BW-1:0];
								end
							end

							// write to llt - reference address values
							2'b01: begin
								if (lease_initialization_counter_reg < LEASE_LLT_ENTRIES) begin
									llt_wren_ref_addr_reg = 1'b1;
									llt_addr_reg = lease_initialization_counter_reg;
									//llt_ref_addr_reg = buffer_data_i[`LEASE_REF_ADDR_BW-1:0];
									llt_ref_addr_reg = buffer_data_i[`LEASE_REF_ADDR_BW+1:2]; 		// shift to make it a word address
									lease_initialization_counter_reg = lease_initialization_counter_reg + 1'b1;
								end
							end

							// write to llt - lease values
							2'b10: begin
								if (lease_initialization_counter_reg < LEASE_LLT_ENTRIES) begin
									llt_wren_lease_reg = 1'b1;
									llt_addr_reg = lease_initialization_counter_reg;
									llt_ref_lease_reg = buffer_data_i[`LEASE_REGISTER_BW-1:0];
									lease_initialization_counter_reg = lease_initialization_counter_reg + 1'b1;
								end
							end

							default:; 	// set no write signals
						endcase


						// manage the transfers here
						// if not yet done transfering data then just keep in this logical block
						if (n_transfer_reg != {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg = n_transfer_reg + 1'b1;
						end

						// done transfering the block so determine next action
						else begin

							// clear for next iteration
							n_transfer_reg = 'b0;

							case(lease_initialization_base_reg)

								2'b00: begin
									lease_initialization_base_reg = lease_initialization_base_reg + 1'b1;
									state_reg = ST_REQUEST_LLT_DATA;
									//core_done_o_reg = 1'b1;
									//state_reg = ST_NORMAL;
								end

								2'b01: begin
									// if counter rolls over then all data transfered
									// if not then pull next block for table
									if (lease_initialization_counter_reg == 'b0) begin
										lease_initialization_base_reg = lease_initialization_base_reg + 1'b1;
										state_reg = ST_REQUEST_LLT_DATA;
									end
									else begin
										state_reg = ST_REQUEST_LLT_DATA;
									end
								end

								2'b10: begin
									// if counter rolls over then all data transfered
									// if not then pull next block for table
									if (lease_initialization_counter_reg == 'b0) begin
										core_done_o_reg = 1'b1;
										state_reg = ST_NORMAL;
									end
									else begin
										state_reg = ST_REQUEST_LLT_DATA;
									end
								end

							endcase
						end
					end
				end


				// after populating lease hardware proceed to normal sequencing
				ST_NORMAL: begin
					// only execute if there is a new request or returning from servicing a miss
					if (core_req_i | req_flag_reg) begin

						// hit condition
						// ------------------------------------
						if (cam_hit_i) begin
							
							// mux in reference information based on previous actions
							if (req_flag_reg) begin 			// return from miss hit
								cache_mem_rw_reg = rw_flag_reg;
								req_flag_reg = 1'b0;
							end
							else begin 							// initial reference hit
								cache_mem_rw_reg = core_rw_i;
							end

							flag_hit_reg = 1'b1;
							cache_mem_add_reg = {cam_addr_i, core_word_i};		// set cache address

							cache_mem_data_reg = core_data_i;					// redundant if cache read
							core_done_o_reg = 1'b1; 							// unstall processor core


							// set dirty bit if write to the cache line
							if (cache_mem_rw_reg) begin
								dirtybits_reg[cam_addr_i] = 1'b1;
							end

						end

						// miss condition
						// ------------------------------------
						else begin
							// set performance counter flag
							flag_miss_reg = 1'b1;

							// issue a request for a new block
							req_flag_reg = 1'b1; 				// so that upon handling the miss the cache serves the core
							rw_flag_reg = core_rw_i; 			// register request type (ld/st)
							core_done_o_reg = 1'b0;				// stall processor

							// move to read block request state
							state_reg = ST_WAIT_READY;

						end // if miss

					end
				end


				ST_WAIT_READY: begin
					// only proceed if there is no remaining memory operation to complete
					if ((mem_ready_i) & (writeback_flag_reg == 1'b0)) begin

						// request the target block
						mem_req_reg = 1'b1;
						mem_req_block_reg = 1'b1;
						mem_addr_reg = {core_tag_i, {`BW_BLOCK{1'b0}} };		// mask off word to specify block starting address
						mem_rw_reg = 1'b0;

						// get replacement addr in next stage
						state_reg = ST_WAIT_REPLACEMENT_GEN;

					end
				end

				ST_WAIT_REPLACEMENT_GEN: begin
					// check if the lease controller generated an address
					if (lease_replacement_done) begin
						replacement_ptr_reg = lease_replacement_addr;

						// check writeback condition
						if (dirtybits_reg[replacement_ptr_reg] != 1'b1) begin
							state_reg = ST_READ_BUFFER;
						end

						// dirty bit set so write out line
						else begin
							flag_writeback_reg = 1'b1;
							cam_addr_reg = replacement_ptr_reg; 	// get tag next cycle (ST_WRITE_BUFFER)
							cache_mem_rw_reg = 1'b0;
							cache_mem_add_reg = {replacement_ptr_reg, {`BW_BLOCK{1'b0}} };
							state_reg = ST_WRITE_BUFFER;
						end

					end
				end


				ST_WRITE_BUFFER: begin
					// if buffer ready to accept data then send out
					if (buffer_write_ready_i) begin

						buffer_write_ack_reg = 1'b1; 			// write to buffer
						buffer_data_reg = cache_mem_data_i;

						// if first transfer set writeback flag, starting address, etc...
						if (n_transfer_reg == 'b0) begin
							writeback_flag_reg = 1'b1;
							add_writeback_reg = {cam_tag_i, {`BW_BLOCK{1'b0}} };
						end													
						
						// transfer complete
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg = 'b0;
							dirtybits_reg[replacement_ptr_reg] = 1'b0; 	// clear dirty bit
							state_reg = ST_READ_BUFFER; 				// read in new block and write it to cache
						end
						else begin
							n_transfer_reg = n_transfer_reg + 1'b1;
							cache_mem_add_reg = {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						end
					end
				end

				ST_READ_BUFFER: begin
					// only read if there is content in the buffer
					if (buffer_read_ready_i) begin
						buffer_read_ack_reg = 1'b1;		// increment buffer pointer for next word

						// write the word to cache memory at the replacement position
						cache_mem_rw_reg = 1'b1;
						cache_mem_add_reg = {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						cache_mem_data_reg = buffer_data_i;

						// if last word then write block to cam and return to "normal condition"
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg = 'b0;
							cam_wren_reg = 1'b1; 							// tag set by core
							cam_addr_reg = replacement_ptr_reg; 	// add set by controller
							state_reg = ST_NORMAL;
						end
						else begin
							n_transfer_reg = n_transfer_reg + 1'b1;
						end
					end
				end


			endcase

			// cache writeback logic block
			// --------------------------------------------------------------------
			if (writeback_flag_reg & mem_ready_i) begin
				writeback_flag_reg = 1'b0; 					// prevent followup request
				mem_req_reg = 1'b1; 						// request a block write
				mem_req_block_reg = 1'b1;
				mem_rw_reg = 1'b1;
				mem_addr_reg = add_writeback_reg;
			end

		end // if(en_i)

	end // if not in reset

end // synch. block

endmodule