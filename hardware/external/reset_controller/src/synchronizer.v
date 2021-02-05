module synchronizer (
	input 		clock,    			// clock from pin
	input 		reset,
	input 		in,
	output reg	out
);

// 3 stage synchronizer chain
reg ff0, ff1;
always @(posedge clock) begin
	if (reset != 1'b1) begin
		ff0 <= 1'b0; 				// reset active low
		ff1 <= 1'b0;
		out <= 1'b0;
	end
	else begin
		ff0 <= in;
		ff1 <= ff0;
		out <= ff1;
	end
end

endmodule