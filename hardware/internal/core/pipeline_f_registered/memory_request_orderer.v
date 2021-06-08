// if core and cache clock on rising edge, this needs to clock on negative edge
// note that pipeline data buffer writes-in on the rising edge, so this hardware
// should writeout on the falling edge

module memory_request_orderer #(
	parameter N_ENTRIES = 0, 					// size of tracking buffer
	parameter BW_DATA 	= 0,
	parameter BW_ADDR 	= 0
)(
	input 					clock_i, 			// trigger for registering inputs
	input 					resetn_i,
	input 					hart_request_i,
	input 					hart_wren_i,
	input 	[BW_ADDR-1:0]	hart_addr_i,
	output 					hart_valid_o,
	output 	[BW_DATA-1:0] 	hart_data_o,
	output 					memory_request_o,
	input 	[BW_DATA-1:0]	memory_data_i,
	input 					memory_valid_i,
	output 					io_request_o,
	input 	[BW_DATA-1:0]	io_data_i,
	input 					io_valid_i
);

// parameterizations
// ------------------------------------------------------------------------------------------
localparam BW_ENTRIES 	= `CLOG2(N_ENTRIES);

localparam REQ_MEM 		= 2'b01;
localparam REQ_IO 		= 2'b10;

localparam MUX_MEM 		= 2'b00;
localparam MUX_IO 		= 2'b01;
localparam MUX_IO_BUF 	= 2'b10;


// internal signals
// ------------------------------------------------------------------------------------------
wire 	memory_load_request, io_load_request;

assign memory_request_o = hart_request_i & !hart_addr_i[26]; 	// if peripheral bit not set then route to memory
assign io_request_o = hart_request_i & hart_addr_i[26]; 		// if peripheral bit set then route to io registers
assign memory_load_request = memory_request_o & !hart_wren_i; 	// special designation for loads bc. they are recorded in request stack
assign io_load_request = io_request_o & !hart_wren_i; 			// ^


// declare signals that would require buffer incoming data
reg 	[1:0]				io_flag_reg;
reg 	[BW_DATA-1:0]		io_data_reg;
reg 	[1:0]				mux_select_reg;
reg 	[1:0]				tracking_buffer_regs [0:N_ENTRIES-1];
reg 	[BW_ENTRIES-1:0]	request_ptr_reg;
reg 	[BW_ENTRIES-1:0]	valid_ptr_reg;


assign hart_valid_o = 	(mux_select_reg == MUX_IO) 		? io_valid_i : 
						(mux_select_reg == MUX_IO_BUF) 	? 1'b1 :
						memory_valid_i;
assign hart_data_o 	= 	(mux_select_reg == MUX_IO) 		? io_data_i : 
						(mux_select_reg == MUX_IO_BUF) 	? io_data_reg :
						memory_data_i;


// request history controller
// -------------------------------------------------- 
integer i;
always @(posedge clock_i) begin
	if (!resetn_i) begin
		mux_select_reg 	<= MUX_MEM;
		io_flag_reg 	<= 'b0;
		io_data_reg 	<= 'b0;
		request_ptr_reg <= 'b0;
		valid_ptr_reg 	<= 'b0;
		for (i = 0; i < N_ENTRIES; i = i + 1) tracking_buffer_regs[i] <= 'b0;
	end
	else begin

		// default mux behavior is to pass memory references
		mux_select_reg <= MUX_MEM;

		// if the io_flag is set check that memory valid is seen before muxing
		if (memory_valid_i & (io_flag_reg == 2'b10)) begin
			io_flag_reg 	<= io_flag_reg - 1'b1;
			valid_ptr_reg 	<= valid_ptr_reg + 1'b1;
		end
		else if (io_flag_reg == 2'b01) begin
			io_flag_reg 	<= io_flag_reg - 1'b1;
			valid_ptr_reg 	<= valid_ptr_reg + 1'b1;
			mux_select_reg 	<= MUX_IO_BUF;
		end

		// request tracking
		if (memory_load_request) begin
			tracking_buffer_regs[request_ptr_reg] <= REQ_MEM;
			request_ptr_reg <= request_ptr_reg + 1'b1;
		end

		if (io_load_request) begin
			tracking_buffer_regs[request_ptr_reg] <= REQ_IO;
			request_ptr_reg <= request_ptr_reg + 1'b1;
		end

		// valid operations
		if (io_valid_i & (tracking_buffer_regs[valid_ptr_reg] == REQ_IO)) begin
			mux_select_reg 	<= MUX_IO;
			valid_ptr_reg 	<= valid_ptr_reg + 1'b1;
		end
		else if (memory_valid_i & (tracking_buffer_regs[valid_ptr_reg] == REQ_MEM)) begin
			mux_select_reg 	<= MUX_MEM;
			valid_ptr_reg 	<= valid_ptr_reg + 1'b1;
		end

		// invalid operation - need to register inputs
		// note: cannot have invalid memory_valid
		else if (io_valid_i & (tracking_buffer_regs[valid_ptr_reg] != REQ_IO)) begin
			mux_select_reg 	<= MUX_MEM;
			io_flag_reg 	<= 2'b10;
			io_data_reg 	<= io_data_i;
		end

	end
end


endmodule