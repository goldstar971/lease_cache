module one_hot_decoder #(
	parameter INPUT_BW = 0
)(
	input 	[INPUT_BW-1:0]		binary_i,
	output 	[OUTPUT_SIZE-1:0]	encoding_o
);

// parameterizations
// ------------------------------------------------------------------------
localparam OUTPUT_SIZE = 2**INPUT_BW;


// port mappings
// ------------------------------------------------------------------------
assign encoding_o = 1'b1 << binary_i;

endmodule