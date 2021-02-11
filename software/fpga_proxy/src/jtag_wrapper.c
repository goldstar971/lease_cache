#include "jtag_wrapper.h"
#include "jtag_atlantic.h"
#include <assert.h>

// need to allocate a static memory partition for write commands
// threads are not protected, in specific the write in non-blocking
// and will create issues if you don't explicitly send a copy of the data (two threads cannot r/w the same data)
// and sub-tasks like fifo scans will seg fault or stack crash
static char static_buffer[WRITE_BUFFER_BYTES];


void *jtag_init(){

	// open port
	JTAGATLANTIC *pjtag = jtagatlantic_open(NULL, -1, -1, "proxy");
	if(!pjtag) {
        printf("Error: JTAG connection error\n");
        exit(0);
    }
    printf("JTAG Connection successful - press Cntrl+C to exit\n");

    // pass handle
	return (void *) pjtag;
}


void jtag_close(void *pHandle){
	jtagatlantic_close((JTAGATLANTIC *)pHandle);
	printf("JTAG port closed\n");
}


uint32_t jtag_write(void *pHandle, char *pBuffer, uint32_t n_bytes){

    // check that request does not exceed static buffer size
    if (n_bytes > WRITE_BUFFER_BYTES){
        printf("Error: JTAG-WRITE is larger than allocated buffer\n");
        return 1;
    } 

    // send packet
    // reverse endianess every word
    for (uint32_t i = 0; i < n_bytes; i = i + BYTES_PER_WORD){
        for (uint32_t j = 0; j < BYTES_PER_WORD; j++){
            static_buffer[i+j] = pBuffer[i+BYTES_PER_WORD-1-j];
        }
    }
    assert(jtagatlantic_write((JTAGATLANTIC *)pHandle, static_buffer, n_bytes) == n_bytes);

    // no error
    return 0;
}


void jtag_read(void *pHandle, char *pBuffer, uint32_t n_bytes){

	// wait until the specified number of bytes are available
    while(jtagatlantic_bytes_available((JTAGATLANTIC *)pHandle) != n_bytes);

    // fetch all and make sure the right amount was taken
    assert(jtagatlantic_read((JTAGATLANTIC *)pHandle, pBuffer, n_bytes) == n_bytes);

}