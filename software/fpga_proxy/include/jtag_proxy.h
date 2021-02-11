#ifndef _JTAG_PROXY_H_
#define _JTAG_PROXY_H_

#include <stdint.h>
#include "protocol.h"
#include "command.h"
#include "fpga_elf.h"
#include "test.h"
#include "sampler.h"

#define TERMINAL_COMMAND_BUFFER_LENGTH 	100

pHandle 	proxy_connect(void);
// description:	 	- blocking
//					- connect and synchronize to FPGA jtag_uart hardware
// return: 			handle to jtag_uart object

uint32_t 	proxy_terminal_command(pHandle);
// description: 	- blocking
// 					- read terminal command and execute 
// return: 			0: success, 1: fail
// pHandle: 		proxy handle

uint32_t 	proxy_string_command(pHandle, char *command_str);
// description: 	- blocking
// 					- execute command based on string input
// return: 			0: success, 1: fail
// pHandle: 		proxy handle
// command_str: 	command string

uint32_t 	proxy_execute(pHandle, command *pCommand);
// description: 	- blocking
// 					- execute command
// return: 			0: success, 1: unsuccessful, 2: close
// pHandle: 		proxy handle
// pCommand: 		command encoding data structure (results from command.h 'parse' method) 	


#endif