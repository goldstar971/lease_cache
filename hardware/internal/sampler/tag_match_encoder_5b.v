module tag_match_encoder_5b(
input [31:0] match_bits,
	output reg [4:0] match_index_reg,
 output reg actual_match);
wire [1:0] or_o[4:0];
wire [4:0] match_index;
	assign or_o[0][0]=|({match_bits[1],match_bits[3],match_bits[5],match_bits[7],match_bits[9],match_bits[11],match_bits[13],match_bits[15]});
	assign or_o[0][1]=|({match_bits[17],match_bits[19],match_bits[21],match_bits[23],match_bits[25],match_bits[27],match_bits[29],match_bits[31]});
	assign match_index[0]=|({or_o[0][0],or_o[0][1]});
	assign or_o[1][0]=|({match_bits[2],match_bits[3],match_bits[6],match_bits[7],match_bits[10],match_bits[11],match_bits[14],match_bits[15]});
	assign or_o[1][1]=|({match_bits[18],match_bits[19],match_bits[22],match_bits[23],match_bits[26],match_bits[27],match_bits[30],match_bits[31]});
	assign match_index[1]=|({or_o[1][0],or_o[1][1]});
	assign or_o[2][0]=|({match_bits[4],match_bits[5],match_bits[6],match_bits[7],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[2][1]=|({match_bits[20],match_bits[21],match_bits[22],match_bits[23],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign match_index[2]=|({or_o[2][0],or_o[2][1]});
	assign or_o[3][0]=|({match_bits[8],match_bits[9],match_bits[10],match_bits[11],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[3][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign match_index[3]=|({or_o[3][0],or_o[3][1]});
	assign or_o[4][0]=|({match_bits[16],match_bits[17],match_bits[18],match_bits[19],match_bits[20],match_bits[21],match_bits[22],match_bits[23]});
	assign or_o[4][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign match_index[4]=|({or_o[4][0],or_o[4][1]});
always@(match_index)begin
	match_index_reg=match_index;
	actual_match=match_index&match_bits[0];
end

endmodule