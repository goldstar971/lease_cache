`ifndef _MEMORY_PROTOCOL_CONVERSION_BUFFER_V_
`define _MEMORY_PROTOCOL_CONVERSION_BUFFER_V_

module memory_protocol_conversion_buffer #( 
    parameter N_BUFFER_ENTRIES  = 0,
    parameter BW_COMMAND        = 0,
    parameter BW_ADDRESS        = 0,
    parameter BW_DATA           = 0, 
    parameter BW_BUFFER_ENTRIES = `CLOG2(N_BUFFER_ENTRIES)
)(
    // general
    input                       sys_clock_i,
    input                       sys_clock_buffer_i,
    input                       sys_resetn_i,

    // incoming dma controller signals
    input                       sys_write_i,         
    input   [BW_COMMAND-1:0]    sys_command_i,
    input   [BW_ADDRESS-1:0]    sys_address_i,
    input   [BW_DATA-1:0]       sys_data_i,
    output                      sys_full_o,
    // outgoing dma controller signals
    output                      sys_write_o,
    output  [BW_COMMAND-1:0]    sys_command_o,
    output  [BW_ADDRESS-1:0]    sys_address_o,
    output  [BW_DATA-1:0]       sys_data_o,
    input                       sys_full_i, 

    // interface to avalon DDR3 controller hardware subsystem 
    input                       s0_ready,           
    input                       s0_rdata_valid,   
    input       [255:0]         s0_rdata,   
    output wire                 s0_burstbegin,      
    output wire [24:0]          s0_addr,  
    output wire [255:0]         s0_wdata,    
    output wire                 s0_read_req,
    output wire                 s0_write_req, 
    output wire [9:0]           s0_size
);


// parameterizations
// ----------------------------------------------------------------------------------------------------------
localparam ST_IDLE                  = 3'b000;
localparam ST_DDR3_WORD_READIN      = 3'b001;
localparam ST_DDR3_BLOCK_READIN     = 3'b010;
localparam ST_DDR3_WORD_WRITEOUT    = 3'b011;
localparam ST_DDR3_WORD_WRITEOUT    = 3'b100;
localparam ST_SYS_WRITE_TO_BUFFER   = 3'b101;


// incoming dma buffer
// ----------------------------------------------------------------------------------------------------------
reg                     buffer_read_reg;
wire                    buffer_empty_flag;
wire [BW_COMMAND-1:0]   buffer_command_bus;
wire [BW_ADDRESS-1:0]   buffer_address_bus;
wire [BW_DATA-1:0]      buffer_data_bus;

command_buffer #(
    .N_ENTRIES      (N_BUFFER_ENTRIES           ),
    .BW_COMMAND     (BW_COMMAND                 ),
    .BW_ADDRESS     (BW_ADDRESS                 ),
    .BW_DATA        (BW_DATA                    ) 
) dma_command_buffer (
    .clock_i        (sys_clock_buffer_i         ),
    .resetn_i       (sys_resetn_i               ),
    .write_i        (sys_write_i                ),      // command write in
    .command_i      (sys_command_i              ),
    .addr_i         (sys_address_i              ),
    .data_i         (sys_data_i                 ),
    .full_o         (sys_full_o                 ),
    .read_i         (buffer_read_reg            ),      // command read out
    .empty_o        (buffer_empty_flag          ),
    .command_o      (buffer_command_bus         ),
    .addr_o         (buffer_address_bus         ),
    .data_o         (buffer_data_bus            )
);


// port mappings
// ----------------------------------------------------------------------------------------------------------
reg                      sys_write_reg;
reg  [BW_COMMAND-1:0]    sys_command_reg;
reg  [BW_ADDRESS-1:0]    sys_address_reg;
reg  [BW_DATA-1:0]       sys_data_reg;

assign sys_write_o      = sys_write_reg;
assign sys_command_o    = sys_command_reg;
assign sys_address_o    = sys_address_reg;
assign sys_data_o       = sys_data_reg;

reg                     s0_burstbegin_reg, 
                        s0_read_req_reg, 
                        s0_write_req_reg;
reg [24:0]              s0_addr_reg;
reg [255:0]             s0_wdata_reg;
reg [9:0]               s0_size_reg;

assign s0_burstbegin    = s0_burstbegin_reg;
assign s0_addr          = s0_addr_reg;
assign s0_wdata         = s0_wdata_reg;
assign s0_read_req      = s0_read_req_reg;
assign s0_write_req     = s0_write_req_reg;
assign s0_size          = s0_size_reg;


// controller logic
// ----------------------------------------------------------------------------------------------------------
reg     [2:0]   state_reg;
reg     [2:0]   sub_word_reg;

reg             block_reg,
                request_reg,
                word_writeout_reg;


always @(posedge sys_clock_i) begin

    if (!resetn_i) begin
        // sequencing signals
        state_reg           <= ST_IDLE;
        sub_word_reg        <= 'b0;
        block_reg           <= 1'b0;
        request_reg         <= 1'b0;
        word_writeout_reg   <= 1'b0;

        // buffer signals
        buffer_read_reg     <= 1'b0;

        // port signals
        sys_write_reg       <= 1'b0;
        sys_command_reg     <= 'b0;
        sys_address_reg     <= 'b0;
        sys_data_reg        <= 'b0;
        s0_burstbegin_reg   <= 1'b0;
        s0_read_req_reg     <= 1'b0;
        s0_write_req_reg    <= 1'b0;
        s0_addr_reg         <= 'b0;
        s0_wdata_reg        <= 'b0;
        s0_size_reg         <= 'b0;

    end
    else begin

        // default signals
        buffer_read_reg     <= 1'b0;
        sys_write_reg       <= 1'b0;
        s0_burstbegin_reg   <= 1'b0;
        s0_read_req_reg     <= 1'b0;
        s0_write_req_reg    <= 1'b0;

        // state sequencing 
        case(state_reg)

            ST_IDLE: begin
                // if there is a request, service it
                if (!buffer_empty_flag & s0_ready) begin

                    // pull from buffer and register request packets and pull 
                    buffer_read_reg     <= 1'b1;               
                    sys_command_reg     <= buffer_command_bus;
                    sys_address_reg     <= buffer_address_bus;
                    sys_data_reg        <= buffer_data_bus;
                    sub_word_reg        <= buffer_address_bus[2:0];
                    
                    // sequence based on command type
                    s0_burstbegin_reg   <= 1'b1;
                    s0_size_reg         <= 10'h001;
                    s0_addr_reg         <= {{4'b0000},buffer_address_bus[23:3]};

                    case(buffer_command_bus)

                        `REQUEST_READIN_BLOCK: begin
                            s0_read_req_reg     <= 1'b1;                    // request read to ddr3
                            block_reg           <= 1'b0;                    // indicates first half-block
                            request_reg         <= 1'b0;                    // will not immediately request second half word
                            word_writeout_reg   <= 1'b0;                    // no word writeout required
                            state_reg           <= ST_DDR3_BLOCK_READIN;
                        end

                        `REQUEST_READIN_WORD: begin
                            s0_read_req_reg     <= 1'b1;
                            s0_read_req_reg     <= 1'b1;
                            state_reg           <= ST_DDR3_WORD_READIN;
                        end

                        // block write to memory
                        // request a write of first half block here
                        // next state request the other half
                        `REQUEST_WRITEOUT_BLOCK: begin
                            s0_write_req_reg    <= 1'b1; 
                            s0_wdata_reg        <= buffer_data_bus[255:0];
                            state_reg           <= ST_DDR3_BLOCK_WRITEOUT;
                        end

                        // word write to memory
                        // first read request the target address (half block)
                        // next cycle over-write the target word and writeout
                        `REQUEST_WRITEOUT_WORD: begin
                            s0_read_req_reg     <= 1'b1;
                            request_reg         <= 1'b0;    // prevent a second half-block request
                            block_reg           <= 1'b1;    // prevent a second half-block request
                            word_writeout_reg   <= 1'b1;    // prevent a second half-block request
                            state_reg           <= ST_DDR3_BLOCK_READIN;
                            s0_wdata_reg[31:0]  <= buffer_data_bus[31:0];   // use this register as a temporary holder  
                        end

                        default:;

                    endcase

                end
            end


            // setup for word writeout servicing
            // ----------------------------------------
            ST_DDR3_WORD_WRITEOUT: begin

                // data here is store in upper hald word [511:256]
                // overwrite the correct word
                case(sub_word_reg)
                    3'b000: sys_data_reg[287:256] <= s0_wdata_reg[31:0];
                    3'b001: sys_data_reg[319:288] <= s0_wdata_reg[31:0];
                    3'b010: sys_data_reg[351:320] <= s0_wdata_reg[31:0];
                    3'b011: sys_data_reg[383:352] <= s0_wdata_reg[31:0];
                    3'b100: sys_data_reg[415:384] <= s0_wdata_reg[31:0];
                    3'b101: sys_data_reg[447:416] <= s0_wdata_reg[31:0];
                    3'b110: sys_data_reg[479:448] <= s0_wdata_reg[31:0];
                    3'b111: sys_data_reg[511:480] <= s0_wdata_reg[31:0];
                end

                s0_addr_reg     <= s0_addr_reg - 1'b1;      // will auto-increment in next state (look below)
                state_reg       <= ST_DDR3_BLOCK_WRITEOUT;
            end


            // block write servicing
            // ----------------------------------------
            ST_DDR3_BLOCK_WRITEOUT: begin
                if (s0_ready) begin
                    s0_write_req_reg        <= 1'b1;
                    s0_burstbegin_reg       <= 1'b1;
                    s0_size_reg             <= 10'h001;
                    s0_addr_reg             <= s0_addr_reg + 1'b1;
                    s0_wdata_reg            <= sys_data_reg[511:256];
                    state_reg               <= ST_IDLE;
                end
            end


            // word read servicing
            // ----------------------------------------
            ST_DDR3_WORD_READIN: begin
                if (s0_rdata_valid) begin

                    case(sub_word_reg)
                        3'b000: sys_data_reg <= {480'h0,s0_rdata[31:0]}; 
                        3'b001: sys_data_reg <= {480'h0,s0_rdata[63:32]}; 
                        3'b010: sys_data_reg <= {480'h0,s0_rdata[95:64]}; 
                        3'b011: sys_data_reg <= {480'h0,s0_rdata[127:96]}; 
                        3'b100: sys_data_reg <= {480'h0,s0_rdata[159:128]}; 
                        3'b101: sys_data_reg <= {480'h0,s0_rdata[191:160]}; 
                        3'b110: sys_data_reg <= {480'h0,s0_rdata[223:192]}; 
                        3'b111: sys_data_reg <= {480'h0,s0_rdata[255:224]}; 
                    endcase

                    state_reg <= ST_SYS_WRITE_TO_BUFFER;    // write value out to buffer in next state
                end
            end


            // block read servicing
            // ----------------------------------------
            ST_DDR3_BLOCK_READIN: begin

                // if the request flag is set then send second sub packet
                if (request_reg) begin
                    if (s0_ready) begin
                        request_reg             <= 1'b0;
                        s0_burstbegin_reg       <= 1'b1;
                        s0_size_reg             <= 10'h001;
                        s0_addr_reg             <= s0_addr_reg + 1'b1;
                        s0_read_req_reg         <= 1'b1;
                    end
                end
                // if no pending request needs to be sent just look for received data
                else begin
                    if (s0_rdata_valid) begin
                        if (block_reg == 1'b0) begin
                            request_reg             <= 1'b1;
                            block_reg               <= 1'b1;
                            sys_data_reg[255:0]     <= s0_rdata;
                        end
                        else begin
                            sys_data_reg[511:256]   <= s0_rdata;

                            if (!word_writeout_reg) state_reg <= ST_SYS_WRITE_TO_BUFFER;
                            else                    state_reg <= ST_DDR3_WORD_WRITEOUT;
                        end
                    end
                end
            end


            // write out block to system
            // -----------------------------------------
            ST_SYS_WRITE_TO_BUFFER: begin
                if (!sys_full_i) begin
                    sys_write_reg   <= 1'b1;
                    sys_command_reg <= sys_command_reg | `SERVICE_SET_FLAG;
                    state_reg       <= ST_IDLE;
                end
            end

            default:;

        endcase
    end
end

endmodule 

`endif