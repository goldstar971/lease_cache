module data_buffer_ccd #(
	parameter BUFFER_SIZE 	= 4,
	parameter DATA_SIZE 	= 32,
	parameter CCD_POLARITY 	= 0
)(
	input 						clock_fast_i,
	input 						clock_slow_i,
	input 						resetn_i,
	input 						read_i,
	input 						write_i,
	input	[DATA_SIZE-1:0] 	data_i,
	output	[DATA_SIZE-1:0]		data_o,
	output 						empty_o,
	output 						full_o
);

localparam BW_BUFFER_SIZE = `CLOG2(BUFFER_SIZE);

integer i;
reg 	[DATA_SIZE-1:0]			buffer_regs[0:BUFFER_SIZE-1];
reg 	[BW_BUFFER_SIZE-1:0]	read_ptr, write_ptr;
reg 	[BW_BUFFER_SIZE:0]		m_active;
reg 							flag_ccd;
reg 							flag_enable;

assign empty_o 	= (m_active == 'b0) 	? 1'b1 : 1'b0;
assign full_o 	= (m_active == 3'b100) 	? 1'b1 : 1'b0;
assign data_o 	= buffer_regs[read_ptr];

always @(posedge clock_fast_i) begin
	if (!resetn_i) begin
		for (i = 0; i < BUFFER_SIZE; i = i + 1) buffer_regs[i] = 'b0;
		read_ptr 	= 'b0;
		write_ptr 	= 'b0;
		m_active 	= 'b0;
		flag_ccd 	= 1'b1; 	// must see a falling edge first
	end
	else begin

		// CCD Control
		case(flag_ccd)
			1'b0: begin
				if (clock_slow_i) begin
					flag_ccd 	= 1'b1;
					flag_enable = 1'b1;
				end
			end

			1'b1: begin
				if (!clock_slow_i) begin
					flag_ccd 	= 1'b0;
					flag_enable = 1'b0;
				end
			end
		endcase

		// buffer transaction control
		// ----------------------------------------------------
		if (CCD_POLARITY) begin
			// if writing side is the slow domain 
			if (write_i & !full_o & flag_enable) begin
				buffer_regs[write_ptr] 	= data_i;
				write_ptr 				= write_ptr + 1'b1;
				m_active 				= m_active + 1'b1;
				flag_enable 			= 1'b0;
			end
			if (read_i & !empty_o) begin
				read_ptr 				= read_ptr + 1'b1;
				m_active 				= m_active - 1'b1;
			end
 		end
 		// if reading side is the slow domain
		else begin
			if (write_i & !full_o) begin
				buffer_regs[write_ptr] 	= data_i;
				write_ptr 				= write_ptr + 1'b1;
				m_active 				= m_active + 1'b1;
			end
			if (read_i & !empty_o & flag_enable) begin
				read_ptr 				= read_ptr + 1'b1;
				m_active 				= m_active - 1'b1;
				flag_enable 			= 1'b0;
			end
	 	end
	end
end 

endmodule