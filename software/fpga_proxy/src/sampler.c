#include "sampler.h"
#include <time.h> 				// timers
#include <inttypes.h> 
#include <unistd.h> 			// sleep
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>


void get_file_name(command *pcommand,char * file_name, char* dir ){
	char unsplit[200];
	char parts[5][50];
	int counter=0;
	strcpy(unsplit,pcommand->field[1]);
	char *ptr =strtok(unsplit,"/");

	while(ptr !=NULL){
	    strcpy(parts[counter],ptr);
	     ptr = strtok(NULL,"/");
	   counter=counter+1;
	}
	
	sprintf(file_name,"%s.txt",parts[counter-2]);

	sprintf(dir,"%s",parts[counter-3]);
}

uint32_t sampler_read_buffer(pHandle pInst, uint32_t n_entries, FILE* file_handle){

	uint32_t buffer_start_address = 0;
	uint32_t buffer_packet_size = 0;
	uint32_t remaining_entries = n_entries;

	// while there are still unread buffer entries, keep drawing packets
	while(remaining_entries){

		// if the number of entries to read exceeds the transaction limit, ceiling it
		if (remaining_entries > SAMPLER_BUFFER_PACKET_CAPACITY){ 
			buffer_packet_size = SAMPLER_BUFFER_PACKET_CAPACITY;
		}
		else{
			buffer_packet_size = remaining_entries;
		}

		// execute the buffer read
		if(protocol_sampler_buffer_read(pInst, buffer_start_address, buffer_packet_size, file_handle)){
			return 1;
		}
		buffer_start_address = buffer_start_address + buffer_packet_size;
		remaining_entries = remaining_entries - buffer_packet_size;
	
	}
	// return without error
	return 0;
}

uint32_t tracker_read_buffer(pHandle pInst, uint32_t n_entries, FILE * file_handle){

	uint32_t buffer_start_address = 0;
	uint32_t buffer_packet_size = 0;
	uint32_t remaining_entries = n_entries;

	// while there are still unread buffer entries, keep drawing packets
	while(remaining_entries){

		// if the number of entries to read exceeds the transaction limit, ceiling it
		if (remaining_entries > TRACKER_BUFFER_PACKET_CAPACITY){ 
			buffer_packet_size = TRACKER_BUFFER_PACKET_CAPACITY;
		}
		else{
			buffer_packet_size = remaining_entries;
		}

		// execute the buffer read
		if(protocol_tracker_buffer_read(pInst, buffer_start_address, buffer_packet_size, file_handle)){
			return 1;
		}
		buffer_start_address = buffer_start_address + buffer_packet_size;
		remaining_entries = remaining_entries - buffer_packet_size;
	}

	// return without error
	return 0;
}

uint32_t protocol_sampler_buffer_read(pHandle pInst, uint32_t buffer_start_address, uint32_t buffer_packet_size, FILE *file_handle){
	
	// create buffer to receive the data
	char rx_buffer[4*SAMPLER_WORDS_PER_SAMPLE*buffer_packet_size];

	// make the command packet, send it, and receive response
	char tx_buffer[4*BYTES_PER_WORD];
	*(uint32_t *)(tx_buffer+0*BYTES_PER_WORD) = PROTOCOL_INIT_PACKET; 			// initiator
	*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = PROTOCOL_FLAG_SAMPLER_FUSION; 	// config flag
	*(uint32_t *)(tx_buffer+2*BYTES_PER_WORD) = buffer_start_address;
	*(uint32_t *)(tx_buffer+3*BYTES_PER_WORD) = buffer_packet_size;

	if(jtag_write(pInst, tx_buffer, 4*BYTES_PER_WORD)){
		return 1;
	}
	jtag_read(pInst, rx_buffer, 4*SAMPLER_WORDS_PER_SAMPLE*buffer_packet_size);
    
	
	// write data to file
	for (uint32_t i = 0; i < 4*SAMPLER_WORDS_PER_SAMPLE*buffer_packet_size; i = i + 4*SAMPLER_WORDS_PER_SAMPLE){
		char temp_line[160];
		sprintf(temp_line, "%08x,%08x,%08x,%lu\n",	*(uint32_t *)(rx_buffer+(i+0)),
													*(uint32_t *)(rx_buffer+(i+4)),
													*(uint32_t *)(rx_buffer+(i+8)),
													*(uint64_t *)(rx_buffer+(i+12)));
		fprintf(file_handle, "%s", temp_line);
	}

	// close the file
	
	return 0;
}

uint32_t protocol_tracker_buffer_read(pHandle pInst, uint32_t buffer_start_address, uint32_t buffer_packet_size, FILE* file_handle){
	
	// create buffer to receive the data
	char rx_buffer[4*TRACKER_WORDS_PER_SAMPLE*buffer_packet_size];

	// make the command packet, send it, and receive response
	char tx_buffer[4*BYTES_PER_WORD];
	*(uint32_t *)(tx_buffer+0*BYTES_PER_WORD) = PROTOCOL_INIT_PACKET; 			// initiator
	*(uint32_t *)(tx_buffer+1*BYTES_PER_WORD) = PROTOCOL_FLAG_TRACKER_FUSION; 	// config flag
	*(uint32_t *)(tx_buffer+2*BYTES_PER_WORD) = buffer_start_address;
	*(uint32_t *)(tx_buffer+3*BYTES_PER_WORD) = buffer_packet_size;

	if(jtag_write(pInst, tx_buffer, 4*BYTES_PER_WORD)){
		return 1;
	}
	jtag_read(pInst, rx_buffer, 4*TRACKER_WORDS_PER_SAMPLE*buffer_packet_size);



	// write data to file
	for (uint32_t i = 0; i < 4*TRACKER_WORDS_PER_SAMPLE*buffer_packet_size; i = i + 4*TRACKER_WORDS_PER_SAMPLE){
		char temp_line[512];
		sprintf(temp_line, "%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x\n",
								*(uint32_t *)(rx_buffer+(i+0)),
								*(uint32_t *)(rx_buffer+(i+4)),
								*(uint32_t *)(rx_buffer+(i+8)),
								*(uint32_t *)(rx_buffer+(i+12)),
								*(uint32_t *)(rx_buffer+(i+16)),
								*(uint32_t *)(rx_buffer+(i+20)),
								*(uint32_t *)(rx_buffer+(i+24)),
								*(uint32_t *)(rx_buffer+(i+28)),
								*(uint32_t *)(rx_buffer+(i+32)),
								*(uint32_t *)(rx_buffer+(i+36)),
								*(uint32_t *)(rx_buffer+(i+40)),
								*(uint32_t *)(rx_buffer+(i+44)),
								*(uint32_t *)(rx_buffer+(i+48)),
								*(uint32_t *)(rx_buffer+(i+52)),
								*(uint32_t *)(rx_buffer+(i+56)),
								*(uint32_t *)(rx_buffer+(i+60)));

		fprintf(file_handle, "%s", temp_line);
	}


	return 0;
}


uint32_t sampler_run(pHandle pInst, command *pCommand){

	// temporaries
	time_t time0, time1;
	char command_str[200];
	char file_path[200]; 
	char file_name[50];
	char benchmark_type[50];
	char full_output_path[250]; 
	// put system in reset
	sprintf(command_str, "CONFIG 0x2 0x0");
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
	sprintf(command_str, RESET);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}

	// load fpga memory with target application
	sprintf(command_str, "LOAD %s\r",pCommand->field[1]);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}


	//get file name
	get_file_name(pCommand,file_name,benchmark_type);
	//combine into full path
	sprintf(file_path,"%s%s/",SAMPLER_OUTPUT_PATH,benchmark_type);
	sprintf(full_output_path,"%s%s",file_path,file_name);
	//if directory doesn't exist, try to create it.
	if(0!= access(file_path,F_OK)){
		//make folder if error is that dir doesn't exist
		if (ENOENT==errno){
			mkdir(file_path,0777);
		}
		else{
			printf("Can't access directory for reasons other than non-existence.\n");
			return 1;
		}
	}


	//open file to log data
	FILE *file_handle =fopen(full_output_path,"w");
	if (file_handle == NULL){
    	return 1;
    }

 //pull peripherals out of reset
	sprintf(command_str, SET_PERIPHS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}

	// begin wall-clock timer
	sprintf(command_str, SEL_PERIPHS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}

		    //select sampling as metric
	 sprintf(command_str, SAMPLING_SEL);
    if(proxy_string_command(pInst, command_str)){
		return 1;
	}
	//pull processor out of reset
	sprintf(command_str, SET_CPU);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}


	time0 = time(NULL); 						


	// check for completion of the main
	// --------------------------------------------------------------------------------------------------------------------------------------
	char rx_buffer[4];
	*(uint32_t *)rx_buffer = 0x00000000;

	// continuously check for application completion
	while(*(uint32_t *)rx_buffer != 0x00000001){

		// check if the sampler buffer is full
		sprintf(command_str, CHECK_IF_SAMPLER_FULL); 		// switch to full flag register
		if(proxy_string_command(pInst, command_str)){
				return 1;
			}
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 		// read the full flag

		// if full then read out the contents of the buffer
		if (*(uint32_t *)rx_buffer == 0x00000001){

			// read contents and write to file
			printf("%s\n","Sampler buffer full, reading contents");
			sampler_read_buffer(pInst, SAMPLER_BUFFER_CAPACITY,file_handle);

			// clear the buffer full flag
			sprintf(command_str, CLEAR_BUFFER); 	// writing this bit clears the buffer and full flag
			if(proxy_string_command(pInst, command_str)){
					return 1;
				}
			*(uint32_t *)rx_buffer = 0x00000000;
		}
		// else check to see if the application execution has finished
		else{
			protocol_read(pInst, rx_buffer, 4, TEST_DONE_ADDR); 	// read done flag
		}
	}

	// read out the remaining entries of the sampler buffer
	sprintf(command_str, GET_NUM_BUFFER_ENTRIES); 		// switch to number of buffer entries register
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 		// read the number of buffer entries
	sampler_read_buffer(pInst, *(uint32_t *)rx_buffer,file_handle);

	// read out the remaining entries of the sampler lookup table
	// it takes 64 cycles to dump the table; takes longer in software here to transition so no external delay necessary - allegedly (Ian)
	sprintf(command_str, CLEAR_BUFFER); 	// writing this bit clears the buffer and full flag
	proxy_string_command(pInst, command_str);
	sprintf(command_str, "WRITE 0x04000110 0x00400000");	// command sampler to writeout table contents to buffer
	proxy_string_command(pInst, command_str);
	sleep(1); 												// make sure table has time to writeout entries to buffer
	sprintf(command_str, GET_NUM_BUFFER_ENTRIES); 	// switch to number of buffer(table) entries register
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 	// read the number of buffer(table) entries
	sampler_read_buffer(pInst, *(uint32_t *)rx_buffer,file_handle);

	// report
	// --------------------------------------------------------------------------------------------------------------------------------------
	time1 = time(NULL);
	printf("Approx. Time-to-Execute: %lu seconds\n", time1-time0);

		// close the file
	fclose(file_handle);

	// report and exit without error
	return 0;
}


uint32_t tracker_run(pHandle pInst, command *pCommand){

	// temporaries
	time_t time0, time1;
	char command_str[200];
	char file_path[200]; 
	char file_name[50];
	char benchmark_type[50];
	char full_output_path[250]; 

	// put system in reset
	sprintf(command_str, "CONFIG 0x2 0x0");
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	sprintf(command_str, RESET);
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}

	// load fpga memory with target application
	sprintf(command_str, "LOAD %s\r",pCommand->field[1]);
	proxy_string_command(pInst, command_str);

//get file name
	get_file_name(pCommand,file_name,benchmark_type);
	//combine into full path
	sprintf(file_path,"%s%s/",TRACKER_OUTPUT_PATH,benchmark_type);
	sprintf(full_output_path,"%s%s",file_path,file_name);
	//if directory doesn't exist, try to create it.
	if(0!= access(file_path,F_OK)){
		//make folder if error is that dir doesn't exist
		if (ENOENT==errno){
			mkdir(file_path,0777);
		}
		else{
			printf("Can't access directory for reasons other than non-existence.\n");
			return 1;
		}
	}


	//open file to log data
	FILE *file_handle =fopen(full_output_path,"w");
	if (file_handle == NULL){
    	return 1;
    }

 

  //pull peripherals out of reset
	sprintf(command_str, SET_PERIPHS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}

	// begin wall-clock timer
	sprintf(command_str, SEL_PERIPHS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}

		    //select tracking as metric
	 sprintf(command_str, TRACKING_SEL);
    if(proxy_string_command(pInst, command_str)){
		return 1;
	}
	//pull processor out of reset
	sprintf(command_str, SET_CPU);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}



	time0 = time(NULL); 						



	// check for completion of the main
	// --------------------------------------------------------------------------------------------------------------------------------------
	char rx_buffer[4];
	*(uint32_t *)rx_buffer = 0x00000000;

	// continuously check for application completion
	while(*(uint32_t *)rx_buffer != 0x00000001){

		// check if the tracker buffer is full
		sprintf(command_str, CHECK_IF_TRACKER_FULL); 		// switch to full flag register
		if(proxy_string_command(pInst, command_str)){
				return 1;
			}
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 		// read the full flag

		// if full then read out the contents of the buffer
		if (*(uint32_t *)rx_buffer == 0x00000001){

			// read contents and write to file
			printf("%s\n","Tracker buffer full, reading contents");
			tracker_read_buffer(pInst, TRACKER_BUFFER_CAPACITY,file_handle);

			// clear the buffer full flag
			sprintf(command_str, CLEAR_BUFFER); 	// writing this bit clears the buffer and full flag
			if(proxy_string_command(pInst, command_str)){
					return 1;
				}
			*(uint32_t *)rx_buffer = 0x00000000;
		}
		// else check to see if the application execution has finished
		else{
			protocol_read(pInst, rx_buffer, 4, TEST_DONE_ADDR); 	// read done flag
		}
	}

	// read out the remaining entries of the sampler buffer
	sprintf(command_str, "WRITE 0x04000110 0x00000010"); 		// switch to number of used entries
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 		// read the number of buffer entries
	tracker_read_buffer(pInst, *(uint32_t *)rx_buffer, file_handle);

	// report
	// --------------------------------------------------------------------------------------------------------------------------------------
	time1 = time(NULL);
	printf("Approx. Time-to-Execute: %lu seconds\n", time1-time0);

	// close the file
	fclose(file_handle);
	// report and exit without error
	return 0;
}
