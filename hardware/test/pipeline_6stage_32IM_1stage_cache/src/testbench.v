`timescale 1 ns / 1 ns

module testbench;

// internal signals
// ----------------------------

// testbench controlled signals
reg 		hart_clock_reg;
reg 		hart_reset_reg;
wire 		flag_done;

// riscv core 
// ----------------------------
pipeline_test test_inst(

	// system
	.clock_i 		(hart_clock_reg 	),
	.reset_i 		(hart_reset_reg 	),
	.flag_done_o 	(flag_done 			)	
);


// testbench controller
// ----------------------------

// clock generation
always #10 hart_clock_reg = ~hart_clock_reg;


initial begin
	// reset hold
	hart_clock_reg = 1'b0;
	hart_reset_reg = 1'b0;
	#100;

	// pull out of reset and keep processing until finished signal
	// finished signal is a write to 0x04000104
	hart_reset_reg = 1'b1;

end

always begin
	#1 if (flag_done) #1000 $stop;
end

/*always begin
	#5000 $stop;
end*/

endmodule