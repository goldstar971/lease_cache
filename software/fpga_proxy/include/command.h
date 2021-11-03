#ifndef _COMMAND_H_
#define _COMMAND_H_

#include <stdint.h>

#define N_FIELDS 				4
#define FIELD_LENGTH 			100

// command delimiters
#define COMMAND_DELIMITERS 		" \t\r\n"

// lookup table for command
// LOAD & VERIFY are from fpga_elf.h
static const char *pCodes[] 	= {"CLOSE", "READ", "WRITE","LOAD", "VERIFY",	"CONFIG", 	"RUN",	"SCRIPT", 	"TRACK", 	"SAMPLE" };
static const char n_fields[] 	= {1, 		2, 		3, 		2, 		2, 			3,  		2, 		2,			3, 			4 		};
static const bool field1_hex[] 	= {false, 	true, 	true, 	false, 	false, 		true, 		false, 	false,	 	false, 		false	}; 
static const bool field2_hex[] 	= {false, 	false, 	true, 	false, 	false,	 	true, 		false, 	false, 		true, 	 	true	};
static const bool field3_hex[]  = {false, 	false, 	false, 	false, 	false, 		false, 		false, 	false,	 	false, 		true	}; 


typedef struct command{
	char 		table_index; 						// lookup table match index
	char 		n_fields; 							// number of fields extracted from parse
	char 		field[N_FIELDS][FIELD_LENGTH]; 		// parsed fields as strings
	uint32_t 	field1_number; 						// field0 converted to number
	uint32_t 	field2_number; 						// field1 converted to number
	uint32_t    field3_number;                      // field3 converted to number
} command;


uint32_t 		parse_input(command *pCommand, char *pBuffer);
// description: 	- blocking
// 					- parse and error check the command
// return: 			0: success, 1: fail
// pCommand: 		command data structure to populate
// pBuffer: 		command string to parse

#endif