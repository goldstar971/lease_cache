`ifndef _PERIPHERAL_REGISTERS_V_
`define _PERIPHERAL_REGISTERS_V_

`include "../include/peripheral_registers.h"

module peripheral_registers #(
	parameter BW_ADDRESS 			= 0,
	parameter BW_DATA 				= 0,
	parameter BW_CACHE_CONTROL_BUS 	= 0, 	// [core_control,proxy_control]
	parameter BW_CACHE_SERVICE_BUS 	= 0 	// [status,data,buffer]
)(
	// general purpose
	input								clock_i, 
	input 								resetn_i,  		
	// core request interface
	input 								core_request_i,
	input 								core_wren_i,
	input 	[BW_ADDRESS-1:0] 			core_address_i,
	input 	[BW_DATA-1:0] 				core_data_i,
	output 								core_valid_o,
	output 	[BW_DATA-1:0] 				core_data_o,
	// proxy request interface
	input 								proxy_request_i,
	input 								proxy_wren_i,
	input 	[BW_ADDRESS-1:0] 			proxy_address_i,
	input 	[BW_DATA-1:0] 				proxy_data_i,
	output 								proxy_valid_o,
	output 	[BW_DATA-1:0] 				proxy_data_o,
	// cache ports
	output 	[BW_CACHE_CONTROL_BUS-1:0] 	cache_control_bus0_o,
	input 	[BW_CACHE_SERVICE_BUS-1:0] 	cache_service_bus0_i, 
	input 	[BW_CACHE_SERVICE_BUS-1:0] 	cache_service_bus1_i 

);

// write control
// ------------------------------------------------------------------------------------------
reg [BW_DATA-1:0]	GP_REG0_reg,
					GP_REG1_reg,
					GP_REG2_reg;
reg [BW_DATA-1:0]	CACHE_CONTROL_REG0_reg,
					CACHE_CONTROL_REG1_reg;
reg [BW_DATA-1:0] 	CACHE_L1_BUFFER_CONTROL_REG0_reg,
					CACHE_L1_BUFFER_CONTROL_REG1_reg;

always @(posedge clock_i) begin
	if (!resetn_i) begin
		GP_REG0_reg 						<= 'b0;
		GP_REG1_reg							<= 'b0;
		GP_REG2_reg							<= 'b0;
		CACHE_CONTROL_REG0_reg 				<= 'b0;
		CACHE_CONTROL_REG1_reg 				<= 'b0;
		CACHE_L1_BUFFER_CONTROL_REG0_reg 	<= 'b0;
		CACHE_L1_BUFFER_CONTROL_REG1_reg	<= 'b0;
	end
	else begin
		// core writable
		// -----------------------------------------------
		if (core_request_i & core_wren_i) begin
			case(core_address_i) 
				`GP_REG0: 				GP_REG0_reg 			<= core_data_i;
				`GP_REG1: 				GP_REG1_reg 			<= core_data_i;
				`GP_REG2: 				GP_REG2_reg 			<= core_data_i;
				`CACHE_CONTROL_REG0: 	CACHE_CONTROL_REG0_reg 	<= core_data_i;
				default:;
			endcase
		end

		// proxy writable
		// -----------------------------------------------
		if (proxy_request_i & proxy_wren_i) begin
			case(proxy_address_i) begin
				`CACHE_CONTROL_REG1: 			CACHE_CONTROL_REG1_reg 				<= proxy_data_i;
				`CACHE_L1_BUFFER_CONTROL_REG0: 	CACHE_L1_BUFFER_CONTROL_REG0_reg 	<= proxy_data_i;
				`CACHE_L1_BUFFER_CONTROL_REG1:  CACHE_L1_BUFFER_CONTROL_REG1_reg 	<= proxy_data_i;
				default:;
			end
		end
	end
end


// read control
// ------------------------------------------------------------------------------------------
reg 				core_valid_reg,
					proxy_valid_reg;
reg [BW_DATA-1:0]	core_data_reg,
					proxy_data_reg;

assign core_valid_o 		= core_valid_reg;
assign core_data_o 			= core_data_reg;
assign proxy_valid_o 		= proxy_valid_reg;
assign proxy_data_o 		= proxy_data_reg;
assign cache_control_bus0_o	= {CACHE_CONTROL_REG0_reg, CACHE_CONTROL_REG1_reg};

always @(posedge clock_i) begin
	if (!resetn_i) begin
		core_valid_reg 	<= 1'b0;
		core_data_reg 	<= 'b0;
		proxy_valid_reg <= 1'b0;
		proxy_data_reg 	<= 'b0;
	end
	else begin

		// default signals
		core_valid_reg 	<= 1'b0;
		proxy_valid_reg <= 1'b0;

		// core read service
		// ------------------------------------------------
		if (core_request_i & !core_wren_i) begin

			core_valid_reg <= 1'b1;

			case(core_address_i)
				`GP_REG0: 						core_data_reg <= GP_REG0_reg;
				`GP_REG1: 						core_data_reg <= GP_REG1_reg;
				`GP_REG2: 						core_data_reg <= GP_REG2_reg;
				`CACHE_CONTROL_REG0: 			core_data_reg <= CACHE_CONTROL_REG0_reg;
				`CACHE_CONTROL_REG1: 			core_data_reg <= CACHE_CONTROL_REG1_reg;
				`CACHE_L1_BUFFER_CONTROL_REG0: 	core_data_reg <= CACHE_L1_BUFFER_CONTROL_REG0_reg;
				`CACHE_L1_BUFFER_CONTROL_REG1: 	core_data_reg <= CACHE_L1_BUFFER_CONTROL_REG1_reg;
				`CACHE_L1_STATUS_REG0: 			core_data_reg <= cache_service_bus0_i[BW_DATA-1:0];
				`CACHE_L1_STATUS_REG1: 			core_data_reg <= cache_service_bus1_i[BW_DATA-1:0];
				`CACHE_L1_DATA_REG0: 			core_data_reg <= cache_service_bus0_i[2*BW_DATA-1:BW_DATA];
				`CACHE_L1_DATA_REG1: 			core_data_reg <= cache_service_bus1_i[2*BW_DATA-1:BW_DATA];
				`CACHE_L1_BUFFER_DATA_REG0: 	core_data_reg <= cache_service_bus0_i[3*BW_DATA-1:2*BW_DATA];
				`CACHE_L1_BUFFER_DATA_REG1: 	core_data_reg <= cache_service_bus1_i[3*BW_DATA-1:2*BW_DATA];
			endcase
		end

		// proxy read service
		// ------------------------------------------------
		if (proxy_request_i & !proxy_wren_i) begin

			proxy_valid_reg <= 1'b1;

			case(proxy_address_i)
				`GP_REG0: 						proxy_data_reg <= GP_REG0_reg;
				`GP_REG1: 						proxy_data_reg <= GP_REG1_reg;
				`GP_REG2: 						proxy_data_reg <= GP_REG2_reg;
				`CACHE_CONTROL_REG0: 			proxy_data_reg <= CACHE_CONTROL_REG0_reg;
				`CACHE_CONTROL_REG1: 			proxy_data_reg <= CACHE_CONTROL_REG1_reg;
				`CACHE_L1_BUFFER_CONTROL_REG0: 	proxy_data_reg <= CACHE_L1_BUFFER_CONTROL_REG0_reg;
				`CACHE_L1_BUFFER_CONTROL_REG1: 	proxy_data_reg <= CACHE_L1_BUFFER_CONTROL_REG1_reg;
				`CACHE_L1_STATUS_REG0: 			proxy_data_reg <= cache_service_bus0_i[BW_DATA-1:0];
				`CACHE_L1_STATUS_REG1: 			proxy_data_reg <= cache_service_bus1_i[BW_DATA-1:0];
				`CACHE_L1_DATA_REG0: 			proxy_data_reg <= cache_service_bus0_i[2*BW_DATA-1:BW_DATA];
				`CACHE_L1_DATA_REG1: 			proxy_data_reg <= cache_service_bus1_i[2*BW_DATA-1:BW_DATA];
				`CACHE_L1_BUFFER_DATA_REG0: 	proxy_data_reg <= cache_service_bus0_i[3*BW_DATA-1:2*BW_DATA];
				`CACHE_L1_BUFFER_DATA_REG1: 	proxy_data_reg <= cache_service_bus1_i[3*BW_DATA-1:2*BW_DATA];
			endcase
		end
	end
end

endmodule

`endif