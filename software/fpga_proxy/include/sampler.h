#ifndef _SAMPLER_H_
#define _SAMPLER_H_

#include "protocol.h"
#include "command.h"
#include "fpga_elf.h"
#include "jtag_proxy.h"
#include "test.h"
#include <stdint.h>

#define SAMPLER_WORDS_PER_SAMPLE 		5
#define SAMPLER_BUFFER_CAPACITY 		0x1FFF 	// (256kB = 64kW; 64kW / max_log2(5words per pair) = 64kW / 8 =  8k entries)
#define SAMPLER_BUFFER_PACKET_CAPACITY 	0x1F4 	// max number of entries that can be read at once
												// legacy option, I believe there is no restriction with this version of the software


#ifdef MULTI_LEVEL_CACHE
	#define TRACKER_WORDS_PER_SAMPLE 		52
	#define TRACKER_BUFFER_PACKET_CAPACITY  0x4C // line size is 1664 bits, which divided in 16kB and rounded down gives 76 
	#define TRACKER_BUFFER_CAPACITY 		0x4CF 	// buffer capacity (aggregrate) divided by line size
												

#else
	#define TRACKER_WORDS_PER_SAMPLE 		16
	#define TRACKER_BUFFER_PACKET_CAPACITY 	0xFA 	// max transfer size is 16kB
												// ex, if line size is 512bit = 64B, then can transfer 100 max
	#define TRACKER_BUFFER_CAPACITY 		0x1000 	// buffer capacity (aggregrate) divided by pair size
												// ex, 256kB is buffer capacity, a line pair is 512 bit
												// 2^18 / (2^6) = 2^12 = 0x1000
#endif


#define COMM_CONTROL 0x20000110
#define METRIC_SEL   0x20000088


#define DISABLE_METRICS "WRITE 0x2000088, 0x00000000"
#define SAMPLING_SEL "WRITE 0x20000088, 0x00000001"
#define TRACKING_SEL "WRITE 0x20000088, 0x00000002"
#define SET_PERIPHS "WRITE 0x20000124     0x2"
#define SET_CPU     "WRITE 0x20000124     0x3"
#define RESET "WRITE 0x20000124     0x0"
#define CHECK_IF_TRACKER_FULL "WRITE 0x20000110 0x00000011"
#define CHECK_IF_TRACKER_FULL_L2 "WRITE 0x20000110 0x00000035"
#define CHECK_IF_SAMPLER_FULL "WRITE 0x20000110 0x0000000F"
#define CLEAR_BUFFER "WRITE 0x20000110 0x00800000"
#define GET_NUM_BUFFER_ENTRIES_SAMPLER    "WRITE 0x20000110 0x00000008"
#define GET_NUM_BUFFER_ENTRIES_TRACKER 	  "WRITE 0x20000110 0x00000010"
#define GET_NUM_BUFFER_ENTRIES_TRACKER_L2 "WRITE 0x20000110 0x00000034"
#define WRITEOUT_TABLE "WRITE 0x20000110 0x00400000"
#define SET_MM_ACCESS_COMMS "CONFIG 0x2 0x0"
#define SET_MM_ACCESS_CPU   "CONFIG 0x2 0x1"




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
void get_file_name(char *, char*, char*);
uint32_t sampler_read_buffer(pHandle, uint32_t n_entries,FILE *);
uint32_t protocol_sampler_buffer_read(pHandle pInst, uint32_t buffer_start_address, uint32_t buffer_packet_size, FILE *);

uint32_t tracker_read_buffer(pHandle, uint32_t n_entries, FILE*);
uint32_t protocol_tracker_buffer_read(pHandle pInst, uint32_t buffer_start_address, uint32_t buffer_packet_size, FILE *);

#endif