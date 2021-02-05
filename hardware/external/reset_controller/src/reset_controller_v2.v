module reset_controller_v2(
	input 				clock,
	input 				reset_i,
	output 	reg	[2:0]	reset_bus_o,
	input 				req_i,
	input 		[1:0]	config_i
);

always @(posedge clock) begin

	if (reset_i != 1'b1) begin
		reset_bus_o <= 'b0;
	end
	else begin
		// default 
		reset_bus_o[0] <= reset_i;

		if (req_i) reset_bus_o[2:1] <= config_i;

	end
end

endmodule