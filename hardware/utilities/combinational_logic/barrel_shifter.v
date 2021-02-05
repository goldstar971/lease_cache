// shifts MSb of data_i to the LSb of data_o

`ifndef _BARREL_SHIFTER_V_
`define _BARREL_SHIFTER_V_

module barrel_shifter #(
	parameter BW_DATA = 4

	`ifdef SIMULATION_SYNTHESIS ,
	parameter BW_SHIFT = `CLOG2(BW_DATA)
	`endif

)(
	input  	[BW_DATA-1:0] 	data_i,
	input 	[BW_SHIFT-1:0]	shift_i,
	output	[BW_DATA-1:0] 	data_o
);

// parameterizations
// ----------------------------------------------------------------------
`ifndef SIMULATION_SYNTHESIS
localparam BW_SHIFT = `CLOG2(BW_DATA);
`endif

// combinational logic
// ----------------------------------------------------------------------
wire 	[2*BW_DATA-1:0]	barrel_bus;

assign barrel_bus = {data_i,data_i};
//assign data_o = barrel_bus[shift_i+:BW_DATA];
//assign data_o = barrel_bus[shift_i+:BW_DATA];

// puts lsb into msb


// puts msb into lsb
assign data_o = barrel_bus[((BW_DATA)-shift_i)+:BW_DATA];

endmodule

`endif