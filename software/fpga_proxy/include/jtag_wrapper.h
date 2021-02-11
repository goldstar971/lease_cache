#ifndef _JTAG_WRAPPER_H_
#define _JTAG_WRAPPER_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// write buffer needs to be statically allocated because there is no thread protection for  
// non-blocking write command in the jtag_atlantic shared libraries
#define WRITE_BUFFER_BYTES 	0x4000		

// word size - used to swap endianess for writes
// NOTE: this parameter needs to be matched in hardware 
#define BYTES_PER_WORD 		0x4


void 		*jtag_init	(void); 							
// description:  	- non-blocking call
// 					- create jtag_atlantic data structure
// return: 			pointer to jtag_atlantic data structure (wrapped as void pointer)


void 		jtag_close	(void *pHandle); 							  		
// description: 	- non-blocking call
// 					- de-allocate jtag_atlantic data structure
// return: 			n/a
// pHandle: 		pointer to jtag_atlantic data structure


void	 	jtag_read	(void *pHandle, char *pBuffer, uint32_t n_bytes); 	
// description: 	- blocking call 
// 					- read requested number of bytes 
// 					- does not swap endianess
// return: 			n/a
// pHandle: 		pointer to jtag_atlantic data structure 
// pBuffer: 		pointer to buffer to store read data in
// n_bytes: 		number of bytes to read


uint32_t 	jtag_write	(void *pHandle, char *pBuffer, uint32_t n_bytes); 	
// description: 	- non-blocking call
// 					- write specified bytes of buffered data
// 					- method copies buffer contents to statically allocated buffer
// 					- reverses endianess of every packet (four bytes)
// return: 			0 if successful, 1 if unsuccessful
// pHandle: 		pointer to jtag_atlantic data structure 
// pBuffer: 		pointer to buffer to store read data in
// n_bytes: 		number of bytes to write

#endif