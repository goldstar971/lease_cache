#include "sampler.h"
#include <time.h> 				// timers
#include <inttypes.h> 
#include <unistd.h> 			// sleep
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>



void get_file_name(char* application, char* dir, char * benchmark_name ){
	char unsplit[200];
	char parts[5][50];
	int counter=-1; //loop will increment 1 passed where we want

	strcpy(unsplit,application);
	char *ptr =strtok(unsplit,"/");
	do {
	    counter++;
	    strcpy(parts[counter],ptr);
	     ptr = strtok(NULL,"/");
	}while(ptr !=NULL);
	//if absolute path provided
    if(!strcmp(parts[counter],"program")){
        counter--;
    }
	sprintf(benchmark_name,"%s",parts[counter]);
		sprintf(dir,"%s",parts[counter-1]);
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



	#ifdef MULTI_LEVEL_CACHE
	for (uint32_t i = 0; i < 4*TRACKER_WORDS_PER_SAMPLE*buffer_packet_size; i = i + 4*TRACKER_WORDS_PER_SAMPLE){
		char temp_line[1664];
		sprintf(temp_line, "%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,\
			%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,\
			%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x\n",
								*(uint32_t *)(rx_buffer),
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
								*(uint32_t *)(rx_buffer+(i+60)),
								*(uint32_t *)(rx_buffer+(i+64)),
								*(uint32_t *)(rx_buffer+(i+68)),
								*(uint32_t *)(rx_buffer+(i+72)),
								*(uint32_t *)(rx_buffer+(i+76)),
								*(uint32_t *)(rx_buffer+(i+80)),
								*(uint32_t *)(rx_buffer+(i+84)),
								*(uint32_t *)(rx_buffer+(i+88)),
								*(uint32_t *)(rx_buffer+(i+92)),
								*(uint32_t *)(rx_buffer+(i+96)),
								*(uint32_t *)(rx_buffer+(i+100)),
								*(uint32_t *)(rx_buffer+(i+104)),
								*(uint32_t *)(rx_buffer+(i+108)),
								*(uint32_t *)(rx_buffer+(i+112)),
								*(uint32_t *)(rx_buffer+(i+116)),
								*(uint32_t *)(rx_buffer+(i+120)),
								*(uint32_t *)(rx_buffer+(i+124)),
								*(uint32_t *)(rx_buffer+(i+128)),
								*(uint32_t *)(rx_buffer+(i+132)),
								*(uint32_t *)(rx_buffer+(i+136)),
								*(uint32_t *)(rx_buffer+(i+140)),
								*(uint32_t *)(rx_buffer+(i+144)),
								*(uint32_t *)(rx_buffer+(i+148)),
								*(uint32_t *)(rx_buffer+(i+152)),
								*(uint32_t *)(rx_buffer+(i+156)),
								*(uint32_t *)(rx_buffer+(i+160)),
								*(uint32_t *)(rx_buffer+(i+164)),
								*(uint32_t *)(rx_buffer+(i+168)),
								*(uint32_t *)(rx_buffer+(i+172)),
								*(uint32_t *)(rx_buffer+(i+176)),
								*(uint32_t *)(rx_buffer+(i+180)),
								*(uint32_t *)(rx_buffer+(i+184)),
								*(uint32_t *)(rx_buffer+(i+188)),
								*(uint32_t *)(rx_buffer+(i+192)),
								*(uint32_t *)(rx_buffer+(i+196)),
								*(uint32_t *)(rx_buffer+(i+200)),
								*(uint32_t *)(rx_buffer+(i+204)));


		fprintf(file_handle, "%s", temp_line);
	}

	#else
	// write data to file
	for (uint32_t i = 0; i < 4*TRACKER_WORDS_PER_SAMPLE*buffer_packet_size; i = i + 4*TRACKER_WORDS_PER_SAMPLE){
		char temp_line[512];
		sprintf(temp_line, "%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x,%08x\n",
								*(uint32_t *)(rx_buffer),
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
	#endif

	return 0;
}


uint32_t sampler_run(pHandle pInst, command *pCommand){
	// temporaries
	time_t time0, time1;
	char command_str[300];

	char file_path[512];
	char benchmark_type[50];
	char benchmark_name[50];
	char full_output_path[570]; 
	char application[256];

	strcpy(application,pCommand->field[1]);
	//get benchmark type and benchmark name
	get_file_name(application,benchmark_type,benchmark_name);
	
	//if we aren't given the relative or absolute path try an assemble using benchmark directory
	if(access(application,F_OK)!=0){
		sprintf(application,"%s/%s/%s/program.elf",BENCHMARK_DIR,benchmark_type,benchmark_name);
		
	}

	//check if sampling rate allowed
	if(pCommand->field2_number>2048){
		printf("sample rate selected must be less than 2048!\n");
		return 1;
	}


	if(access(application,F_OK)!=0){
		printf("Could not find provided application file: %s. \
Attempt to find alternative %s failed.\n  \
Provide either the absolute or relative path or just policy and benchmark name: \
e.g CLAM_large/adi\n If following these instructions \
fails, check to see that BENCHMARK_DIRECTORY has been defined correctly in the\
proxy makefile",pCommand->field[1],application);
		return 1;
	}
		//now that existence has been checked, remove the file extension, otherwise it will cause problems
	application[strlen(application)-4]='\0';

	
//applications sometimes fail to load to the FPGA, loop until the program written has been sucessfully 
	
	int tries=0;
	do {
		//if more than ten tries, terminate.
		if(tries>9){
			return 1;
		}
// give comms system permission to r/w main memory.
		sprintf(command_str, SET_MM_ACCESS_COMMS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
	sleep(.1);
	sprintf(command_str, RESET);

	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
		sleep(.1);
		// load fpga memory with target application
	sprintf(command_str, "LOAD %s\r",application);
		if(proxy_string_command(pInst, command_str)==2){
			return 1;
		}
		sleep(.1);
	sprintf(command_str, "VERIFY %s\r",application);
	tries++;
	}while(proxy_string_command(pInst, command_str));


	
	//create full path
	#ifdef MULTI_LEVEL_CACHE
		sprintf(file_path,"%s/sample/%s_multi_level/",RESULT_DIR,benchmark_type);
	#else
		sprintf(file_path,"%s/sample/%s/",RESULT_DIR,benchmark_type);
	#endif
	
	//if directories don't exist, try to create them.
	for(int i=0;i<3;i++){
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
		char path_extension [30];
		//create directory for rate
		if (i==0){
			sprintf(path_extension,"rate_%d/",pCommand->field2_number);
			strcat(file_path,path_extension);
		}
		//create directory for seed
		else if (i==1){
			sprintf(path_extension,"seed_%d/",pCommand->field3_number);
			strcat(file_path,path_extension);
		}
		
	}
	sprintf(full_output_path,"%s%s.txt",file_path,benchmark_name);
	
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

	// give CPU permission to r/w main memory.
		sprintf(command_str, SET_MM_ACCESS_CPU);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}

	int seed_value;
	//seed random number generator with provided or default seed
	srand(pCommand->field3_number);
	seed_value=rand()%4096;
	
	    //select sampling as metric and give sampling rate
	 sprintf(command_str,"WRITE 0x20000088, 0x%08x",1|(pCommand->field2_number<<2)|(seed_value<<14));
	
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
		#ifdef MULTI_LEVEL_CACHE
			protocol_read(pInst, rx_buffer, 4, CACHE_L2_ADDR); 
		#else
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 
		#endif	
			// read the full flag

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
	sprintf(command_str, GET_NUM_BUFFER_ENTRIES_SAMPLER); 		// switch to number of buffer entries register
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
			#ifdef MULTI_LEVEL_CACHE
			protocol_read(pInst, rx_buffer, 4, CACHE_L2_ADDR); 
		#else
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 
		#endif	
	printf("%s%x\n","Num_entries==",*(uint32_t *)rx_buffer);

	sampler_read_buffer(pInst, *(uint32_t *)rx_buffer,file_handle);

	// read out the remaining entries of the sampler lookup table
	// it takes 64 cycles to dump the table; takes longer in software here to transition so no external delay necessary - allegedly (Ian)
	sprintf(command_str, CLEAR_BUFFER); 	// writing this bit clears the buffer and full flag
	proxy_string_command(pInst, command_str);
	sprintf(command_str, WRITEOUT_TABLE);	// command sampler to writeout table contents to buffer
	proxy_string_command(pInst, command_str);
	sleep(1); 												// make sure table has time to writeout entries to buffer
	sprintf(command_str, GET_NUM_BUFFER_ENTRIES_SAMPLER); 	// switch to number of buffer(table) entries register
	
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
		#ifdef MULTI_LEVEL_CACHE
			protocol_read(pInst, rx_buffer, 4, CACHE_L2_ADDR); 
		#else
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 
		#endif	 	// read the number of buffer(table) entries
	printf("%s%x\n","Num_entries==",*(uint32_t *)rx_buffer);
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
	char command_str[300];
	char file_path[200]; 
	
	char benchmark_type[50];
	char benchmark_name[50];
	char full_output_path[256]; 
	char application[256];

	
	
	strcpy(application,pCommand->field[1]);
	//get benchmark type and benchmark name
	get_file_name(application,benchmark_type,benchmark_name);

	//if we aren't given the relative or absolute path try an assemble using benchmark directory
	if(access(application,F_OK)!=0){
		sprintf(application,"%s/%s/%s/program.elf",BENCHMARK_DIR,benchmark_type,benchmark_name);
	}
	if(access(application,F_OK)!=0){
		printf("Could not find provided application file: %s. \
Attempt to find alternative %s failed.\n  \
Provide either the absolute or relative path or just policy and benchmark name: \
e.g CLAM_large/adi\n If following these instructions \
fails, check to see that BENCHMARK_DIRECTORY has been defined correctly in the\
proxy makefile",pCommand->field[1],application);
		return 1;
	}
	//now that existence has been checked, remove the file extension, otherwise it will cause problems
	application[strlen(application)-4]='\0';
	int tries=0;
	do {
		//if more than ten tries, terminate.
		if(tries>9){
			return 1;
		}
		// give comms system permission to r/w main memory.
		sprintf(command_str, SET_MM_ACCESS_COMMS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
	sleep(.1);
	sprintf(command_str, RESET);

	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
		sleep(.1);
		// load fpga memory with target application
	sprintf(command_str, "LOAD %s\r",application);
		if(proxy_string_command(pInst, command_str)==2){
			return 1;
		}
		sleep(.1);
	sprintf(command_str, "VERIFY %s\r",application);
	tries++;
	}while(proxy_string_command(pInst, command_str));


	//create full path
	#ifdef MULTI_LEVEL_CACHE
		sprintf(file_path,"%s/track/%s_multi_level/",RESULT_DIR,benchmark_type);
	#else
		sprintf(file_path,"%s/track/%s/",RESULT_DIR,benchmark_type);
	#endif
	sprintf(full_output_path,"%s%s.csv",file_path,benchmark_name);
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

	//give CPU permission to r/w main memory
	sprintf(command_str, SET_MM_ACCESS_CPU);
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	
		    //select tracking as metric
	 sprintf(command_str,"WRITE 0x20000088, 0x%08x",2|(pCommand->field2_number<<2));
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
		#ifdef MULTI_LEVEL_CACHE
			sprintf(command_str, CHECK_IF_TRACKER_FULL_L2); 		// switch to full flag register
		#else
		sprintf(command_str, CHECK_IF_TRACKER_FULL); 		// switch to full flag register
		#endif
		if(proxy_string_command(pInst, command_str)){
				return 1;
			}
		#ifdef MULTI_LEVEL_CACHE
			protocol_read(pInst, rx_buffer, 4, CACHE_L2_ADDR); 
		#else
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 
		#endif	 		// read the full flag

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
	// read out the remaining entries of the tracker buffer
	#ifdef MULTI_LEVEL_CACHE
			sprintf(command_str, GET_NUM_BUFFER_ENTRIES_TRACKER_L2); 		// switch to number of used entries
	#else
			sprintf(command_str, GET_NUM_BUFFER_ENTRIES_TRACKER); 		// switch to number of used entries
	#endif	 	
	
	
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
		#ifdef MULTI_LEVEL_CACHE
			protocol_read(pInst, rx_buffer, 4, CACHE_L2_ADDR); 
		#else
		protocol_read(pInst, rx_buffer, 4, CACHE_L1D_ADDR); 
		#endif	 		// read the number of buffer entries
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
