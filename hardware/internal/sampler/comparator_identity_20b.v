module comparator_identity_20b(
	input 	[19:0]		opA_i, opB_i,
	output 				match_o
);

wire [4:0]	match_node;
wire 		match_node_0, match_node_1;

comparator_identity_4b comp0(.opA_i(opA_i[3:0]), .opB_i(opB_i[3:0]), .match_o(match_node[0]));
comparator_identity_4b comp1(.opA_i(opA_i[7:4]), .opB_i(opB_i[7:4]), .match_o(match_node[1]));
comparator_identity_4b comp2(.opA_i(opA_i[11:8]), .opB_i(opB_i[11:8]), .match_o(match_node[2]));
comparator_identity_4b comp3(.opA_i(opA_i[15:12]), .opB_i(opB_i[15:12]), .match_o(match_node[3]));
comparator_identity_4b comp4(.opA_i(opA_i[19:16]), .opB_i(opB_i[19:16]), .match_o(match_node[4]));

and and0(match_node_0, match_node[0], match_node[1]);
and and1(match_node_1, match_node[2], match_node[3]);
and and2(match_o, match_node_0, match_node_1, match_node[4]);

endmodule


module comparator_identity_4b(
	input 	[3:0]		opA_i, opB_i,
	output 				match_o
);

wire 	[3:0]	node_xnor;

xnor xnor0(node_xnor[0], opA_i[0], opB_i[0]);
xnor xnor1(node_xnor[1], opA_i[1], opB_i[1]);
xnor xnor2(node_xnor[2], opA_i[2], opB_i[2]);
xnor xnor3(node_xnor[3], opA_i[3], opB_i[3]);

and and0(match_o, node_xnor[0], node_xnor[1], node_xnor[2], node_xnor[3]);

endmodule