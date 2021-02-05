#ifndef _PROCESSOR_H_
#define _PROCESSOR_H_

#include <stdint.h>

// memory bases
// -------------------------------------------------------------------
#define BASE_RW_PERIPHERALS			((uint32_t) 0x04000100)
#define BASE_R_PERIPHERALS 			((uint32_t) 0x04000000)
#define BASE_STACK					((uint32_t) 0x03FFFFFC)

// memory mapped peripherals
// -------------------------------------------------------------------

// read and write
#define TIMER_CONTROL 				(BASE_RW_PERIPHERALS+0x00)
#define COMM_REGISTER0 				(BASE_RW_PERIPHERALS+0x04)
#define COMM_REGISTER1 				(BASE_RW_PERIPHERALS+0x08)
#define COMM_REGISTER2 				(BASE_RW_PERIPHERALS+0x0C)
#define COMM_CONTROL 				(BASE_RW_PERIPHERALS+0x10)
#define PHASE_REG 					(BASE_RW_PERIPHERALS+0x50)

// read only
#define TIMER0 						(BASE_R_PERIPHERALS+0x00)
#define TIMER1 						(BASE_R_PERIPHERALS+0x04)


// function calls
// -------------------------------------------------------------------
void benchmark_timer_start	(void);
void benchmark_timer_stop 	(void);
void benchmark_set_comm1 	(uint32_t);
void benchmark_set_comm2 	(uint32_t);
void set_phase 				(uint32_t);

#endif // _PROCESSOR_H_