`include "../../../include/exception.h"

module txrx_buffer_L2_L1(
	// system i/o
	input 		[1:0]	clock_bus_i,  	// clock[0] = 90deg, clock[1] = 270deg
	input 				reset_i,
	output 		[3:0]	exception_bus_o,

	// controller side
	input 				req_i, rw_i,
	input 		[23:0]	add_i, 
	input 				write_en, read_ack, 
	input 		[31:0]	data_i,
	output				ready_write_o, ready_read_o,
	output 		[31:0]	data_o,

	// sdram side
	output 	reg			cacheL2_L1_req_o, cacheL2_L1_rw_o, 
	output 	reg [23:0]	cacheL2_L1_add_o, 
	output [31:0]	cacheL2_L1_data_o,
	output  L2_ready_read_o,
	output L2_ready_write_o,
	input 				cacheL2_L1_ready_i,
	input 		[31:0]	cacheL2_L1_data_i,
	input         cacheL2_L1_valid_i,
	input   L2_read_ack_i

);


// write out buffer and request controller (270deg phase trigger)
// ----------------------------------------------------------------
integer 						i; 						// used to initialize buffer registers
reg 	[31:0]					tx_buffer[0:15];		// outgoing buffer
reg 							tx_flag;
reg 	[3:0]					tx_ptr, write_ptr;
reg     [4:0]							n_in;					// number of un-sent items in fifo

reg 	[3:0]					tx_exception_reg;

assign ready_write_o = (n_in < 5'b10000) ? 1'b1 : 1'b0;

assign L2_ready_read_o=(n_in >5'b00000) ? 1'b1 :1'b0;
assign cacheL2_L1_data_o = tx_buffer[tx_ptr];
always @(posedge clock_bus_i[1]) begin

	// reset condition
	// -------------------------
	if (reset_i != 1'b1) begin
		// reset pointers
		tx_ptr = 'b0; write_ptr = 'b0;  n_in = 'b0;

		for (i = 0; i < 16; i = i + 1'b1) begin
			tx_buffer[i] = 'b0;
		end

		// default requests
		cacheL2_L1_rw_o = 1'b0; cacheL2_L1_add_o = 'b0; 
		

		tx_exception_reg = 4'b0000;
	end

	// active condition
	// -------------------------
	else begin
		// default signals
		cacheL2_L1_req_o = 1'b0;
	

		// process request here
		// ---------------------------------------------------
		if ((req_i) & (cacheL2_L1_ready_i)) begin
			cacheL2_L1_req_o = 1'b1;
			cacheL2_L1_rw_o = rw_i;
			cacheL2_L1_add_o = add_i;
			
		end

		// if commanded to r/w then increment ptrs
		if (write_en) begin
			n_in = n_in + 1'b1;
			tx_buffer[write_ptr] = data_i;
			write_ptr = write_ptr + 1'b1;

			if (n_in > 5'b10000) begin
				tx_exception_reg = `MEM_INT_BUFFER_TX_OVERFLOW;
			end
		end

		// tx buffer - only transmit if enabled
		if(L2_read_ack_i)begin
			if (n_in > 5'b00000) begin
				
				tx_ptr = tx_ptr + 1'b1;
				n_in = n_in - 1'b1;
			end
		end
	end
end

// read in buffer and response controller (90deg phase trigger)
// ---------------------------------------------------------------------
integer 						j; 						// used to initialize buffer registers
reg 	[31:0]					rx_buffer[0:15];		// outgoing buffer
reg 	[3:0]					read_ptr, rx_ptr;
reg 	[4:0]					n_counts;
reg 	[3:0]					rx_exception_reg;

assign data_o = rx_buffer[read_ptr];
assign ready_read_o = (n_counts > 5'b00000) ? 1'b1 : 1'b0;	// if unread contents then ready to be read
assign L2_ready_write_o=(n_counts<5'b10000) ? 1'b1 : 1'b0;
always @(posedge clock_bus_i[0]) begin

	// reset condition
	// ------------------------
	if (reset_i != 1'b1) begin
		rx_ptr = 'b0; //read_ptr = 'b0;
		for (j = 0; j < 16; j = j + 1'b1) begin
			rx_buffer[j] = 'b0;
		end
		n_counts = 'b0;
		rx_exception_reg = 4'b0000;
	end

	// active condition
	// ------------------------
	else begin
		// if commanded to r/w then increment ptrs
		//if (read_ack) begin
			//read_ptr = read_ptr + 1'b1;
		if (read_flag == 1'b1) begin
			if (n_counts == 5'b00000) begin
				rx_exception_reg = `MEM_INT_BUFFER_RX_UNDERFLOW;
			end

			n_counts = n_counts - 1'b1;
		end

		// rx buffer - only receive if enabled
		if (cacheL2_L1_valid_i == 1'b1) begin
			rx_buffer[rx_ptr] = cacheL2_L1_data_i;
			rx_ptr = rx_ptr + 1'b1;
			n_counts = n_counts + 1'b1;
			if (n_counts > 5'b10000) begin
				rx_exception_reg = `MEM_INT_BUFFER_RX_OVERFLOW;
			end
		end
	end
end

reg read_flag;
always @(posedge clock_bus_i[1]) begin
	if (reset_i != 1'b1) begin
		read_ptr = 'b0;
		read_flag = 1'b0;
	end
	else begin
		if (read_ack) begin
			read_ptr = read_ptr + 1'b1;
			read_flag = 1'b1;
		end
		else begin
			read_flag = 1'b0;
		end
	end
end


assign exception_bus_o = tx_exception_reg | rx_exception_reg;




endmodule