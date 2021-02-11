#ifndef _FPGA_ELF_H_
#define _FPGA_ELF_H_

#include "protocol.h"
#include "command.h"
#include "stdint.h" 
#include "stdio.h"

uint32_t get_elf_sections(char *filepath, uint32_t *pAddr, uint32_t *pSize);
// description: 		- blocking
//  					- get elf section data for fpga memory import
// return: 				0: success, 1: fail
// filepath: 			path to file (w/o extension) to get section info
// pAddr: 				buffer to store section addresses
// pSize: 				buffer to store section sizes

uint32_t get_elf_data(char *filepath, char *pBuffer, uint32_t buffer_size, uint32_t starting_index, uint32_t length);
// description: 		- blocking
//  					- get elf binary data for fpga memory import
// return: 				0: success, 1: fail
// filepath:  			path to file (w/o extension) to get binary data
// pBuffer: 			buffer to store read binary data
// buffer_size: 		size of the read data buffer to make sure there is no overflow (redundant)
// starting_index: 		file line of where to begin reading data
// length: 				the number of bytes to read

uint32_t dma_elf_data(pHandle pInst, char *filename, uint32_t address, uint32_t size, uint32_t bytes_sent, uint32_t write_flag);
// description: 		- blocking
//  					- either write-in or read-out the data specified by the filename to/from fpga
// return: 				0: success, 1: fail
// filename: 			path to file (w/o extension) to fpga-dma
// address: 			fpga address (byte-addr) of where to read/write data
// size: 				number of bytes to read/write
// bytes_sent: 			record of the number of bytes that have already been read/written (used to manage the file read/write) 
// write_flag: 			0: read-out and verify data, 1: write-in data

uint32_t fpga_load_memory(pHandle, command *);
// description: 		- blocking
// 						- writes the specified file into fpga memory
// return: 				0: success, 1: error
// pHandle: 			proxy handle
// command*: 			data structure that holds filename

uint32_t fpga_verify_memory(pHandle, command *);
// description: 		- blocking
// 						- reads fpga memory and checks the read values against a specified file's contents
// return: 				0: success, 1: error
// pHandle: 			proxy handle
// command*: 			data structure that holds filename

#endif