`define 	ACCESS_COMM 			1'b0
`define 	ACCESS_PROCESSOR 		1'b1
`define 	ST_MEMuC_EXT_NOMINAL 	1'b0
`define 	ST_MEMuC_EXT_SWITCH 	1'b1
`include "../../../include/mem.h"


module external_memory_controller(
	// system
	input 				clock_i, 
	input 				reset_i,
	
	// internal system controller
	input 				req_int_i, 
	input 				reqBlock_int_i, 
	input 				rw_int_i, 
	input 				clear_int_i,
	input 	[31:0]		data_int_i, 
	input 	[`BW_WORD_ADDR-1:0]		add_int_i, 			// word addressible
	output 	[31:0]		data_int_o,
	output				ready_int_o, 
	output 				done_int_o, 
	output 				valid_int_o,

	// i/o - comm system
	input 				req0_i, 
	input 				reqBlock0_i, 
	input 				rw0_i, 
	input 				clear0_i,
	input 	[2:0]		dev0_i,
	input 	[31:0]		data0_i, 
	input 	[`BW_BYTE_ADDR:0]		add0_i, 			// byte addressible
	output 	[31:0]		data0_o,
	output				ready0_o, 
	output 				done0_o, 
	output 				valid0_o,



	// peripherals
	output 				req2_o, 
	output 				rw2_o,
	output 	[`BW_BYTE_ADDR:0] 		add2_o,
	output 	[31:0]		data2_o,
	input 	[31:0] 		data2_i,

	// external memory
	output 				req3_o, 
	output 				reqBlock3_o, 
	output 				rw3_o, 
	output 				clear3_o, 
	output 	[31:0]		data3_o, 
	output 	[`BW_BYTE_ADDR-1:0]		add3_o, 
	input 	[31:0]		data3_i,
	input 				ready3_i, 
	input 				done3_i, 
	input 				valid3_i
);


// controller description
// ----------------------------------------
reg 	mem_access; 					// who has access to sdram
reg 	comm_req_type; 					// what the request is for - can be either peripheral or memory
reg 	per_read_flag, per_done_flag;
reg 	state;

// controller
// ----------------------------------------
always @(posedge clock_i) begin

	// reset condition
	// ------------------------------------
	if (reset_i != 1'b1) begin
		mem_access <= `ACCESS_COMM; 			// by default jtag has access to sdram
		comm_req_type <= 1'b0;
		per_read_flag <= 1'b0;
		per_done_flag <= 1'b0;
		state <= `ST_MEMuC_EXT_NOMINAL;
	end

	// nominal operation
	// ------------------------------------
	else begin

		// default signals
		per_done_flag <= 1'b0;

		case(state)

			`ST_MEMuC_EXT_NOMINAL: begin

				if (per_read_flag) begin		//  need to make this a longer delay maybe so that value is latched
					per_read_flag <= 1'b0;
					per_done_flag <= 1'b1;
				end

				// permission independent
				// ---------------------------------------------------------

	
				// memory controller
				if (req0_i & (dev0_i == 3'b010)) begin
					// try trying to take back memory permission 
					// if a transaction is in progress then wait until complete
					// if ((mem_access == `ACCESS_PROCESSOR) & (data0_i[0] == `ACCESS_COMM)) begin
					if (!ready3_i) begin 
						state <= `ST_MEMuC_EXT_SWITCH;
					end
					else begin
						mem_access <= data0_i[0];
						if (data0_i[0] == `ACCESS_PROCESSOR) begin
							comm_req_type <= 1'b1;
						end
					end
				end

				// permission dependent
				// ---------------------------------------------------------

				// if you get a request from the comm manager for peripheral set comm_req high, else set low
				else if (req0_i & (dev0_i == 3'b000) & (add0_i[`BW_BYTE_ADDR] == 1'b1)) begin
					comm_req_type <= 1'b1;
					per_read_flag <= 1'b1;
				end

				else if (req0_i & (dev0_i == 3'b000) & (add0_i[`BW_BYTE_ADDR] == 1'b0) & (mem_access == `ACCESS_COMM)) begin
					comm_req_type <= 1'b0;
				end
			end

			`ST_MEMuC_EXT_SWITCH: begin
				// wait until current transaction is completed
				if (ready3_i) begin
					mem_access <= data0_i[0];
					state <= `ST_MEMuC_EXT_NOMINAL;
					if (data0_i[0] == `ACCESS_PROCESSOR) begin
						comm_req_type <= 1'b1;
					end
				end
			end

		endcase
	end
end

// continuous switch assignments
// ------------------------------------------------------------------

// to sdram
assign req3_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0) & (dev0_i == 3'b000)) ? req0_i : req_int_i;
assign clear3_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? clear0_i : clear_int_i;
assign reqBlock3_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? reqBlock0_i : reqBlock_int_i;
assign rw3_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? rw0_i : rw_int_i;
assign add3_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? add0_i[`BW_BYTE_ADDR-1:0] : {add_int_i,{2'b00}};
assign data3_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? data0_i : data_int_i;

// to peripherals
assign req2_o = ((comm_req_type == 1'b1)  & (dev0_i == 3'b000)) ? req0_i : 1'b0;
assign rw2_o = (comm_req_type == 1'b1) ? rw0_i : 1'b0;
assign add2_o = (comm_req_type == 1'b1) ? add0_i : 1'b0;
assign data2_o = (comm_req_type == 1'b1) ? data0_i : 1'b0;

// to comm
assign valid0_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? valid3_i : 1'b1;
assign data0_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? data3_i : data2_i;
assign done0_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? done3_i : per_done_flag;
assign ready0_o = ((mem_access == `ACCESS_COMM) & (comm_req_type == 1'b0)) ? ready3_i : 1'b1;

// to processor
assign valid_int_o = (mem_access == `ACCESS_PROCESSOR) ? valid3_i : 1'b0;
assign data_int_o = (mem_access == `ACCESS_PROCESSOR) ? data3_i : 'b0;
assign done_int_o = (mem_access == `ACCESS_PROCESSOR) ? done3_i : 1'b0;
assign ready_int_o = (mem_access == `ACCESS_PROCESSOR) ? ready3_i : 1'b0;

endmodule