`include "../include/top.h"

module approx_circuit #(
	parameter N_REGS = 4,
	parameter DATA_SIZE = 6,
	parameter BW_REGS = `CLOG2(N_REGS)
)(
	input 						clock_i,
	input 						resetn_i,
	input 						write_i,
	input 	[BW_REGS-1:0] 		addr_i,
	input 	[DATA_SIZE-1:0] 	data_i,
	output 	[BW_REGS-1:0] 		data_o
);

reg [DATA_SIZE-1:0]	lease_registers [0:N_REGS-1];

integer i;
always @(posedge clock_i) begin
	if (!resetn_i) begin
		for (i = 0; i < N_REGS; i = i + 1) lease_registers[i] = 'b0;
	end
	else begin
		if (write_i) begin
			lease_registers[addr_i] = data_i;
		end
	end
end

/*genvar x;
genvar y;

generate
	for (x = 0; x < DATA_SIZE; x = x + 1) begin: stuff_a

		wire [DATA_SIZE-1:0] temp;
		assign temp = x;

		assign data_o[x] = |temp;

		for (y = 0; y < N_REGS; y = y + 1) begin: reg_index_arr

			// unpack register wire
			wire [DATA_SIZE-1:0] 	unpacked_reg_bus;
			assign unpacked_reg_bus = lease_registers[y];

			// route bit to encoder
			assign data_o[x] = unpacked_reg_bus[x];
		end


	end
endgenerate*/

//assign data_o = lease_registers[0];


//localparam BW_REGS = `CLOG2(N_REGS);
localparam CACHE_BLOCK_CAPACITY = N_REGS;
localparam BW_CACHE_CAPACITY = `CLOG2(CACHE_BLOCK_CAPACITY);
localparam BW_LEASE_REGISTER = DATA_SIZE;

genvar x; 	// x is bit index
genvar y; 	// y is the reg index

generate
	// first generate the end multiplexer signals
	wire [BW_CACHE_CAPACITY-1:0] 	encoder_output [0:BW_LEASE_REGISTER-1]; 	// inputs to the multiplexer
	wire [BW_CACHE_CAPACITY-1:0] 	multiplexer_output; 						// output of the multiplexer
	wire [BW_LEASE_REGISTER-1:0] 	reduction_bus; 								// controls mux array
	wire [BW_CACHE_CAPACITY-1:0] 	mux_stage_output_bus [0:BW_LEASE_REGISTER-2];

	assign multiplexer_output = mux_stage_output_bus[0];

	// loop through bits of all lease registers
	for (x = 0; x < BW_LEASE_REGISTER; x = x + 1) begin: lease_bit_encoder_arr

		// create 1 priority encoder
		wire [CACHE_BLOCK_CAPACITY-1:0]	encoder_input;
 		
		priority_encoder #( 
			.INPUT_SIZE 	(CACHE_BLOCK_CAPACITY 		) 
		) lease_bit_encoder_inst(
			.encoding_i 	(encoder_input 		 		),
			.binary_o 		(encoder_output[x] 	 		)
		);

		// make reduction of encoder input
		//assign reduction_bus[x] = |encoder_output[x];
		assign reduction_bus[x] = |encoder_input;

		// multiplexer array logic
		// careful, indexes are reversed
		if (x == BW_LEASE_REGISTER-2) begin
			assign mux_stage_output_bus[x] = (reduction_bus[x+1] == 1'b1) ? encoder_output[x+1] : encoder_output[x];
		end
		else if (x < BW_LEASE_REGISTER-2) begin
			assign mux_stage_output_bus[x] = (|reduction_bus[BW_LEASE_REGISTER-1:x+1] == 1'b1) ?  mux_stage_output_bus[x+1] : encoder_output[x];
		end  

		// loop through lease register array to bus each aligned bit to the appropriate encoder
		for (y = 0; y < CACHE_BLOCK_CAPACITY; y = y + 1) begin: reg_index_arr

			// unpack register wire
			wire [BW_LEASE_REGISTER-1:0] unpacked_reg_bus;
			assign unpacked_reg_bus = lease_registers[y];

			// route bit to encoder
			assign encoder_input[y] = unpacked_reg_bus[x];
		end

	end

endgenerate

assign data_o = multiplexer_output;

endmodule

module priority_encoder #(
	parameter INPUT_SIZE = 0,
	parameter BW_INPUT_SIZE = `CLOG2(INPUT_SIZE)
)(
	input 	[INPUT_SIZE-1:0]		encoding_i,
	output	[BW_INPUT_SIZE-1:0]		binary_o
);

//localparam BW_INPUT_SIZE = `CLOG2(INPUT_SIZE);

reg [BW_INPUT_SIZE-1:0]	binary_output_reg;
assign binary_o = binary_output_reg;

integer i;
always @(*) begin

	// default if everything is zero
	binary_output_reg = 'b0;

	//for (i = 0; i < INPUT_SIZE; i = i + 1) begin
	for (i = INPUT_SIZE-1; i >= 0; i = i - 1) begin
		if (encoding_i[i]) binary_output_reg = i[BW_INPUT_SIZE-1:0];
	end

end

endmodule

