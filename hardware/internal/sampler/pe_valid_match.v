// pe4_valid_match: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 4, l2i: 2, l4i: 1
module pe4_valid_match(input clk, input rst, input [4-1:0] oht, output [2-1:0] bin, output vld);
  assign {bin,vld} = {!(oht[0]||oht[1]),!oht[0]&&(oht[1]||!oht[2]),|oht};
endmodule

// pe16_valid_match: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 16, l2i: 4, l4i: 2
module pe16_valid_match(input clk, input rst, input [16-1:0] oht, output [4-1:0] bin, output vld);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [4-3:0] binI[3:0];
  wire [   3:0] vldI     ;
  pe4_valid_match pe4_valid_match_in0(clk, rst, oht[  16/4-1:0        ],binI[0],vldI[0]);
  pe4_valid_match pe4_valid_match_in1(clk, rst, oht[  16/2-1:  16/4 ],binI[1],vldI[1]);
  pe4_valid_match pe4_valid_match_in2(clk, rst, oht[3*16/4-1:  16/2 ],binI[2],vldI[2]);
  pe4_valid_match pe4_valid_match_in3(clk, rst, oht[  16  -1:3*16/4 ],binI[3],vldI[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [4-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
  pe4_valid_match pe4_valid_match_out0(clk,rst,vldII,bin[4-1:4-2],vld);
  // a 4->1 mux to steer indices from the narrower pe's
  reg [4-3:0] binO;
  always @(*)
    case (bin[4-1:4-2])
      2'b00: binO = binII[0];
      2'b01: binO = binII[1];
      2'b10: binO = binII[2];
      2'b11: binO = binII[3];
  endcase
  assign bin[4-3:0] = binO;
endmodule

// pe64_valid_match: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 64, l2i: 6, l4i: 3
module pe64_valid_match(input clk, input rst, input [64-1:0] oht, output [6-1:0] bin, output vld);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [6-3:0] binI[3:0];
  wire [   3:0] vldI     ;
  pe16_valid_match pe16_valid_match_in0(clk, rst, oht[  64/4-1:0        ],binI[0],vldI[0]);
  pe16_valid_match pe16_valid_match_in1(clk, rst, oht[  64/2-1:  64/4 ],binI[1],vldI[1]);
  pe16_valid_match pe16_valid_match_in2(clk, rst, oht[3*64/4-1:  64/2 ],binI[2],vldI[2]);
  pe16_valid_match pe16_valid_match_in3(clk, rst, oht[  64  -1:3*64/4 ],binI[3],vldI[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [6-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
  pe4_valid_match pe4_valid_match_out0(clk,rst,vldII,bin[6-1:6-2],vld);
  // a 4->1 mux to steer indices from the narrower pe's
  reg [6-3:0] binO;
  always @(*)
    case (bin[6-1:6-2])
      2'b00: binO = binII[0];
      2'b01: binO = binII[1];
      2'b10: binO = binII[2];
      2'b11: binO = binII[3];
  endcase
  assign bin[6-3:0] = binO;
endmodule

// pe256_valid_match: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 256, l2i: 8, l4i: 4
module pe256_valid_match(input clk, input rst, input [256-1:0] oht, output [8-1:0] bin, output vld);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [8-3:0] binI[3:0];
  wire [   3:0] vldI     ;
  pe64_valid_match pe64_valid_match_in0(clk, rst, oht[  256/4-1:0        ],binI[0],vldI[0]);
  pe64_valid_match pe64_valid_match_in1(clk, rst, oht[  256/2-1:  256/4 ],binI[1],vldI[1]);
  pe64_valid_match pe64_valid_match_in2(clk, rst, oht[3*256/4-1:  256/2 ],binI[2],vldI[2]);
  pe64_valid_match pe64_valid_match_in3(clk, rst, oht[  256  -1:3*256/4 ],binI[3],vldI[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [8-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
  pe4_valid_match pe4_valid_match_out0(clk,rst,vldII,bin[8-1:8-2],vld);
  // a 4->1 mux to steer indices from the narrower pe's
  reg [8-3:0] binO;
  always @(*)
    case (bin[8-1:8-2])
      2'b00: binO = binII[0];
      2'b01: binO = binII[1];
      2'b10: binO = binII[2];
      2'b11: binO = binII[3];
  endcase
  assign bin[8-3:0] = binO;
endmodule

// pe1024_valid_match: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 1024, l2i: 10, l4i: 5
module pe1024_valid_match(input clk, input rst, input [1024-1:0] oht, output [10-1:0] bin, output vld);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [10-3:0] binI[3:0];
  wire [   3:0] vldI     ;
  pe256_valid_match pe256_valid_match_in0(clk, rst, oht[  1024/4-1:0        ],binI[0],vldI[0]);
  pe256_valid_match pe256_valid_match_in1(clk, rst, oht[  1024/2-1:  1024/4 ],binI[1],vldI[1]);
  pe256_valid_match pe256_valid_match_in2(clk, rst, oht[3*1024/4-1:  1024/2 ],binI[2],vldI[2]);
  pe256_valid_match pe256_valid_match_in3(clk, rst, oht[  1024  -1:3*1024/4 ],binI[3],vldI[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [10-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
  pe4_valid_match pe4_valid_match_out0(clk,rst,vldII,bin[10-1:10-2],vld);
  // a 4->1 mux to steer indices from the narrower pe's
  reg [10-3:0] binO;
  always @(*)
    case (bin[10-1:10-2])
      2'b00: binO = binII[0];
      2'b01: binO = binII[1];
      2'b10: binO = binII[2];
      2'b11: binO = binII[3];
  endcase
  assign bin[10-3:0] = binO;
endmodule

// pe_valid_match.v: priority encoder top module file
// Automatically generated for priority encoder design
// Ameer Abedlhadi; April 2014 - University of British Columbia

module pe_valid_match(input clk, input rst, input [512-1:0] oht, output [9-1:0] bin, output vld);
  wire [512-1:0] ohtR = oht;
  wire [9-1:0] binII;
  wire          vldI ;
  // instantiate peiority encoder
  wire [1024-1:0] ohtI = {{(1024-512){1'b0}},ohtR};
  wire [10-1:0] binI ;
  pe1024_valid_match pe1024_valid_match_0(clk,rst,ohtI,binI,vldI);
  assign binII = binI[9-1:0];
  assign {bin,vld} = {binII ,vldI };
endmodule
