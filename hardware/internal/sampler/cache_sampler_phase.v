`include "cache.h"

`define LST_CACHE_NORMAL 					4'b0000 		// check for hit/miss
`define LST_WAIT_READY 						4'b0001 		// upon miss request a block be brought in - if ext. mem not ready then idle
`define LST_CACHE_WRITE_BUFFER 				4'b0010 		// read in block from cache and write to buffer
`define LST_CACHE_READ_BUFFER 				4'b0011 		// read in from buffer and write block to cache
`define LST_WAIT_REPLACE_DONE 				4'b0100 		// wait until state machine determines the cache address to replace/write to
`define LST_REQ_UNIFORM_LEASE 				4'b0101
`define LST_GET_UNIFORM_LEASE 				4'b0110
`define LST_CHECK_POOL 						4'b0111
`define LST_CHECK_WB 						4'b1000

// comm_i info - [23] is clear bit (pulsed)
// phase_i[31] is interrupt bit

module cache_sampler_phase(

	// system i/o
	input 		[1:0]							clock_bus_i, 						// clock[0] = 180deg, clock[1] = 270deg
	input 										reset_i,
	input 		[31:0]							comm_i, 							// generic comm port in
	output 		[31:0]							comm_o,								// specific comm port out
	input 		[31:0] 							phase_i,

	// i/o to/from processor
	input 										core_req_i, core_rw_i,
	input 		[23:0] 							core_add_i,
	input 		[31:0]							core_data_i,
	output 										core_done_o,
	output 		[31:0]							core_data_o,
	input 		[31:0]							pc_i,

	// i/o to/from internal memory controller
	input 										en_i, ready_req_i, ready_write_i, ready_read_i,
	input 		[31:0]							data_i, 
	output 										hit_o, req_o, req_block_o, rw_o, write_o, read_o,
	output 		[23:0]							add_o,
	output 		[31:0]							data_o
);

parameter init_done = 1'b0;

// extract tag and word from address
wire 	[`BW_CACHE_TAG-1:0] 		req_tag;
wire 	[`BW_WORDS_PER_BLOCK-1:0]	req_word;

assign req_tag = core_add_i[23:4];
assign req_word = core_add_i[3:0];


// route tag to cam for look up (determine hit/miss)
// tag_i -> add_o : add_o is CL driven so should arrive for controller rising edge
reg 								rw_cam;			// from controller
reg 	[`BW_CACHE_BLOCKS-1:0] 		add_cache2cam;	// from controller (only need for writebac replacement)

wire 	[`BW_CACHE_BLOCKS-1:0] 		add_cam2cache; 	// [11:4] : tag_in -> add_out
wire 	[`BW_CACHE_TAG-1:0] 		tag_cam2cache;	// add_in -> tag_out
wire 								hit_cam;
memory_cam tag_mem0(
	.clock_i(clock_bus_i[1]), .reset_i(reset_i), .wren_i(rw_cam),
	.tag_i(req_tag), .add_i(add_cache2cam), .add_o(add_cam2cache), .tag_o(tag_cam2cache), .hit_o(hit_cam)
);

// local cache memory
// ----------------------------------------------------------------------
reg 								rw_cache; 			// set by local controller
reg 	[`BW_CACHE_WORDS-1:0]		add_cache;			// {cam_block_add_out, word_in}
reg 	[`BW_CACHE_DATA-1:0]		data_toCache; 		// hit - from core, miss - from buffer
wire 	[`BW_CACHE_DATA-1:0]	 	data_fromCache;




memory_cache data_mem0(
	.clock_i(clock_bus_i[1]), .rw_i(rw_cache), .add_i(add_cache), .data_i(data_toCache), .data_o(data_fromCache) 
);

assign core_data_o = data_fromCache;

// local cache controller
// ----------------------------------------------------------------------
reg 		[3:0] 						state; 								// controller state machine
reg 		[4:0]						n_transfer;							// number of words read/written
reg 		[`N_CACHE_BLOCKS-1:0]		n_dirtyBit;							// dirty bit set on store (cache write by processor)

//reg 									en_replace;							// enables replacement state machine
reg 		[23:0]						add_writeback_reg; 					// registered replacement address (to prevent tag overwrite issue)
//reg 									replacement_done;					// high when state machine done determining repl. loc.
reg 		[`BW_CACHE_BLOCKS-1:0]		replacement_ptr;//, replacement_add;
//reg 		[`BW_CACHE_BLOCKS-1:0]

reg 									hit_flag, miss_flag, wb_flag;//, rep_exp_flag, rep_nexp_flag;

reg 									req_flag, rw_flag, full_flag, writeback_flag;	// status/op flags
//reg 		[63:0]						n_hit_reg, n_miss_reg, n_wb_reg;	// performance registers
//reg 		[31:0]						n_hit_reg, n_miss_reg, n_wb_reg;	// performance registers

// registered output ports
reg 					core_done_o_reg;
reg 					req_o_reg, req_block_o_reg, rw_o_reg, write_o_reg, read_o_reg;
reg 		[23:0]		add_o_reg;
reg 		[31:0]		data_o_reg; 
reg 					miss_o_reg;

wire sampler_stall;
wire sampler_full_flag; 		// if high then sampler buffer is full and needs to be deloaded

assign core_done_o = core_done_o_reg & ~sampler_full_flag & ~sampler_stall;
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
reg 		[31:0]	config_register;

//reg 				sampler_clear_reg;		// if driven high by uC then the buffer is cleared and sampler_full_flag is driven low by sampler

always @(posedge clock_bus_i[0]) begin

	// reset condition
	// ----------------------------------
	if (reset_i != 1'b1) begin

		// internal signals
		//state = `LST_REQ_UNIFORM_LEASE;
		state = `LST_CACHE_NORMAL;
		n_transfer = 'b0;
		n_dirtyBit = 'b0;
		add_writeback_reg = 'b0;
		//n_hit_reg = 'b0; n_miss_reg = 'b0; n_wb_reg = 'b0;
		hit_flag = 1'b0; miss_flag = 1'b0; wb_flag = 1'b0; //rep_exp_flag = 1'b0; rep_nexp_flag = 1'b0;
		replacement_ptr = {`BW_CACHE_BLOCKS{1'b1}}; 	// start at max so first replacement rolls over into first cache line location 
		req_flag = 1'b0; rw_flag = 1'b0; full_flag = 1'b0; writeback_flag = 1'b0;

		// ports signals
		core_done_o_reg = init_done;	// lease should be = 1'b0 to force lease pulls from memory

		req_o_reg = 1'b0; req_block_o_reg = 1'b0; rw_o_reg = 1'b0; write_o_reg = 1'b0; read_o_reg = 1'b0;
		add_o_reg = 'b0; data_o_reg = 'b0;

		// cam signals
		rw_cam = 1'b0; add_cache2cam = 'b0; 

		// cache memory signals
		rw_cache = 1'b0; add_cache = 'b0; data_toCache = 'b0;

		config_register = 'b0;

		//sampler_clear_reg = 1'b0;
	end

	// active sequencing
	// ----------------------------------
	else begin

		// default signals
		rw_cache = 1'b0; rw_cam = 1'b0; req_o_reg = 1'b0; req_block_o_reg = 1'b0;
		write_o_reg = 1'b0; read_o_reg = 1'b0;
		hit_flag = 1'b0; miss_flag = 1'b0; wb_flag = 1'b0; //rep_exp_flag = 1'b0; rep_nexp_flag = 1'b0;
		//lfsr_enable = 1'b0;
		//sampler_clear_reg = 1'b0;

		// only execute if cache is enabled - only important in multi-cache/component arch
		if (en_i & !sampler_full_flag & !sampler_stall) begin

			case(state)

				// out of reset state - request leases from memory
				/*`LST_REQ_UNIFORM_LEASE: begin
					if (ready_req_i) begin
						// request signle word from start of lease value section
						req_o_reg = 1'b1;
						req_block_o_reg = 1'b0;							// request only 1 word
						add_o_reg = `LEASE_SAMPLER_FS_WADDR;	// mask off word to specify block starting address
						rw_o_reg = 1'b0;
						state = `LST_GET_UNIFORM_LEASE;
					end
				end

				`LST_GET_UNIFORM_LEASE: begin
					if (ready_read_i) begin
						read_o_reg = 1'b1;
						config_register = data_i;
						core_done_o_reg = 1'b1;
						state = `LST_CACHE_NORMAL;
					end
				end*/

				// nominal state - evaluate hit/miss
				`LST_CACHE_NORMAL: begin

					// really should register things here
					if (core_req_i | req_flag) begin

						// hit condition
						// ------------------------------------
						if (hit_cam) begin
							
							hit_flag = 1'b1;
							
							if (req_flag) begin
								rw_cache = rw_flag;
								req_flag = 1'b0;
							end
							else begin
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

							miss_flag = 1'b1;

							// issue a request for a new block
							req_flag = 1'b1; 				// so that upon handling the miss the cache serves the core
							rw_flag = core_rw_i; 			// register request type (ld/st)
							core_done_o_reg = 1'b0;			// stall processor

							// move to read block request state
							state = `LST_WAIT_READY;

						end // if miss

					end // req_flag


				end // ST_CACHE_NORMAL


				// upon miss wait until memory buffer is ready for request
				// give writebacks priority here if not yet executed
				`LST_WAIT_READY: begin
					//if (ready_req_i) begin
					if ((ready_req_i) & (writeback_flag == 1'b0)) begin

						// request the target block
						req_o_reg = 1'b1;
						req_block_o_reg = 1'b1;
						add_o_reg = {req_tag, 4'b0000};		// mask off word to specify block starting address
						rw_o_reg = 1'b0;

						// fully utilized condition
						if (full_flag == 1'b1) begin
							replacement_ptr = replacement_ptr + 1'b1; 	// will wrap around on overflow
							

							// check writeback condition
							if (n_dirtyBit[replacement_ptr] != 1'b1) begin
								state = `LST_CACHE_READ_BUFFER;		// try pulling data from buffer
							end
							// dirty bit set so write out line
							else begin
								wb_flag = 1'b1;
								add_cache2cam = replacement_ptr; 	// get tag 
								rw_cache = 1'b0;
								add_cache = {replacement_ptr, 4'b0000};		// request block from cache
								state = `LST_CACHE_WRITE_BUFFER;
							end

						end
						// not yet fully utilized condition
						else begin
							// increment pointer to next open cache address
							replacement_ptr = replacement_ptr + 1'b1;

							// if filling in last cache location then set full flag to initiate replacement policy on next miss
							if (replacement_ptr == {`BW_CACHE_BLOCKS{1'b1}}) begin
								full_flag = 1'b1;
							end
							state = `LST_CACHE_READ_BUFFER; 
						end

					end
				end


				// write out cache line to buffer
				`LST_CACHE_WRITE_BUFFER: begin
					// if writeback not set then do so
					// if buffer ready to accept data then send out
					if (ready_write_i) begin

						// write to fifo
						write_o_reg = 1'b1;
						data_o_reg = data_fromCache;

						// if first transfer set writeback flag, starting address, etc...
						if (n_transfer == 5'b00000) begin
							writeback_flag = 1'b1;
							add_writeback_reg = {tag_cam2cache, 4'b0000};
						end													
						
						// transfer complete
						if (n_transfer == 5'b01111) begin
							n_transfer = 'b0;
							n_dirtyBit[replacement_ptr] = 1'b0;
							// if transfer complete then read out replacement block
							state = `LST_CACHE_READ_BUFFER;
						end
						else begin
							n_transfer = n_transfer + 1'b1;
							add_cache = {replacement_ptr, n_transfer[3:0]};
						end
					end
				end


				// need to read block from buffer
				`LST_CACHE_READ_BUFFER: begin
					
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
							state = `LST_CACHE_NORMAL;

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


// sampler controller
// --------------------------------------------------------------------------------
wire 	[31:0]		rui_interval, rui_refpc, rui_used, rui_count, rui_remaining, rui_target;
wire 	[63:0]		rui_trace;


// final includes the target address
// 8 includes RI as negative numbers
// 6 for lfsr sampling
// 5 for fs sampling
lease_sampler_phase inst0(
	.clock_bus_i 		(clock_bus_i 		), 
	.reset_i 			(reset_i 			), 
	.comm_i 			(comm_i 			), 
	.phase_i 			(phase_i 			),
	.fs_i 				(config_register 	), //.offset_i(config_register[1]),// .clear_i(sampler_clear_reg),
	.req_i 				(core_req_i 		), 
	.pc_ref_i 			(pc_i 				), 
	.tag_ref_i 			(req_tag 			),
	.addr_ref_i 		(core_add_i 		),
	.ref_address_o 		(rui_interval 		), 
	.ref_target_o 		(rui_target 		),
	.ref_interval_o 	(rui_refpc 			), 
	.ref_trace_o 		(rui_trace 			), 
	.used_o 			(rui_used 			), 
	.count_o 			(rui_count 			), 
	.remaining_o 		(rui_remaining 		),
	.full_flag_o 		(sampler_full_flag 	), 
	.stall_o 			(sampler_stall 		)
);

// communication controller
// --------------------------------------------------------------------------------
reg 	[31:0]	comm_o_reg;
assign comm_o = comm_o_reg;

reg 	[63:0]	perf_hit_reg, perf_miss_reg, perf_wb_reg;
//reg 	[63:0] 	rep_lease_reg, rep_default_reg;

always @(posedge clock_bus_i[0]) begin
	if (reset_i != 1'b1) begin
		comm_o_reg <= 'b0;
		perf_hit_reg <= 'b0; perf_miss_reg <= 'b0; perf_wb_reg <= 'b0;
		//rep_lease_reg <= 'b0; rep_default_reg <= 'b0;
	end
	else begin

		// if enabled then upcount depending on flag thrown by cache
		if (comm_i[24] == 1'b1) begin
			// hit/miss flags
			if (hit_flag) perf_hit_reg <= perf_hit_reg + 1'b1;
			else if (miss_flag) perf_miss_reg <= perf_miss_reg + 1'b1;
			else if (wb_flag) perf_wb_reg <= perf_wb_reg + 1'b1;

			// replacement flags
			//if (rep_exp_flag) rep_lease_reg <= rep_lease_reg + 1'b1;
			//if (rep_nexp_flag) rep_default_reg <= rep_default_reg + 1'b1;
		end

		// output switching
		case (comm_i[3:0])

			// primary outputs
			4'b0000: comm_o_reg <= perf_hit_reg[31:0];
			4'b0001: comm_o_reg <= perf_hit_reg[63:32];
			4'b0010: comm_o_reg <= perf_miss_reg[31:0];
			4'b0011: comm_o_reg <= perf_miss_reg[63:32];
			4'b0100: comm_o_reg <= perf_wb_reg[31:0];
			4'b0101: comm_o_reg <= perf_wb_reg[63:32];

			// replacement statistics
			4'b0110: comm_o_reg <= rui_interval;
			4'b0111: comm_o_reg <= rui_refpc;
			4'b1000: comm_o_reg <= rui_used;
			4'b1001: comm_o_reg <= rui_count;
			4'b1010: comm_o_reg <= rui_remaining;
			4'b1011: comm_o_reg <= rui_trace[31:0];
			4'b1100: comm_o_reg <= rui_trace[63:32];
			4'b1101: comm_o_reg <= rui_target;


			4'b1110: comm_o_reg <= `ID_CACHE_SAMPLER; 				// cache system id
			4'b1111: comm_o_reg <= sampler_full_flag;

			default comm_o_reg <= 'b0;
		endcase

	end
end

endmodule