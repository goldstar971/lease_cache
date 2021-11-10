// pe4_multi_detect_priority_encoder: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 4, l2i: 2, l4i: 1
module pe4_multi_detect_priority_encoder(input clk, input rst, input [4-1:0] oht, output [2-1:0] bin, output vld, output multi_detect);
  assign {bin,vld} = {!(oht[0]||oht[1]),!oht[0]&&(oht[1]||!oht[2]),|oht};
 assign multi_detect = (oht[3] | oht[2] | oht[1]) & (oht[3] | oht[2] | oht[0]) & (oht[3] | oht[1] | oht[0]) & (oht[2] | oht[1] | oht[0]);
endmodule

module pe4_priority_encoder_2(input clk, input rst, input [4-1:0] oht, output [2-1:0] bin, output vld);
  assign {bin,vld} = {!(oht[0]||oht[1]),!oht[0]&&(oht[1]||!oht[2]),|oht};
endmodule


// pe16_multi_detect_priority_encoder: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 16, l2i: 4, l4i: 2
module pe16_multi_detect_priority_encoder(input clk, input rst, input [16-1:0] oht, output [4-1:0] bin, output vld,multi_detect);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [4-3:0] binI[3:0];
  wire [   3:0] vldI     ;
  wire [3:0] multi_detect_ar;
  assign multi_detect=|(multi_detect_ar);
  pe4_multi_detect_priority_encoder pe4_multi_detect_priority_encoder_in0(clk, rst, oht[  16/4-1:0        ],binI[0],vldI[0],multi_detect_ar[0]);
  pe4_multi_detect_priority_encoder pe4_multi_detect_priority_encoder_in1(clk, rst, oht[  16/2-1:  16/4 ],binI[1],vldI[1],multi_detect_ar[1]);
  pe4_multi_detect_priority_encoder pe4_multi_detect_priority_encoder_in2(clk, rst, oht[3*16/4-1:  16/2 ],binI[2],vldI[2],multi_detect_ar[2]);
  pe4_multi_detect_priority_encoder pe4_multi_detect_priority_encoder_in3(clk, rst, oht[  16  -1:3*16/4 ],binI[3],vldI[3],multi_detect_ar[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [4-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
  pe4_priority_encoder_2 pe4_priority_encoder_2_out0(clk,rst,vldII,bin[4-1:4-2],vld);
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

// pe64_multi_detect_priority_encoder: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 64, l2i: 6, l4i: 3
module pe64_multi_detect_priority_encoder(input clk, input rst, input [64-1:0] oht, output [6-1:0] bin, output vld,output multi_detect);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [6-3:0] binI[3:0];
  wire [   3:0] vldI     ;
   wire [3:0] multi_detect_ar;
  assign multi_detect=|(multi_detect_ar);
  pe16_multi_detect_priority_encoder pe16_multi_detect_priority_encoder_in0(clk, rst, oht[  64/4-1:0        ],binI[0],vldI[0],multi_detect_ar[0]);
  pe16_multi_detect_priority_encoder pe16_multi_detect_priority_encoder_in1(clk, rst, oht[  64/2-1:  64/4 ],binI[1],vldI[1],multi_detect_ar[1]);
  pe16_multi_detect_priority_encoder pe16_multi_detect_priority_encoder_in2(clk, rst, oht[3*64/4-1:  64/2 ],binI[2],vldI[2],multi_detect_ar[2]);
  pe16_multi_detect_priority_encoder pe16_multi_detect_priority_encoder_in3(clk, rst, oht[  64  -1:3*64/4 ],binI[3],vldI[3],multi_detect_ar[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [6-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
  pe4_priority_encoder_2 pe4_priority_encoder_2_out0(clk,rst,vldII,bin[6-1:6-2],vld);
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

// pe256_multi_detect_priority_encoder: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 256, l2i: 8, l4i: 4
module pe256_multi_detect_priority_encoder(input clk, input rst, input [256-1:0] oht, output [8-1:0] bin, output vld,output multi_detect);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [8-3:0] binI[3:0];
  wire [   3:0] vldI     ;
    wire [3:0] multi_detect_ar;
  assign multi_detect=|(multi_detect_ar);
  pe64_multi_detect_priority_encoder pe64_multi_detect_priority_encoder_in0(clk, rst, oht[  256/4-1:0       ],binI[0],vldI[0],multi_detect_ar[0]);
  pe64_multi_detect_priority_encoder pe64_multi_detect_priority_encoder_in1(clk, rst, oht[  256/2-1:  256/4 ],binI[1],vldI[1],multi_detect_ar[1]);
  pe64_multi_detect_priority_encoder pe64_multi_detect_priority_encoder_in2(clk, rst, oht[3*256/4-1:  256/2 ],binI[2],vldI[2],multi_detect_ar[2]);
  pe64_multi_detect_priority_encoder pe64_multi_detect_priority_encoder_in3(clk, rst, oht[  256  -1:3*256/4 ],binI[3],vldI[3],multi_detect_ar[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [8-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
   pe4_priority_encoder_2 pe4_priority_encoder_2_out0(clk,rst,vldII,bin[8-1:8-2],vld);
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

// pe1024_multi_detect_priority_encoder: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: 1024, l2i: 10, l4i: 5
module pe1024_multi_detect_priority_encoder(input clk, input rst, input [1024-1:0] oht, output [10-1:0] bin, output vld, output multi_detect);
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [10-3:0] binI[3:0];
  wire [   3:0] vldI     ;
      wire [3:0] multi_detect_ar;
  assign multi_detect=|(multi_detect_ar);
  pe256_multi_detect_priority_encoder pe256_multi_detect_priority_encoder_in0(clk, rst, oht[  1024/4-1:0        ],binI[0],vldI[0],multi_detect_ar[0]);
  pe256_multi_detect_priority_encoder pe256_multi_detect_priority_encoder_in1(clk, rst, oht[  1024/2-1:  1024/4 ],binI[1],vldI[1],multi_detect_ar[1]);
  pe256_multi_detect_priority_encoder pe256_multi_detect_priority_encoder_in2(clk, rst, oht[3*1024/4-1:  1024/2 ],binI[2],vldI[2],multi_detect_ar[2]);
  pe256_multi_detect_priority_encoder pe256_multi_detect_priority_encoder_in3(clk, rst, oht[  1024  -1:3*1024/4 ],binI[3],vldI[3],multi_detect_ar[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [10-3:0] binII[3:0];
  wire [   3:0] vldII     ;
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
  // output pe4 to generate indices from valid bits
   pe4_priority_encoder_2 pe4_priority_encoder_2_out0(clk,rst,vldII,bin[10-1:10-2],vld);
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

// multi_detect_priority_encoder.v: priority encoder top module file
// Automatically generated for priority encoder design
// Ameer Abedlhadi; April 2014 - University of British Columbia

module multi_detect_priority_encoder(input clk, input rst, input [1024-1:0] oht, output [10-1:0] bin, output vld, output multi_detect);
  wire [1024-1:0] ohtR = oht;
  wire [10-1:0] binII;
  wire          vldI ;
  // instantiate peiority encoder
  pe1024_multi_detect_priority_encoder pe1024_multi_detect_priority_encoder_0(clk,rst,ohtR,binII,vldI,multi_detect);
  assign {bin,vld} = {binII ,vldI };
endmodule
