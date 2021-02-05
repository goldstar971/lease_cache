
module ddr3_cmd_intf (
    // RISC (clock crossed) Interface
    input  [9:0]   m0_burstcount,
    input  [255:0] m0_writedata,
    input  [24:0]  m0_address, 
    input          m0_write,  
    input          m0_read,  
    input          m0_burstbegin,
    output         m0_ready,
    output [255:0] m0_readdata,
    output         m0_readdatavalid,
    
    // DDR3 Interface
    output [9:0]   ddr3_burstcount,
    output [255:0] ddr3_writedata,
    output [24:0]  ddr3_address, 
    output         ddr3_write,  
    output         ddr3_read,  
    output         ddr3_burstbegin,
    input          ddr3_ready,
    input  [255:0] ddr3_readdata,
    input          ddr3_readdatavalid,
    
    // Inputs
	input          ddr3_clk,
	input          reset_n
);

reg burst_begin;

wire       hold_read;
reg        hold_read_reg;
wire       hold_read_wire;
reg [24:0] delay_address; 
reg [9:0]  delay_burstcount;
wire       release_read;
reg        first_release;

wire ddr3_pass;
wire single;

// Only pass command to DDR3 at beginning of new burst
// Only automatically pass commands with burst size 1
// All commands require burst begin on RISC side, 
// only write command requires burst begin on DDR3 side
assign single    = (m0_burstcount == 10'h1); // This will have to change when stepping down commands to single words
assign ddr3_pass = m0_burstbegin && ddr3_ready && !burst_begin && single;

// Hold first half of burst read in order to send together
assign hold_read_wire = (m0_read && (m0_burstcount !== 10'h1));
assign hold_read = hold_read_wire || hold_read_reg;

assign release_read = (m0_read && (m0_burstcount == 10'h1) && hold_read_reg);

assign ddr3_writedata  = (ddr3_pass) ? (256'h0) : (m0_writedata );
assign ddr3_write      = (ddr3_pass) ? (1'b0  ) : (m0_write     );
assign ddr3_burstbegin = (ddr3_pass) ? (1'b0  ) : (m0_write     );

assign ddr3_burstcount = (ddr3_pass) ? (10'h0 ) : 
        ((hold_read) ? ((release_read) ? (delay_burstcount) : (10'h0)) : 
        (m0_burstcount));
assign ddr3_address    = (ddr3_pass) ? (25'h0 ) : 
        ((hold_read) ? ((release_read) ? (delay_address) : (25'h0)) : 
        (m0_address   ));
assign ddr3_read       = (ddr3_pass) ? (1'b0  ) : 
        ((hold_read) ? ((release_read) ? (1'h1) : (1'b0)) : 
        (m0_read      ));

// Backpressure clock bridge to delay new instructions
assign m0_ready         = ddr3_ready; 

// Always pass read response back
assign m0_readdata      = ddr3_readdata;
assign m0_readdatavalid = ddr3_readdatavalid;

// Impose read/write rules and cut off extended burst begins
always @(posedge ddr3_clk or negedge reset_n)
begin
    if (!reset_n)
    begin
        burst_begin <= 1'b0;
        hold_read_reg <= 1'b0;
        first_release <= 1'b1;
    end
    else
    begin
        if (m0_burstbegin && ddr3_ready && !burst_begin)
        begin
            burst_begin <= 1'b1;
            
        end
        else if (!m0_burstbegin)
        begin
            burst_begin <= 1'b0;
        end
        
        if (hold_read_wire && !hold_read_reg) // Need to delay first half of read
        begin
            hold_read_reg <= 1'b1;
            
            delay_address <= m0_address;
            delay_burstcount <= 10'h2;
        end
        else if (release_read && first_release) // First half
        begin
            delay_address <= m0_address;
            delay_burstcount <= 10'h1;
            first_release <= 1'b0;
        end
        else if (hold_read_reg && !first_release) // Second half
        begin
            first_release <= 1'b1;
            hold_read_reg <= 1'b0;
        end
    end
end

endmodule 