#ifndef _SAMPLER_H_
#define _SAMPLER_H_

#include "protocol.h"
#include "command.h"
#include "fpga_elf.h"
#include "jtag_proxy.h"
#include "test.h"
#include <stdint.h>

#define SAMPLER_OUTPUT_PATH 			"results/sample/"
#define SAMPLER_WORDS_PER_SAMPLE 		5
#define SAMPLER_BUFFER_CAPACITY 		0x1FFF 	// (256kB = 64kW; 64kW / max_log2(5words per pair) = 64kW / 8 =  8k entries)
#define SAMPLER_BUFFER_PACKET_CAPACITY 	0x1F4 	// max number of entries that can be read at once
												// legacy option, I believe there is no restriction with this version of the software

#define TRACKER_OUTPUT_PATH 			"results/track/"
#define TRACKER_WORDS_PER_SAMPLE 		16
#define TRACKER_BUFFER_CAPACITY 		0x1000 	// buffer capacity (aggregrate) divided by pair size
												// ex, 256kB is buffer capacity, a line pair is 512 bit
												// 2^18 / (2^6) = 2^12 = 0x1000
#define TRACKER_BUFFER_PACKET_CAPACITY 	0xFA 	// max transfer size is 16kB
												// ex, if line size is 512bit = 64B, then can transfer 100 max


uint32_t sampler_run(pHandle, command *);
// description: 		- blocking
//  					- custom sampler sequence
// return: 				0: success, 1: fail
// pHandle: 			proxy handle
// command: 			command to execute

uint32_t tracker_run(pHandle, command *);
// description: 		- blocking
//  					- custom tracker sequence
// return: 				0: success, 1: fail
// pHandle: 			proxy handle
// command: 			command to execute
void get_file_name(command *, char *);
uint32_t sampler_read_buffer(pHandle, uint32_t n_entries,FILE *);
uint32_t protocol_sampler_buffer_read(pHandle pInst, uint32_t buffer_start_address, uint32_t buffer_packet_size, FILE *);

uint32_t tracker_read_buffer(pHandle, uint32_t n_entries, FILE*);
uint32_t protocol_tracker_buffer_read(pHandle pInst, uint32_t buffer_start_address, uint32_t buffer_packet_size, FILE *);

#endif