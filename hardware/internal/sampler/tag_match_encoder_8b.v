module tag_match_encoder_8b(
input [255:0] match_bits,
	output reg [7:0] match_index_reg,
 output reg actual_match);
wire [15:0] or_o[7:0];
wire [7:0] match_index;
	assign or_o[0][0]=|({match_bits[1],match_bits[3],match_bits[5],match_bits[7],match_bits[9],match_bits[11],match_bits[13],match_bits[15]});
	assign or_o[0][1]=|({match_bits[17],match_bits[19],match_bits[21],match_bits[23],match_bits[25],match_bits[27],match_bits[29],match_bits[31]});
	assign or_o[0][2]=|({match_bits[33],match_bits[35],match_bits[37],match_bits[39],match_bits[41],match_bits[43],match_bits[45],match_bits[47]});
	assign or_o[0][3]=|({match_bits[49],match_bits[51],match_bits[53],match_bits[55],match_bits[57],match_bits[59],match_bits[61],match_bits[63]});
	assign or_o[0][4]=|({match_bits[65],match_bits[67],match_bits[69],match_bits[71],match_bits[73],match_bits[75],match_bits[77],match_bits[79]});
	assign or_o[0][5]=|({match_bits[81],match_bits[83],match_bits[85],match_bits[87],match_bits[89],match_bits[91],match_bits[93],match_bits[95]});
	assign or_o[0][6]=|({match_bits[97],match_bits[99],match_bits[101],match_bits[103],match_bits[105],match_bits[107],match_bits[109],match_bits[111]});
	assign or_o[0][7]=|({match_bits[113],match_bits[115],match_bits[117],match_bits[119],match_bits[121],match_bits[123],match_bits[125],match_bits[127]});
	assign or_o[0][8]=|({match_bits[129],match_bits[131],match_bits[133],match_bits[135],match_bits[137],match_bits[139],match_bits[141],match_bits[143]});
	assign or_o[0][9]=|({match_bits[145],match_bits[147],match_bits[149],match_bits[151],match_bits[153],match_bits[155],match_bits[157],match_bits[159]});
	assign or_o[0][10]=|({match_bits[161],match_bits[163],match_bits[165],match_bits[167],match_bits[169],match_bits[171],match_bits[173],match_bits[175]});
	assign or_o[0][11]=|({match_bits[177],match_bits[179],match_bits[181],match_bits[183],match_bits[185],match_bits[187],match_bits[189],match_bits[191]});
	assign or_o[0][12]=|({match_bits[193],match_bits[195],match_bits[197],match_bits[199],match_bits[201],match_bits[203],match_bits[205],match_bits[207]});
	assign or_o[0][13]=|({match_bits[209],match_bits[211],match_bits[213],match_bits[215],match_bits[217],match_bits[219],match_bits[221],match_bits[223]});
	assign or_o[0][14]=|({match_bits[225],match_bits[227],match_bits[229],match_bits[231],match_bits[233],match_bits[235],match_bits[237],match_bits[239]});
	assign or_o[0][15]=|({match_bits[241],match_bits[243],match_bits[245],match_bits[247],match_bits[249],match_bits[251],match_bits[253],match_bits[255]});
	assign match_index[0]=|({or_o[0][0],or_o[0][1],or_o[0][2],or_o[0][3],or_o[0][4],or_o[0][5],or_o[0][6],or_o[0][7],or_o[0][8],or_o[0][9],or_o[0][10],or_o[0][11],or_o[0][12],or_o[0][13],or_o[0][14],or_o[0][15]});
	assign or_o[1][0]=|({match_bits[2],match_bits[3],match_bits[6],match_bits[7],match_bits[10],match_bits[11],match_bits[14],match_bits[15]});
	assign or_o[1][1]=|({match_bits[18],match_bits[19],match_bits[22],match_bits[23],match_bits[26],match_bits[27],match_bits[30],match_bits[31]});
	assign or_o[1][2]=|({match_bits[34],match_bits[35],match_bits[38],match_bits[39],match_bits[42],match_bits[43],match_bits[46],match_bits[47]});
	assign or_o[1][3]=|({match_bits[50],match_bits[51],match_bits[54],match_bits[55],match_bits[58],match_bits[59],match_bits[62],match_bits[63]});
	assign or_o[1][4]=|({match_bits[66],match_bits[67],match_bits[70],match_bits[71],match_bits[74],match_bits[75],match_bits[78],match_bits[79]});
	assign or_o[1][5]=|({match_bits[82],match_bits[83],match_bits[86],match_bits[87],match_bits[90],match_bits[91],match_bits[94],match_bits[95]});
	assign or_o[1][6]=|({match_bits[98],match_bits[99],match_bits[102],match_bits[103],match_bits[106],match_bits[107],match_bits[110],match_bits[111]});
	assign or_o[1][7]=|({match_bits[114],match_bits[115],match_bits[118],match_bits[119],match_bits[122],match_bits[123],match_bits[126],match_bits[127]});
	assign or_o[1][8]=|({match_bits[130],match_bits[131],match_bits[134],match_bits[135],match_bits[138],match_bits[139],match_bits[142],match_bits[143]});
	assign or_o[1][9]=|({match_bits[146],match_bits[147],match_bits[150],match_bits[151],match_bits[154],match_bits[155],match_bits[158],match_bits[159]});
	assign or_o[1][10]=|({match_bits[162],match_bits[163],match_bits[166],match_bits[167],match_bits[170],match_bits[171],match_bits[174],match_bits[175]});
	assign or_o[1][11]=|({match_bits[178],match_bits[179],match_bits[182],match_bits[183],match_bits[186],match_bits[187],match_bits[190],match_bits[191]});
	assign or_o[1][12]=|({match_bits[194],match_bits[195],match_bits[198],match_bits[199],match_bits[202],match_bits[203],match_bits[206],match_bits[207]});
	assign or_o[1][13]=|({match_bits[210],match_bits[211],match_bits[214],match_bits[215],match_bits[218],match_bits[219],match_bits[222],match_bits[223]});
	assign or_o[1][14]=|({match_bits[226],match_bits[227],match_bits[230],match_bits[231],match_bits[234],match_bits[235],match_bits[238],match_bits[239]});
	assign or_o[1][15]=|({match_bits[242],match_bits[243],match_bits[246],match_bits[247],match_bits[250],match_bits[251],match_bits[254],match_bits[255]});
	assign match_index[1]=|({or_o[1][0],or_o[1][1],or_o[1][2],or_o[1][3],or_o[1][4],or_o[1][5],or_o[1][6],or_o[1][7],or_o[1][8],or_o[1][9],or_o[1][10],or_o[1][11],or_o[1][12],or_o[1][13],or_o[1][14],or_o[1][15]});
	assign or_o[2][0]=|({match_bits[4],match_bits[5],match_bits[6],match_bits[7],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[2][1]=|({match_bits[20],match_bits[21],match_bits[22],match_bits[23],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[2][2]=|({match_bits[36],match_bits[37],match_bits[38],match_bits[39],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[2][3]=|({match_bits[52],match_bits[53],match_bits[54],match_bits[55],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[2][4]=|({match_bits[68],match_bits[69],match_bits[70],match_bits[71],match_bits[76],match_bits[77],match_bits[78],match_bits[79]});
	assign or_o[2][5]=|({match_bits[84],match_bits[85],match_bits[86],match_bits[87],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[2][6]=|({match_bits[100],match_bits[101],match_bits[102],match_bits[103],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[2][7]=|({match_bits[116],match_bits[117],match_bits[118],match_bits[119],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign or_o[2][8]=|({match_bits[132],match_bits[133],match_bits[134],match_bits[135],match_bits[140],match_bits[141],match_bits[142],match_bits[143]});
	assign or_o[2][9]=|({match_bits[148],match_bits[149],match_bits[150],match_bits[151],match_bits[156],match_bits[157],match_bits[158],match_bits[159]});
	assign or_o[2][10]=|({match_bits[164],match_bits[165],match_bits[166],match_bits[167],match_bits[172],match_bits[173],match_bits[174],match_bits[175]});
	assign or_o[2][11]=|({match_bits[180],match_bits[181],match_bits[182],match_bits[183],match_bits[188],match_bits[189],match_bits[190],match_bits[191]});
	assign or_o[2][12]=|({match_bits[196],match_bits[197],match_bits[198],match_bits[199],match_bits[204],match_bits[205],match_bits[206],match_bits[207]});
	assign or_o[2][13]=|({match_bits[212],match_bits[213],match_bits[214],match_bits[215],match_bits[220],match_bits[221],match_bits[222],match_bits[223]});
	assign or_o[2][14]=|({match_bits[228],match_bits[229],match_bits[230],match_bits[231],match_bits[236],match_bits[237],match_bits[238],match_bits[239]});
	assign or_o[2][15]=|({match_bits[244],match_bits[245],match_bits[246],match_bits[247],match_bits[252],match_bits[253],match_bits[254],match_bits[255]});
	assign match_index[2]=|({or_o[2][0],or_o[2][1],or_o[2][2],or_o[2][3],or_o[2][4],or_o[2][5],or_o[2][6],or_o[2][7],or_o[2][8],or_o[2][9],or_o[2][10],or_o[2][11],or_o[2][12],or_o[2][13],or_o[2][14],or_o[2][15]});
	assign or_o[3][0]=|({match_bits[8],match_bits[9],match_bits[10],match_bits[11],match_bits[12],match_bits[13],match_bits[14],match_bits[15]});
	assign or_o[3][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[3][2]=|({match_bits[40],match_bits[41],match_bits[42],match_bits[43],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[3][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[3][4]=|({match_bits[72],match_bits[73],match_bits[74],match_bits[75],match_bits[76],match_bits[77],match_bits[78],match_bits[79]});
	assign or_o[3][5]=|({match_bits[88],match_bits[89],match_bits[90],match_bits[91],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[3][6]=|({match_bits[104],match_bits[105],match_bits[106],match_bits[107],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[3][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign or_o[3][8]=|({match_bits[136],match_bits[137],match_bits[138],match_bits[139],match_bits[140],match_bits[141],match_bits[142],match_bits[143]});
	assign or_o[3][9]=|({match_bits[152],match_bits[153],match_bits[154],match_bits[155],match_bits[156],match_bits[157],match_bits[158],match_bits[159]});
	assign or_o[3][10]=|({match_bits[168],match_bits[169],match_bits[170],match_bits[171],match_bits[172],match_bits[173],match_bits[174],match_bits[175]});
	assign or_o[3][11]=|({match_bits[184],match_bits[185],match_bits[186],match_bits[187],match_bits[188],match_bits[189],match_bits[190],match_bits[191]});
	assign or_o[3][12]=|({match_bits[200],match_bits[201],match_bits[202],match_bits[203],match_bits[204],match_bits[205],match_bits[206],match_bits[207]});
	assign or_o[3][13]=|({match_bits[216],match_bits[217],match_bits[218],match_bits[219],match_bits[220],match_bits[221],match_bits[222],match_bits[223]});
	assign or_o[3][14]=|({match_bits[232],match_bits[233],match_bits[234],match_bits[235],match_bits[236],match_bits[237],match_bits[238],match_bits[239]});
	assign or_o[3][15]=|({match_bits[248],match_bits[249],match_bits[250],match_bits[251],match_bits[252],match_bits[253],match_bits[254],match_bits[255]});
	assign match_index[3]=|({or_o[3][0],or_o[3][1],or_o[3][2],or_o[3][3],or_o[3][4],or_o[3][5],or_o[3][6],or_o[3][7],or_o[3][8],or_o[3][9],or_o[3][10],or_o[3][11],or_o[3][12],or_o[3][13],or_o[3][14],or_o[3][15]});
	assign or_o[4][0]=|({match_bits[16],match_bits[17],match_bits[18],match_bits[19],match_bits[20],match_bits[21],match_bits[22],match_bits[23]});
	assign or_o[4][1]=|({match_bits[24],match_bits[25],match_bits[26],match_bits[27],match_bits[28],match_bits[29],match_bits[30],match_bits[31]});
	assign or_o[4][2]=|({match_bits[48],match_bits[49],match_bits[50],match_bits[51],match_bits[52],match_bits[53],match_bits[54],match_bits[55]});
	assign or_o[4][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[4][4]=|({match_bits[80],match_bits[81],match_bits[82],match_bits[83],match_bits[84],match_bits[85],match_bits[86],match_bits[87]});
	assign or_o[4][5]=|({match_bits[88],match_bits[89],match_bits[90],match_bits[91],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[4][6]=|({match_bits[112],match_bits[113],match_bits[114],match_bits[115],match_bits[116],match_bits[117],match_bits[118],match_bits[119]});
	assign or_o[4][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign or_o[4][8]=|({match_bits[144],match_bits[145],match_bits[146],match_bits[147],match_bits[148],match_bits[149],match_bits[150],match_bits[151]});
	assign or_o[4][9]=|({match_bits[152],match_bits[153],match_bits[154],match_bits[155],match_bits[156],match_bits[157],match_bits[158],match_bits[159]});
	assign or_o[4][10]=|({match_bits[176],match_bits[177],match_bits[178],match_bits[179],match_bits[180],match_bits[181],match_bits[182],match_bits[183]});
	assign or_o[4][11]=|({match_bits[184],match_bits[185],match_bits[186],match_bits[187],match_bits[188],match_bits[189],match_bits[190],match_bits[191]});
	assign or_o[4][12]=|({match_bits[208],match_bits[209],match_bits[210],match_bits[211],match_bits[212],match_bits[213],match_bits[214],match_bits[215]});
	assign or_o[4][13]=|({match_bits[216],match_bits[217],match_bits[218],match_bits[219],match_bits[220],match_bits[221],match_bits[222],match_bits[223]});
	assign or_o[4][14]=|({match_bits[240],match_bits[241],match_bits[242],match_bits[243],match_bits[244],match_bits[245],match_bits[246],match_bits[247]});
	assign or_o[4][15]=|({match_bits[248],match_bits[249],match_bits[250],match_bits[251],match_bits[252],match_bits[253],match_bits[254],match_bits[255]});
	assign match_index[4]=|({or_o[4][0],or_o[4][1],or_o[4][2],or_o[4][3],or_o[4][4],or_o[4][5],or_o[4][6],or_o[4][7],or_o[4][8],or_o[4][9],or_o[4][10],or_o[4][11],or_o[4][12],or_o[4][13],or_o[4][14],or_o[4][15]});
	assign or_o[5][0]=|({match_bits[32],match_bits[33],match_bits[34],match_bits[35],match_bits[36],match_bits[37],match_bits[38],match_bits[39]});
	assign or_o[5][1]=|({match_bits[40],match_bits[41],match_bits[42],match_bits[43],match_bits[44],match_bits[45],match_bits[46],match_bits[47]});
	assign or_o[5][2]=|({match_bits[48],match_bits[49],match_bits[50],match_bits[51],match_bits[52],match_bits[53],match_bits[54],match_bits[55]});
	assign or_o[5][3]=|({match_bits[56],match_bits[57],match_bits[58],match_bits[59],match_bits[60],match_bits[61],match_bits[62],match_bits[63]});
	assign or_o[5][4]=|({match_bits[96],match_bits[97],match_bits[98],match_bits[99],match_bits[100],match_bits[101],match_bits[102],match_bits[103]});
	assign or_o[5][5]=|({match_bits[104],match_bits[105],match_bits[106],match_bits[107],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[5][6]=|({match_bits[112],match_bits[113],match_bits[114],match_bits[115],match_bits[116],match_bits[117],match_bits[118],match_bits[119]});
	assign or_o[5][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign or_o[5][8]=|({match_bits[160],match_bits[161],match_bits[162],match_bits[163],match_bits[164],match_bits[165],match_bits[166],match_bits[167]});
	assign or_o[5][9]=|({match_bits[168],match_bits[169],match_bits[170],match_bits[171],match_bits[172],match_bits[173],match_bits[174],match_bits[175]});
	assign or_o[5][10]=|({match_bits[176],match_bits[177],match_bits[178],match_bits[179],match_bits[180],match_bits[181],match_bits[182],match_bits[183]});
	assign or_o[5][11]=|({match_bits[184],match_bits[185],match_bits[186],match_bits[187],match_bits[188],match_bits[189],match_bits[190],match_bits[191]});
	assign or_o[5][12]=|({match_bits[224],match_bits[225],match_bits[226],match_bits[227],match_bits[228],match_bits[229],match_bits[230],match_bits[231]});
	assign or_o[5][13]=|({match_bits[232],match_bits[233],match_bits[234],match_bits[235],match_bits[236],match_bits[237],match_bits[238],match_bits[239]});
	assign or_o[5][14]=|({match_bits[240],match_bits[241],match_bits[242],match_bits[243],match_bits[244],match_bits[245],match_bits[246],match_bits[247]});
	assign or_o[5][15]=|({match_bits[248],match_bits[249],match_bits[250],match_bits[251],match_bits[252],match_bits[253],match_bits[254],match_bits[255]});
	assign match_index[5]=|({or_o[5][0],or_o[5][1],or_o[5][2],or_o[5][3],or_o[5][4],or_o[5][5],or_o[5][6],or_o[5][7],or_o[5][8],or_o[5][9],or_o[5][10],or_o[5][11],or_o[5][12],or_o[5][13],or_o[5][14],or_o[5][15]});
	assign or_o[6][0]=|({match_bits[64],match_bits[65],match_bits[66],match_bits[67],match_bits[68],match_bits[69],match_bits[70],match_bits[71]});
	assign or_o[6][1]=|({match_bits[72],match_bits[73],match_bits[74],match_bits[75],match_bits[76],match_bits[77],match_bits[78],match_bits[79]});
	assign or_o[6][2]=|({match_bits[80],match_bits[81],match_bits[82],match_bits[83],match_bits[84],match_bits[85],match_bits[86],match_bits[87]});
	assign or_o[6][3]=|({match_bits[88],match_bits[89],match_bits[90],match_bits[91],match_bits[92],match_bits[93],match_bits[94],match_bits[95]});
	assign or_o[6][4]=|({match_bits[96],match_bits[97],match_bits[98],match_bits[99],match_bits[100],match_bits[101],match_bits[102],match_bits[103]});
	assign or_o[6][5]=|({match_bits[104],match_bits[105],match_bits[106],match_bits[107],match_bits[108],match_bits[109],match_bits[110],match_bits[111]});
	assign or_o[6][6]=|({match_bits[112],match_bits[113],match_bits[114],match_bits[115],match_bits[116],match_bits[117],match_bits[118],match_bits[119]});
	assign or_o[6][7]=|({match_bits[120],match_bits[121],match_bits[122],match_bits[123],match_bits[124],match_bits[125],match_bits[126],match_bits[127]});
	assign or_o[6][8]=|({match_bits[192],match_bits[193],match_bits[194],match_bits[195],match_bits[196],match_bits[197],match_bits[198],match_bits[199]});
	assign or_o[6][9]=|({match_bits[200],match_bits[201],match_bits[202],match_bits[203],match_bits[204],match_bits[205],match_bits[206],match_bits[207]});
	assign or_o[6][10]=|({match_bits[208],match_bits[209],match_bits[210],match_bits[211],match_bits[212],match_bits[213],match_bits[214],match_bits[215]});
	assign or_o[6][11]=|({match_bits[216],match_bits[217],match_bits[218],match_bits[219],match_bits[220],match_bits[221],match_bits[222],match_bits[223]});
	assign or_o[6][12]=|({match_bits[224],match_bits[225],match_bits[226],match_bits[227],match_bits[228],match_bits[229],match_bits[230],match_bits[231]});
	assign or_o[6][13]=|({match_bits[232],match_bits[233],match_bits[234],match_bits[235],match_bits[236],match_bits[237],match_bits[238],match_bits[239]});
	assign or_o[6][14]=|({match_bits[240],match_bits[241],match_bits[242],match_bits[243],match_bits[244],match_bits[245],match_bits[246],match_bits[247]});
	assign or_o[6][15]=|({match_bits[248],match_bits[249],match_bits[250],match_bits[251],match_bits[252],match_bits[253],match_bits[254],match_bits[255]});
	assign match_index[6]=|({or_o[6][0],or_o[6][1],or_o[6][2],or_o[6][3],or_o[6][4],or_o[6][5],or_o[6][6],or_o[6][7],or_o[6][8],or_o[6][9],or_o[6][10],or_o[6][11],or_o[6][12],or_o[6][13],or_o[6][14],or_o[6][15]});
	assign or_o[7][0]=|({match_bits[128],match_bits[129],match_bits[130],match_bits[131],match_bits[132],match_bits[133],match_bits[134],match_bits[135]});
	assign or_o[7][1]=|({match_bits[136],match_bits[137],match_bits[138],match_bits[139],match_bits[140],match_bits[141],match_bits[142],match_bits[143]});
	assign or_o[7][2]=|({match_bits[144],match_bits[145],match_bits[146],match_bits[147],match_bits[148],match_bits[149],match_bits[150],match_bits[151]});
	assign or_o[7][3]=|({match_bits[152],match_bits[153],match_bits[154],match_bits[155],match_bits[156],match_bits[157],match_bits[158],match_bits[159]});
	assign or_o[7][4]=|({match_bits[160],match_bits[161],match_bits[162],match_bits[163],match_bits[164],match_bits[165],match_bits[166],match_bits[167]});
	assign or_o[7][5]=|({match_bits[168],match_bits[169],match_bits[170],match_bits[171],match_bits[172],match_bits[173],match_bits[174],match_bits[175]});
	assign or_o[7][6]=|({match_bits[176],match_bits[177],match_bits[178],match_bits[179],match_bits[180],match_bits[181],match_bits[182],match_bits[183]});
	assign or_o[7][7]=|({match_bits[184],match_bits[185],match_bits[186],match_bits[187],match_bits[188],match_bits[189],match_bits[190],match_bits[191]});
	assign or_o[7][8]=|({match_bits[192],match_bits[193],match_bits[194],match_bits[195],match_bits[196],match_bits[197],match_bits[198],match_bits[199]});
	assign or_o[7][9]=|({match_bits[200],match_bits[201],match_bits[202],match_bits[203],match_bits[204],match_bits[205],match_bits[206],match_bits[207]});
	assign or_o[7][10]=|({match_bits[208],match_bits[209],match_bits[210],match_bits[211],match_bits[212],match_bits[213],match_bits[214],match_bits[215]});
	assign or_o[7][11]=|({match_bits[216],match_bits[217],match_bits[218],match_bits[219],match_bits[220],match_bits[221],match_bits[222],match_bits[223]});
	assign or_o[7][12]=|({match_bits[224],match_bits[225],match_bits[226],match_bits[227],match_bits[228],match_bits[229],match_bits[230],match_bits[231]});
	assign or_o[7][13]=|({match_bits[232],match_bits[233],match_bits[234],match_bits[235],match_bits[236],match_bits[237],match_bits[238],match_bits[239]});
	assign or_o[7][14]=|({match_bits[240],match_bits[241],match_bits[242],match_bits[243],match_bits[244],match_bits[245],match_bits[246],match_bits[247]});
	assign or_o[7][15]=|({match_bits[248],match_bits[249],match_bits[250],match_bits[251],match_bits[252],match_bits[253],match_bits[254],match_bits[255]});
	assign match_index[7]=|({or_o[7][0],or_o[7][1],or_o[7][2],or_o[7][3],or_o[7][4],or_o[7][5],or_o[7][6],or_o[7][7],or_o[7][8],or_o[7][9],or_o[7][10],or_o[7][11],or_o[7][12],or_o[7][13],or_o[7][14],or_o[7][15]});
always@(match_index)begin
	match_index_reg=match_index;
	actual_match=|({match_index,match_bits[0]});
end

endmodule