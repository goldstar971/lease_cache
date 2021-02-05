module linear_shift_register_9b(clock, reset, enable, out);

// module i/o
input 			clock;
input 			reset;
input 			enable;
output	[8:0] 	out;

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
wire 	tap4;
xor(tap4, y3, y8);
DFF_Custom dff0 (clock, reset, 1'b0, enable, y8, y0);
DFF_Custom dff1 (clock, reset, 1'b0, enable, y0, y1);
DFF_Custom dff2 (clock, reset, 1'b0, enable, y1, y2);
DFF_Custom dff3 (clock, reset, 1'b0, enable, y2, y3);
DFF_Custom dff4 (clock, reset, 1'b1, enable, tap4, y4);
DFF_Custom dff5 (clock, reset, 1'b0, enable, y4, y5);
DFF_Custom dff6 (clock, reset, 1'b0, enable, y5, y6);
DFF_Custom dff7 (clock, reset, 1'b0, enable, y6, y7);
DFF_Custom dff8 (clock, reset, 1'b1, enable, y7, y8);

assign out = {y0,y1,y2,y3,y4,y5,y6,y7,y8};

endmodule