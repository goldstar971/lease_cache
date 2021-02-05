// $File: //acds/rel/18.1std/ip/sopc/components/altera_avalon_dc_fifo/altera_avalon_dc_fifo.v $
// $Revision: #1 $
// $Date: 2018/07/18 $
// $Author: psgswbuild $
//-------------------------------------------------------------------------------
// Description: Dual clocked single channel FIFO with fill levels and status
// information.
// ---------------------------------------------------------------------

`timescale 1 ns / 100 ps

//altera message_off 10036 10858 10230 10030 10034
module altera_avalon_dc_fifo(
    
    in_clk,
    in_reset_n,

    out_clk,
    out_reset_n,

    // sink
    in_data,
    in_valid,
    in_ready,

    // source
    out_data,
    out_valid,
    out_ready,

    // streaming in status
    almost_full_valid,
    almost_full_data,

    // streaming out status
    almost_empty_valid,
    almost_empty_data,

    // (internal, experimental interface) space available st source
    space_avail_data

);

    // ---------------------------------------------------------------------
    // Parameters
    // ---------------------------------------------------------------------
    parameter SYMBOLS_PER_BEAT  = 1;
    parameter BITS_PER_SYMBOL   = 8;
    parameter FIFO_DEPTH        = 16;
    parameter CHANNEL_WIDTH     = 0;
    parameter ERROR_WIDTH       = 0;
    parameter USE_PACKETS       = 0;

    parameter USE_IN_FILL_LEVEL   = 0;
    parameter USE_OUT_FILL_LEVEL  = 0;
    parameter WR_SYNC_DEPTH       = 2;
    parameter RD_SYNC_DEPTH       = 2;
    parameter STREAM_ALMOST_FULL  = 0;
    parameter STREAM_ALMOST_EMPTY = 0;

    parameter BACKPRESSURE_DURING_RESET = 0;

    // optimizations
    parameter LOOKAHEAD_POINTERS  = 0;
    parameter PIPELINE_POINTERS   = 0;

    // experimental, internal parameter
    parameter USE_SPACE_AVAIL_IF  = 0;

    localparam ADDR_WIDTH   = log2ceil(FIFO_DEPTH);
    localparam DEPTH        = 2 ** ADDR_WIDTH;
    localparam DATA_WIDTH   = SYMBOLS_PER_BEAT * BITS_PER_SYMBOL;
    localparam EMPTY_WIDTH  = log2ceil(SYMBOLS_PER_BEAT);
    localparam PACKET_SIGNALS_WIDTH = 2 + EMPTY_WIDTH;
    localparam PAYLOAD_WIDTH        = (USE_PACKETS == 1) ?
                                          DATA_WIDTH + ERROR_WIDTH + CHANNEL_WIDTH:
                                          DATA_WIDTH + ERROR_WIDTH + CHANNEL_WIDTH;

    // ---------------------------------------------------------------------
    // Input/Output Signals
    // ---------------------------------------------------------------------
    input in_clk;
    input in_reset_n;

    input out_clk;
    input out_reset_n;

    input [DATA_WIDTH - 1 : 0] in_data;
    input in_valid;
    output in_ready;

    output [DATA_WIDTH - 1 : 0] out_data;
    output reg out_valid;
    input out_ready;

    output reg almost_full_valid;
    output reg almost_full_data;
    output reg almost_empty_valid;
    output reg almost_empty_data;

    output [ADDR_WIDTH : 0] space_avail_data; 

    // ---------------------------------------------------------------------
    // Memory Pointers
    // ---------------------------------------------------------------------
    (* ramstyle="no_rw_check" *) reg [PAYLOAD_WIDTH - 1 : 0] mem [DEPTH - 1 : 0];
    
    wire [ADDR_WIDTH - 1 : 0] mem_wr_ptr;
    wire [ADDR_WIDTH - 1 : 0] mem_rd_ptr;

    reg [ADDR_WIDTH : 0] in_wr_ptr;
    reg [ADDR_WIDTH : 0] in_wr_ptr_lookahead;
    reg [ADDR_WIDTH : 0] out_rd_ptr;
    reg [ADDR_WIDTH : 0] out_rd_ptr_lookahead;
    
    // ---------------------------------------------------------------------
    // Internal Signals
    // ---------------------------------------------------------------------
    wire [ADDR_WIDTH : 0] next_out_wr_ptr;
    wire [ADDR_WIDTH : 0] next_in_wr_ptr;
    wire [ADDR_WIDTH : 0] next_out_rd_ptr;
    wire [ADDR_WIDTH : 0] next_in_rd_ptr;

    reg  [ADDR_WIDTH : 0] in_wr_ptr_gray     /*synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=D102" */;
    wire [ADDR_WIDTH : 0] out_wr_ptr_gray;    

    reg  [ADDR_WIDTH : 0] out_rd_ptr_gray    /*synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=D102" */;
    wire [ADDR_WIDTH : 0] in_rd_ptr_gray;

    reg  [ADDR_WIDTH : 0] out_wr_ptr_gray_reg;
    reg  [ADDR_WIDTH : 0] in_rd_ptr_gray_reg;

    reg full;
    reg empty;

    wire [PAYLOAD_WIDTH - 1 : 0] in_payload;
    reg  [PAYLOAD_WIDTH - 1 : 0] out_payload;
    reg  [PAYLOAD_WIDTH - 1 : 0] internal_out_payload;

    wire internal_out_ready;
    wire internal_out_valid;

    wire [ADDR_WIDTH : 0] out_fill_level;
    reg  [ADDR_WIDTH : 0] out_fifo_fill_level;
    reg  [ADDR_WIDTH : 0] in_fill_level;
    reg  [ADDR_WIDTH : 0] in_space_avail;

    reg [23 : 0] almost_empty_threshold;
    reg [23 : 0] almost_full_threshold;

    reg          sink_in_reset;
    
    // --------------------------------------------------
    // Define Payload
    //
    // Icky part where we decide which signals form the
    // payload to the FIFO.
    // --------------------------------------------------

    assign in_payload = in_data;
    assign out_data = out_payload;

    // ---------------------------------------------------------------------
    // Memory
    //
    // Infers a simple dual clock memory with unregistered outputs
    // ---------------------------------------------------------------------
    
    always @(posedge in_clk) begin
        if (in_valid && in_ready)
            mem[mem_wr_ptr] <= in_payload;
    end

    always @(posedge out_clk or negedge out_reset_n) 
    begin
        if (!out_reset_n)
        begin
            internal_out_payload <= 0;
        end
        else
        begin
            internal_out_payload <= mem[mem_rd_ptr];
        end
    end

    assign mem_rd_ptr = next_out_rd_ptr;
    assign mem_wr_ptr = in_wr_ptr;

    // ---------------------------------------------------------------------
    // Pointer Management
    //
    // Increment our good old read and write pointers on their native
    // clock domains.
    // ---------------------------------------------------------------------
    
    always @(posedge in_clk or negedge in_reset_n) begin
        if (!in_reset_n) begin
            in_wr_ptr           <= 0;
        end
        else begin
            in_wr_ptr           <= next_in_wr_ptr;
        end
    end

    always @(posedge out_clk or negedge out_reset_n) begin
        if (!out_reset_n) begin
            out_rd_ptr           <= 0;
        end
        else begin
            out_rd_ptr           <= next_out_rd_ptr;
        end
    end

    assign next_in_wr_ptr = (in_ready && in_valid) ? in_wr_ptr + 1'b1 : in_wr_ptr;
    assign next_out_rd_ptr = (internal_out_ready && internal_out_valid) ? out_rd_ptr + 1'b1 : out_rd_ptr;

    // ---------------------------------------------------------------------
    // Empty/Full Signal Generation
    //
    // We keep read and write pointers that are one bit wider than
    // required, and use that additional bit to figure out if we're
    // full or empty.
    // ---------------------------------------------------------------------
    always @(posedge out_clk or negedge out_reset_n) begin
        if(!out_reset_n)
            empty <= 1;
        else
            empty <= (next_out_rd_ptr == next_out_wr_ptr);
    end

    always @(posedge in_clk or negedge in_reset_n) begin
        if (!in_reset_n) begin
            full <= 0;
            sink_in_reset <= 1'b1;
        end
        else begin
            full <= (next_in_rd_ptr == next_in_wr_ptr) && (next_in_rd_ptr[ADDR_WIDTH] != next_in_wr_ptr[ADDR_WIDTH]);
            sink_in_reset <= 1'b0;
        end
    end

    // ---------------------------------------------------------------------
    // Write Pointer Clock Crossing
    //
    // Clock crossing is done with gray encoding of the pointers. What? You
    // want to know more? We ensure a one bit change at sampling time,
    // and then metastable harden the sampled gray pointer.
    // ---------------------------------------------------------------------
    
    always @(posedge in_clk or negedge in_reset_n) begin
        if (!in_reset_n)
            in_wr_ptr_gray <= 0;
        else
            in_wr_ptr_gray <= bin2gray(in_wr_ptr);
    end

    altera_dcfifo_synchronizer_bundle #(.WIDTH(ADDR_WIDTH+1), .DEPTH(WR_SYNC_DEPTH)) 
      write_crosser (
        .clk(out_clk),
        .reset_n(out_reset_n),
        .din(in_wr_ptr_gray),
        .dout(out_wr_ptr_gray)
    );

    // ---------------------------------------------------------------------
    // Optionally pipeline the gray to binary conversion for the write pointer. 
    // Doing this will increase the latency of the FIFO, but increase fmax.
    // ---------------------------------------------------------------------

    assign next_out_wr_ptr = gray2bin(out_wr_ptr_gray);

    // ---------------------------------------------------------------------
    // Read Pointer Clock Crossing
    //
    // Go the other way, go the other way...
    // ---------------------------------------------------------------------
    
    always @(posedge out_clk or negedge out_reset_n) begin
        if (!out_reset_n)
            out_rd_ptr_gray <= 0;
        else
            out_rd_ptr_gray <= bin2gray(out_rd_ptr);
    end

    altera_dcfifo_synchronizer_bundle #(.WIDTH(ADDR_WIDTH+1), .DEPTH(RD_SYNC_DEPTH)) 
      read_crosser (
        .clk(in_clk),
        .reset_n(in_reset_n),
        .din(out_rd_ptr_gray),
        .dout(in_rd_ptr_gray)
    );

    // ---------------------------------------------------------------------
    // Optionally pipeline the gray to binary conversion of the read pointer. 
    // Doing this will increase the pessimism of the FIFO, but increase fmax.
    // ---------------------------------------------------------------------
    
    assign next_in_rd_ptr = gray2bin(in_rd_ptr_gray);

    // ---------------------------------------------------------------------
    // Avalon ST Signals
    // ---------------------------------------------------------------------
    
    assign in_ready = BACKPRESSURE_DURING_RESET ? !(full || sink_in_reset) : !full;
    assign internal_out_valid = !empty;

    // --------------------------------------------------
    // Output Pipeline Stage
    //
    // We do this on the single clock FIFO to keep fmax
    // up because the memory outputs are kind of slow.
    // Therefore, this stage is even more critical on a dual clock
    // FIFO, wouldn't you say? No one wants a slow dcfifo.
    // --------------------------------------------------
    
    assign internal_out_ready = out_ready || !out_valid;

    always @(posedge out_clk or negedge out_reset_n) begin
        if (!out_reset_n) begin
            out_valid   <= 0;
            out_payload <= 0;
        end
        else begin
            if (internal_out_ready) begin
                out_valid   <= internal_out_valid;
                out_payload <= internal_out_payload;
            end
        end
    end
    
    // ---------------------------------------------------------------------
    // In Fill Level & In Status Connection Point
    //
    // Note that the input fill level does not account for the output
    // stage i.e it is only the fifo fill level.
    //
    // Is this a problem? No, because the input fill is usually used to 
    // see how much data can still be pushed into this FIFO. The FIFO
    // fill level gives exactly this information, and there's no need to
    // make our lives more difficult by including the output stage here.
    // 
    // One might ask: why not just report a space available level on the
    // input side? Well, I'd like to make this FIFO be as similar as possible
    // to its single clock cousin, and that uses fill levels and 
    // fill thresholds with nary a mention of space available.
    // ---------------------------------------------------------------------


    always @(posedge in_clk or negedge in_reset_n) begin
        if (!in_reset_n) begin
            in_space_avail <= FIFO_DEPTH;
        end
        else begin
            // -------------------------------------
            // space = DEPTH-fill = DEPTH-(wr-rd) = DEPTH+rd-wr
            // Conveniently, DEPTH requires the same number of bits
            // as the pointers, e.g. a dcfifo with depth = 8
            // requires 4-bit pointers.
            //
            // Adding 8 to a 4-bit pointer is simply negating the
            // first bit... as is done below.
            // -------------------------------------

            in_space_avail <= {~next_in_rd_ptr[ADDR_WIDTH], 
                                next_in_rd_ptr[ADDR_WIDTH-1:0]} -
                              next_in_wr_ptr;
        end
    end
    assign space_avail_data = in_space_avail;

    // ---------------------------------------------------------------------
    // Gray Functions
    // 
    // These are real beasts when you look at them. But they'll be
    // tested thoroughly.
    // ---------------------------------------------------------------------
    
    function [ADDR_WIDTH : 0] bin2gray;
        input [ADDR_WIDTH : 0]  bin_val;
        integer i; 
                
        for (i = 0; i <= ADDR_WIDTH; i = i + 1)
        begin
            if (i == ADDR_WIDTH)
                bin2gray[i] = bin_val[i];
            else
                bin2gray[i] = bin_val[i+1] ^ bin_val[i];
        end
    endfunction

    function [ADDR_WIDTH : 0] gray2bin;
        input [ADDR_WIDTH : 0]  gray_val;
        integer i;
        integer j;
                
        for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin
            
            gray2bin[i] = gray_val[i];

            for (j = ADDR_WIDTH; j > i; j = j - 1) begin
                gray2bin[i] = gray2bin[i] ^ gray_val[j];	
            end

        end
    endfunction

    // --------------------------------------------------
    // Calculates the log2ceil of the input value
    // --------------------------------------------------
    function integer log2ceil;
        input integer val;
        integer i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule
