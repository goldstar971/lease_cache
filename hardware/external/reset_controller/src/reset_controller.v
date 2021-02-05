module reset_controller(
	input 				clock,
	input 				lock_i,
	input 				reset_i,
	output 	reg	[2:0]	reset_bus_o, 		// [0] - reset jtag controller
											// [1] - control system
											// [2] - core
											// [3] - internal memory
											// [4] - peripherals 
	input 				req_i,
	input 		[1:0]	config_i
);

// synchronize external async. reset signal
// reset active low
wire 	reset_sync;
synchronizer reset_sync_inst(.clock(clock), .reset(lock_i), .in(reset_i), .out(reset_sync));

always @(posedge clock) begin

	// default
	reset_bus_o[0] <= reset_sync;

	// reconfiguration logic
	if (reset_sync != 1'b1) begin
		reset_bus_o[2:1] <= 2'b00; 		// all subsystems in reset by default
	end
	else begin
		if (req_i) begin
			reset_bus_o[2:1] <= config_i;
		end
	end
end

endmodule