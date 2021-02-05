`include "../../../../include/cache.h"
`include "../../../../include/utilities.h"

module cache_fa_fifo_replacement(

	// system
	input 	[1:0]					clock_bus_i, 		// clock[0] = 180deg (controller clock)
														// clock[1] = 270deg (write clock)
	input 							resetn_i, 			
	input 	[31:0]					comm_i, 			// generic comm port in
	output 	[31:0]					comm_o,				// specific comm port out

	// core/hart
	input 							core_req_i,  		// 1: valid request 
	input 	[`BW_WORD_ADDR-1:0] 	core_ref_add_i, 	// address of the requesting instruction (only used in lease data caches)
	input 							core_rw_i, 			// 1: write, 0: read
	input 	[`BW_WORD_ADDR-1:0] 	core_add_i, 		// address of mem. request from core
	input 	[31:0]					core_data_i,
	output 							core_done_o, 		// driven high when a cache operation is serviced
	output 	[31:0]					core_data_o,

	// internal memory controller
	input 							en_i,  				// logic high if mem. controller enables cache
	input 							ready_req_i,  		// buffer signal (1: can accept a request)
	input 							ready_write_i,  	// buffer signal (1: can be written to)
	input 							ready_read_i, 		// buffer signal (1: can be read from)
	input 	[31:0]					data_i,  			// data being read in from buffer (interfaced to external system)
	output 							hit_o, 
	output 							req_o, 
	output 							req_block_o, 
	output 							rw_o, 
	output 							write_o,  			// drive high when writing to buffer
	output 							read_o, 			// drive high when reading from buffer
	output 	[`BW_WORD_ADDR-1:0]		add_o, 				// address of mem. request from cache
	output 	[31:0]					data_o  			// data being written to buffer (interfaced to external system)

);

// parameterizations
// -----------------------------------------------------------------------------------------------

// configurable parameterizations
parameter INIT_DONE = 1'b1; 				// when coming out of reset will not stall core if logic high, 
											// if logic low will stall until out-of-reset operations are complete
parameter CACHE_BLOCK_CAPACITY = 128;

// derived parameterizations - do not overwrite
localparam BW_CACHE_ADDR_PART = `CLOG2(CACHE_BLOCK_CAPACITY);  		// [grp]
localparam BW_CACHE_ADDR_FULL = BW_CACHE_ADDR_PART + `BW_BLOCK;		// [grp|word]			 
localparam BW_TAG = `BW_WORD_ADDR - `BW_BLOCK;  


// internal memories and signals
// -----------------------------------------------------------------------------------------------
wire 	[BW_TAG-1:0] 		req_tag;
wire 	[`BW_BLOCK-1:0]		req_word;

assign req_tag = core_add_i[`BW_WORD_ADDR-1:`BW_BLOCK];	 	// extract tag from core request
assign req_word = core_add_i[`BW_BLOCK-1:0];				// extract word address from core request


// tag lookup and operations
// -----------------------------------------------------------------------------------------------
reg 								rw_cam_reg;
reg 	[BW_CACHE_ADDR_PART-1:0] 	add_cache2cam_reg; 	// address to be written to/looked up
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cam2cache; 		// given a tag, returns the address of that tag in cache
wire 	[BW_TAG-1:0] 				tag_cam2cache;		// given an address, returns the tag stored at that location
wire 								hit_cam; 			// 1: cache lookup hit

tag_memory_fa #(.CACHE_BLOCK_CAPACITY(CACHE_BLOCK_CAPACITY)) cache_tag_lookup_inst (
	.clock_i 		(clock_bus_i[1] 	), 			// write edge
	.resetn_i 		(resetn_i 			), 			// reset active low 		
	.wren_i 		(rw_cam_reg 		), 			// write enable (write new entry)
	.rmen_i 		(1'b0 				), 			// remove enable (invalidate entry) 	
	.tag_i 			(req_tag 			), 			// primary input (tag -> cache location)
	.add_i 			(add_cache2cam_reg 	), 			// add -> tag (part of absolute memory address) - used for replacement
	.add_o 			(add_cam2cache 		), 			// primary output (cache location <- tag)
	.tag_o 			(tag_cam2cache 		),			// tag <- add
	.hit_o 			(hit_cam 			) 			// logic high if lookup hit
);


// cache memory
// -----------------------------------------------------------------------------------------------
reg 								rw_cache_reg; 
reg 	[BW_CACHE_ADDR_FULL-1:0]	add_cache_reg;			// [tag|word]
reg 	[31:0]						data_toCache_reg; 		// hit - from core, miss - from buffer
wire 	[31:0]	 					data_fromCache;

bram_32b_8kB cache_mem(
	.address 		(add_cache_reg 		),
	.clock 			(clock_bus_i[1] 	), 
	.data 			(data_toCache_reg 	),
	.wren 			(rw_cache_reg 		), 
	.q 				(data_fromCache 	)
);

assign core_data_o = data_fromCache;


// performance controller
// -----------------------------------------------------------------------------------------------
reg 								hit_flag_reg,  	// performance metric flags set by controller
									miss_flag_reg, 
									wb_flag_reg;

cache_performance_controller #(
	.CACHE_STRUCTURE	(`ID_CACHE_FULLY_ASSOCIATIVE), 
	.CACHE_REPLACEMENT 	(`ID_CACHE_FIFO		) 
) perf_cont_inst(
	.clock_i 			(clock_bus_i[0] 	),
	.resetn_i 			(resetn_i 			),
	.hit_i 				(hit_flag_reg 		), 		// logic high when there is a cache hit
	.miss_i 			(miss_flag_reg 		), 		// logic high when there is the initial cache miss
	.writeback_i 		(wb_flag_reg 		), 		// logic high when the cache writes a block back to externa memory
	.comm_i 			(comm_i 			), 		// configuration signal
	.comm_o 			(comm_o 			) 		// return value of comm_i
);

// cache controller
// -----------------------------------------------------------------------------------------------
reg 	[1:0] 						state_reg; 				// controller state machine
reg 	[`BW_BLOCK:0]				n_transfer_reg;			// number of words read/written
reg 	[CACHE_BLOCK_CAPACITY-1:0]	dirtybits_reg;			// dirty bit set on store (cache write by processor)

reg 	[`BW_WORD_ADDR-1:0]			add_writeback_reg; 		// registered replacement address (to prevent tag overwrite issue)
reg 	[BW_CACHE_ADDR_PART-1:0]	replacement_ptr_reg;
reg 								req_flag_reg,  			// status/operation flags
									rw_flag_reg, 
									writeback_flag_reg,
									full_flag_reg;

// registered output ports
reg 								core_done_o_reg;
reg 								req_o_reg, 
									req_block_o_reg, 
									rw_o_reg, 
									write_o_reg, 
									read_o_reg;
reg 	[`BW_WORD_ADDR-1:0]			add_o_reg;
reg 	[31:0]						data_o_reg; 
reg 								miss_o_reg;

assign core_done_o = core_done_o_reg;
assign req_o = req_o_reg;
assign req_block_o = req_block_o_reg;
assign rw_o = rw_o_reg;
assign write_o = write_o_reg;
assign read_o = read_o_reg;
assign add_o = add_o_reg;
assign data_o = data_o_reg;
assign hit_o = (core_req_i | req_flag_reg) ? hit_cam : 1'b1; 	// to prevent stall cycle if no request

// cache controller logic
localparam ST_NORMAL 			= 2'b00; 		// check for hit/miss
localparam ST_WAIT_READY 		= 2'b01; 		// upon miss request a block be brought in - if ext. mem not ready then idle
localparam ST_WRITE_BUFFER 		= 2'b10; 		// read in block from cache and write to buffer
localparam ST_READ_BUFFER  		= 2'b11; 		// read in from buffer and write block to cache

always @(posedge clock_bus_i[0]) begin

	// reset state
	// ----------------------------------------------------
	if (!resetn_i) begin

		// internal control signals
		state_reg = ST_NORMAL;
		n_transfer_reg = 'b0; 
		dirtybits_reg = 'b0;
		add_writeback_reg = 'b0;
		hit_flag_reg = 1'b0; 
		miss_flag_reg = 1'b0; 
		wb_flag_reg = 1'b0;
		replacement_ptr_reg = {BW_CACHE_ADDR_PART{1'b1}}; 	// start at max so first replacement rolls over into first cache line location 
		req_flag_reg = 1'b0; 
		rw_flag_reg = 1'b0; 
		full_flag_reg = 1'b0; 
		writeback_flag_reg = 1'b0;

		// port signals
		core_done_o_reg = INIT_DONE;
		req_o_reg = 1'b0; 
		req_block_o_reg = 1'b0; 
		rw_o_reg = 1'b0; 
		write_o_reg = 1'b0; 
		read_o_reg = 1'b0;
		add_o_reg = 'b0; 
		data_o_reg = 'b0;


	end

	// active sequencing
	// ----------------------------------------------------
	else begin

		// default control signals
		rw_cache_reg = 1'b0;
		rw_cam_reg = 1'b0; 
		req_o_reg = 1'b0; 
		req_block_o_reg = 1'b0;
		write_o_reg = 1'b0; 
		read_o_reg = 1'b0;
		hit_flag_reg = 1'b0; 
		miss_flag_reg = 1'b0; 
		wb_flag_reg = 1'b0;

		// cache only sequences if enabled by internal memory controller
		if (en_i) begin

			// cache state sequencing
			// --------------------------------------------
			case(state_reg)

				ST_NORMAL: begin
					// only execute if there is a new request or returning from servicing a miss
					if (core_req_i | req_flag_reg) begin

						// hit condition
						// ------------------------------------
						if (hit_cam) begin
							
							// mux in reference information based on previous actions
							if (req_flag_reg) begin 			// return from miss hit
								rw_cache_reg = rw_flag_reg;
								req_flag_reg = 1'b0;
							end
							else begin 							// initial reference hit
								rw_cache_reg = core_rw_i;
							end

							hit_flag_reg = 1'b1;
							add_cache_reg = {add_cam2cache, req_word};		// set cache address
							data_toCache_reg = core_data_i;					// redundant if cache read
							core_done_o_reg = 1'b1; 						// unstall processor core

							// set dirty bit if write to the cache line
							if (rw_cache_reg) begin
								dirtybits_reg[add_cam2cache] = 1'b1;
							end

						end // if hit

						// miss condition
						// ------------------------------------
						else begin
							// set performance counter flag
							miss_flag_reg = 1'b1;

							// issue a request for a new block
							req_flag_reg = 1'b1; 				// so that upon handling the miss the cache serves the core
							rw_flag_reg = core_rw_i; 			// register request type (ld/st)
							core_done_o_reg = 1'b0;			// stall processor

							// move to read block request state
							state_reg = ST_WAIT_READY;

						end // if miss

					end
				end


				ST_WAIT_READY: begin
					// only proceed if there is no remaining memory operation to complete
					if ((ready_req_i) & (writeback_flag_reg == 1'b0)) begin

						// request the target block
						req_o_reg = 1'b1;
						req_block_o_reg = 1'b1;
						add_o_reg = {req_tag, {`BW_BLOCK{1'b0}} };		// mask off word to specify block starting address
						rw_o_reg = 1'b0;

						// fully utilized condition
						if (full_flag_reg == 1'b1) begin
							replacement_ptr_reg = replacement_ptr_reg + 1'b1; 	// will wrap around on overflow
							
							// check writeback condition
							if (dirtybits_reg[replacement_ptr_reg] != 1'b1) begin
								state_reg = ST_READ_BUFFER;
							end
							// dirty bit set so write out line
							else begin
								wb_flag_reg = 1'b1;
								add_cache2cam_reg = replacement_ptr_reg; 	// get tag next cycle (ST_WRITE_BUFFER)
								rw_cache_reg = 1'b0;
								add_cache_reg = {replacement_ptr_reg, {`BW_BLOCK{1'b0}} };
								state_reg = ST_WRITE_BUFFER;
							end

						end
						// not yet fully utilized condition
						else begin
							// increment pointer to next open cache address
							replacement_ptr_reg = replacement_ptr_reg + 1'b1;

							// if filling in last cache location then set full flag to initiate replacement policy on next miss
							if (replacement_ptr_reg == {BW_CACHE_ADDR_PART{1'b1}}) begin
								full_flag_reg = 1'b1;
							end
							state_reg = ST_READ_BUFFER; 
						end

					end
				end


				ST_WRITE_BUFFER: begin
					// if buffer ready to accept data then send out
					if (ready_write_i) begin

						write_o_reg = 1'b1; 			// write to buffer
						data_o_reg = data_fromCache;

						// if first transfer set writeback flag, starting address, etc...
						if (n_transfer_reg == 'b0) begin
							writeback_flag_reg = 1'b1;
							add_writeback_reg = {tag_cam2cache, {`BW_BLOCK{1'b0}} };
						end													
						
						// transfer complete
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg = 'b0;
							dirtybits_reg[replacement_ptr_reg] = 1'b0; 	// clear dirty bit
							state_reg = ST_READ_BUFFER; 				// read in new block and write it to cache
						end
						else begin
							n_transfer_reg = n_transfer_reg + 1'b1;
							add_cache_reg = {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						end
					end
				end


				ST_READ_BUFFER: begin
					// only read if there is content in the buffer
					if (ready_read_i) begin
						read_o_reg = 1'b1;		// increment buffer pointer for next word

						// write the word to cache memory at the replacement position
						rw_cache_reg = 1'b1;
						add_cache_reg = {replacement_ptr_reg, n_transfer_reg[`BW_BLOCK-1:0]};
						data_toCache_reg = data_i;

						// if last word then write block to cam and return to "normal condition"
						//if (n_transfer_reg == 5'b01111) begin
						if (n_transfer_reg == {1'b0,{`BW_BLOCK{1'b1}}}) begin
							n_transfer_reg = 'b0;
							rw_cam_reg = 1'b1; 							// tag set by core
							add_cache2cam_reg = replacement_ptr_reg; 	// add set by controller
							state_reg = ST_NORMAL;
						end
						else begin
							n_transfer_reg = n_transfer_reg + 1'b1;
						end
					end
				end
			endcase

			// cache writeback logic block
			// --------------------------------------------
			if (writeback_flag_reg & ready_req_i) begin
				req_o_reg = 1'b1;
				req_block_o_reg = 1'b1;
				rw_o_reg = 1'b1;
				add_o_reg = add_writeback_reg;
				writeback_flag_reg = 1'b0;
			end

		end

	end
end

endmodule