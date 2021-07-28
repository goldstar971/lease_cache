#include "jtag_proxy.h"


pHandle proxy_connect(void){

	// connect to the port and return handle
	pHandle pInst = protocol_connect();

	// synchronize host (software) and client (hardware)
	
	if(protocol_synchronize(pInst, 15, 0)){
		
		return NULL;
	}
	else{
		return pInst;
	}
}

uint32_t proxy_terminal_command(pHandle pInst){

	// get input from terminal
	char pBuffer[TERMINAL_COMMAND_BUFFER_LENGTH];

	printf(">>");
	if(!fgets(pBuffer, TERMINAL_COMMAND_BUFFER_LENGTH, stdin)){
		return 1; 		// error reading terminal
	}
	// parse the terminal command
	// if parse returns '1' then command was not executed
	command command_inst; 

	if(parse_input(&command_inst, pBuffer)){
		return 1;
	}
		
	// execute the command on successfully parse command
	return proxy_execute(pInst, &command_inst);

}

uint32_t proxy_string_command(pHandle pInst, char *command_str){

	// use string command to populate command data structure
	command command_inst; 

	if(parse_input(&command_inst, command_str)){
		return 1;
	}

	// execute the command on successfully parse command
	return proxy_execute(pInst, &command_inst);

}

uint32_t proxy_execute(pHandle pInst, command *pCommand){

	// execute the command specified by the lookup table index (found during parsing)
	switch(pCommand->table_index){

		// CLOSE
		// --------------------------------------------------
		case 0:
		{
			return 2;
		}

		// READ (command line reads are single word)
		// --------------------------------------------------
		case 1:
		{
			char rx_buffer[BYTES_PER_WORD];
			if (protocol_read(pInst, rx_buffer, BYTES_PER_WORD, pCommand->field1_number)){
				return 1;
			}
			else{
				printf("0x%08x = %08x\n",pCommand->field1_number, *(uint32_t *)rx_buffer);
				return 0;
			}
		}

		// WRITE (command line writes are single word)
		// --------------------------------------------------
		case 2:
		{
			if (protocol_write(pInst, (char *)&pCommand->field2_number, BYTES_PER_WORD, pCommand->field1_number)){
				return 1;
			}
			else{
				//printf("Write successful\n");
				return 0;
			}
		}

		// LOAD (fpga_elf_dma extension command)
		// --------------------------------------------------
		case 3: return fpga_load_memory(pInst, pCommand);

		// VERIFY (fpga_elf_dma extension command)
		// --------------------------------------------------
		case 4: return fpga_verify_memory(pInst, pCommand);

		// CONFIG (legacy)
		// --------------------------------------------------
		case 5: return protocol_fpga_config(pInst, pCommand->field1_number, pCommand->field2_number);

		// RUN
		// --------------------------------------------------
		case 6: return test_run(pInst, pCommand);

		// SCRIPT
		// --------------------------------------------------
		case 7: return script_run(pInst, pCommand);

		// SAMPLE
		// --------------------------------------------------
		case 8: return sampler_run(pInst, pCommand);

		// TRACK
		// --------------------------------------------------
		case 9: return tracker_run(pInst, pCommand);

	}

	// if no match then return error
	return 1;

}
