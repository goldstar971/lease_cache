`include "../../../include/peripheral.h"
`include "../../../include/mem.h"
`include "../../../include/sampler.h"
module peripheral_system_3(

	// internal system
	input				clock_i, 
	input 				cpu_resetn_i, 
	input 				req_core_i, 
	input				rw_core_i, 
	input 		[`BW_BYTE_ADDR:0] 	add_core_i, 
	input 		[31:0]	data_core_i,
	output 	reg	[31:0]	data_core_o,
	input           [191:0]        cycle_counts_i,

	// external system
	input 				req_cs_i, 
	input 				rw_cs_i, 
	input 		[`BW_BYTE_ADDR:0] 	add_cs_i, 
	input 		[31:0]	data_cs_i,
	output 	reg	[31:0]	data_cs_o,

	// misc comm stuff
	input 		[31:0]	comm_cache0_i, 
	input 		[31:0]	comm_cache1_i,
	input       [31:0]  comm_cacheL2_i,
	output   	[1:0]    metric_sel_o,
	output      [18:0]    shift_sample_rate_o,
	output 		[31:0] 	phase_o,
	output 		[31:0]	comm_o,
	output      reset_system_o
	
);
reg [1:0] reset_reg;
assign reset_system_o=reset_reg[0];

// write control
reg [31:0]	comm_reg0, comm_reg1;
reg [7:0]	comm_pro_i_reg;
reg [23:0]	comm_cs_i_reg;
reg [18:0]   sample_rate_reg;
reg [1:0] metric_sel_reg;
wire [4:0]shift_sample_rate;

assign shift_sample_rate= data_cs_i[17:2]>=32768 ? 5'd0 : data_cs_i[17:2]>=16384 ? 5'd1 : 
data_cs_i[17:2]>=8192 ? 5'd2 : data_cs_i[17:2]>=4096? 5'd3 : data_cs_i[17:2]>=2048 ? 5'd4 : data_cs_i[17:2]>=1024 ? 5'd5 : data_cs_i[17:2]>=512
? 5'd6 : data_cs_i[17:2]>=256 ? 5'd7 : data_cs_i[17:2]>=128 ? 5'd8 : data_cs_i[17:2]>=64 ? 5'd9 : data_cs_i[17:2]>=32 ? 5'd10 :
data_cs_i[17:2]>=16 ? 5'd11 : data_cs_i[17:2]>=8 ? 5'd12: data_cs_i[17:2] >=4 ? 5'd13 :data_cs_i[17:2]>=2 ? 5'd14 : data_cs_i[17:2] ==1 ? 5'd15 : 5'd16;


assign metric_sel_o=metric_sel_reg;
assign shift_sample_rate_o=sample_rate_reg;

assign comm_o = {comm_pro_i_reg, comm_cs_i_reg};
		reg [31:0]	core_phase_reg;
		assign phase_o = core_phase_reg;

always @(posedge clock_i) begin
	if (!reset_reg[1]) begin
		comm_reg0 		<= 32'h0; 
		comm_reg1 		<= 32'h0; 
		comm_pro_i_reg 	<= 'b0; 
		comm_cs_i_reg 	<= 'b0;
		metric_sel_reg<='b0;
		core_phase_reg 	<= 'b0;
		sample_rate_reg<='b0;
	end
	else begin

		// pulsing reset 
		// -----------------------------------------------------------
		if (comm_cs_i_reg[23]) comm_cs_i_reg[23] 	<= 1'b0; //clear sampler buffer
		if (comm_cs_i_reg[22]) comm_cs_i_reg[22]    <= 1'b0; //write out sampling table to buffer
			if (core_phase_reg[31])core_phase_reg[31] 	<= 1'b0; 				// phase interrupt bit
		
		if (req_core_i & rw_core_i) begin
			case(add_core_i)
				`COMM_REGISTER0: comm_reg0 <= data_core_i;
			
				// communication stuff here
				`COMM_CONTROL: 		comm_pro_i_reg <= data_core_i[7:0];
					`PHASE_REG: 		core_phase_reg <= {1'b1,data_core_i[30:0]};
			endcase
		end
		// communication interface writing
		if (req_cs_i & rw_cs_i) begin
			case(add_cs_i)
				`COMM_CONTROL:  comm_cs_i_reg <= data_cs_i[23:0];
				`CPC_METRIC_SWITCH:   begin
						metric_sel_reg<=data_cs_i[1:0];
						if(data_cs_i[1:0]==2'b1)begin
							sample_rate_reg<={data_cs_i[31:18],shift_sample_rate}; //combine seed and sampling rate
						end
						else begin
							sample_rate_reg<=data_cs_i[19:2]; //get tracking data sampling rate
						end
				end
				`STATS_BASE: begin
					case(data_cs_i[2:0])
						3'b000: comm_reg1 <= cycle_counts_i[31:0];
						3'b001: comm_reg1 <= cycle_counts_i[63:32];
						3'b010: comm_reg1 <= cycle_counts_i[95:64];
						3'b011: comm_reg1<= cycle_counts_i[127:96];
						3'b100: comm_reg1 <= cycle_counts_i[159:128];
						3'b101: comm_reg1 <= cycle_counts_i[191:160];
						default: comm_reg1<=32'b0;
					endcase
				end
			endcase
		end
	end
end


// read control
always @(posedge clock_i) begin
	if (!reset_reg[1]) begin
		data_core_o <= 32'hDEADBEAF; 
		//even when peripheral system is in reset, output the value of the reset reg
		case(add_cs_i)
			`RESET_CONTROL: data_cs_o <= {{30{1'b1}},reset_reg};
			default: data_cs_o <= 32'hDEADBEAF;
		endcase
	end
	else begin
		// core requests
		if (req_core_i & !rw_core_i) begin
			case(add_core_i)
				`COMM_REGISTER0: data_core_o <= comm_reg0;

			endcase
		end
		// control system requests
		if (req_cs_i & !rw_cs_i) begin
			case(add_cs_i)
				`COMM_REGISTER0: data_cs_o <= comm_reg0;
				`STATS_BASE:     data_cs_o <= comm_reg1;
				`RESET_CONTROL:  data_cs_o <= {{30{1'b1}},reset_reg};
				
				// cache comm stuff
				`COMM_CACHE0: data_cs_o <= comm_cache0_i;
				`COMM_CACHE1: data_cs_o <= comm_cache1_i;
				`COMM_CACHE2: data_cs_o <= comm_cacheL2_i;

				default: data_cs_o <= 32'h0;
			endcase
		end
	end
end


//reset control
//handles write control
always @(posedge clock_i)begin
	if(!cpu_resetn_i)begin
		reset_reg<=2'b00;
	end
	else begin
		if(req_cs_i & rw_cs_i)begin 
			case(add_cs_i)
				`RESET_CONTROL: reset_reg<=data_cs_i[1:0];
			endcase
		end
	end 
end

	
endmodule
