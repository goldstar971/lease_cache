`timescale 1 ns / 1 ns

`include "../include/top.h"

module test;

parameter N_REGS = 4;
parameter BW_DATA = 6;
parameter BW_REGS = `CLOG2(N_REGS);

reg 				clock_reg,
					reset_reg,
					write_reg;
reg [BW_REGS-1:0] 	addr_reg;
reg [BW_DATA-1:0]	data_reg;
wire [BW_REGS-1:0]	data_bus;


// dut
approx_circuit #(
	.N_REGS 	(N_REGS 		),
	.DATA_SIZE 	(BW_DATA 		)
) dut (
	.clock_i 	(clock_reg 		),
	.resetn_i 	(reset_reg 		),
	.write_i 	(write_reg 	 	),
	.addr_i 	(addr_reg 		),
	.data_i 	(data_reg 		),
	.data_o 	(data_bus 		)
);

always #10 clock_reg = ~clock_reg;

reg 	[9:0] 	iterations_reg;
reg 	[9:0]	correct_reg;

initial begin
	reset_reg = 1'b0;
	clock_reg = 1'b0;
	write_reg = 1'b0;
	addr_reg = 'b0;
	data_reg = 'b0;
	iterations_reg = 'b0;
	correct_reg = 'b0;
	#100;
	reset_reg = 1'b1;

	// write data, pause, examine, check
	while(iterations_reg < 20) begin
		write_reg = 1'b1;
		addr_reg = $urandom;
		data_reg = $urandom;
		#40;
		iterations_reg = iterations_reg + 1'b1;
	end


	$stop;

end



endmodule