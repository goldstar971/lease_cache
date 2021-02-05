`timescale 1 ns / 1 ps

// dependencies
`include "/home/ian/Documents/school/thesis/include/riscv_lease.h"

`define ITERATIONS 50000
`define ADDRESS_LIMIT 2**(`bw_memW)
`define freq 50 		// freq in MHZ

module test();

// internal signals
// ---------------------------
reg 						reset_IN;			// reset active low
reg 	[`bw_memW-1:0] 		address_IN;			// address to r/w from
reg 						clock_IN;			// system clock
reg 	[`bw_word-1:0]		data_IN;			// data to be written to memory
reg 						wr_IN;				// wr = 1: write, else read
wire 	[`bw_word-1:0] 		data_OUT;			// data being read from memory
wire 						done_OUT;			// high when a valid transaction (0 if cache is writing to/from main memory)

integer nError;
integer nCorrect;
integer i;
reg [`bw_word-1:0]		temp_val;
reg [`bw_word-1:0] 		mem_check [0:2**(`bw_memW)];
integer 				timeMark;
integer 				firstTimeHit;
integer 				writeToOnly;
integer 				writeBackAlso;
reg [`bw_word-1:0] 		mem_check_active;	


// clock generation
always #10 clock_IN = ~clock_IN;
reg 	clock_core,
		clock_camUpdate,
		clock_cacheController,
		clock_busWrite,
		clock_busRead;

initial begin
	clock_core = 1'b0;
	#0;
	clock_core = 1'b1;
	while(1) begin
		#10 clock_core = ~clock_core;
	end
end
initial begin
	clock_camUpdate = 1'b0;
	#4;
	clock_camUpdate = 1'b1;
	while(1) begin
		#10 clock_camUpdate = ~clock_camUpdate;
	end
end
initial begin
	clock_cacheController = 1'b0;
	#8;
	clock_cacheController = 1'b1;
	while(1) begin
		#10 clock_cacheController = ~clock_cacheController;
	end
end
initial begin
	clock_busWrite = 1'b0;
	#12;
	clock_busWrite = 1'b1;
	while(1) begin
		#10 clock_busWrite = ~clock_busWrite;
	end
end
initial begin
	clock_busRead = 1'b0;
	#16;
	clock_busRead = 1'b1;
	while(1) begin
		#10 clock_busRead = ~clock_busRead;
	end
end


// hardware being verified
// ------------------------------------
cache_fa_random_2kB test (
	.reset_IN(reset_IN), 
	.clock_camUpdate(clock_camUpdate), 
	.clock_cacheController(clock_cacheController), 
	.clock_busWrite(clock_busWrite), 
	.clock_busRead(clock_busRead), 
	.address_IN(address_IN), 
	.data_IN(data_IN), 
	.rw_IN(wr_IN), 
	.data_OUT(data_OUT), 
	.done_OUT(done_OUT), 
	.writeto(), 
	.writeback(),
	.core_memReq()
);

// verification sequence
// -------------------------------------
initial begin
	// testbench params
	mem_check_active = 0;
	nError = 0;
	nCorrect = 0;
	firstTimeHit = 0;
	writeToOnly = 0;
	writeBackAlso = 0;
	for (i = 0; i < 2**(`bw_memW); i = i + 1) begin
		mem_check[i] = i[`bw_memW-1:0];
	end
	// start in reset condition
	clock_IN = 1'b1;
	reset_IN = 1'b0;
	address_IN = {(`bw_memW){1'b0}};
	data_IN = {(`bw_word){1'b0}};
	wr_IN = 1'b0;
	// block until PLL active
	repeat(5) @(posedge clock_IN);

	// come out of reset
	reset_IN = 1'b1;

	// testing sequence
	repeat(`ITERATIONS) begin
		timeMark = $time;
		address_IN = $urandom() % `ADDRESS_LIMIT;// generate random address between 0 and the limit
		wr_IN = $random();						// generate random r/w

		// if write operation then generate accomp. data
		if (wr_IN == 1'b1) begin
			temp_val = $random();
			mem_check[address_IN] = temp_val;
			data_IN = temp_val;
			mem_check_active = 32'hzzzzzzzz;
		end
		else begin 
			mem_check_active = mem_check[address_IN];
		end

		// block until complete
		@(posedge done_OUT);
		timeMark = $time - timeMark;
		if (timeMark < 200) firstTimeHit = firstTimeHit + 1'b1;
		else if ((timeMark >= 200) & (timeMark < 3400)) writeToOnly = writeToOnly + 1'b1;
		else if ((timeMark >= 3400) & (timeMark < 6800)) writeBackAlso = writeBackAlso + 1'b1;

		// check result
		// read operation
		if (wr_IN == 1'b0) begin
			if (data_OUT != mem_check[address_IN]) begin
				nError = nError + 1;
				$display("Error %t", $time);
			end
			else
				nCorrect = nCorrect + 1;
		end

		// block until system clock trigger - emulates processor req.
		@(posedge clock_IN);
	end

	// display simulation results
	$display("Total Iterations:\t%d", `ITERATIONS);
	$display("Hit - on Request:\t%d", firstTimeHit);
	$display("Miss - Writeto:\t%d", writeToOnly);
	$display("Miss - Writeback:\t%d", writeBackAlso);

	$display("Correct:\t%d", nCorrect);
	$display("Errors:\t%d", nError);
	$stop;
end

endmodule
