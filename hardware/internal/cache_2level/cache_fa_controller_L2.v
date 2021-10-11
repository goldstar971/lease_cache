module cache_fa_controller_L2 #(
	parameter POLICY 				= "",
	parameter INIT_DONE 			= 1'b1,
	parameter CACHE_BLOCK_CAPACITY 	= 0
)(

	input 								clock_i,
	input 								resetn_i,
	input 								enable_i,

	// l1/hart signals
	input 								L1_req_i,
	input 	[`BW_WORD_ADDR-1:0]			L1_ref_addr_i,
	input 								L1_rw_i,
	input 	[BW_TAG-1:0]				L1_tag_i,
	input 	[`BW_BLOCK-1:0]	 			L1_word_i,
	input 	[31:0]						L1_data_i,
	input 								L2_ready_read_i,
	input                               L2_ready_write_i,
	output 								L2_read_ack_o,
	output								L1_done_o,
	output 								L1_hit_o,
	output                              L1_valid_o,


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
	output 								mem_req_block_o,
	output 								mem_rw_o,
	output 	[`BW_WORD_ADDR-1:0]			mem_addr_o,

	// performance ports
	output 								flag_hit_o,
	output 								flag_miss_o,
	output 								flag_writeback_o
);

// parameterizations
// ---------------------------------------------------------------------------------------------------------------------
localparam ST_NORMAL 				= 3'b000; 		// check for hit/miss
localparam ST_WAIT_READY 			= 3'b001; 		// upon miss request a block be brought in - if ext. mem not ready then idle
localparam ST_WRITE_BUFFER 			= 3'b010; 		// read in block from cache and write to buffer
localparam ST_READ_BUFFER  			= 3'b011; 		// read in from buffer and write block to cache
localparam ST_WAIT_REPLACEMENT_GEN 	= 3'b100;
localparam ST_READ_FROM_L1_BUFFER =3'b101;
localparam ST_WRITE_TO_L1_BUFFER =3'b110;
localparam ST_TAG_WAIT= 3'b111;

localparam BW_CACHE_ADDR_PART 		= `CLOG2(CACHE_BLOCK_CAPACITY); 
localparam BW_CACHE_ADDR_FULL 		= BW_CACHE_ADDR_PART + `BW_BLOCK; 				
localparam BW_TAG 					= `BW_WORD_ADDR - `BW_BLOCK; 


// internal signals - registered ports
// ---------------------------------------------------------------------------------------------------------------------

// l1/hart
reg 		cache_ready_reg;

assign L1_done_o = cache_ready_reg;

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
reg 					init_hit_reg,
						strobe_hit_reg,
						flag_miss_reg,
						flag_writeback_reg;

assign flag_hit_o		= init_hit_reg;
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
	.CACHE_SET_SIZE 		(CACHE_BLOCK_CAPACITY 	)
) fifo_contr_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.miss_i 				(flag_miss_reg			), 		// pulse trigger to generate a replacement address
	.group_i 				('b0					), 		// grounded for fully assoc. 
	.done_o 				(replacement_done 		), 		// logic high when replacement address generated
	.addr_o 				(replacement_addr		) 		// replacement address generated
);
	end

	// LRU controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_LRU) begin

lru_line_controller #(
	.N_LOCATIONS 			(CACHE_BLOCK_CAPACITY 	)
) lru_line_controller_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.enable_i 				(1'b1 					),
	.addr_i	 				(cam_addr_i 			), 		// no cycle latency, signal to port does not need to be register
	.hit_i 	 				(strobe_hit_reg 		), 		// no cycle latency, signal to port does not need to be register
	.miss_i  				(flag_miss_reg 			), 		// no cycle latency, signal to port does not need to be register
	.done_o  				(replacement_done 		),
	.addr_o  				(replacement_addr 		)
);
	end

	// MRU controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_MRU) begin

mru_line_controller #(
	.N_LOCATIONS 			(CACHE_BLOCK_CAPACITY 	)
) lru_line_controller_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.enable_i 				(1'b1 					),
	.addr_i	 				(cam_addr_i 			), 		// no cycle latency, signal to port does not need to be register
	.hit_i 	 				(strobe_hit_reg 		), 		// no cycle latency, signal to port does not need to be register
	.miss_i  				(flag_miss_reg 			), 		// no cycle latency, signal to port does not need to be register
	.done_o  				(replacement_done 		),
	.addr_o  				(replacement_addr 		)
);
	end

	// PLRU controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_PLRU) begin

plru_line_controller #(
	.N_LOCATIONS			(CACHE_BLOCK_CAPACITY 	)
)plru_line_controller_inst(
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.miss_i 				(flag_miss_reg 			),
	.enable_i 				(strobe_hit_reg 		),
	.addr_i 				(cam_addr_i 			),
	.addr_o 				(replacement_addr 		)
);

assign replacement_done = 1'b1; // no latency needed

	end

	// SRRIP controller
	// -------------------------------------------------------------
	else if (POLICY == `ID_CACHE_SRRIP) begin

srrip_line_controller #(
	.N_LOCATIONS 			(CACHE_BLOCK_CAPACITY 	),
	.RRPV_REG_WIDTH 		(`SRRIP_BW 				),
	.RRPV_REG_INS 			(`SRRIP_INIT 			)
) srrip_contr_inst (
	.clock_i 				(!clock_i 				),
	.resetn_i 				(resetn_i 				),
	.enable_i 				(1'b1 					),
	.hit_i 					(strobe_hit_reg 		),
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

assign L1_hit_o = (L1_req_i | req_flag_reg) ? cam_hit_i : 1'b1; 	// to prevent stall cycle if no request

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

		// L1/L2
		cache_ready_reg = 		INIT_DONE;
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
		init_hit_reg = 			1'b0;
		strobe_hit_reg=         1'b0;
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
		mem_req_block_reg 		= 1'b0;
		mem_rw_reg 				= 1'b0;

		init_hit_reg 			= 1'b0;
		strobe_hit_reg          = 1'b0;
		flag_miss_reg 			= 1'b0;
		flag_writeback_reg 		= 1'b0;

		data_valid_reg =1'b0;
		L2_read_ack_reg=1'b0;

		// only sequence if enabled
		if(enable_i) begin

			// cache state sequencing
			// --------------------------------------------------------------------
			case(state_reg)

			ST_NORMAL: begin

					// only execute if there is a new request or returning from servicing a miss
					if (L1_req_i | req_flag_reg) begin
						cache_ready_reg 		= 1'b0; 							// stall processor L1 regardless if miss or hit.
						// hit condition
						// ------------------------------------
						if (cam_hit_i) begin
							
							// mux in reference information based on previous actions
							if (!req_flag_reg) begin 									// initial reference hit
								 rw_flag_reg=L1_rw_i;
								 init_hit_reg 			= 1'b1;								//signal there was a hit
							end
							else begin 													// return from miss hit
								req_flag_reg 		= 1'b0;

							end
						
							if(rw_flag_reg)begin
								state_reg = ST_READ_FROM_L1_BUFFER;
								dirtybits_reg[cam_addr_i] = 1'b1; 	// set dirty bit if writing back cache block from L1
							end
							else begin
								state_reg = ST_WRITE_TO_L1_BUFFER;
							end
							strobe_hit_reg          =1'b1;
							n_transfer_reg          ='b0;                  
							
							
						
						end

						// miss condition
						// ------------------------------------
						else begin
							// set performance counter flag
							flag_miss_reg = 1'b1;

							// register inputs and flag for reassessment after servicing miss
							req_flag_reg 	= 1'b1; 				// so that upon handling the miss the cache serves the L1
							rw_flag_reg 	= L1_rw_i; 			// register request type (ld/st)

							// move to read block request state
							state_reg 		= ST_WAIT_READY;

						end // if miss

					end
				end

				ST_WRITE_TO_L1_BUFFER: begin 
					if(L2_ready_write_i)begin
						cache_mem_add_reg 	= {cam_addr_i, n_transfer_reg[`BW_BLOCK-1:0]};
						data_valid_reg          = 1'b1;  //signal that data is valid so rx buffer starts reading in values from L2 cache
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
						cache_mem_data_reg=L1_data_i;
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
					// only proceed if there is no remaining memory operation to complete
					if (mem_ready_i) begin

						// normal condition - bring cache the item
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
						
						// if last word then write block to cam and wait a cycle for tag calculation
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
					//if writeback from L1, grab block from transmit buffer
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
								//if writeback no need to serve a hit
								req_flag_reg=1'b0;
								cache_ready_reg=1'b1; //unstall CPU
							end
							else begin
									
								n_transfer_reg 	= n_transfer_reg + 1'b1;// increment L1 tx buffer pointer for next word
							end
						end
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