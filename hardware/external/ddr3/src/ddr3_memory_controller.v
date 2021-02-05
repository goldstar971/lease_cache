///////////////////////////////////////////////////////////////////////////////
// Top level of DDR3 soft memory controller for Cyclone V GT                 //
// Contains an optional internal pattern generator/checker pair              //
//                                                                           //
// Created by Adam Taylor, Spring Semester 2020                              //
// Advised by Dr. Patru, RIT Faculty                                         //
//                                                                           //
// If using in test mode within a larger project, comment                    //
// out the lines under the following statement:                              //
//  "For standalone project only!"                                           //
// Also uncomment the two lines below them                                   //
// This should be around line 131 of this file                               //
///////////////////////////////////////////////////////////////////////////////

module ddr3_memory_controller #(
    parameter TEST_MODE = 1,
    parameter AWIDTH    = 25,
    parameter DWIDTH    = 32    
    )(
    
	// Interface to DDR3
	output      [13:0]       ddr3b_a,
	output      [2:0]        ddr3b_ba,
	output                   ddr3b_casn,
	output                   ddr3b_clk_n,
	output                   ddr3b_clk_p,
	output                   ddr3b_cke,
	output                   ddr3b_csn,
	output      [7:0]        ddr3b_dm,
	output                   ddr3b_odt,
	output                   ddr3b_rasn,
	output                   ddr3b_resetn,
	output                   ddr3b_wen,
    inout       [63:0]       ddr3b_dq,
	inout       [7:0]        ddr3b_dqs_n,
	inout       [7:0]        ddr3b_dqs_p,
    
	// User pins and LEDs
	output wire [3:0]        user_led,
    input                    clkin_r_p,        // for DDR3 soft memory controller, 100 MHz
    input                    cpu_resetn,       // Top level reset
    input                    rzqin_1_5v,        // on chip termination
    
    // Interface to RISC  
    input                   clock_ext_i,
    input                   req_i,
    input                   reqBlock_i,
    input                   rw_i,
    input       [26:0]      add_i,
    input       [31:0]      data_i,
    input                   clear_i,
    output                  ready_o,
    output                  done_o,
    output                  valid_o,
    output      [31:0]      data_o
    
);

// Internal wires and buses
	
wire         afi_clk;
wire         smc_clk;

wire         s0_ready;          
wire         s0_rdata_valid;  
wire [255:0] s0_rdata;   
wire         s0_burstbegin;     
wire [24:0]  s0_addr; 
wire [255:0] s0_wdata; 
wire         s0_read_req;
wire         s0_write_req;
wire [9:0]   s0_size;

// Unified bus between RISC input and internal test
wire         avl_ready;      
wire         avl_burstbegin;      
wire [24:0]  avl_addr;            
wire         avl_rdata_valid;    
wire [255:0] avl_rdata;          
wire [255:0] avl_wdata;      
wire         avl_read_req;    
wire         avl_write_req;   
wire [9:0]   avl_size; 

// Input bus to controller front end
wire         m0_ready;      
wire         m0_burstbegin;      
wire [24:0]  m0_addr;            
wire         m0_rdata_valid;    
wire [255:0] m0_rdata;          
wire [255:0] m0_wdata;      
wire         m0_read_req;    
wire         m0_write_req;   
wire [9:0]   m0_size; 

// Output bus from controller to DDR3
wire         ddr3_ready;      
wire         ddr3_burstbegin;      
wire [24:0]  ddr3_addr;            
wire         ddr3_rdata_valid;    
wire [255:0] ddr3_rdata;          
wire [255:0] ddr3_wdata;      
wire         ddr3_read_req;    
wire         ddr3_write_req;   
wire [9:0]   ddr3_size; 
       
wire         local_init_done;
wire         local_cal_success;
wire         local_cal_fail;
    
wire [3:0]   reset_int;

wire [15:0]  parallelterminationcontrol;
wire [15:0]  seriesterminationcontrol; 

wire         user_clk;


// Only generate hardware test if it is selected
generate 
    if (TEST_MODE) begin

        ///////////////////////////////////////////////////////////////////////////
        // For standalone project only!
        assign       test_mode = 1'b0;
        assign       user_clk = clock_ext_i;
        ///////////////////////////////////////////////////////////////////////////
        // For use in larger projects!
        //assign       test_mode = i_test_mode;
        //assign       user_clk = i_clk;
        ///////////////////////////////////////////////////////////////////////////

        // Test mode input bus
        wire         test_ready;      
        wire         test_burstbegin;      
        wire [24:0]  test_addr;            
        wire         test_rdata_valid;    
        wire [255:0] test_rdata;          
        wire [255:0] test_wdata;      
        wire         test_read_req;    
        wire         test_write_req;   
        wire [9:0]   test_size; 

        wire         test_fail;
        wire         test_mode;
        wire         test_pass;
        wire [31:0]  pass_cnt;
        wire [7:0]   failures;

        //assign user_led[0] = !pass_cnt[26];
        //assign user_led[1] = !pass_cnt[24];
        //assign user_led[2] = !pass_cnt[22];
        //assign user_led[3] = !pass_cnt[20];

        assign user_led[0] = !local_init_done;
        assign user_led[1] = !local_cal_success;
        assign user_led[2] = !test_fail;
        assign user_led[3] = !cpu_resetn; 

        assign test_ready       = avl_ready;
        assign s0_ready         = avl_ready;
        assign avl_burstbegin   = (!cpu_resetn) ? (1'b0  ) : ((test_mode) ? (test_burstbegin ) : (s0_burstbegin ));    
        assign avl_addr         = (!cpu_resetn) ? (25'h0 ) : ((test_mode) ? (test_addr       ) : (s0_addr       ));
        assign test_rdata_valid = avl_rdata_valid;
        assign s0_rdata_valid   = avl_rdata_valid;
        assign test_rdata       = avl_rdata;
        assign s0_rdata         = avl_rdata;
        assign avl_wdata        = (!cpu_resetn) ? (256'h0) : ((test_mode) ? (test_wdata      ) : (s0_wdata      ));
        assign avl_read_req     = (!cpu_resetn) ? (1'b0  ) : ((test_mode) ? (test_read_req   ) : (s0_read_req   ));
        assign avl_write_req    = (!cpu_resetn) ? (1'b0  ) : ((test_mode) ? (test_write_req  ) : (s0_write_req  ));
        assign avl_size         = (!cpu_resetn) ? (10'h0 ) : ((test_mode) ? (test_size       ) : (s0_size       ));
    end
    else begin

    	assign user_clk = clock_ext_i;
        assign user_led[0] = !local_init_done;
        assign user_led[1] = !local_cal_success;
        assign user_led[2] = 1'b1;
        assign user_led[3] = !cpu_resetn; 

        assign s0_ready         = avl_ready;
        assign avl_burstbegin   = (!cpu_resetn) ? (1'b0  ) : (s0_burstbegin );    
        assign avl_addr         = (!cpu_resetn) ? (25'h0 ) : (s0_addr       );
        assign s0_rdata_valid   = avl_rdata_valid;
        assign s0_rdata         = avl_rdata;
        assign avl_wdata        = (!cpu_resetn) ? (256'h0) : (s0_wdata      );
        assign avl_read_req     = (!cpu_resetn) ? (1'b0  ) : (s0_read_req   );
        assign avl_write_req    = (!cpu_resetn) ? (1'b0  ) : (s0_write_req  );
        assign avl_size         = (!cpu_resetn) ? (10'h0 ) : (s0_size       );
    end
endgenerate

// Probably does nothing but costs nothing to keep
// Holdout from the IP example project -adam's notes
issp issp (
    .probe          ({6'h0}         ),
    .source         (reset_int      )
);

clkctrl clkctrl_0(
    .inclk          (clkin_r_p      ),  
    .outclk         (smc_clk        ) 
);

// convert from non-standard comm protocol to Intel Avalon protocol
io_conversion_buffer_v2 #( .AWIDTH(24), .DWIDTH(DWIDTH) ) io_buf (
    
    // Interface to external ports
    .sys_clock_i    (clock_ext_i    ), 
    .sys_reset_i    (cpu_resetn     ), 
    .sys_req_i      (req_i          ), 
    .sys_reqBlock_i (reqBlock_i     ), 
    .sys_rw_i       (rw_i           ), 
    .sys_clear_i    (clear_i        ), 
    .sys_addr_i     (add_i[25:2]    ), 
    .sys_data_i     (data_i         ), 
    .sys_ready_o    (ready_o        ), 
    .sys_valid_o    (valid_o        ), 
    .sys_done_o     (done_o         ), 
    .sys_data_o     (data_o         ),
    
    // Interface to Controller 
    .s0_ready        (s0_ready      ),           
    .s0_rdata_valid  (s0_rdata_valid),   
    .s0_rdata        (s0_rdata      ),   
    .s0_burstbegin   (s0_burstbegin ),      
    .s0_addr         (s0_addr       ),  
    .s0_wdata        (s0_wdata      ),    
    .s0_read_req     (s0_read_req   ),
    .s0_write_req    (s0_write_req  ), 
    .s0_size         (s0_size       )
);


// Optional pattern generator creates pseudorandom write and read commands
generate if (TEST_MODE)
begin

    ddr3_pattern_gen test_patgen (
        // Outputs
        .avl_burstbegin    (test_burstbegin  ),
        .avl_addr          (test_addr        ),
        .avl_wdata         (test_wdata       ), 
        .avl_read_req      (test_read_req    ),
        .avl_write_req     (test_write_req   ),
        .avl_size          (test_size        ),
    
        // Inputs
        .risc_clk          (user_clk         ),
        .reset_n           (cpu_resetn       ),
    
        .avl_ready         (test_ready       ),
        .avl_rdata_valid   (test_rdata_valid ),
        .avl_rdata         (test_rdata       ),
        .local_init_done   (local_init_done  ),
        .local_cal_success (local_cal_success),
        
        .test_mode         (test_mode        ),
        .test_pass         (test_pass        ),
        .pass_cnt          (pass_cnt         )
    );

end
endgenerate

// Bridge from input clock domain to controller clock domain
altera_avalon_mm_clock_crossing_bridge mm_bridge (
	.s0_clk            (user_clk       ),
	.s0_reset_n        (cpu_resetn     ),
	        
	.m0_clk            (afi_clk        ),
	.m0_reset_n        (cpu_resetn     ),
	
	.s0_ready          (avl_ready      ), 
	.s0_readdata       (avl_rdata      ), 
	.s0_readdatavalid  (avl_rdata_valid), 
	.s0_burstcount     (avl_size       ), 
	.s0_writedata      (avl_wdata      ), 
	.s0_address        (avl_addr       ),  
	.s0_write          (avl_write_req  ),   
	.s0_read           (avl_read_req   ),
    .s0_burstbegin     (avl_burstbegin ),
                        
	.m0_ready          (m0_ready       ), 
	.m0_readdata       (m0_rdata       ), 
	.m0_readdatavalid  (m0_rdata_valid ), 
	.m0_burstcount     (m0_size        ), 
	.m0_writedata      (m0_wdata       ), 
	.m0_address        (m0_addr        ),  
	.m0_write          (m0_write_req   ),   
	.m0_read           (m0_read_req    ),
    .m0_burstbegin     (m0_burstbegin  ) 
);

// Front end controller
// Eliminates burstbegins from read requests, and groups block reads together
// In Signaltap, the second word of a read cannot be seen, but is transmitted
ddr3_cmd_intf controller (
    // RISC Interface
    .m0_burstcount      (m0_size         ),
    .m0_writedata       (m0_wdata        ),
    .m0_address         (m0_addr         ), 
    .m0_write           (m0_write_req    ),  
    .m0_read            (m0_read_req     ),  
    .m0_burstbegin      (m0_burstbegin   ),
    .m0_ready           (m0_ready        ),
    .m0_readdata        (m0_rdata        ),
    .m0_readdatavalid   (m0_rdata_valid  ),
   
    // DDR3 Interface
    .ddr3_burstcount    (ddr3_size       ),
    .ddr3_writedata     (ddr3_wdata      ),
    .ddr3_address       (ddr3_addr       ), 
    .ddr3_write         (ddr3_write_req  ),  
    .ddr3_read          (ddr3_read_req   ),  
    .ddr3_burstbegin    (ddr3_burstbegin ),
    .ddr3_ready         (ddr3_ready      ),
    .ddr3_readdata      (ddr3_rdata      ),
    .ddr3_readdatavalid (ddr3_rdata_valid),
    
    // Inputs
	.ddr3_clk           (afi_clk         ),
	.reset_n            (cpu_resetn      )
);

// On chip termination
altera_mem_if_oct_cyclonev #( .OCT_TERM_CONTROL_WIDTH (16) ) oct0 (
	.oct_rzqin                  (rzqin_1_5v                ),
	.seriesterminationcontrol   (seriesterminationcontrol  ),   
	.parallelterminationcontrol (parallelterminationcontrol)  
);

// IP Soft Memory Controller
q_sys_smc_0 smc_0 (
	.memory_mem_a               (ddr3b_a                   ),    
	.memory_mem_ba              (ddr3b_ba                  ),    
	.memory_mem_ck              (ddr3b_clk_p               ),    
	.memory_mem_ck_n            (ddr3b_clk_n               ),    
	.memory_mem_cke             (ddr3b_cke                 ),    
	.memory_mem_cs_n            (ddr3b_csn                 ),    
	.memory_mem_dm              (ddr3b_dm                  ),    
	.memory_mem_ras_n           (ddr3b_rasn                ),    
	.memory_mem_cas_n           (ddr3b_casn                ),    
	.memory_mem_we_n            (ddr3b_wen                 ),    
	.memory_mem_reset_n         (ddr3b_resetn              ),    
	.memory_mem_dq              (ddr3b_dq                  ),    
	.memory_mem_dqs             (ddr3b_dqs_p               ),    
	.memory_mem_dqs_n           (ddr3b_dqs_n               ),    
	.memory_mem_odt             (ddr3b_odt                 ),         
	.clk_100                    (smc_clk                   ),                        
                
    .avl_ready                  (ddr3_ready                ),        
    .avl_burstbegin             (ddr3_burstbegin           ),   
    .avl_addr                   (ddr3_addr                 ),         
    .avl_rdata_valid            (ddr3_rdata_valid          ),  
    .avl_rdata                  (ddr3_rdata                ),        
    .avl_wdata                  (ddr3_wdata                ),        
    .avl_read_req               (ddr3_read_req             ),     
    .avl_write_req              (ddr3_write_req            ),    
    .avl_size                   (ddr3_size                 ),         
    .local_init_done            (local_init_done           ),  
    .local_cal_success          (local_cal_success         ),
    .local_cal_fail             (local_cal_fail            ),   
	          
	.afi_clk                    (afi_clk                   ),
       
	.seriesterminationcontrol   (seriesterminationcontrol  ),  
	.parallelterminationcontrol (parallelterminationcontrol),                                         
	.reset_n                    (cpu_resetn & reset_int[3] )                                        
);

// Optional pattern checker
// Stores writes from pattern generator in internal RAM, and compares
// against read data. 
generate if (TEST_MODE)
begin

    ddr3_pattern_chk test_check (
        // Outputs 
        .test_fail          (test_fail        ),
        .test_pass          (test_pass        ),
        .pass_cnt           (pass_cnt         ),
        
        // Inputs
        .risc_clk           (user_clk         ),
        .reset_n            (cpu_resetn       ),
        
        .avl_burstbegin     (avl_burstbegin   ),
        .avl_addr           (avl_addr         ),
        .avl_wdata          (avl_wdata        ), 
        .avl_read_req       (avl_read_req     ),
        .avl_write_req      (avl_write_req    ),
        .avl_size           (avl_size         ),
        
        .avl_ready          (avl_ready        ),
        .avl_rdata_valid    (avl_rdata_valid  ),
        .avl_rdata          (avl_rdata        ),
        .local_init_done    (local_init_done  ),
        .local_cal_success  (local_cal_success)
    );

end
endgenerate

endmodule
