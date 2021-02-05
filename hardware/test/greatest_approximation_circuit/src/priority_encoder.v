//`include "../../../include/utilities.h"

// encoder prioritives lowest index (thus loop begins at highest numeric location)

module priority_encoder #(
	parameter INPUT_SIZE = 0
)(
	input 	[INPUT_SIZE-1:0]		encoding_i,
	output	[BW_INPUT_SIZE-1:0]		binary_o
);

localparam BW_INPUT_SIZE = `CLOG2(INPUT_SIZE);

reg [BW_INPUT_SIZE-1:0]	binary_output_reg;
assign binary_o = binary_output_reg;

integer i;
always @(*) begin

	// default if everything is zero
	binary_output_reg = 'b0;

	//for (i = 0; i < INPUT_SIZE; i = i + 1) begin
	for (i = INPUT_SIZE-1; i >= 0; i = i - 1) begin
		if (encoding_i[i]) binary_output_reg = i[BW_INPUT_SIZE-1:0];
	end

end

endmodule