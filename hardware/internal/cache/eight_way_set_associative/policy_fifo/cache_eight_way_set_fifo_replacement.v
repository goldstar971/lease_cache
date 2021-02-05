`include "../../include/cache.h"
`include "../../../include/utilities.h"

// local definitions
`define ST_CACHE_NORMAL 					3'b000 		// check for hit/miss
`define ST_WAIT_READY 						3'b001 		// upon miss request a block be brought in - if ext. mem not ready then idle
`define ST_CACHE_WRITE_BUFFER 				3'b010 		// read in block from cache and write to buffer
`define ST_CACHE_READ_BUFFER 				3'b011 		// read in from buffer and write block to cache
`define ST_WAIT_REPLACE_DONE 				3'b100 		// wait until state machine determines the cache address to replace/write to

module cache_eight_way_set_fifo_replacement(

	// system i/o
	input 		[1:0]							clock_bus_i, 						// clock[0] = 180deg, clock[1] = 270deg
	input 										reset_i,
	input 		[31:0]							comm_i, 							// generic comm port in
	output 		[31:0]							comm_o,								// specific comm port out

	// i/o to/from processor
	input 										core_req_i, core_rw_i,
	input 		[`BW_WORD_ADDR-1:0] 			core_add_i,
	input 		[31:0]							core_data_i,
	output 										core_done_o,
	output 		[31:0]							core_data_o,

	// i/o to/from internal memory controller
	input 										en_i, ready_req_i, ready_write_i, ready_read_i,
	input 		[31:0]							data_i, 
	output 										hit_o, req_o, req_block_o, rw_o, write_o, read_o,
	output 		[`BW_WORD_ADDR-1:0]				add_o,
	output 		[31:0]							data_o 

);

// configurable parameterizations
parameter init_done = 1'b1;
parameter CACHE_BLOCK_CAPACITY = 128;

// derived parameterizations - do not overwrite
localparam BW_CACHE_ADDR_PART = `CLOG2(CACHE_BLOCK_CAPACITY); 
localparam BW_CACHE_ADDR_FULL = BW_CACHE_ADDR_PART + `BW_BLOCK; 
localparam BW_GRP = BW_CACHE_ADDR_PART - 3; 					
localparam BW_TAG = `BW_WORD_ADDR - BW_GRP - `BW_BLOCK; 			

// extract fields from address
wire 	[BW_TAG-1:0] 		req_tag;
wire 	[BW_GRP-1:0]		req_group;
wire 	[`BW_BLOCK-1:0]		req_word;

assign req_tag = core_add_i[`BW_WORD_ADDR-1:BW_GRP+`BW_BLOCK]; 	
assign req_group = core_add_i[BW_GRP+`BW_BLOCK-1:`BW_BLOCK];
assign req_word = core_add_i[`BW_BLOCK-1:0];


// route tag to cam for look up (determine hit/miss)
// tag_i -> add_o : add_o is CL driven so should arrive for controller rising edge
reg 								rw_cam;			// from controller
reg 	[BW_CACHE_ADDR_PART-1:0] 	add_cache2cam;	// [set|group]
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cam2cache;	// [set|group]
wire 	[BW_TAG-1:0] 				tag_cam2cache;
wire 								hit_cam;

tag_memory_8way #(.CACHE_BLOCK_CAPACITY(CACHE_BLOCK_CAPACITY)) tag_mem_inst (	
	.clock_i(clock_bus_i[1]), .reset_i(reset_i), .wren_i(rw_cam),
 	.tag_i(req_tag), .group_i(req_group), .addr_i(add_cache2cam),
	.addr_o(add_cam2cache), .tag_o(tag_cam2cache),
	.hit_o(hit_cam)
);

// local cache memory
// ----------------------------------------------------------------------
reg 								rw_cache; 			// set by local controller
reg 	[BW_CACHE_ADDR_FULL-1:0]	add_cache;			// [set|group|word]
reg 	[31:0]						data_toCache; 		// hit - from core, miss - from buffer
wire 	[31:0]	 					data_fromCache;

bram_32b_8kB cache_mem(.address(add_cache),.clock(clock_bus_i[1]), .data(data_toCache),.wren(rw_cache), .q(data_fromCache));
assign core_data_o = data_fromCache;


// local cache controller
// ----------------------------------------------------------------------
reg 	[2:0] 						state; 								// controller state machine
reg 	[4:0]						n_transfer;							// number of words read/written
reg 	[CACHE_BLOCK_CAPACITY-1:0]	n_dirtyBit;							// dirty bit set on store (cache write by processor)
reg 	[`BW_WORD_ADDR-1:0]			add_writeback_reg; 					// registered replacement address (to prevent tag overwrite issue)
reg 	[BW_CACHE_ADDR_PART-1:0]	replacement_ptr;
reg 								hit_flag, miss_flag, wb_flag;
reg 								req_flag, rw_flag, writeback_flag;	// status/op flags
reg 	[(2**BW_GRP)-1:0] 			set_full_bits;
reg 	[2:0]						replacement_bits [0:(2**BW_GRP)-1];

// registered output ports
reg 								core_done_o_reg;
reg 								req_o_reg, req_block_o_reg, rw_o_reg, write_o_reg, read_o_reg;
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

assign hit_o = (core_req_i | req_flag) ? hit_cam : 1'b1; 	// to prevent stall cycle if no request


// cache controller
// -------------------------------------------------------------------------------------------
integer i;
always @(posedge clock_bus_i[0]) begin

	// reset condition
	// ----------------------------------
	if (reset_i != 1'b1) begin

		// internal signals
		state = `ST_CACHE_NORMAL;
		n_transfer = 'b0; n_dirtyBit = 'b0;
		add_writeback_reg = 'b0;
		hit_flag = 1'b0; miss_flag = 1'b0; wb_flag = 1'b0;
		replacement_ptr = 'b0;

		req_flag = 1'b0; rw_flag = 1'b0; writeback_flag = 1'b0;

		// ports signals
		core_done_o_reg = init_done;
		req_o_reg = 1'b0; req_block_o_reg = 1'b0; rw_o_reg = 1'b0; write_o_reg = 1'b0; read_o_reg = 1'b0;
		add_o_reg = 'b0; data_o_reg = 'b0;

		// cam signals
		rw_cam = 1'b0; add_cache2cam = 'b0; 

		// cache memory signals
		rw_cache = 1'b0; add_cache = 'b0; data_toCache = 'b0;

		set_full_bits = 'b0;
		for (i = 0; i < (2**BW_GRP); i = i + 1) replacement_bits[i] = 'b0;

	end

	// active sequencing
	// ----------------------------------
	else begin

		// default signals
		rw_cache = 1'b0; rw_cam = 1'b0; req_o_reg = 1'b0; req_block_o_reg = 1'b0;
		write_o_reg = 1'b0; read_o_reg = 1'b0;
		hit_flag = 1'b0; miss_flag = 1'b0; wb_flag = 1'b0;

		// only execute if cache is enabled - only important in multi-cache/component arch
		if (en_i) begin

			case(state)

				// nominal state - evaluate hit/miss
				`ST_CACHE_NORMAL: begin

					// really should register things here
					if (core_req_i | req_flag) begin

						// hit condition
						// ------------------------------------
						if (hit_cam) begin
							
							// set performance counter flag
							hit_flag = 1'b1;
							
							if (req_flag) begin			// immediate hit condition
								rw_cache = rw_flag;
								req_flag = 1'b0;
							end
							else begin 					// hit after servicing a miss condition
								rw_cache = core_rw_i;
							end

							add_cache = {add_cam2cache, req_word};		// set cache address
							data_toCache = core_data_i;					// redundant if cache read
							core_done_o_reg = 1'b1; 					// unstall processor core

							// set dirty bit if write to the cache line
							if (rw_cache) begin
								n_dirtyBit[add_cam2cache] = 1'b1;
							end

						end // if hit

						// miss condition
						// ------------------------------------
						else begin
							// set performance counter flag
							miss_flag = 1'b1;

							// issue a request for a new block
							req_flag = 1'b1; 				// so that upon handling the miss the cache serves the core
							rw_flag = core_rw_i; 			// register request type (ld/st)
							core_done_o_reg = 1'b0;			// stall processor

							// move to read block request state
							state = `ST_WAIT_READY;

						end // if miss

					end // req_flag

				end // ST_CACHE_NORMAL


				// upon miss wait until memory buffer is ready for request
				// give writebacks priority here if not yet executed
				`ST_WAIT_READY: begin
					if ((ready_req_i) & (writeback_flag == 1'b0)) begin

						// request the target block
						req_o_reg = 1'b1;
						req_block_o_reg = 1'b1;
						add_o_reg = {req_tag, req_group, 4'b0000};	// mask off word to specify block starting address
						rw_o_reg = 1'b0;

						// replacement logic
						if (set_full_bits[req_group]) begin
							// set fully utilized condition 
							// --- FIFO POLICY ---
							replacement_ptr = {replacement_bits[req_group],req_group};
							replacement_bits[req_group] = replacement_bits[req_group] + 1'b1; // point to next set

							// check writeback condition
							if (n_dirtyBit[replacement_ptr] != 1'b1) begin
								state = `ST_CACHE_READ_BUFFER;		// try pulling data from buffer
							end
							// dirty bit set so write out line
							else begin
								wb_flag = 1'b1;
								add_cache2cam = replacement_ptr; 	// get tag 
								rw_cache = 1'b0;
								add_cache = {replacement_ptr, 4'b0000};		// request block from cache
								state = `ST_CACHE_WRITE_BUFFER;
							end

						end
						else begin
							// set not fully utilized 
							replacement_ptr = {replacement_bits[req_group],req_group};
							replacement_bits[req_group] = replacement_bits[req_group] + 1'b1; // point to next set

							// check if set fully utilized
							if (replacement_bits[req_group] == 2'b00) set_full_bits[req_group] = 1'b1;

							//set_full_bits[req_group] = 1'b1;
							state = `ST_CACHE_READ_BUFFER;
						end
					end
				end


				// write out cache line to buffer
				`ST_CACHE_WRITE_BUFFER: begin
					// if writeback not set then do so
					// if buffer ready to accept data then send out
					if (ready_write_i) begin

						// write to fifo
						write_o_reg = 1'b1;
						data_o_reg = data_fromCache;

						// if first transfer set writeback flag, starting address, etc...
						if (n_transfer == 5'b00000) begin
							writeback_flag = 1'b1;
							//add_writeback_reg = {tag_cam2cache, grp_cam2cache, 4'b0000};
							add_writeback_reg = {tag_cam2cache, req_group, 4'b0000};

						end													
						
						// transfer complete
						if (n_transfer == 5'b01111) begin
							n_transfer = 'b0;
							n_dirtyBit[replacement_ptr] = 1'b0;
							// if transfer complete then read out replacement block
							state = `ST_CACHE_READ_BUFFER;
						end
						else begin
							n_transfer = n_transfer + 1'b1;
							add_cache = {replacement_ptr, n_transfer[3:0]};
						end
					end
				end


				// need to read block from buffer
				`ST_CACHE_READ_BUFFER: begin
					
					// only read if there is content in the buffer
					if (ready_read_i) begin
						read_o_reg = 1'b1;		// increment buffer pointer for next word

						// write the word to cache memory at the replacement position
						rw_cache = 1'b1;
						add_cache = {replacement_ptr, n_transfer[3:0]};
						data_toCache = data_i;

						// if last word then write block to cam and return to "normal condition"
						if (n_transfer == 5'b01111) begin
							n_transfer = 'b0;
							rw_cam = 1'b1;
							add_cache2cam = replacement_ptr;

							// tag set by core (continuously driven)
							state = `ST_CACHE_NORMAL;

						end
						else begin
							n_transfer = n_transfer + 1'b1;
						end
					end // end if ready_read

				end // end read_buffer_case

			endcase // state

			// writeback scheduler
			// -------------------------------------------
			if (writeback_flag == 1'b1) begin
				// external memory ready
				if (ready_req_i) begin
					req_o_reg = 1'b1;
					req_block_o_reg = 1'b1;
					rw_o_reg = 1'b1;
					add_o_reg = add_writeback_reg;
					writeback_flag = 1'b0;
				end
			end

		end // if en_i

	end // if ~reset

end // always


// communication controller
// --------------------------------------------------------------------------------
reg 	[31:0]	comm_o_reg;
assign comm_o = comm_o_reg;

reg 	[63:0]	perf_hit_reg, perf_miss_reg, perf_wb_reg, perf_count_reg;

always @(posedge clock_bus_i[0]) begin
	if (reset_i != 1'b1) begin
		comm_o_reg <= 'b0;
		perf_hit_reg <= 'b0; perf_miss_reg = 'b0; perf_wb_reg = 'b0; perf_count_reg = 'b0;
	end
	else begin

		// if enabled then upcount depending on flag thrown by cache
		//if (comm_i[24] == 1'b1) begin
			if (hit_flag) perf_hit_reg <= perf_hit_reg + 1'b1;
			else if (miss_flag) perf_miss_reg <= perf_miss_reg + 1'b1;
			else if (wb_flag) perf_wb_reg <= perf_wb_reg + 1'b1;

			// always increment wall-timer
			perf_count_reg <= perf_count_reg + 1'b1;
		//end

		case (comm_i[3:0])
			// primary outputs
			4'b0000: comm_o_reg <= perf_hit_reg[31:0];
			4'b0001: comm_o_reg <= perf_hit_reg[63:32];
			4'b0010: comm_o_reg <= perf_miss_reg[31:0];
			4'b0011: comm_o_reg <= perf_miss_reg[63:32];
			4'b0100: comm_o_reg <= perf_wb_reg[31:0];
			4'b0101: comm_o_reg <= perf_wb_reg[63:32];

			// replacement statistics
			4'b0110: comm_o_reg <= perf_count_reg[31:0];
			4'b0111: comm_o_reg <= perf_count_reg[63:32];

			4'b1110: comm_o_reg <= `ID_CACHE_FIFO | `ID_CACHE_8WAY_SET_ASSOCIATIVE;

			default comm_o_reg <= 'b0;
		endcase
	end
end

endmodule