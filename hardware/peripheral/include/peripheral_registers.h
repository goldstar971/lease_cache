`ifndef _PERIPHERAL_REGISTERS_H_
`define _PERIPHERAL_REGISTERS_H_

															// permissions 	- access 	- description
															// --------------------------------------
`define GP_REG0 						32'h04000100 		// r/w 			- core 		- general purpose
`define GP_REG1 						32'h04000104 		// r/w 			- core 		- general purpose
`define GP_REG2 						32'h04000108 		// r/w 			- core 		- general purpose

`define CACHE_CONTROL_REG0 				32'h04000140 		// r/w 			- core 		- cache control (start/stop benchmarking)
`define CACHE_CONTROL_REG1  			32'h04000144 		// r/w 			- host 		- cache control (data selection)

`define CACHE_L1_STATUS_REG0 			32'h04000150 		// read only 	- all 		- instruction cache status (not really used)
`define CACHE_L1_STATUS_REG1 			32'h04000154 		// read only  	- all 		- data cache status (buffer full, etc.)

`define CACHE_L1_BUFFER_CONTROL_REG0 	32'h04000160 		// r/w 			- host 		- instruction cache buffer control (not used) 
`define CACHE_L1_BUFFER_CONTROL_REG1 	32'h04000164 		// r/w 			- host 		- data cache buffer control 

`define CACHE_L1_DATA_REG0 				32'h04000170 		// read only 	- all 		- instruction cache buffer data (not used)
`define CACHE_L1_DATA_REG1 				32'h04000174 		// read only 	- all 		- instruction cache buffer data (not used)

`define CACHE_L1_BUFFER_DATA_REG0 		32'h04000180 		// read only 	- all 		- instruction cache buffer data (not used)
`define CACHE_L1_BUFFER_DATA_REG1 		32'h04000184 		// read only  	- all 		- data cache buffer data

`endif