// include

module uart_system_2(
	input 		[2:0]	clock_bus_i,
	input 				resetn_i,
	input 				ready_i, done_i, valid_i,
	input 		[31:0]	data_i,
	output  	[2:0]	reqdev_o,
	output  			req_o,
	output  			req_block_o,
	output  			rw_o,
	output  	[26:0]	add_o,					// addresses are byte addressible (64MB mem, above that are peripherals)
	output  	[31:0]	data_o,
	output  			clear_o,
	output  			exception_o
);

assign exception_o = 1'b0;

// signals are essential compliements, a put for uart is a get for comm, etc.
wire 		uart_full, uart_empty;
wire 		uart_put, uart_get;
wire [31:0]	uart_put_data, uart_get_data;

wire 		comm_full, comm_empty;
wire 		comm_put, comm_get;
wire [31:0]	comm_put_data, comm_get_data;	

uart_jtag_driver #(
	.BYTES_PER_PACKET 		(`UART_JTAG_N_BYTES_PER_PACKET 	),
	.BW_BYTES_PER_PACKET 	(`UART_JTAG_BW_BYTES_PER_PACKET	),
	.BW_PACKET 				(`UART_JTAG_BW_PACKET 			)
)uart_jtag_inst(
	.clock_i				(clock_bus_i[1]					), 		
	.resetn_i				(resetn_i						),
	.full_i					(uart_full 						),
	.empty_i				(uart_empty 					),
	.data_i					(uart_get_data 					),
	.read_o					(uart_get 						),
	.write_o				(uart_put 						),
	.data_o					(uart_put_data 					)
);

data_buffer_ccd #(.BUFFER_SIZE(4), .DATA_SIZE(32), .CCD_POLARITY(0)) uart_rx_buffer(
	.clock_fast_i	(clock_bus_i[2]),
	.clock_slow_i	(clock_bus_i[0]),		
	.resetn_i		(resetn_i),
	.read_i 		(comm_get),
	.write_i 		(uart_put),
	.data_i 		(uart_put_data),
	.data_o 		(comm_get_data),
	.empty_o 		(comm_empty),
	.full_o 		(uart_full)
);

data_buffer_ccd #(.BUFFER_SIZE(4), .DATA_SIZE(32), .CCD_POLARITY(1)) uart_tx_buffer(
	.clock_fast_i	(clock_bus_i[2]),
	.clock_slow_i	(clock_bus_i[0]), 		
	.resetn_i		(resetn_i),
	.read_i 		(uart_get),
	.write_i 		(comm_put),
	.data_i 		(comm_put_data),
	.data_o 		(uart_get_data),
	.empty_o 		(uart_empty),
	.full_o 		(comm_full)
);
comm_controller_v3 comm_inst(
	.clock_i		(clock_bus_i[0]), 		
	.resetn_i		(resetn_i),
	.tx_full_i		(comm_full),
	.rx_empty_i		(comm_empty),
	.rx_data_i		(comm_get_data),
	.rx_read_o		(comm_get),
	.tx_write_o		(comm_put), 			// data data into uart_tx_buffer (to be sent out to the host)
	.tx_data_o		(comm_put_data),
	.ready_i		(ready_i), 
	.done_i			(done_i), 
	.valid_i		(valid_i),
	.data_i 		(data_i),
	.reqdev_o 		(reqdev_o),
	.req_o 			(req_o),
	.req_block_o 	(req_block_o),
	.rw_o 			(rw_o),
	.add_o 			(add_o),					
	.data_o 		(data_o),
	.clear_o 		(clear_o),
	.exception_o 	(exception_o)
);

endmodule