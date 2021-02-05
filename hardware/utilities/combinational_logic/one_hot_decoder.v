`ifndef _ONE_HOT_DECODER_V_
`define _ONE_HOT_DECODER_V_

module one_hot_decoder #(
	parameter INPUT_BW = 0

	`ifdef SIMULATION_SYNTHESIS
	,
	parameter OUTPUT_SIZE = 2**INPUT_BW
	`endif

)(
	input 	[INPUT_BW-1:0]		binary_i,
	output 	[OUTPUT_SIZE-1:0]	encoding_o
);

// parameterizations
// ------------------------------------------------------------------------
`ifndef SIMULATION_SYNTHESIS
localparam OUTPUT_SIZE = 2**INPUT_BW;
`endif

// port mappings
// ------------------------------------------------------------------------
assign encoding_o = 1'b1 << binary_i;

endmodule

`endif