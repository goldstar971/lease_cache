module stage4_memory_operation(

	input 	[15:0]	encoding_i,
	input 	[2:0]	func3_i,
	input 	[4:0]	fdest_i,
	input 	[31:0]	memory_data_i,
	input 	[31:0]	stage3_result_i, 		// mux'ed result from previous stage
	output 			writeback_flag_o, 		// logic high if the value routed needs to be written to register file in subsequent stage (writeback)
	output 	[31:0]	writeback_value_o,
	output 			exception_o 			// LOAD unknown func3

);

// port mappings
// -------------------------------------------------------------------------------------
reg 		writeback_flag_reg;
reg [31:0]	writeback_value_reg;
reg  		exception_reg;

assign writeback_flag_o 	= writeback_flag_reg;
assign writeback_value_o 	= writeback_value_reg;
assign exception_o 			= exception_reg;


// memory result routing combinational logic
// -------------------------------------------------------------------------------------
always @(*) begin

	// default signals
	writeback_flag_reg = 1'b0;
	writeback_value_reg = 'b0;
	exception_reg = 1'b0;

	// only check if the destination register is not R0 in the integer register file (tied low)  
	if (fdest_i||encoding_i[15:9]) begin
		case(encoding_i)

			// arithmetic and jumps
			`ENCODING_LUI, `ENCODING_AUIPC, `ENCODING_ARITH_IMM, `ENCODING_ARITH_REG, `ENCODING_JAL, `ENCODING_JALR,
			`ENCODING_FARITH,`ENCODING_FNMADD,`ENCODING_FNMSUB,`ENCODING_FMSUB,`ENCODING_FMADD: begin
				writeback_flag_reg 	= 1'b1;
				writeback_value_reg = stage3_result_i;
			end

			// load - adjust per instruction
			`ENCODING_LOAD: begin

				writeback_flag_reg = 1'b1;

				case (func3_i) 
					`RV32I_FUNC3_LOAD_BYTE: begin
						writeback_value_reg = {{24{memory_data_i[7]}}, memory_data_i[7:0]};
					end
					`RV32I_FUNC3_LOAD_HWORD: begin	
						writeback_value_reg = {{16{memory_data_i[15]}}, memory_data_i[15:0]};
					end
					`RV32I_FUNC3_LOAD_WORD: begin
						writeback_value_reg = memory_data_i;	
					end
					`RV32I_FUNC3_LOAD_UBYTE: begin	
						writeback_value_reg = {{24{1'b0}}, memory_data_i[7:0]};
					end
					`RV32I_FUNC3_LOAD_UHWORD: begin	
						writeback_value_reg = {{16{1'b0}}, memory_data_i[15:0]};
					end

					// throw exception if no match
					default: begin
						exception_reg = 1'b1;
						writeback_flag_reg = 'b0;
					end	

				endcase
			end

			`ENCODING_FLOAD:begin
				writeback_flag_reg =1'b1;
				writeback_value_reg =memory_data_i;
			end

			// branch, store
			default: begin
				writeback_flag_reg = 1'b0;
				writeback_value_reg = 'b0;
				exception_reg = 1'b0;
			end

		endcase
	end
end

endmodule