// "latching" buffer with no control on overflow/underflow
// niche implementation - only use if known how to actually use correctly

module pipeline_data_buffer #(
	parameter N_ENTRIES = 0,
	parameter BW_DATA	= 0
)(
	input 					clock_i,
	input 					resetn_i,
	input 					valid_i,
	input [BW_DATA-1:0] 	data_i,
	input 					read_i,
	input 					clear_i,
	output [BW_DATA-1:0] 	data_o
);

// parameterization
// -------------------------------------------------------------------------------
localparam BW_ENTRIES = `CLOG2(N_ENTRIES);


// local signals
// -------------------------------------------------------------------------------
reg [BW_DATA-1:0]		buffer_regs [0:N_ENTRIES-1];
reg [BW_ENTRIES:0] 		buffer_count_reg; 				// count of entries in the buffer that have not been read
reg [BW_ENTRIES-1:0] 	buffer_write_ptr_reg,
						buffer_read_ptr_reg;


// buffer controller
// -------------------------------------------------------------------------------

// if buffer is empty pass through the input data
// if buffer is not empty then pass through oldest entry
//assign data_o = (!buffer_count_reg) ? data_i : buffer_regs[buffer_read_ptr_reg];

// if not equal - can be written to by data so this should work even on overflow
assign data_o = (buffer_write_ptr_reg == buffer_read_ptr_reg) ? data_i : buffer_regs[buffer_read_ptr_reg];

integer i;
always @(posedge clock_i) begin
	if (!resetn_i) begin
		buffer_write_ptr_reg 	<= 'b0;
		for (i = 0; i < N_ENTRIES; i = i + 1) buffer_regs[i] = 'b0;
	end
	else begin

		if (clear_i) 	buffer_write_ptr_reg 	<= 'b0;

		// if incoming data is valid and controller read from buffer last cycle
		else if (valid_i) begin
			buffer_regs[buffer_write_ptr_reg] 	<= data_i;
			buffer_write_ptr_reg 				<= buffer_write_ptr_reg + 1'b1;
		end
	end
end 

// read clock
always @(negedge clock_i) begin
	if (!resetn_i) 		buffer_read_ptr_reg 	<= 'b0;
	else begin
		if (clear_i) 	buffer_read_ptr_reg 	<= 'b0;
		else if (read_i) 	buffer_read_ptr_reg 	<= buffer_read_ptr_reg + 1'b1;
	end
end


endmodule