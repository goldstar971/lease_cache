module multiplexer #(
	parameter SIZE_INPUT 	= 0,
	parameter SIZE_DATA 	= 0
)(
	input data_vecd_i,
	output

);


localparam SIZE_INPUTS_VECD = SIZE_INPUT * SIZE_DATA;

endmodule