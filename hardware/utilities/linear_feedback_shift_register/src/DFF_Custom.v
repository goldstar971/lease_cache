// Parameterized D-Flip-Flop

module DFF_Custom(clk, reset, resetValue, enable, in0, out0);

// parameterizations
parameter size = 1;

// module i/o
input 					clk;
input 					reset;
input 		[size-1:0]	resetValue;
input 					enable;
input 		[size-1:0] 	in0;
output reg	[size-1:0]	out0;

// behavorial description
always @(posedge clk, negedge reset) begin

	// reset condition
	if (!reset) 
		out0 = resetValue;
	// nominal operation
	else begin
		// if enabled
		if (enable) 
			out0 = in0;
		else
			out0 = out0;
	end

end

endmodule
