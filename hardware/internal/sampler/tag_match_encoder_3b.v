module tag_match_encoder_3b(
input [7:0] match_bits,
	output reg [2:0] match_index_reg,
 output reg actual_match);
wire [2:0] or_o[2:0];
wire [2:0] match_index;
	assign or_o[0][0]=|({match_bits[1],match_bits[3],match_bits[5],match_bits[7],	assign match_index[0]=|({or_o[0][0]});
	assign or_o[1][0]=|({match_bits[2],match_bits[3],match_bits[6],match_bits[7],	assign match_index[1]=|({or_o[1][0]});
	assign or_o[2][0]=|({match_bits[4],match_bits[5],match_bits[6],match_bits[7],	assign match_index[2]=|({or_o[2][0]});
always@(match_index)begin
	match_index_reg=match_index;
	actual_match=match_index&match_bits[0];
end

endmodule