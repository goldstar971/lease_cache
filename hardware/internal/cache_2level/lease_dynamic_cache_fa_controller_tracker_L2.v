module lease_dynamic_cache_fa_controller_tracker_L2 #(
	parameter POLICY 				= "",
	parameter INIT_DONE 			= 1'b1,
	parameter CACHE_BLOCK_CAPACITY 	= 0
)(

	input 								clock_i,
	input 								clock_lease_i,
	input 								resetn_i,
	input 								enable_i,
	input 	[31:0] 						phase_i,

	// L1/hart signals
	input 								L1_req_i,
	input 	[`BW_WORD_ADDR-1:0]			L1_ref_addr_i,
	input 								L1_rw_i,
	input 	[BW_TAG-1:0]				L1_tag_i,
	input 	[`BW_BLOCK-1:0]	 			L1_word_i,
	input 	[31:0]						L1_data_i,
	input 								L2_ready_read_i,
	input                              L2_ready_write_i,
	output 								L2_read_ack_o,
	output								L1_done_o,
	output 								L1_hit_o,
	output 	[31:0]						L1_data_o, 			// data routed directly from cache controller (on non-cacheable operation)
	output                              L1_valid_o,
	


	// tag memory signals
	input 								cam_hit_i,
	output 								cam_wren_o,
	output 								cam_rmen_o,
	input 	[BW_TAG-1:0]				cam_tag_i, 				// tag <- addr
	input 	[BW_CACHE_ADDR_PART-1:0] 	cam_addr_i, 			// addr <- tag
	output 	[BW_CACHE_ADDR_PART-1:0] 	cam_addr_o, 			// tag -> addr

	// cache memory signals
	input 	[31:0]						cache_mem_data_i,
	output 	[BW_CACHE_ADDR_FULL-1:0]	cache_mem_add_o,
	output 								cache_mem_rw_o,
	output 	[31:0]						cache_mem_data_o,

	// data buffer signals
	input 								buffer_read_ready_i, 	// mem -> cache buffer signals
	input  	[31:0]						buffer_data_i,
	output 								buffer_read_ack_o,
	input 								buffer_write_ready_i, 	// mem <- cache buffer signals
	output	[31:0] 						buffer_data_o,
	output 								buffer_write_ack_o,


	// command ports
	input 								mem_ready_i,
	output 								mem_req_o, 				// must be at least one item in the buffer before driving high
	output 								mem_req_block_o,
	output 								mem_rw_o,
	output 	[`BW_WORD_ADDR-1:0]			mem_addr_o,

	// performance ports
	output 								flag_hit_o,
	output 								flag_miss_o,
	output 								flag_writeback_o,
	output 								flag_expired_o,
	output 								flag_expired_multi_o,
	output 								flag_defaulted_o,
	output 								flag_swap_o,


	// line tracking ports
	output [CACHE_BLOCK_CAPACITY-1:0]	flag_expired_0_o,
	output [CACHE_BLOCK_CAPACITY-1:0]	flag_expired_1_o,
	output [CACHE_BLOCK_CAPACITY-1:0]	flag_expired_2_o
);

// parameterizations
// ---------------------------------------------------------------------------------------------------------------------
localparam ST_NORMAL 				= 4'b0000; 		// check for hit/miss
localparam ST_WAIT_READY 			= 4'b0001; 		// upon miss request a block be brought in - if ext. mem not ready then idle
localparam ST_WRITE_BUFFER 			= 4'b0010; 		// read in block from cache and write to buffer
localparam ST_READ_BUFFER  			= 4'b0011; 		// read in from buffer and write block to cache
localparam ST_WAIT_REPLACEMENT_GEN 	= 4'b0100;
localparam ST_REQUEST_LLT_DATA 		= 4'b0101; 		// lease cache specific states
localparam ST_TRANSFER_LLT_DATA 	= 4'b0110;
localparam ST_NO_SWAP_READ 			= 4'b0111;
localparam ST_UPDATE_REQUEST_LLT 	= 4'b1000;
localparam ST_UPDATE_SERVICE_LLT 	= 4'b1001;
localparam ST_STALL 				= 4'b1010;
localparam ST_READ_FROM_L1_BUFFER =4'b1011;
localparam ST_WRITE_TO_L1_BUFFER =4'b1100;
localparam ST_TAG_WAIT        = 4'b1101;

localparam BW_CACHE_ADDR_PART 		= `CLOG2(CACHE_BLOCK_CAPACITY); 
localparam BW_CACHE_ADDR_FULL 		= BW_CACHE_ADDR_PART + `BW_BLOCK; 				
localparam BW_TAG 					= `BW_WORD_ADDR - `BW_BLOCK; 

localparam BW_ENTRIES 				= `CLOG2(`LEASE_LLT_ENTRIES); 	// entries per table
localparam BW_ADDR_SPACE 			= BW_ENTRIES + 2; 				// four tables total (address, lease0, lease1, lease0_probability)


// internal signals - registered ports
// ---------------------------------------------------------------------------------------------------------------------

// L1/hart
reg 		cache_ready_reg;
reg [31:0]	L1_data_reg;

assign L1_done_o = cache_ready_reg;
assign L1_data_o = L1_data_reg;

// tag memory
reg 							cam_wren_reg;
reg [BW_CACHE_ADDR_PART-1:0]	cam_addr_reg;

assign cam_wren_o = cam_wren_reg;
assign cam_rmen_o = 1'b0; 				// not used but allocated for
assign cam_addr_o = cam_addr_reg;
// cache memory
reg 							cache_mem_rw_reg;
reg [BW_CACHE_ADDR_FULL-1:0] 	cache_mem_add_reg;
reg [31:0] 						cache_mem_data_reg;

assign cache_mem_rw_o 	= cache_mem_rw_reg;
assign cache_mem_add_o 	= cache_mem_add_reg;
assign cache_mem_data_o = cache_mem_data_reg;

// data buffer
reg 					buffer_read_ack_reg,
						buffer_write_ack_reg;
reg [31:0]				buffer_data_reg;
reg                     data_valid_reg;
reg                     L2_read_ack_reg;

assign buffer_read_ack_o 	= buffer_read_ack_reg;
assign buffer_write_ack_o 	= buffer_write_ack_reg;
assign buffer_data_o 		= buffer_data_reg;
assign L1_valid_o = data_valid_reg;
assign L2_read_ack_o=L2_read_ack_reg;

// command out ports
reg 					mem_req_reg, 			// must be at least one item in the buffer before driving high
						mem_req_block_reg,
						mem_rw_reg;
reg [`BW_WORD_ADDR-1:0]	mem_addr_reg;

assign mem_req_o 		= mem_req_reg;
assign mem_req_block_o 	= mem_req_block_reg;
assign mem_rw_o 		= mem_rw_reg;
assign mem_addr_o 		= mem_addr_reg;

// performance controller
reg 					flag_hit_reg,
						flag_miss_reg,
						flag_writeback_reg;

assign flag_hit_o		= flag_hit_reg;
assign flag_miss_o 		= flag_miss_reg;
assign flag_writeback_o = flag_writeback_reg;
assign flag_swap_o 		= replacement_swap_reg;

// replacement logic
// ---------------------------------------------------------------------------------------------------------------------
reg 					llt_wren_reg;
reg 					con_wren_reg;
reg [BW_ADDR_SPACE-1:0] llt_addr_reg;
reg [31:0]				llt_data_reg;

wire 							replacement_done;
wire [BW_CACHE_ADDR_PART-1:0] 	replacement_addr;
wire 							replacement_swap; 		// 1: missed item should be cache'd
reg 							replacement_swap_reg; 	// saved version of above


`LEASE_POLICY_CONTROLLER_INST #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	)
) lease_policy_controller_inst(
	// system generics
	.clock_i 				(clock_lease_i 			), 	// clock for all submodules (prob. cntrl uses falling edge)
	.resetn_i 				(resetn_i 				),

	// lease lookup table and config register
	// ports directly routed to LLT from cache controller
	.con_wren_i 			(con_wren_reg 			), 	// high when writing to configuration registers
	.llt_wren_i 			(llt_wren_reg 			), 	// high when writing to lease lookup table
	.llt_addr_i 			(llt_addr_reg			), 	// also used to write configurations (assumed that config reg addr space < llt addr space)
	.llt_data_i 			(llt_data_reg 			), 	// value to write to llt_addr_i
	.llt_search_addr_i 		(L1_ref_addr_i 		), 	// address from L1 to table search for

	// controller - lease ports
	.cache_addr_i 			(cam_addr_i 			), 	// translated cache address - so that lease controller can update lease value
	.hit_i 					(flag_hit_reg 			), 	// when high, adjust lease register values (strobe trigger)
	.miss_i 				(flag_miss_reg 			), 	// when high, generate a replacement address (strobe trigger)
	.done_o 				(replacement_done 		), 	// logic high when controller generates replacement addr
	.addr_o 				(replacement_addr 		),
	.swap_o 				(replacement_swap		), 	// logic high if the missed block has non-zero lease (i.e. should be brought into cache)
	.expired_o 				(flag_expired_o 		), 	// logic high if the replaced cache addr.'s lease expired
	.expired_multi_o 		(flag_expired_multi_o 	),
	.default_o 				(flag_defaulted_o 		), 	// logic high if upon a hit the line is renewed with the default lease value

	.expired_flags_0_o 		(flag_expired_0_o 		),
	.expired_flags_1_o 		(flag_expired_1_o 		),
	.expired_flags_2_o 		(flag_expired_2_o 		)
);



// cache controller logic
// ---------------------------------------------------------------------------------------------------------------------
reg 	[3:0] 						state_reg; 					// controller state machine
reg 	[`BW_BLOCK:0]				n_transfer_reg;				// number of words read/written
reg 	[CACHE_BLOCK_CAPACITY-1:0]	dirtybits_reg;				// dirty bit set on store (cache write by processor)

reg 	[`BW_WORD_ADDR-1:0]			add_writeback_reg; 			// registered replacement address (to prevent tag overwrite issue)
reg 	[BW_CACHE_ADDR_PART-1:0]	replacement_ptr_reg;
reg 								req_flag_reg,  				// status/operation flags
									rw_flag_reg, 
									writeback_flag_reg;

assign L1_hit_o = (L1_req_i | req_flag_reg) ? cam_hit_i : 1'b1; 	// to prevent stall cycle if no request

// lease lookup table signals
reg 							latch_swap_reg; 				// when high tells the controller to latch swap value on next cycle


// scope lease subsystem
// ----------------------------------------------------------------------------------------------------------

// config registers
reg 	[BW_ENTRIES:0]		header_table_size_reg; 	 		// max size is the hardware table size
reg 	[`BW_WORD_ADDR-1:0] header_lease_base_addr_reg; 	// beginning of phase0 subsection

wire 	[BW_ENTRIES+1:0] 	llt_section_entries_bus;
assign 	llt_section_entries_bus = (header_table_size_reg << 2'b10) - 1'b1;

// phase load interrupt
reg 	[7:0]				phase_reg;
wire 						phase_interrupt;
assign phase_interrupt 	= 	(phase_i[31] & (phase_reg != phase_i[7:0])) ? 1'b1 : 1'b0;

// llt population
reg 	[BW_ENTRIES+1:0]	llt_counter_reg; 				// {2'bXY, BW_ENTRIES-1}
															// XY = 00 : ref_addr
															// XY = 01 : lease_primary
															// XY = 10 : lease_secondary
															// XY = 11 : lease_primary_percentage


// phase_addr pointer circuit
wire 	[`BW_WORD_ADDR-1:0] phase_addr_ptr_bus;

assign phase_addr_ptr_bus = header_lease_base_addr_reg + ({phase_i[7:0],{(BW_ADDR_SPACE){1'b0}}});


// cache controller
// ----------------------------------------------------------------------------------------------------------
always @(posedge clock_i) begin

	// reset state
	// ----------------------------------------------------
	if (!resetn_i) begin

		// internal control
		state_reg = 			ST_REQUEST_LLT_DATA;
		n_transfer_reg = 		'b0; 
		dirtybits_reg = 		'b0;
		add_writeback_reg = 	'b0;
		req_flag_reg =  		1'b0; 
		rw_flag_reg =  			1'b0; 
		writeback_flag_reg =  	1'b0;
		replacement_ptr_reg = 	{BW_CACHE_ADDR_PART{1'b1}}; 	// start at max so first replacement rolls over into first cache line location 

		// L1/L2
	
		cache_ready_reg = 		INIT_DONE;
		L1_data_reg = 		'b0;
		data_valid_reg =1'b0;
		L2_read_ack_reg=1'b0;

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

		// lease cache signals
		con_wren_reg 			= 	1'b0;
		llt_wren_reg 			= 	1'b0;
		llt_addr_reg 			= 	'b0;
		llt_data_reg 			= 	'b0;
		replacement_swap_reg 	= 	1'b0;
		latch_swap_reg 			= 	1'b0;

		// scope leasing
		header_table_size_reg 		<= 'b0;
		header_lease_base_addr_reg 	<= 'b0;
		phase_reg 					<= 8'hFF;
		llt_counter_reg 			<= 'b0;

	end

	// active sequencing
	// ----------------------------------------------------------------------------
	else begin

		// default control signals
		cam_wren_reg 			= 1'b0;
		cache_mem_rw_reg 		= 1'b0;

		buffer_read_ack_reg 	= 1'b0;
		buffer_write_ack_reg 	= 1'b0;

		mem_req_reg 			= 1'b0;
		mem_req_block_reg 		= 1'b0;
		mem_rw_reg 				= 1'b0;

		flag_hit_reg 			= 1'b0;
		flag_miss_reg 			= 1'b0;
		flag_writeback_reg 		= 1'b0;

		// lease cache defaults
		llt_wren_reg 			= 1'b0;
		con_wren_reg 			= 1'b0;

		data_valid_reg =1'b0;
		L2_read_ack_reg=1'b0;


		// only sequence if enabled
		if(enable_i) begin

			// cache state sequencing
			// --------------------------------------------------------------------
			case(state_reg)

				// lease cache table population states
				ST_REQUEST_LLT_DATA: begin

					// wait until controller ready for data
					if (mem_ready_i) begin

						// request full block of data
						mem_req_reg 		= 1'b1;
						mem_req_block_reg 	= 1'b1;
						mem_rw_reg 			= 1'b0;
						mem_addr_reg 		= 24'h7FC000;
						state_reg 			= ST_TRANSFER_LLT_DATA;

					end
				end


				ST_TRANSFER_LLT_DATA: begin

					// read out data from buffer and write it to the lease hardware
					if (buffer_read_ready_i) begin

						// rotate fifo to next entry
						buffer_read_ack_reg = 1'b1;

						// write in configuration data
						con_wren_reg = 1'b1;
						llt_addr_reg = n_transfer_reg;
						llt_data_reg = buffer_data_i;


						// populate config registers
						case(n_transfer_reg)
							4'b0001: header_table_size_reg 	 	<= buffer_data_i[BW_ENTRIES:0]; 		// table size
							4'b0010: header_lease_base_addr_reg <= buffer_data_i[`BW_WORD_ADDR-1:0]; 	// phase0 ptr
							default:;
						endcase


						// sequence control
						// -----------------------------------------------------------------
						if (n_transfer_reg != {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg = n_transfer_reg + 1'b1;
						end
						else begin
							n_transfer_reg = 'b0;
							cache_ready_reg = 1'b1;
							state_reg 		= ST_NORMAL;
						end	
					end
				end

				// request updated llt information
				ST_UPDATE_REQUEST_LLT: begin
					if (mem_ready_i) begin
						// request data
						mem_req_reg 		= 1'b1; 									// request flag
						mem_req_block_reg 	= 1'b1; 									// request block
						mem_rw_reg 			= 1'b0; 									// request a read
						mem_addr_reg 		= phase_addr_ptr_bus + llt_counter_reg; 	// always points to first element of block
						state_reg 			<= ST_UPDATE_SERVICE_LLT;
					end
				end



				ST_UPDATE_SERVICE_LLT: begin

					// read out data from buffer and write it to the lease hardware
					if (buffer_read_ready_i) begin

						// rotate fifo to next entry
						buffer_read_ack_reg = 1'b1;

						// write in llt data
						llt_wren_reg = 1'b1;
						llt_addr_reg = llt_counter_reg;
						llt_data_reg = buffer_data_i;


						// sequence control
						// -----------------------------------------------------------------

						// if done with importing 
						//if (llt_counter_reg == 4'b1111) begin
						if (llt_counter_reg == llt_section_entries_bus) begin
							llt_counter_reg <= 'b0;
							n_transfer_reg 	<= 'b0;
							state_reg 		<= ST_NORMAL;
							// if there was no buffered request unstall the L1
							if (!req_flag_reg) cache_ready_reg = 1'b1;
						end

						else begin

							// increment counter
							llt_counter_reg <= llt_counter_reg + 1'b1;

							// check for end of block
							if (n_transfer_reg != {1'b0,{`BW_BLOCK{1'b1}}}) begin
								n_transfer_reg 	= n_transfer_reg + 1'b1;
							end
							else begin
								n_transfer_reg 	= 'b0;
								state_reg 		<= ST_UPDATE_REQUEST_LLT;
							end
						end
					end
				end

				ST_STALL: begin
				end

				// --------------------------------------------------------------------------------------------------------------------------------
				ST_NORMAL: begin

					// if there is a new phase set then populate the llt
					if (phase_interrupt) begin

						// stall L1 until done populating table
						cache_ready_reg 	= 1'b0;

						if (L1_req_i) begin
							req_flag_reg 	= 1'b1; 				// so that upon handling the miss the cache serves the L1
							rw_flag_reg 	= L1_rw_i; 			// register request type (ld/st)
						end

						// switch to population sequence
						state_reg  				<=  ST_UPDATE_REQUEST_LLT;
						llt_counter_reg 		<= 'b0;
						phase_reg 				<= phase_i[7:0];

					end

					// only execute if there is a new request or returning from servicing a miss
					else if (L1_req_i | req_flag_reg) begin
						cache_ready_reg = 1'b0;	// stall processor L1
						// hit condition
						// ------------------------------------
						if (cam_hit_i) begin
							
							// mux in reference information based on previous actions
							if (!req_flag_reg) begin 									// return from miss hit
								 rw_flag_reg=L1_rw_i;                             //if it is an initial hit, then this needs to be stored
							end
							else begin 													// initial reference hit
								req_flag_reg 		= 1'b0;
							end
						
							if(rw_flag_reg)begin
								state_reg <= ST_READ_FROM_L1_BUFFER;
								dirtybits_reg[cam_addr_i] = 1'b1; 	// set dirty bit if writing back cache block from L1
							end
							else begin
								state_reg <= ST_WRITE_TO_L1_BUFFER;
							end

							n_transfer_reg          ='b0;                  
							replacement_swap_reg 	= 1'b1; 							// swap indicate item is in cache/cacheable
							flag_hit_reg 			= 1'b1;								//signal there was a hit
							
						end

						// miss condition
						// ------------------------------------
						else begin
							// set performance counter flag
							flag_miss_reg = 1'b1;

							// register inputs and flag for reassessment after servicing miss
							// not need to service a hit if L1 write back after servicing the miss
							rw_flag_reg 	= L1_rw_i; 			// register request type (ld/st)
							req_flag_reg 	= (rw_flag_req) ? 1'b0: 1'b1; 				
							
											// stall processor
							// must wait one cycle to register the swap flag
							latch_swap_reg 	= 1'b1;

							// move to read block request state
							state_reg 		= ST_WAIT_READY;

						end // if miss

					end
				end

				ST_WRITE_TO_L1_BUFFER: begin 
					if(L2_ready_write_i)begin
						cache_mem_add_reg 	= {cam_addr_i, n_transfer_reg[`BW_BLOCK-1:0]};
						data_valid_reg          = 1'b1;//signal that data is valid so rx buffer starts reading in values from L2 cache
						// transfer complete
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg 		= 'b0;
							
							state_reg 			= ST_NORMAL; 			// read in new block and write it to cache
							cache_ready_reg = 1'b1; //unstall processor
						end
						else begin
							n_transfer_reg 		= n_transfer_reg + 1'b1;
							
						end
					end
				end
				ST_READ_FROM_L1_BUFFER: begin 
					if(L2_ready_read_i)begin
					//only proceed if a data value has been written to the buffer
						// transfer complete
							L2_read_ack_reg=1'b1;
						cache_mem_rw_reg 	= 1'b1;
						cache_mem_add_reg 	= {cam_addr_i, n_transfer_reg[`BW_BLOCK-1:0]};
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg 		= 'b0;
							state_reg 			= ST_NORMAL; 			// read in new block and write it to cache
							cache_ready_reg = 1'b1; //unstall processor
						end
						else begin
						
							n_transfer_reg 		= n_transfer_reg + 1'b1;
						end
					end
				end


				ST_WAIT_READY: begin
					// latch the swap flag to determine sequencing (if miss item should be cached)
					if (latch_swap_reg) begin
						latch_swap_reg = 1'b0;
						replacement_swap_reg = replacement_swap; 
					end

					// only proceed if there is no remaining memory operation to complete
					if ((mem_ready_i)) begin

						// normal condition - bring cache the item
						if (replacement_swap_reg) begin
							//if read, request block from memory
							if(!rw_flag_reg) begin
								// request the target block
								mem_req_reg 		= 1'b1;
								mem_req_block_reg 	= 1'b1;
								mem_addr_reg 		= {L1_tag_i, {`BW_BLOCK{1'b0}} };
								mem_rw_reg 			= 1'b0;
							end
							// get replacement addr in next stage
							state_reg 			= ST_WAIT_REPLACEMENT_GEN;

						end

						// lease only condition - do not cache the item, just service the miss
						else begin
							// clear the L1 request flag so that upon returning without writing/reading entire cache 
							// block the controller doesn't try to reservice the request
							req_flag_reg 		= 1'b0;

							// request the item
							mem_req_reg 		= 1'b1;
							mem_req_block_reg 	= 1'b0;
							mem_addr_reg 		= {L1_tag_i, L1_word_i};
							mem_rw_reg 			= rw_flag_reg;

							if (!rw_flag_reg) begin
								state_reg 				= ST_NO_SWAP_READ;
							end
							else begin
								state_reg 				= ST_NORMAL;
								buffer_write_ack_reg 	= 1'b1; 				// write to buffer
								buffer_data_reg 		= L1_data_i;
								cache_ready_reg 		= 1'b1;
							end
						end
					end
				end

				ST_WAIT_REPLACEMENT_GEN: begin

					// check if the policy controller generated an address
					if (replacement_done) begin
						replacement_ptr_reg = replacement_addr;

						// check writeback condition
						if (dirtybits_reg[replacement_ptr_reg] != 1'b1) begin
							state_reg = ST_READ_BUFFER;
						end

						// dirty bit set so write out line
						else begin
							flag_writeback_reg 	= 1'b1;
							cam_addr_reg 		= replacement_ptr_reg; 	// get tag next cycle (ST_WRITE_BUFFER)
							cache_mem_rw_reg 	= 1'b0;
							cache_mem_add_reg 	= {replacement_ptr_reg, {`BW_BLOCK{1'b0}} };
							state_reg 			= ST_WRITE_BUFFER;
						end

					end
				end


				ST_WRITE_BUFFER: begin
					// if buffer ready to accept data then send out
					if (buffer_write_ready_i) begin

						buffer_write_ack_reg 	= 1'b1; 					// write to buffer
						buffer_data_reg 	 	= cache_mem_data_i;

						// if first transfer set writeback flag, starting address, etc...
						if (n_transfer_reg == 'b0) begin
							writeback_flag_reg 	= 1'b1;
							add_writeback_reg 	= {cam_tag_i, {`BW_BLOCK{1'b0}} };
						end													
						
						// transfer complete
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg 		= 'b0;
							state_reg 			= ST_READ_BUFFER; 			// read in new block and write it to cache
							dirtybits_reg[replacement_ptr_reg] = 1'b0; 		// clear dirty bit
							
						end
						else begin
							n_transfer_reg 		= n_transfer_reg + 1'b1;
							cache_mem_add_reg 	= {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						end
					end
				end

				ST_READ_BUFFER: begin

					//if L1 read from L2
					if(!rw_flag_reg)begin
							// only read if there is content in the buffer
						if (buffer_read_ready_i) begin
							buffer_read_ack_reg = 1'b1;		// increment buffer pointer for next word

						// write the word to cache memory at the replacement position
							cache_mem_rw_reg 	= 1'b1;
							cache_mem_add_reg 	= {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						//if write back from L1, just read from L1 transmit buffer, don't bring in block from memory
							cache_mem_data_reg 	= buffer_data_i;
						
						// if last word then write block to cam and return to "normal condition"
							if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
								n_transfer_reg 	= 'b0;
								cam_wren_reg 	= 1'b1; 							// tag set by L1
								cam_addr_reg 	= replacement_ptr_reg; 	// add set by controller
								state_reg 		= ST_TAG_WAIT;
							end
							else begin
								n_transfer_reg 	= n_transfer_reg + 1'b1;
							end
						end
					end
					//if writeback from L1, grab block from trans memory
					else begin
						if (L2_ready_read_i) begin
							L2_read_ack_reg = 1'b1;	
						// write the word to cache memory at the replacement position
							cache_mem_rw_reg 	= 1'b1;
							cache_mem_add_reg 	= {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						//if write back from L1, just read from L1 transmit buffer, don't bring in block from memory
							cache_mem_data_reg 	= L1_data_i;
						// if last word then write block to cam and return to "normal condition"
							if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
								n_transfer_reg 	= 'b0;
								cam_wren_reg 	= 1'b1; 							// tag set by L1
								cam_addr_reg 	= replacement_ptr_reg; 	// add set by controller
								dirtybits_reg[replacement_ptr_reg] = 1'b1; 		// set dirty bit as block differs from that which is in main memory
								state_reg 		= ST_TAG_WAIT;
								cache_ready_reg=1'b1; //unstall CPU
								//if writeback no need to serve a hit
								req_flag_reg=1'b0;
							end
							else begin
								n_transfer_reg 	= n_transfer_reg + 1'b1;
							end
						end
					end

				end

				ST_NO_SWAP_READ: begin
					if (buffer_read_ready_i) begin

						// pull data from buffer and route to L2
						buffer_read_ack_reg = 1'b1;
						L1_data_reg 		= buffer_data_i;

						// signal done and resume
						cache_ready_reg	 	= 1'b1;
						state_reg 			= ST_NORMAL;
					end
				end
				//tag takes a cycle so delay a cycle.
				ST_TAG_WAIT: begin 
					state_reg = ST_NORMAL;
				end


			endcase

			// cache writeback logic block
			// --------------------------------------------------------------------
			if (writeback_flag_reg & mem_ready_i) begin
				writeback_flag_reg 	= 1'b0; 					// prevent followup request
				mem_req_reg 		= 1'b1; 						// request a block write
				mem_req_block_reg 	= 1'b1;
				mem_rw_reg 			= 1'b1;
				mem_addr_reg 		= add_writeback_reg;
			end

		end // if(en_i)

	end // if not in reset

end // synch. block

endmodule