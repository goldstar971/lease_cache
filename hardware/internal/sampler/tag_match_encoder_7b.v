module tag_match_encoder_7b(
input [127:0] match_bits,
	output reg [6:0] match_index_reg,
 output reg actual_match);
wire [7:0] or_o[6:0];
wire [6:0] match_index;
	assign or_o[0][0]=|({match_bits[1],match_bits[3],match_bits[5],match_bits[7],match_bits[9],match_bits[11],match_bits[13],match_bits[15]});
	assign or_o[0][1]=|({match_bits[17],match_bits[19],match_bits[21],match_bits[23],match_bits[25],match_bits[27],match_bits[29],match_bits[31]});
	assign or_o[0][2]=|({match_bits[33],match_bits[35],match_bits[37],match_bits[39],match_bits[41],match_bits[43],match_bits[45],match_bits[47]});
	assign or_o[0][3]=|({match_bits[49],match_bits[51],match_bits[53],match_bits[55],match_bits[57],match_bits[59],match_bits[61],match_bits[63]});
	assign or_o[0][4]=|({match_bits[65],match_bits[67],match_bits[69],match_bits[71],match_bits[73],match_bits[75],match_bits[77],match_bits[79]});
	assign or_o[0][5]=|({match_bits[81],match_bits[83],match_bits[85],match_bits[87],match_bits[89],match_bits[91],match_bits[93],match_bits[95]});
	assign or_o[0][6]=|({match_bits[97],match_bits[99],match_bits[101],match_bits[103],match_bits[105],match_bits[107],match_bits[109],match_bits[111]});
	assign or_o[0][7]=|({match_bits[113],match_bits[115],match_bits[117],match_bits[119],match_bits[121],match_bits[123],match_bits[125],match_bits[127]});
	assign match_index[0]=|({or_o[0][0],or_o[0][1],or_o[0][2],or_o[0][3],or_o[0][4],or_o[0][5],or_o[0][6],or_o[0][7]});
	assign or_o[1][0]=|({match_bits[2],match_bits[3],match_bits[6],match_bits[7],match_bits[10],match_bits[11],match_bits[14],match_bits[15]});
	assign or_o[1][1]=|({match_bits[18],match_bits[19],match_bits[22],match_bits[23],match_bits[26],match_bits[27],match_bits[30],match_bits[31]});
	assign or_o[1][2]=|({match_bits[34],match_bits[35],match_bits[38],match_bits[39],match_bits[42],match_bits[43],match_bits[46],match_bits[47]});
	assign or_o[1][3]=|({match_bits[50],match_bits[51],match_bits[54],match_bits[55],match_bits[58],match_bits[59],match_bits[62],match_bits[63]});
	assign or_o[1][4]=|({match_bits[66],match_bits[67],match_bits[70],match_bits[71],match_bits[74],match_bits[75],match_bits[78],match_bits[79]});
	assign or_o[1][5]=|({match_bits[82],match_bits[83],match_bits[86],match_bits[87],match_bits[90],match_bits[91],match_bits[94],match_bits[95]});
	assign or_o[1][6]=|({match_bits[98],match_bits[99],match_bits[102],match_bits[103],match_bits[106],match_bits[107],match_bits[110],match_bits[111]});
	assign or_o[1][7]=|({match_bits[114],match_bits[115],match_bits[118],match_bits[119],match_bits[122],match_bits[123],match_bits[126],match_bits[127]});
	assign match_index[1]=|({or_o[1][0],or_o[1][1],or_o[1][2],or_o[1][3],or_o[1][4],or_o[1][5],or_o[1][6],or_o[1][7]});
	assign or_o[2][0]=|({match_bits[4],match_bits[5],match_bits[6],match_bits[7],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[2][1]=|({match_bits[20],match_bits[21],match_bits[22],match_bits[23],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[2][2]=|({match_bits[36],match_bits[37],match_bits[38],match_bits[39],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[2][3]=|({match_bits[52],match_bits[53],match_bits[54],match_bits[55],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[2][4]=|({match_bits[68],match_bits[69],match_bits[70],match_bits[71],match_bits[76],match_bits[77],match_bits[78],match_bits[79]});
	assign or_o[2][5]=|({match_bits[84],match_bits[85],match_bits[86],match_bits[87],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[2][6]=|({match_bits[100],match_bits[101],match_bits[102],match_bits[103],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[2][7]=|({match_bits[116],match_bits[117],match_bits[118],match_bits[119],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign match_index[2]=|({or_o[2][0],or_o[2][1],or_o[2][2],or_o[2][3],or_o[2][4],or_o[2][5],or_o[2][6],or_o[2][7]});
	assign or_o[3][0]=|({match_bits[8],match_bits[9],match_bits[10],match_bits[11],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[3][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[3][2]=|({match_bits[40],match_bits[41],match_bits[42],match_bits[43],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[3][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[3][4]=|({match_bits[72],match_bits[73],match_bits[74],match_bits[75],match_bits[76],match_bits[77],match_bits[78],match_bits[79]});
	assign or_o[3][5]=|({match_bits[88],match_bits[89],match_bits[90],match_bits[91],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[3][6]=|({match_bits[104],match_bits[105],match_bits[106],match_bits[107],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[3][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign match_index[3]=|({or_o[3][0],or_o[3][1],or_o[3][2],or_o[3][3],or_o[3][4],or_o[3][5],or_o[3][6],or_o[3][7]});
	assign or_o[4][0]=|({match_bits[16],match_bits[17],match_bits[18],match_bits[19],match_bits[20],match_bits[21],match_bits[22],match_bits[23]});
	assign or_o[4][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[4][2]=|({match_bits[48],match_bits[49],match_bits[50],match_bits[51],match_bits[52],match_bits[53],match_bits[54],match_bits[55]});
	assign or_o[4][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[4][4]=|({match_bits[80],match_bits[81],match_bits[82],match_bits[83],match_bits[84],match_bits[85],match_bits[86],match_bits[87]});
	assign or_o[4][5]=|({match_bits[88],match_bits[89],match_bits[90],match_bits[91],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[4][6]=|({match_bits[112],match_bits[113],match_bits[114],match_bits[115],match_bits[116],match_bits[117],match_bits[118],match_bits[119]});
	assign or_o[4][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign match_index[4]=|({or_o[4][0],or_o[4][1],or_o[4][2],or_o[4][3],or_o[4][4],or_o[4][5],or_o[4][6],or_o[4][7]});
	assign or_o[5][0]=|({match_bits[32],match_bits[33],match_bits[34],match_bits[35],match_bits[36],match_bits[37],match_bits[38],match_bits[39]});
	assign or_o[5][1]=|({match_bits[40],match_bits[41],match_bits[42],match_bits[43],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[5][2]=|({match_bits[48],match_bits[49],match_bits[50],match_bits[51],match_bits[52],match_bits[53],match_bits[54],match_bits[55]});
	assign or_o[5][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[5][4]=|({match_bits[96],match_bits[97],match_bits[98],match_bits[99],match_bits[100],match_bits[101],match_bits[102],match_bits[103]});
	assign or_o[5][5]=|({match_bits[104],match_bits[105],match_bits[106],match_bits[107],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[5][6]=|({match_bits[112],match_bits[113],match_bits[114],match_bits[115],match_bits[116],match_bits[117],match_bits[118],match_bits[119]});
	assign or_o[5][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign match_index[5]=|({or_o[5][0],or_o[5][1],or_o[5][2],or_o[5][3],or_o[5][4],or_o[5][5],or_o[5][6],or_o[5][7]});
	assign or_o[6][0]=|({match_bits[64],match_bits[65],match_bits[66],match_bits[67],match_bits[68],match_bits[69],match_bits[70],match_bits[71]});
	assign or_o[6][1]=|({match_bits[72],match_bits[73],match_bits[74],match_bits[75],match_bits[76],match_bits[77],match_bits[78],match_bits[79]});
	assign or_o[6][2]=|({match_bits[80],match_bits[81],match_bits[82],match_bits[83],match_bits[84],match_bits[85],match_bits[86],match_bits[87]});
	assign or_o[6][3]=|({match_bits[88],match_bits[89],match_bits[90],match_bits[91],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[6][4]=|({match_bits[96],match_bits[97],match_bits[98],match_bits[99],match_bits[100],match_bits[101],match_bits[102],match_bits[103]});
	assign or_o[6][5]=|({match_bits[104],match_bits[105],match_bits[106],match_bits[107],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[6][6]=|({match_bits[112],match_bits[113],match_bits[114],match_bits[115],match_bits[116],match_bits[117],match_bits[118],match_bits[119]});
	assign or_o[6][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign match_index[6]=|({or_o[6][0],or_o[6][1],or_o[6][2],or_o[6][3],or_o[6][4],or_o[6][5],or_o[6][6],or_o[6][7]});
always@(match_index)begin
	match_index_reg=match_index;
	actual_match=match_index&match_bits[0];
end

endmodule