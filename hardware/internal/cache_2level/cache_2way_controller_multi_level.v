module cache_2way_controller_multi_level #(
	parameter POLICY 				= "",
	parameter INIT_DONE 			= 1'b1,
	parameter CACHE_BLOCK_CAPACITY 	= 0
)(

	input 								clock_i,
	input 								resetn_i,
	input 								enable_i,

	// core/hart signals
	input 								core_req_i,
	input 								core_rw_i,
	input 	[BW_TAG-1:0]				core_tag_i,
	input 	[BW_GRP-1:0] 				core_grp_i,
	input 	[`BW_BLOCK-1:0]	 			core_word_i,
	input 	[31:0]						core_data_i,
	output  [31:0]                      core_data_o,
	output								core_done_o,
	output 								core_hit_o,

	// tag memory signals
	input 								cam_hit_i,
	output 								cam_wren_o,
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
	output 								mem_req_o, 			// must be at least one item in the buffer before driving high
	output 								mem_rw_o,
	output 	[`BW_WORD_ADDR-1:0]			mem_addr_o,
	`ifdef L2_CACHE_POLICY_DLEASE
	input                               swap_flag_i,
	`endif

	// performance ports
	output 								flag_hit_o,
	output 								flag_miss_o,
	output 								flag_writeback_o
);

// parameterizations
// ---------------------------------------------------------------------------------------------------------------------
localparam ST_NORMAL 				= 3'b000; 		// check for hit/miss
localparam ST_CHECK_L2              = 3'b001;
localparam ST_WAIT_READY 			= 3'b010; 		// upon miss request a block be brought in - if ext. mem not ready then idle
localparam ST_WRITE_BUFFER 			= 3'b011; 		// read in block from cache and write to buffer
localparam ST_READ_BUFFER  			= 3'b100; 		// read in from buffer and write block to cache
localparam ST_WAIT_REPLACEMENT_GEN_1 	= 3'b101;
localparam ST_WAIT_REPLACEMENT_GEN_2    = 3'b110;

localparam BW_CACHE_ADDR_PART 		= `CLOG2(CACHE_BLOCK_CAPACITY); 
localparam BW_CACHE_ADDR_FULL 		= BW_CACHE_ADDR_PART + `BW_BLOCK; 
localparam BW_GRP 					= BW_CACHE_ADDR_PART - 1; 					
localparam BW_TAG 					= `BW_WORD_ADDR - BW_GRP - `BW_BLOCK; 


// internal signals - registered ports
// ---------------------------------------------------------------------------------------------------------------------

// core/hart
reg core_done_o_reg;
reg [31:0] core_data_reg;

assign core_data_o= core_data_reg;
assign core_done_o = core_done_o_reg;

// tag memory
reg 							cam_wren_reg;
reg [BW_CACHE_ADDR_PART-1:0]	cam_addr_reg;

assign cam_wren_o = cam_wren_reg;
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

assign buffer_read_ack_o 	= buffer_read_ack_reg;
assign buffer_write_ack_o 	= buffer_write_ack_reg;
assign buffer_data_o 		= buffer_data_reg;

// command out ports
reg 					mem_req_reg, 			// must be at least one item in the buffer before driving high
						mem_rw_reg;
reg [`BW_WORD_ADDR-1:0]	mem_addr_reg;

assign mem_req_o 		= mem_req_reg;
assign mem_rw_o 		= mem_rw_reg;
assign mem_addr_o 		= mem_addr_reg;

// performance controller
reg 					flag_hit_reg,
						flag_miss_reg,
						flag_writeback_reg;

assign flag_hit_o		= flag_hit_reg;
assign flag_miss_o 		= flag_miss_reg;
assign flag_writeback_o = flag_writeback_reg;


// replacement logic
// ---------------------------------------------------------------------------------------------------------------------
wire 							replacement_done;
wire [BW_CACHE_ADDR_PART-1:0] 	replacement_addr;

generate 

	// FIFO controller
	// -------------------------------------------------------------
	if (POLICY == `ID_CACHE_FIFO) begin

set_cache_fifo_policy_controller #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	),
	.CACHE_SET_SIZE 		(2 						)
) fifo_contr_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.miss_i 				(flag_miss_reg			), 		// pulse trigger to generate a replacement address
	.group_i 				(core_grp_i				), 		// group of the block/reference trying to allocate in cache
	.done_o 				(replacement_done 		), 		// logic high when replacement address generated
	.addr_o 				(replacement_addr		) 		// replacement address generated
);
	end

	// LRU controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_LRU) begin

set_cache_lru_policy_controller #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	),
	.CACHE_SET_SIZE 		(2 						)
) srrip_contr_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.hit_i 					(flag_hit_reg 			),
	.miss_i 				(flag_miss_reg			), 		// pulse trigger to generate a replacement address
	.addr_i 				(cam_addr_i				), 		// on hit update based on set and group, on miss this will provide the group
	.done_o 				(replacement_done 		), 		// logic high when replacement address generated
	.addr_o 				(replacement_addr		) 		// replacement address generated
);
	end

	// PLRU controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_PLRU) begin

set_cache_plru_policy_controller #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	),
	.CACHE_SET_SIZE 		(2 						)
) srrip_contr_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.hit_i 					(flag_hit_reg 			),
	.miss_i 				(flag_miss_reg			), 		// pulse trigger to generate a replacement address
	.addr_i 				(cam_addr_i				), 		// on hit update based on set and group, on miss this will provide the group
	.done_o 				(replacement_done 		), 		// logic high when replacement address generated
	.addr_o 				(replacement_addr		) 		// replacement address generated
);
	end

	// SRRIP controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_SRRIP) begin

set_cache_srrip_policy_controller #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	),
	.CACHE_SET_SIZE 		(2 						)
) srrip_contr_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.hit_i 					(flag_hit_reg 			),
	.miss_i 				(flag_miss_reg			), 		// pulse trigger to generate a replacement address
	.addr_i 				(cam_addr_i				), 		// on hit update based on set and group, on miss this will provide the group
	.done_o 				(replacement_done 		), 		// logic high when replacement address generated
	.addr_o 				(replacement_addr		) 		// replacement address generated
);
	end

endgenerate


// cache controller logic
// ---------------------------------------------------------------------------------------------------------------------
reg 	[2:0] 						state_reg; 					// controller state machine
reg 	[`BW_BLOCK:0]				n_transfer_reg;				// number of words read/written
reg 	[CACHE_BLOCK_CAPACITY-1:0]	dirtybits_reg;				// dirty bit set on store (cache write by processor)

reg 	[`BW_WORD_ADDR-1:0]			add_writeback_reg; 			// registered replacement address (to prevent tag overwrite issue)
reg 	[BW_CACHE_ADDR_PART-1:0]	replacement_ptr_reg;
reg 								req_flag_reg,  				// status/operation flags
									rw_flag_reg, 
									writeback_flag_reg;

assign core_hit_o = (core_req_i | req_flag_reg) ? cam_hit_i : 1'b1; 	// to prevent stall cycle if no request

always @(posedge clock_i) begin

	// reset state
	// ----------------------------------------------------
	if (!resetn_i) begin

		// internal control
		state_reg = 			ST_NORMAL;
		n_transfer_reg = 		'b0; 
		dirtybits_reg = 		'b0;
		add_writeback_reg = 	'b0;
		req_flag_reg =  		1'b0; 
		rw_flag_reg =  			1'b0; 
		writeback_flag_reg =  	1'b0;
		replacement_ptr_reg = 	{BW_CACHE_ADDR_PART{1'b1}}; 	// start at max so first replacement rolls over into first cache line location 

		// core/hart
		core_done_o_reg = 		INIT_DONE;

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
		mem_rw_reg =  			1'b0;
		mem_addr_reg =  		'b0;

		// performance flags
		flag_hit_reg = 			1'b0;
		flag_miss_reg = 		1'b0;
		flag_writeback_reg = 	1'b0;

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
		mem_rw_reg 				= 1'b0;

		flag_hit_reg 			= 1'b0;
		flag_miss_reg 			= 1'b0;
		flag_writeback_reg 		= 1'b0;

		// only sequence if enabled
		if(enable_i) begin

			// cache state sequencing
			// --------------------------------------------------------------------
			case(state_reg)

				ST_NORMAL: begin
					// only execute if there is a new request or returning from servicing a miss
					if (core_req_i | req_flag_reg) begin

						// hit condition
						// ------------------------------------
						if (cam_hit_i) begin
							
							// mux in reference information based on previous actions
							if (req_flag_reg) begin 									// return from miss hit
								cache_mem_rw_reg 	= rw_flag_reg;
								req_flag_reg 		= 1'b0;
							end
							else begin 													// initial reference hit
								cache_mem_rw_reg 	= core_rw_i;
							end

							flag_hit_reg 			= 1'b1;
							cache_mem_add_reg 		= {cam_addr_i, core_word_i};		// set cache address
							cache_mem_data_reg 		= core_data_i;						// redundant if cache read
							core_done_o_reg 		= 1'b1; 							// unstall processor core


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

							// register inputs and flag for reassessment after servicing miss
							req_flag_reg 	= 1'b1; 				// so that upon handling the miss the cache serves the core
							rw_flag_reg 	= core_rw_i; 			// register request type (ld/st)
							core_done_o_reg = 1'b0;					// stall processor

							// move to read block request state
							state_reg 		= ST_CHECK_L2;

						end // if miss

					end
				end
				//check if hit in L2 
				ST_CHECK_L2: begin
					// request the target block if L2 operations have finished
					if(mem_ready_i)begin
						mem_req_reg =1'b1;
						mem_addr_reg={core_tag_i, core_grp_i, {`BW_BLOCK{1'b0}} };	
						mem_rw_reg 			= 1'b0;
						state_reg =ST_WAIT_REPLACEMENT_GEN_1;
					end
				end
				//tag lookup takes two clock cycles, which means we need this to be two staged,since L2 must stall L1 before another request
				//operation can be made (potential writeback) and it takes three cycles for L2 to raise the stall signal and L1 to see it.
				ST_WAIT_REPLACEMENT_GEN_1: begin
					state_reg =ST_WAIT_REPLACEMENT_GEN_2;
				end
				ST_WAIT_REPLACEMENT_GEN_2: begin
					// check if the ssrip controller generated an address
					//and that all L2 operations have completed
					if (replacement_done & mem_ready_i) begin

						replacement_ptr_reg  	= replacement_addr;

						// check writeback condition
						if (dirtybits_reg[replacement_ptr_reg] != 1'b1) begin
							state_reg 			= ST_READ_BUFFER;
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
					//handle zero lease
					`ifdef L2_CACHE_POLICY_DLEASE
					else if (!swap_flag_i)begin 
						if(rw_flag_reg) begin 
							if (buffer_write_ready_i) begin 
								buffer_write_ack_reg = 1'b1; //signal to buffer to read in data
								buffer_data_reg = core_data_i; //write value from core to buffer
								mem_rw_reg 			= 1'b1; //signal to L2 to read from L1 buffer
								state_reg 		= ST_NORMAL;
								core_done_o_reg= 1'b1; //unstall processor 
							end
						end
						else begin
							if(buffer_read_ready_i)begin
								core_data_reg =buffer_data_i;// write data from buffer to core
								buffer_read_ack_reg=1'b1; //signal buffer that value has been read
								mem_rw_reg=1'b0; //signal to L2 to write from
								state_reg 		= ST_NORMAL;
								core_done_o_reg= 1'b1; //unstall processor 
							end
						end
						
					end
				`endif

				end


				ST_WRITE_BUFFER: begin
					// if buffer ready to accept data then send out
					if (buffer_write_ready_i) begin

						buffer_write_ack_reg 	= 1'b1; 					// write to buffer
						buffer_data_reg 	 	= cache_mem_data_i;

						// if first transfer set writeback flag, starting address, etc...
						if (n_transfer_reg == 'b0) begin
							writeback_flag_reg 	= 1'b1;
							add_writeback_reg 	= {cam_tag_i, core_grp_i, {`BW_BLOCK{1'b0}} };
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

					// only read if there is content in the buffer
					if (buffer_read_ready_i) begin
						buffer_read_ack_reg = 1'b1;		// increment buffer pointer for next word

						// write the word to cache memory at the replacement position
						cache_mem_rw_reg 	= 1'b1;
						cache_mem_add_reg 	= {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						cache_mem_data_reg 	= buffer_data_i;

						// if last word then write block to cam and return to "normal condition"
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg 	= 'b0;
							cam_wren_reg 	= 1'b1; 							// tag set by core
							cam_addr_reg 	= replacement_ptr_reg; 	// add set by controller
							state_reg 		= ST_NORMAL;
						end
						else begin
							n_transfer_reg 	= n_transfer_reg + 1'b1;
						end
					end
				end


			endcase

			// cache writeback logic block
			// --------------------------------------------------------------------
			if (writeback_flag_reg & mem_ready_i) begin
				writeback_flag_reg 	= 1'b0; 					// prevent followup request
				mem_req_reg 		= 1'b1; 						// request a block write
				mem_rw_reg 			= 1'b1;
				mem_addr_reg 		= add_writeback_reg;
			end

		end // if(en_i)

	end // if not in reset

end // synch. block

endmodule