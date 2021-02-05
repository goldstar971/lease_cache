module stage_0_1_register(

	input 			clock_i,
	input 			resetn_i,
	input 			enable_i,
	input 	[31:0]	instruction_word_i,
	input 	[31:0]	instruction_addr_i,
	output 	[31:0]	instruction_word_o,
	output 	[31:0]	instruction_addr_o

);

// port mappings
// ------------------------------------------------------------------------
reg	[31:0]	instruction_word_reg;
reg [31:0]	instruction_addr_reg;

assign instruction_word_o = instruction_word_reg;
assign instruction_addr_o = instruction_addr_reg;


// register next state logic
// ------------------------------------------------------------------------
always @(posedge clock_i) begin
	if (!resetn_i) begin
		instruction_word_reg 	<= 'b0;
		instruction_addr_reg 	<= 'b0;
	end
	else begin
		if (enable_i) begin
			instruction_word_reg <= instruction_word_i;
			instruction_addr_reg <= instruction_addr_i;
		end
	end
end

endmodule