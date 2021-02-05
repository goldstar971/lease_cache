module data_buffer #(
	parameter BUFFER_SIZE = 4,
	parameter DATA_SIZE = 32
)(
	input 						clock_i,
	input 						resetn_i,
	input 						read_i,
	input 						write_i,
	input	[DATA_SIZE-1:0] 	data_i,
	output	[DATA_SIZE-1:0]		data_o,
	output 						empty_o,
	output 						full_o
);

integer i;
reg 	[DATA_SIZE-1:0]	buffer_regs[0:BUFFER_SIZE-1];
reg 	[1:0]	read_ptr, write_ptr;
reg 	[2:0]	m_active;

assign empty_o = (m_active == 'b0) ? 1'b1 : 1'b0;
assign full_o = (m_active == 3'b100) ? 1'b1 : 1'b0;
assign data_o = buffer_regs[read_ptr];

always @(posedge clock_i) begin
	if (!resetn_i) begin
		for (i = 0; i < BUFFER_SIZE; i = i + 1) buffer_regs[i] = 'b0;
		read_ptr = 'b0;
		write_ptr = 'b0;
		m_active = 'b0;
	end
	else begin
		if (write_i & !full_o) begin
			buffer_regs[write_ptr] = data_i;
			write_ptr = write_ptr + 1'b1;
			m_active = m_active + 1'b1;
		end
		if (read_i & !empty_o) begin
			read_ptr = read_ptr + 1'b1;
			m_active = m_active - 1'b1;
		end
	end
end 

endmodule