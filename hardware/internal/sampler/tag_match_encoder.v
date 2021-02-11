

module tag_match_encoder(
input [`N_SAMPLER-1:0] match_bits,
output [`BW_SAMPLER-1:0] match_index
);



wire [3:0] or_o [`BW_SAMPLER-1:0];

	assign or_o[0][0]=|({match_bits[1],match_bits[3],match_bits[5],match_bits[7],match_bits[9],match_bits[11],match_bits[13],match_bits[15]});
	assign or_o[0][1]=|({match_bits[17],match_bits[19],match_bits[21],match_bits[23],match_bits[25],match_bits[27],match_bits[29],match_bits[31]});
	assign or_o[0][2]=|({match_bits[33],match_bits[35],match_bits[37],match_bits[39],match_bits[41],match_bits[43],match_bits[45],match_bits[47]});
	assign or_o[0][3]=|({match_bits[49],match_bits[51],match_bits[53],match_bits[55],match_bits[57],match_bits[59],match_bits[61],match_bits[63]});
	assign match_index[0]=|({or_o[0][0],or_o[0][1],or_o[0][2],or_o[0][3]});
	assign or_o[1][0]=|({match_bits[2],match_bits[3],match_bits[6],match_bits[7],match_bits[10],match_bits[11],match_bits[14],match_bits[15]});
	assign or_o[1][1]=|({match_bits[18],match_bits[19],match_bits[22],match_bits[23],match_bits[26],match_bits[27],match_bits[30],match_bits[31]});
	assign or_o[1][2]=|({match_bits[34],match_bits[35],match_bits[38],match_bits[39],match_bits[42],match_bits[43],match_bits[46],match_bits[47]});
	assign or_o[1][3]=|({match_bits[50],match_bits[51],match_bits[54],match_bits[55],match_bits[58],match_bits[59],match_bits[62],match_bits[63]});
	assign match_index[1]=|({or_o[1][0],or_o[1][1],or_o[1][2],or_o[1][3]});
	assign or_o[2][0]=|({match_bits[4],match_bits[5],match_bits[6],match_bits[7],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[2][1]=|({match_bits[20],match_bits[21],match_bits[22],match_bits[23],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[2][2]=|({match_bits[36],match_bits[37],match_bits[38],match_bits[39],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[2][3]=|({match_bits[52],match_bits[53],match_bits[54],match_bits[55],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign match_index[2]=|({or_o[2][0],or_o[2][1],or_o[2][2],or_o[2][3]});
	assign or_o[3][0]=|({match_bits[8],match_bits[9],match_bits[10],match_bits[11],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[3][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[3][2]=|({match_bits[40],match_bits[41],match_bits[42],match_bits[43],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[3][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign match_index[3]=|({or_o[3][0],or_o[3][1],or_o[3][2],or_o[3][3]});
	assign or_o[4][0]=|({match_bits[16],match_bits[17],match_bits[18],match_bits[19],match_bits[20],match_bits[21],match_bits[22],match_bits[23]});
	assign or_o[4][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[4][2]=|({match_bits[48],match_bits[49],match_bits[50],match_bits[51],match_bits[52],match_bits[53],match_bits[54],match_bits[55]});
	assign or_o[4][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign match_index[4]=|({or_o[4][0],or_o[4][1],or_o[4][2],or_o[4][3]});
	assign or_o[5][0]=|({match_bits[32],match_bits[33],match_bits[34],match_bits[35],match_bits[36],match_bits[37],match_bits[38],match_bits[39]});
	assign or_o[5][1]=|({match_bits[40],match_bits[41],match_bits[42],match_bits[43],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[5][2]=|({match_bits[48],match_bits[49],match_bits[50],match_bits[51],match_bits[52],match_bits[53],match_bits[54],match_bits[55]});
	assign or_o[5][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign match_index[5]=|({or_o[5][0],or_o[5][1],or_o[5][2],or_o[5][3]});

	
endmodule
		
