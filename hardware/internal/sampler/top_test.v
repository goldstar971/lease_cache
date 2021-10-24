module top_test(input [511:0] valid, input clock, input reset,output [8:0] leading_0, output valid_match);


pe_valid_match find_leading_zero(.clk(clock), .rst(reset), .oht(~valid),.bin(leading_0),.vld(valid_match));

endmodule