#include "protocol.h"

pHandle protocol_connect(){
	pHandle pInst = jtag_init();
	return pInst;
}

void protocol_close(pHandle pInst){
	jtag_close(pInst); 	// close the port
	pInst = NULL; 		// make sure no double free
}

uint32_t protocol_synchronize(pHandle pInst, uint32_t n_iterations, uint32_t option_print){

	uint32_t 	n_correct = 0; 	 			// synchronization tracking
	char 		tx_buffer[BYTES_PER_WORD]; 	// buffer for sending data
	char 		rx_buffer[BYTES_PER_WORD]; 	// buffer for receiving data

	// send all sync packets, must pass a certain amount in sequence
	// check for that at the end, allow for a handful of incorrect returns pre-sync
	for (uint32_t i = 0; i < (n_iterations + 5); i++){

		*(uint32_t *) tx_buffer = i; 					// get "random" number
		jtag_write(pInst, tx_buffer, BYTES_PER_WORD); 	// send to FPGA
		jtag_read(pInst, rx_buffer, BYTES_PER_WORD); 	// get response

		// check if correct, if not reset the count
		if ((*(uint32_t *) tx_buffer ^ SYNC_KEY) == *(uint32_t *) rx_buffer){
			n_correct++;
		}
		else{
			n_correct = 0;
		}

		if (option_print){
			printf("Sent: 0x%08x, Received: 0x%08x\n",(i ^ SYNC_KEY),*(uint32_t *) rx_buffer);
		}
	}

	// if failed do nothing else
	if (n_correct < n_iterations){
		return 1;
	}

	// if passed then send initialization packet
	*(uint32_t *) tx_buffer = SYNC_DONE;
	jtag_write(pInst, tx_buffer, BYTES_PER_WORD);

	return 0;

}

uint32_t protocol_read(pHandle pInst, char *pBuffer, uint32_t n_bytes, uint32_t addr){

	// validate the number of bytes being sent
	if (!n_bytes | (n_bytes > MAX_READ_BYTES) | (n_bytes % BYTES_PER_WORD)){
		return 1;
	}
	else{

		// create tx buffer
		char tx_buffer[OVERHEAD_READ_BYTES];
		*(uint32_t *)(tx_buffer+0*BYTES_PER_WORD) = PROTOCOL_INIT_PACKET; 						// initiator
		*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = PROTOCOL_MASK_MULTIWORD & (n_bytes >> 2); 	// number of words (4byte increments) to send
		*(uint32_t *)(tx_buffer+2*BYTES_PER_WORD) = addr; 										// address

		// if more than one word being sent flag it
		if (n_bytes > BYTES_PER_WORD){
			*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = *(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) | PROTOCOL_FLAG_MULTIWORD;
		}

		// command
		if(jtag_write(pInst, tx_buffer, OVERHEAD_READ_BYTES)){
			return 1;
		}

		// get response
		jtag_read(pInst, pBuffer, n_bytes);

		return 0;
	}
}

uint32_t protocol_write(pHandle pInst, char *pBuffer, uint32_t n_bytes, uint32_t addr){

	// validate the number of bytes being sent
	if (!n_bytes | (n_bytes > MAX_WRITE_BYTES) | (n_bytes % BYTES_PER_WORD)){
		return 1;
	}
	else{

		// create tx buffer
		char tx_buffer[OVERHEAD_READ_BYTES+n_bytes];
		*(uint32_t *)(tx_buffer+0*BYTES_PER_WORD) = PROTOCOL_INIT_PACKET; 						// initiator
		*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = PROTOCOL_MASK_MULTIWORD & (n_bytes >> 2); 	// number of words to send
		*(uint32_t *)(tx_buffer+2*BYTES_PER_WORD) = addr; 										// address

		// create config flags
		*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = *(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) | PROTOCOL_FLAG_WRITE;
		// if more than one word being sent flag it
		if (n_bytes > BYTES_PER_WORD){
			*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = *(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) | PROTOCOL_FLAG_MULTIWORD;
		}

		// populate the rest of the tx_buffer content
		for (uint32_t i = 0; i < n_bytes; i++){
			tx_buffer[OVERHEAD_READ_BYTES+i] = pBuffer[i];
		}

		// command
		if(jtag_write(pInst, tx_buffer, OVERHEAD_READ_BYTES+n_bytes)){
			return 1;
		}

		// get acknowledgement
		char rx_buffer[BYTES_PER_WORD];
		jtag_read(pInst, rx_buffer, BYTES_PER_WORD);

		// return of 0 means the request is executed and ackowledged
		// anything else is an error
		return *(uint32_t *)rx_buffer; 				
	}
}

uint32_t protocol_fpga_config(pHandle pInst, uint32_t addr, uint32_t data){
// NOTE: legacy command, not well commented b.c. should not be used anymore 

	// make tx buffer
	char tx_buffer[2*BYTES_PER_WORD];

	*(uint32_t *)(tx_buffer+0*BYTES_PER_WORD) = PROTOCOL_INIT_PACKET; 		// initiator
	*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = PROTOCOL_FLAG_CONFIG 	|  	// config flag
												(data & 0x00000FFF) 	| 	
												((addr << 24) & 0xFF000000); 	

	// send command
	if(jtag_write(pInst, tx_buffer, 2*BYTES_PER_WORD)){
		return 1;
	}

	// get acknowledgement
	char rx_buffer[BYTES_PER_WORD];
	jtag_read(pInst, rx_buffer, BYTES_PER_WORD);

	// return of 0 means the request is executed and ackowledged
	// anything else is an error
	return *(uint32_t *)rx_buffer; 
}

uint32_t protocol_cache_fusion(pHandle pInst, char *pBuffer, uint32_t addr, uint32_t data){

	// make the command packet
	char tx_buffer[4*BYTES_PER_WORD];
	*(uint32_t *)(tx_buffer+0*BYTES_PER_WORD) = PROTOCOL_INIT_PACKET; 			// initiator
	*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = PROTOCOL_FLAG_CACHE_FUSION; 	// config flag
	*(uint32_t *)(tx_buffer+2*BYTES_PER_WORD) = addr;
	*(uint32_t *)(tx_buffer+3*BYTES_PER_WORD) = data;

	// send packet
	if(jtag_write(pInst, tx_buffer, 4*BYTES_PER_WORD)){
		return 1;
	}

	// get data
	jtag_read(pInst, pBuffer, 16*BYTES_PER_WORD);

	return 0;
}