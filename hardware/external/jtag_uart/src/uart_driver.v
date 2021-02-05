//
//		_________ 		
// 		|		| <---	full_i 	<--- 	|-------------------|
//		|		| ---> write_o 	--->	|	Writeout buffer	|
//		|		| ---> data_o 	--->	|-------------------|		
// 		|		| 
// 		|		| <--- empty_i 	<--- 	|-------------------|
//		|		| ---> read_o 	--->	|	Readin buffer	|
//		|_______| <--- data_i 	<---	|-------------------|
//
//

`define ST_UART_IDLE 		2'b00
`define ST_UART_RECEIVE 	2'b01
`define ST_UART_TRANSMIT 	2'b10
`define ST_UART_WRITEOUT 	2'b11

module uart_controller(
	input 			clock_i, 		
	input 			resetn_i,
	input 			full_i,
	input 			empty_i,
	input 	[31:0]	data_i,
	output 			read_o,
	output 			write_o,
	output 	[31:0]	data_o
);

// jtag port hardware
// -------------------------------------------------------------------------------------------------------------------------------
reg 			uart_receive, uart_transmit;
wire 	[31:0]	uart_receive_data;
reg 	[31:0]	uart_transmit_data;
wire 			uart_ready, uart_full, uart_dataAvailable;

uart_jtag_uart_0 uart0 (

	// inputs
	.av_address		(1'b0),					// zero for data, 1 for interrupt (ignore interrupt)
	.av_chipselect	(resetn_i),				// 1 to enable jtag
	.av_read_n		(uart_receive),		
	.av_write_n		(uart_transmit),
	.av_writedata	(uart_transmit_data),
	.clk 			(clock_i),					
	.rst_n			(resetn_i),				// reset active low

  	// outputs
   .av_irq(),								// 1: fifo is full?
   .av_readdata		(uart_receive_data), 	// rx data
   .av_waitrequest	(),						// 1: jtag resetting - not ready for data? (this is accounted for in other ways)
   .dataavailable 	(uart_dataAvailable),	// 1: data in rx fifo
   .readyfordata 	(uart_ready),			// 1: tx fifo full
   .fifo_FF 		(uart_full)				// custom add

);

// uart controller state machine
// -------------------------------------------------------------------------------------------------------------------------------
reg [1:0]	state, state_next;
reg 		latency_timer, flag_switch;
reg [1:0]	byte_counter;

reg 		read_reg, write_reg;
reg [31:0]	write_data_reg;
assign read_o = read_reg;
assign write_o = write_reg;
assign data_o = write_data_reg;

localparam ACTIVE = 1'b0;
localparam NONACTIVE = 1'b1;

always @(posedge clock_i) begin
	if (!resetn_i) begin
		state = `ST_UART_IDLE;
		state_next = `ST_UART_TRANSMIT;
		latency_timer <= 1'b0;
		flag_switch <= 1'b0;
		byte_counter = 'b0;

		read_reg = 1'b0;
		write_reg = 1'b0;
		write_data_reg = 'b0;

		uart_receive = NONACTIVE;
		uart_transmit = NONACTIVE;
		uart_transmit_data = 'b0;
	end
	else begin

		// defaults
		read_reg = 1'b0;
		write_reg = 1'b0;

		if (latency_timer) latency_timer = latency_timer - 1'b1;
		else begin
			case(state)
				`ST_UART_IDLE: begin	
					// if uart has data to receive and readin buffer has data to send
					if (!empty_i & uart_dataAvailable) begin
						state = `ST_UART_TRANSMIT;
						state_next = `ST_UART_RECEIVE;
					end
					// if uart has data to receive only
					else if (uart_dataAvailable) begin
						state = `ST_UART_RECEIVE;
						state_next = `ST_UART_IDLE;
					end
					// if readin buffer has data to send only
					else if (!empty_i) begin
						uart_transmit_data = data_i;
						read_reg = 1'b1;
						state = `ST_UART_TRANSMIT;
						state_next = `ST_UART_IDLE;
					end
				end
				`ST_UART_RECEIVE: begin
					if (uart_ready & uart_dataAvailable) begin
						case(flag_switch)
							1'b0: begin
								flag_switch = 1'b1;
								latency_timer = 1'b1;
								uart_receive = ACTIVE;
							end
							1'b1: begin
								flag_switch = 1'b0;
								uart_receive = NONACTIVE;
								write_data_reg = {write_data_reg[23:0], uart_receive_data[7:0]};

								// if entire word transfered then continue sequencing, else repeat
								if (byte_counter == 2'b11) begin
									byte_counter = 2'b00;
									state = `ST_UART_WRITEOUT;
								end
								else begin
									byte_counter = byte_counter + 1'b1;
								end
							end
						endcase
					end
				end

				`ST_UART_TRANSMIT: begin
					// wait until hardware is ready to send
					//if (uart_ready & !uart_full) begin
					if (uart_ready & uart_receive_data[13]) begin	
						case(flag_switch)
							1'b0: begin
								flag_switch = 1'b1;
								uart_transmit = ACTIVE;
								latency_timer <= 1'b1;
							end
							1'b1: begin
								flag_switch = 1'b0;
								uart_transmit = NONACTIVE;
								uart_transmit_data = uart_transmit_data >> 8;

								// if entire word transfered then continue sequencing, else repeat
								if (byte_counter == 2'b11) begin
									byte_counter = 2'b00;
									state = state_next;
								end
								else begin
									byte_counter = byte_counter + 1'b1;
								end
							end
						endcase
					end
				end

				`ST_UART_WRITEOUT: begin
					// only proceed if the writeout buffer can be written to
					if (!full_i) begin 
						write_reg = 1'b1;
						//write_data_reg = uart_receive_data;
						state = `ST_UART_IDLE;
					end
				end
				
			endcase
		end
	end
end

endmodule

