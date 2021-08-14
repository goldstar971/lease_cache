#ifndef _PROTOCOL_H_
#define _PROTOCOL_H_

#include <stdint.h>
#include "jtag_wrapper.h"

// short-hand
#define pHandle  				void *

// keys used for software-hardware synchronization
#define SYNC_KEY        		0xCD0031F7
#define SYNC_DONE 				0x4A78B9F2

// define maximum number of bytes pre-protocol
#define BUFFER_SIZE_BYTES 		0x4000 				// 16kB
#define OVERHEAD_READ_BYTES 	12 					// [init, config, addr]
#define OVERHEAD_WRITE_BYTES 	12 					// [init, config, addr]
#define OVERHEAD_CONFIG_BYTES 	8 					// [init, config]
#define MAX_READ_BYTES 			BUFFER_SIZE_BYTES-OVERHEAD_READ_BYTES
#define MAX_WRITE_BYTES 		BUFFER_SIZE_BYTES-OVERHEAD_WRITE_BYTES

// protocol defines
#define PROTOCOL_INIT_PACKET 			0x00000000
#define PROTOCOL_FLAG_READ 				0x00000000
#define PROTOCOL_FLAG_WRITE 			0x00001000
#define PROTOCOL_FLAG_MULTIWORD 		0x00002000
#define PROTOCOL_FLAG_CONFIG  			0x00004000
#define PROTOCOL_FLAG_CACHE_FUSION  	0x00010000
#define PROTOCOL_FLAG_SAMPLER_FUSION  	0x00020000
#define PROTOCOL_FLAG_TRACKER_FUSION 	0x00040000
#define PROTOCOL_MASK_MULTIWORD 		0x00000FFF


pHandle 	protocol_connect 		(void);
// description: 			- non-blocking
// return: 					handle to data_structure

void 		protocol_close 			(pHandle);
// description: 			- non-blocking
// 							- do not call: double free bug stemming from intel .so (08/12/2020)
// return: 					n/a 
// pHandle: 				handle			 

uint32_t 	protocol_synchronize 	(pHandle, uint32_t n_iterations, uint32_t option_print);
// description: 			- blocking
// 							- sequentially sends packets to FPGA, FPGA modulates the packets and sends them back,
// 							software client verifies that they were decoded correctly
// return: 					0: pass, 1: fail
// pHandle: 				handle
// n_iterations: 			number of correct sync. returns needed (without error) to pass
// option_print: 			0: do not print sync. log to terminal, Else: do ... 


uint32_t 	protocol_read 			(pHandle, char *pBuffer, uint32_t n_bytes, uint32_t addr);
// description: 			- blocking
// 							- creates read request
// return: 					0: pass, 1: fail
// pHandle: 				handle
// pBuffer: 				buffer to store the read data
// n_bytes: 				number of bytes to read
// addr: 					address of where to begin reading from


uint32_t 	protocol_write 			(pHandle, char *pBuffer, uint32_t n_bytes, uint32_t addr);
// description: 			- blocking
// 							- creates write request
// return: 					0: pass, 1: fail
// pHandle: 				handle
// pBuffer: 				buffered data to write
// n_bytes: 				number of bytes to write
// addr: 					address of where to begin writing to

uint32_t 	protocol_fpga_config 	(pHandle, uint32_t addr, uint32_t data);
// description: 			- blocking
//  						- legacy command
// return: 					0: pass, 1: fail 
// pHandle: 				handle
// data: 					configuration data
// addr: 					configuration address

uint32_t 	protocol_cache_fusion 	(pHandle, char *pBuffer, uint32_t addr, uint32_t data, uint32_t num_words);
// description: 			- blocking
//  						- legacy command
// 							- executes a compound command
// return: 					0: pass, 1: fail 
// pHandle: 				handle
// data: 					primary fusion address
// addr: 					fusion data/secondary address

#endif