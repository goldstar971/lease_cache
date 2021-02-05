`ifndef _PIPELINE_INSTRUCTION_BUFFER_V_
`define _PIPELINE_INSTRUCTION_BUFFER_V_

module pipeline_instruction_buffer #(
	parameter N_ENTRIES 	= 0,
	parameter BW_DATA		= 0,
	parameter BW_ADDRESS 	= 0
)(
	input 						clock_i,
	input 						resetn_i,
	input 						valid_i,
	input 	[BW_DATA-1:0] 		data_i,
	input 						read_i,
	input 						clear_i,
	input 						request_i,
	output 	[BW_DATA-1:0] 		data_o
);

// parameterization
// -------------------------------------------------------------------------------
localparam BW_ENTRIES = `CLOG2(N_ENTRIES);


// local signals
// -------------------------------------------------------------------------------
reg [BW_DATA-1:0]		buffer_regs 		[0:N_ENTRIES-1];
reg [BW_ENTRIES-1:0] 	buffer_write_ptr_reg,
						buffer_read_ptr_reg;

reg [BW_ENTRIES:0] 		n_active_reg;


// buffer controller
// -------------------------------------------------------------------------------

// if not equal - can be written to by data so this should work even on overflow
assign data_o 		= (buffer_write_ptr_reg == buffer_read_ptr_reg) ? data_i : buffer_regs[buffer_read_ptr_reg];

reg reject_flag;

integer i;

always @(posedge clock_i) begin
	if (!resetn_i) begin

		buffer_write_ptr_reg 	<= 'b0;
		n_active_reg 			<= 'b0;
		reject_flag 			<= 1'b0;

		for (i = 0; i < N_ENTRIES; i = i + 1) begin
			buffer_regs[i] 			<= 'b0;
		end
	end
	else begin

		// address buffer
		// ------------------------------------------
		if (request_i & !valid_i) 		n_active_reg <= n_active_reg + 1'b1;
		else if (!request_i & valid_i) 	n_active_reg <= n_active_reg - 1'b1;

		// data buffer
		// ------------------------------------------
		if (clear_i) begin
			buffer_write_ptr_reg 	<= 'b0;

			// if there is a pipeline stall during clear command, must reject the next service
			// IF if it not being return this cycle
			if (!valid_i & (n_active_reg != 'b0)) begin
				reject_flag 		<= 1'b1;
			end

		end
		// if incoming data is valid and controller read from buffer last cycle
		else if (valid_i) begin

			if (reject_flag) begin
				reject_flag <= 1'b0;
			end
			else begin
				buffer_regs[buffer_write_ptr_reg] 	<= data_i;
				buffer_write_ptr_reg 				<= buffer_write_ptr_reg + 1'b1;
			end
		end
	end
end 

// read clock
always @(negedge clock_i) begin
	// reset condition
	if (!resetn_i) 			buffer_read_ptr_reg 	<= 'b0;
	// active sequencing
	else begin
		if 		(clear_i) 	buffer_read_ptr_reg 	<= 'b0;
		else if (read_i) 	buffer_read_ptr_reg 	<= buffer_read_ptr_reg + 1'b1;
	end
end


endmodule

`endif