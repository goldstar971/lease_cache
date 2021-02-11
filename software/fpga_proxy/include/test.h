#ifndef _TEST_H_
#define _TEST_H_

#include "protocol.h"
#include "command.h"
#include "fpga_elf.h"
#include "jtag_proxy.h"
#include <stdint.h>

#define TEST_DONE_ADDR  	0x04000104
#define CACHE_RESULT_ADDR 	0x04000110
#define CACHE_L1I_ADDR 		0x04000080
#define CACHE_L1D_ADDR 		0x04000084

#define CACHE_REPORT_BYTES 	128


uint32_t test_run(pHandle, command *);
// description: 		- blocking
//  					- custom test sequence
// return: 				0: success, 1: fail
// pHandle: 			proxy handle
// command: 			command to execute

uint32_t script_run(pHandle, command *);
// description: 		- blocking
//  					- executes command sequence as written in an input .pss file
// return: 				0: success, 1: fail
// pHandle: 			proxy handle
// command: 			command to execute

uint32_t make_cache_report(pHandle, char *rx_buffer);
// description: 		- blocking
//  					- reads all cache data
// return: 				0: success, 1: fail
// pHandle: 			proxy handle
// rx_buffer: 			buffer to store cache data

#endif