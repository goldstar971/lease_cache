module seeded_linear_shift_register_12b (
	input 			clock_i, 
	input 			resetn_i, 
	input 			enable_i, 
	input    [11:0]       seed,
	output 	[11:0] 	result_o
);

// structural definition
wire 	y0;
wire 	y1;
wire 	y2;
wire 	y3;
wire  	y4;
wire 	y5;
wire 	y6;
wire 	y7;
wire 	y8;
wire    y9;
wire    y10;
wire    y11;
wire 	tap12,tap11,tap10,tap4;
xor(tap11, y11,y10);
xor(tap10,tap11,y9);
xor(tap4,tap10,y3);

DFF_Custom dff0 (clock_i, resetn_i, seed[11], enable_i, tap4, y0);
DFF_Custom dff1 (clock_i, resetn_i, seed[10], enable_i, y0, y1);
DFF_Custom dff2 (clock_i, resetn_i, seed[9], enable_i, y1, y2);
DFF_Custom dff3 (clock_i, resetn_i, seed[8], enable_i, y2, y3);
DFF_Custom dff4 (clock_i, resetn_i, seed[7], enable_i, y3, y4);
DFF_Custom dff5 (clock_i, resetn_i, seed[6], enable_i, y4, y5);
DFF_Custom dff6 (clock_i, resetn_i, seed[5], enable_i, y5, y6);
DFF_Custom dff7 (clock_i, resetn_i, seed[4], enable_i, y6, y7);
DFF_Custom dff8 (clock_i, resetn_i, seed[3], enable_i, y7, y8);
DFF_Custom dff9 (clock_i, resetn_i, seed[2], enable_i, y8, y9);
DFF_Custom dff10 (clock_i, resetn_i, seed[1], enable_i, y9, y10);
DFF_Custom dff11 (clock_i, resetn_i, seed[0], enable_i, y10, y11);

assign result_o = {y11,y10,y9,y8,y7,y6,y5,y4,y3,y2,y1,y0};

endmodule