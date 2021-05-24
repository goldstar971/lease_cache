#include "riscv.h"

unsigned int volatile * const pCommReg0 = 		(unsigned int *) COMM_REGISTER0;
unsigned int volatile * const pCommReg1 = 		(unsigned int *) COMM_REGISTER1;
unsigned int volatile * const pCommReg2 = 		(unsigned int *) COMM_REGISTER2;
unsigned int volatile * const pTimer0 = 		(unsigned int *) TIMER0;
unsigned int volatile * const pTimerControl = 	(unsigned int *) TIMER_CONTROL;
unsigned int volatile * const pCommControl = 	(unsigned int *) COMM_CONTROL;	
unsigned int volatile * const pPhaseReg = 		(unsigned int *) PHASE_REG;

void benchmark_timer_start(void){
	*pTimerControl = 0x00000001;      	// enable generic timer 0
  	*pCommControl = 0x00000001;			// enable cache benchmarking timers
  	*pCommReg0 = 0; 					// used to signal to comm terminal that testing is in process
};

void benchmark_timer_stop(void){
	*pTimerControl = 0x00000000;    	// disable generic timer
	*pCommControl = 0x00000000;         // disable cache benchmarking timers
  	*pCommReg0 = 1; 					// used to signal to comm terminal that testing is complete
};

void benchmark_set_comm1(uint32_t _val1){
	*pCommReg1 = _val1;
};

void benchmark_set_comm2(uint32_t _val2){
	*pCommReg2 = _val2;
};

void set_phase(uint32_t _phase){
	*pPhaseReg = _phase;
};
