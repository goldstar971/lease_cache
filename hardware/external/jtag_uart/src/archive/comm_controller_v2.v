`define 	RESET_PURGE 			5'b10001
`define 	IDLE					5'b00000
`define 	SYNC 					5'b00001
`define 	CONFIG		 			5'b00100

`define 	GET_WORD 				5'b00010
`define 	SEND_WORD 				5'b00011

`define 	JTAG_READ 				5'b00101
`define 	JTAG_WRITE 				5'b00110
`define 	ACKNOWLEDGE 			5'b00111
`define 	MANAGE 					5'b01000
`define 	ERROR 					5'b01001
`define 	ACKNOWLEDGE_RELOAD 		5'b01010
`define 	WAIT_FOR_ACKNOWLEDGE 	5'b01011
`define 	CHECK_TERM2 			5'b01100
`define 	WAIT_READY_READ 		5'b01101
`define 	WAIT_READY_WRITE 		5'b01110

`define 	CONFIG2 				5'b10010
`define 	MANAGE_BURST 			5'b10011
`define 	BURST_RX 				5'b10100
`define 	BURST_WAIT_DONE			5'b10101
`define 	BURST_TX 				5'b10110
`define 	BURST_TX_INIT 			5'b10111
`define 	BURST_WAIT_DONE2		5'b11000

`define 	FUSION_MANAGE0 			5'b11001
`define 	FUSION_MANAGE1 			5'b11010
`define 	FUSION_READ 			5'b11011
`define 	FUSION_WRITE 			5'b11100

`define 	FUSION_CACHE_READ 		5'b11101
`define  	FUSION_CACHE_WRITE 		5'b11110
`define 	FUSION_CACHE_MANAGE 	5'b11111

`define 	KEY_SYNC 				32'h4A78B9F2
`define 	XOR_SYNC 				32'hCD0031F7

`define 	PURGE_ITERATIONS 		20000

module comm_controller_v2(
	input 				clock_i,
	input 				resetn_i,
	input 				tx_full_i,
	input 				rx_empty_i,
	input [31:0] 		rx_data_i,
	output 				rx_read_o,
	output 				tx_write_o,
	output [31:0]		tx_data_o,
	input 				ready_i, done_i, valid_i,
	input 		[31:0]	data_i,
	output reg 	[2:0]	reqdev_o,
	output reg 			req_o,
	output reg 			req_block_o,
	output reg 			rw_o,
	output reg 	[26:0]	add_o,					// addresses are byte addressible (64MB mem, above that are peripherals)
	output reg 	[31:0]	data_o,
	output reg 			clear_o,
	output reg 			exception_o
);

// COMM RX buffer (TX does not require buffer) - Buffer used for burst transactions
reg 			buffer_enable;
reg 	[31:0]	txrx_buffer[0:15];
reg 	[4:0]	txrx_ptr, op_ptr;  	// buffer is 16 words so add extra bit for the role over
integer i;

always @(posedge clock_i) begin
	if (resetn_i != 1'b1) begin
		txrx_ptr = 'b0;
		for (i = 0; i < 16; i = i + 1'b1) begin
			txrx_buffer[i] = 'b0;
		end
	end
	else begin
		if (buffer_enable) begin
			if (valid_i) begin
				txrx_buffer[txrx_ptr] = data_i;
				txrx_ptr = txrx_ptr + 1'b1;
			end
		end
		else begin
			txrx_ptr = 'b0;
		end
	end
end


// internal controller/sequencer
// -----------------------------------------------------------------------------------------

// buffer signals
reg 		rx_get_reg, tx_put_reg;
reg [31:0] 	tx_put_data_reg, rx_get_data_reg;
assign rx_read_o = rx_get_reg; 
assign tx_write_o = tx_put_reg;
assign tx_data_o = tx_put_data_reg;

// controller signals
reg 	[4:0]	state_current,
				state_next0,
				state_next1;
reg 	[11:0]	word_reload,
				word_counter;
reg 	[15:0]	fusion_counter;
reg 	[13:0]	packet_counter;

reg 	[31:0]	rx_data_reg;
reg 	[11:0]	config_bits; 			// [31:26]
reg 	[31:0]	iteration_counter;
reg 	[31:0]	uart_tx_data;

reg 	[26:0]	fusion_write_add, fusion_read_add;
reg 	[15:0] 	fusion_base_add;
reg 	[3:0]	fusion_cache_ptr;
//reg 	[15:0]	fusion_limit
reg 			fusion_cache_flag;

always @(posedge clock_i) begin

	// reset condition
	// ------------------------------------------
	if (resetn_i != 1'b1) begin 

		// buffer signals
		tx_put_reg = 1'b0;
		tx_put_data_reg = 'b0;
		rx_get_reg = 1'b0;
		rx_get_data_reg = 'b0;

		// controller signals

		uart_tx_data = 'b0;
		state_current = `RESET_PURGE;
		state_next0 = `IDLE;
		state_next1 = `IDLE;
		word_reload = 'b0;
		word_counter = 'b0;
		packet_counter = 'b0;
		config_bits = 'b0;
		iteration_counter = `PURGE_ITERATIONS;
		fusion_counter = 'b0;

		// pin signals
		req_o = 1'b0;
		req_block_o = 1'b0;
		reqdev_o = 'b0;
		clear_o = 1'b0;
		rw_o = 1'b0;
		add_o = 'b0;
		data_o = 'b0;
		exception_o = 1'b0;

		// buffer init
		buffer_enable = 1'b0;
		op_ptr = 'b0;

		fusion_write_add = 'b0; fusion_read_add = 'b0; fusion_base_add = 'b0;
		fusion_cache_ptr = 4'b0000;
		fusion_cache_flag = 1'b0;
	end

	// controller active
	// ------------------------------------------
	else begin
		// buffer default signals
		rx_get_reg 		= 1'b0;
		tx_put_reg 		= 1'b0;

		// default signals
		req_o 			= 1'b0;
		req_block_o 	= 1'b0;
		clear_o 		= 1'b0;
		rw_o 			= 1'b0;
		reqdev_o 		= 3'b000;

		// state switching
		case(state_current)

			`GET_WORD: begin
				if (!rx_empty_i) begin
					rx_get_reg 		= 1'b1;
					rx_get_data_reg = rx_data_i;
					state_current 	= state_next0;
				end
			end

			`SEND_WORD: begin
				if (!tx_full_i) begin
					tx_put_reg 		= 1'b1;
					tx_put_data_reg = uart_tx_data;
					state_current 	= state_next0;
				end
			end

			`RESET_PURGE: begin
				// purge all data from the uart system, must see XXXX conseq. cycles of no data to proceed
				if (!rx_empty_i) begin
					rx_get_reg = 1'b1;
					iteration_counter = `PURGE_ITERATIONS;
				end
				else begin
					if (iteration_counter != 'b0) 	iteration_counter = iteration_counter - 1'b1;
					else 							state_current = `SYNC;
				end
			end

			`SYNC: begin
				if (!rx_empty_i & !tx_full_i) begin
					rx_get_reg = 1'b1;
					rx_get_data_reg = rx_data_i;

					if (rx_get_data_reg == `KEY_SYNC) state_current = `IDLE;
					else begin
						tx_put_reg = 1'b1;
						tx_put_data_reg = rx_get_data_reg ^ `XOR_SYNC;
					end
				end
			end

			// waiting for a command state
			// command must be initiated by a blank synchronizing packet
			`IDLE: begin
				if (!rx_empty_i) begin
					rx_get_reg 		= 1'b1;
					rx_get_data_reg = rx_data_i;

					// check out of idle terminator
					if (rx_get_data_reg != 32'h0) 	state_current = `ERROR;
					else 							state_current = `CONFIG;
				end
			end

			// configure transaction settings
			`CONFIG: begin
				if (!rx_empty_i) begin
					rx_get_reg 		= 1'b1;
					rx_get_data_reg = rx_data_i;

					// extract configurations
					config_bits = rx_get_data_reg[23:12];

					// CONFIG
					if (config_bits[2] == 1'b1) begin
						state_current 	= `ACKNOWLEDGE;
						req_o 			= 1'b1;
						reqdev_o 		= rx_get_data_reg[26:24];
						data_o 			= rx_get_data_reg[1:0];
					end

					// WRITE
					else if (config_bits[0] == 1'b1) begin
						state_current 	= `GET_WORD; 			// get the target address
						state_next0 	= `CONFIG2;
						state_next1 	= `MANAGE;
						word_counter 	= 'b1;
						packet_counter 	= 'b1;
					end

					// READ
					else if (config_bits[0] == 1'b0) begin
						state_current 	= `GET_WORD; 			// get the target address
						state_next0 	= `CONFIG2;
						state_next1 	= `MANAGE;
						word_counter 	= 'b1;
						packet_counter 	= 'b1;
					end

					// check burst settings
					if (config_bits[1] == 1'b1) begin
						word_counter 	= rx_get_data_reg[11:0];
					end

					// if block burst then enable the read buffer
					if (config_bits[3] == 1'b1) begin
						if (config_bits[0] == 1'b0) begin	// only enable if reading
							buffer_enable <= 1'b1;
						end
						state_current 	= `GET_WORD; 			// get the target address
						state_next0 	= `CONFIG2;
						state_next1 	= `MANAGE_BURST;
					end

					// cache specific operation
					if (config_bits[4] == 1'b1) begin
						// operation is to read all cache parameters as a block - involves write->read sequences
						state_current 	= `GET_WORD; 			// get the target address
						state_next0 	= `FUSION_MANAGE0;
					end

					// CycloneV-DE0: Sampler
					// CycloneV-GT:	 Tracker
					if (config_bits[5] == 1'b1) begin
						fusion_write_add 	= 27'h4000110;
						fusion_read_add 	= 27'h4000084;
						fusion_counter 		= 'b0;

						state_current 		= `GET_WORD; 			// get number of words
						state_next0 		= `FUSION_CACHE_MANAGE;
						fusion_cache_flag 	= 1'b1;
						fusion_base_add 	= 'b0;
					end

				end
			end


			// special fusion states - check for errors - modified with buffer arch (05/01/2020)
			// -------------------------------------------------------------------------------------------------------
			`FUSION_MANAGE0: begin
				fusion_write_add 	= rx_get_data_reg[26:0];
				state_current 		= `GET_WORD;	// first get the address to continuously read from 
				state_next0 		= `FUSION_MANAGE1;
			end
			`FUSION_MANAGE1: begin
				fusion_read_add 	= rx_get_data_reg[26:0];
				state_current 		= `FUSION_WRITE;
				word_counter 		= 'b0;
			end
			`FUSION_WRITE: begin
				if (word_counter != 5'b10000) begin
					state_current 	= `WAIT_READY_WRITE; 	// request a write
					add_o 			= fusion_write_add;			// write address
					rx_get_data_reg = word_counter; 		// value to write is incrementing count
					state_next1 	= `FUSION_READ; 		// then read the output from cache
				end
				// all transfered so end readblock
				else begin
					word_counter 	= 'b0;
					state_current 	= `IDLE;
				end
			end
			`FUSION_READ: begin
				state_current 		= `WAIT_READY_READ;		
				add_o 				= fusion_read_add;
				state_next0 		= `FUSION_WRITE;
				word_counter 		= word_counter + 1'b1;
			end
			// ---------------------------------------------------------------------------------------------------------

				`FUSION_CACHE_MANAGE: begin
					if (fusion_cache_flag == 1'b1) begin
						fusion_cache_flag 	= 1'b0;
						state_current 		= `GET_WORD; 			// get number of words
						state_next0 		= `FUSION_CACHE_MANAGE;
						fusion_base_add 	= rx_get_data_reg[15:0];
					end
					else begin
						word_counter 		= rx_get_data_reg[11:0]; 	// this is correct I believe
						state_current 		= `FUSION_CACHE_WRITE;
						fusion_counter 		= 'b0;
					end
				end

				`FUSION_CACHE_WRITE: begin
					if (fusion_counter[11:0] != word_counter) begin

						// get new data
						rx_get_data_reg 	= {{13'b0},(fusion_counter[14:0]+fusion_base_add[14:0]),fusion_cache_ptr};
																							 	// fusion_cache_ptr switches between comm_o_reg cases
																								// fusion_counter increments buffer address
																								// base is for offsets
						fusion_cache_ptr 	= fusion_cache_ptr + 1'b1;

						// reset for next loop
						if (fusion_cache_ptr == 4'b1000) begin
							fusion_cache_ptr 	= 'b0;
							fusion_counter 		= fusion_counter + 1'b1;
						end

						state_current 	= `WAIT_READY_WRITE; 	// request a write
						add_o 			= fusion_write_add;		// set address
						state_next1 	= `FUSION_CACHE_READ;

					end
					else begin
						fusion_counter 	= 'b0;
						word_counter 	= 'b0;
						state_current 	= `IDLE;
					end
				end

				`FUSION_CACHE_READ: begin
					state_current 	= `WAIT_READY_READ;		
					add_o 			= fusion_read_add;
					state_next0 	= `FUSION_CACHE_WRITE;
				end

			// ---------------------------------------------------------------------------------------------------------


			`CONFIG2: begin
				add_o 			= rx_get_data_reg[26:0] - 3'b100;
				state_current 	= state_next1;
			end

			`WAIT_READY_READ: begin
				if (ready_i == 1'b1) begin
					req_o 			= 1'b1;
					rw_o 			= 1'b0;
					state_current 	= `JTAG_READ;
				end
			end

			`WAIT_READY_WRITE: begin
				if (ready_i == 1'b1) begin
					req_o 			= 1'b1;
					rw_o 			= 1'b1;
					data_o 			= rx_get_data_reg;
					state_current 	= `JTAG_WRITE;
				end
			end

			`MANAGE: begin
				// auto word increment
				add_o = add_o + 3'b100;

				// if read first read memory then TX
				if (config_bits[0] == 1'b0) begin
					state_current = `WAIT_READY_READ;

					// if word counter at limit
					if (word_counter == 'b1) begin
						if (packet_counter != 'b1) begin
							packet_counter = packet_counter - 1'b1;
							state_next0 = `WAIT_FOR_ACKNOWLEDGE;
						end
						else begin
							state_next0 = `IDLE;
						end
					end
					else begin
						word_counter = word_counter - 1'b1;
						state_next0 = `MANAGE;
					end

				end

				// if write first RX then write to memory
				// ---------------------------------------
				else begin
					state_current = `GET_WORD;
					state_next0 = `WAIT_READY_WRITE;

					// if word counter at limit
					if (word_counter == 'b1) begin
						// send ack before going onto next packet
						if (packet_counter != 'b1) begin
							packet_counter = packet_counter - 1'b1;
							state_next1 = `ACKNOWLEDGE_RELOAD;
						end
						else begin
							state_next1 = `ACKNOWLEDGE;
						end
					end
					else begin
						word_counter = word_counter - 1'b1;
						state_next1 = `MANAGE;
					end
				end
			end

			`MANAGE_BURST: begin
				// block read
				if (config_bits[0] == 1'b0) begin
					if (ready_i == 1'b1) begin
						add_o = add_o + 3'b100;
						req_o = 1'b1;
						req_block_o = 1'b1;
						rw_o = 1'b0;
						state_current = `BURST_RX;
					end
				end
				// block write
				else begin
					state_current = `GET_WORD; 	// get word to write
					state_next0 = `BURST_TX_INIT;
				end

			end

			`BURST_RX: begin
				if (txrx_ptr > op_ptr) begin
					rx_data_reg = txrx_buffer[op_ptr];
					uart_tx_data = txrx_buffer[op_ptr];
					op_ptr = op_ptr + 1'b1;
					state_current = `SEND_WORD;
					if (op_ptr == 5'b10000) begin
						op_ptr = 'b0;
						buffer_enable = 1'b0;
						state_next0 = `BURST_WAIT_DONE;
					end
					else begin
						state_next0 = `BURST_RX;
					end
				end
			end

			`BURST_TX_INIT: begin
				//state_current = `ACKNOWLEDGE;
				if (ready_i == 1'b1) begin
					add_o = add_o + 3'b100;
					req_o = 1'b1;
					req_block_o = 1'b1;
					rw_o = 1'b1;
					data_o = rx_get_data_reg;
					state_current = `GET_WORD; 	// get next word
					state_next0 = `BURST_TX;
					op_ptr = 'b1; 				// sent one word
				end
			end

			`BURST_TX: begin
				req_block_o = 1'b1;
				data_o = rx_get_data_reg;
				op_ptr = op_ptr + 1'b1;
				if (op_ptr < 5'b10000) begin
					state_current = `GET_WORD;
					state_next0 = `BURST_TX;
				end
				else begin
					state_current = `BURST_WAIT_DONE2;
					op_ptr = 'b0;
				end
			end

			`BURST_WAIT_DONE: begin
				if (done_i == 1'b1) begin
					clear_o = 1'b1;
					state_current = `IDLE;
				end
			end

			`BURST_WAIT_DONE2: begin
				if (done_i == 1'b1) begin
					clear_o = 1'b1;
					state_current = `ACKNOWLEDGE;
				end
			end

			// memory read
			`JTAG_READ: begin
				if (done_i == 1'b1) begin
					clear_o 		= 1'b1; 
					rx_get_data_reg = data_i;
					uart_tx_data 	= data_i;
					state_current 	= `SEND_WORD;
				end
			end

			`JTAG_WRITE: begin
				// if not busy then apply
				if (done_i == 1'b1) begin
					// clear request
					clear_o 		= 1'b1;
					state_current 	= state_next1;
				end
			end

			`ACKNOWLEDGE: begin
				if (!tx_full_i) begin
					tx_put_reg = 1'b1;
					tx_put_data_reg = 32'h0;
					state_current = `IDLE;
				end
			end

			`ACKNOWLEDGE_RELOAD: begin
				uart_tx_data = 32'h0;
				state_current = `SEND_WORD;
				word_counter = word_reload;
				state_next0 = `MANAGE;
			end

			`WAIT_FOR_ACKNOWLEDGE: begin
				state_current = `GET_WORD;
				word_counter = word_reload;
				state_next0 = `CHECK_TERM2;
			end

			// check for correct sequencing
			`CHECK_TERM2: begin
				if (rx_data_reg != 32'h0) begin
					state_current = `ERROR;
				end
				else begin
					state_current = `MANAGE;
				end
			end

			// error state
			`ERROR: begin
				exception_o = 1'b1;
				state_current = `ERROR;
			end

		endcase

	end
end

endmodule