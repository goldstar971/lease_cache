`include "../../../include/peripheral.h"

module peripheral_system(

	// internal system
	input				clock_i, 
	input 				reset_i, 
	input 				req_core_i, 
	input				rw_core_i, 
	input 		[26:0] 	add_core_i, 
	input 		[31:0]	data_core_i,
	output 	reg	[31:0]	data_core_o,

	// external system
	input 				req_cs_i, 
	input 				rw_cs_i, 
	input 		[26:0] 	add_cs_i, 
	input 		[31:0]	data_cs_i,
	output 	reg	[31:0]	data_cs_o,

	// misc comm stuff
	input 		[31:0]	comm_cache0_i, 
	input 		[31:0]	comm_cache1_i,
	`ifdef DATA_POLICY_DLEASE
		output 		[31:0] 	phase_o,
	`endif
		output 		[31:0]	comm_o
	
);

// write control
reg [31:0]	comm_reg0, comm_reg1, comm_reg2;
reg [7:0]	comm_pro_i_reg;
reg [23:0]	comm_cs_i_reg;
reg [31:0]	core_phase_reg;

assign comm_o = {comm_pro_i_reg, comm_cs_i_reg};
assign phase_o = core_phase_reg;

always @(posedge clock_i) begin
	if (reset_i != 1'b1) begin
		comm_reg0 		<= 32'h0; 
		comm_reg1 		<= 32'h0; 
		comm_reg2 		<= 32'h0;
		comm_pro_i_reg 	<= 'b0; 
		comm_cs_i_reg 	<= 'b0;
		core_phase_reg 	<= 'b0;
	end
	else begin

		// pulsing reset - used for clearing the cache sampler buffer
		// -----------------------------------------------------------
		if (comm_cs_i_reg[23]) comm_cs_i_reg[23] 	<= 1'b0;
		if (core_phase_reg[31])core_phase_reg[31] 	<= 1'b0; 				// phase interrupt bit

		if (req_core_i & rw_core_i) begin
			case(add_core_i)
				`COMM_REGISTER0: comm_reg0 <= data_core_i;
				`COMM_REGISTER1: comm_reg1 <= data_core_i;
				`COMM_REGISTER2: comm_reg2 <= data_core_i;

				// communication stuff here
				`COMM_CONTROL: 		comm_pro_i_reg <= data_core_i[7:0];
				`PHASE_REG: 		core_phase_reg <= {1'b1,data_core_i[30:0]};
			endcase
		end
		// communication interface writing
		if (req_cs_i & rw_cs_i) begin
			case(add_cs_i)
				`COMM_CONTROL: comm_cs_i_reg <= data_cs_i[23:0];
			endcase
		end
	end
end


// read control
always @(posedge clock_i) begin
	if (reset_i != 1'b1) begin
		data_core_o <= 32'hDEADBEAF; data_cs_o <= 32'hDEADBEAF;
	end
	else begin
		// core requests
		if (req_core_i & !rw_core_i) begin
			case(add_core_i)
				`COMM_REGISTER0: data_core_o <= comm_reg0;
				`COMM_REGISTER1: data_core_o <= comm_reg1;
				`COMM_REGISTER2: data_core_o <= comm_reg2;
			endcase
		end
		// control system requests
		if (req_cs_i & !rw_cs_i) begin
			case(add_cs_i)
				`COMM_REGISTER0: data_cs_o <= comm_reg0;
				`COMM_REGISTER1: data_cs_o <= comm_reg1;
				`COMM_REGISTER2: data_cs_o <= comm_reg2;
				
				// cache comm stuff
				`COMM_CACHE0: data_cs_o <= comm_cache0_i;
				`COMM_CACHE1: data_cs_o <= comm_cache1_i;

				default: data_cs_o <= 32'h0;
			endcase
		end
	end
end
	
endmodule