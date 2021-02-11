#include "fpga_elf.h"
#include <string.h>


uint32_t fpga_load_memory(pHandle pInst, command *pCommand){

	// load section information
	uint32_t buffer_addr[10] = {0}; 		// memory address of where the section begins (byte address)
	uint32_t buffer_size[10] = {0}; 		// number of bytes to transfer per section

	if(get_elf_sections(pCommand->field[1], buffer_addr, buffer_size)){
		return 1;
	}

	// packetize data and dma to fpga
	// only send section information if the section size is non-zero
	uint32_t bytes_sent = 0;

	for (uint32_t k = 0; k < 10; k++){
		if (buffer_size[k] > 0){
			if(dma_elf_data(pInst, pCommand->field[1], buffer_addr[k], buffer_size[k], bytes_sent, 1)){
				return 1;
			}
			bytes_sent = bytes_sent + buffer_size[k]; 		
		}
	}
	// return without error
	return 0;
}

uint32_t fpga_verify_memory(pHandle pInst, command *pCommand){

	// load section information
	uint32_t buffer_addr[10] = {0}; 		// memory address of where the section begins (byte address)
	uint32_t buffer_size[10] = {0}; 		// number of bytes to transfer per section

	if(get_elf_sections(pCommand->field[1], buffer_addr, buffer_size)){
		return 1;
	}

	// packetize data and dma to fpga
	// only send section information if the section size is non-zero
	uint32_t bytes_sent = 0;

	for (uint32_t k = 0; k < 10; k++){
		if (buffer_size[k] > 0){
			if(dma_elf_data(pInst, pCommand->field[1], buffer_addr[k], buffer_size[k], bytes_sent, 0)){
				return 1;
			}
			bytes_sent = bytes_sent + buffer_size[k]; 		
		}
	}
	// return without error
	return 0;
}


uint32_t get_elf_sections(char *filepath, uint32_t *pAddr, uint32_t *pSize){

	// first check if the data and info files exist
	char info_path_str[128];

	// copy string literal to new array then add the correct file extensions 	
	strcpy(info_path_str, filepath);
	strncat(info_path_str, "_sections.txt", 14); 	// add one because of terminator

	// open file
	FILE *pFile = fopen(info_path_str,"r");
	if(!pFile){
		printf("Error, could not open %s\n", info_path_str);
    	return 1;
    }

    // loop through file line by line and parse into an address field and size field
	char line[128];
	uint32_t section_index = 0;

	while(fgets(line, sizeof(line)/sizeof(line[0]), pFile)){

		// search for delimiter and separate the line by it
		char field0[64];
		char field1[64];
		char *delimiter_index = strchr(line,',');
		int index0 = delimiter_index - line;

		// copy fields into the new arrays and then convert to numbers
		strncpy ( field0, line, index0);
		strncpy ( field1, delimiter_index+1, 64);

		// add to array
		pAddr[section_index] = (uint32_t)strtol(field0, NULL, 16);
		pSize[section_index++] = (uint32_t)strtol(field1, NULL, 16);
	}

    // close file and return without error
	if (fclose(pFile)){
		printf("Error: could not close file\n");
		return 1;
	}
    return 0;
}


uint32_t dma_elf_data(pHandle pInst, char *filename, uint32_t address, uint32_t size, uint32_t bytes_sent, uint32_t write_flag){

	// transfer temporaries
	char pBuffer[MAX_WRITE_BYTES];
	char pBufferVerify[MAX_WRITE_BYTES];
	uint32_t bytes_remaining = size;
	uint32_t file_address = bytes_sent >> 2;
	uint32_t memory_address = address;
	uint32_t file_size; 					 				// how much data to import
	uint32_t iteration = 0;

	// write-out every section of content
	while(bytes_remaining){

		if (bytes_remaining > MAX_WRITE_BYTES){
			file_size = MAX_WRITE_BYTES;
		}
		else{
			file_size = bytes_remaining;
		}

		// read data
		if(get_elf_data(filename, pBuffer, MAX_WRITE_BYTES, file_address, file_size)){
			printf("Error: could not get program data\n");
			return 1;
		}

		// dma sequence
		// ---------------
		if (write_flag){
			if (protocol_write(pInst, pBuffer, file_size, memory_address)){
				return 1;
			}
			printf("\rWrote: %u bytes - packet: %u",file_size,iteration++);
			fflush(stdout);		
		}
		else{
			// read data
			if (protocol_read(pInst, pBufferVerify, file_size, memory_address)){
				return 1;
			}
			// check data
			for (uint32_t k = 0; k < file_size; k = k + 1){
				if (pBuffer[k] != pBufferVerify[k]){
					printf("Verification failed\n");
					return 1;
				}
			}
			printf("\rVerified: %u bytes - packet: %u",file_size,iteration++);
			fflush(stdout);	
		}

		// update the file address
		file_address = file_address + (file_size >> 2);
		memory_address = memory_address + file_size;
		bytes_remaining = bytes_remaining - file_size;

	}
	// return without error
	// at certain speeds there's a weird double print on the last line
	// solution is to erase line with VT100 escape code and re-enter
	printf("\33[2K\r");
	if (write_flag){
		printf("\rWrote: %u bytes - packet: %u\n",file_size,--iteration);
	}
	else{
		printf("\rVerified: %u bytes - packet: %u\n",file_size,--iteration);
	}
	return 0;
}


uint32_t get_elf_data(char *filepath, char *pBuffer, uint32_t buffer_size, uint32_t starting_index, uint32_t length){

	// create path
	char data_path_str[128];	
	strcpy(data_path_str, filepath);
	strncat(data_path_str, "_compressed.txt", 16); 		// add one because of '\n'

	// open file
	FILE *pFile = fopen(data_path_str,"r");
	if(!pFile){
		printf("Error, could not open %s\n", data_path_str);
    	return 1;
    }

    // loop through file only extracting the necessary information
    char line[64];
    uint32_t n_current_file_line = 0;
    uint32_t n_current_section_entry = 0;

    while(fgets(line, sizeof(line), pFile)){

    	// determine if should be imported
    	if ((n_current_file_line >= starting_index) & (4*n_current_section_entry < length)){

    		if (n_current_section_entry >= buffer_size){
    			printf("Error: buffer overflow\n");
    			return 1;
    		}
    		else{
    			*(uint32_t *)(pBuffer+(4*n_current_section_entry)) = (uint32_t)strtol(line, NULL, 16);
    			n_current_section_entry++;
    		}
    	}
    	n_current_file_line++;
    }

    // close file
    if (fclose(pFile)){
		printf("Error: could not close file\n");
		return 1;
	}
	return 0;
}