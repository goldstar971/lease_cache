#!/bin/csh -f

####################################################################################
## Copyright (c) 2014, University of British Columbia (UBC)  All rights reserved. ##
##                                                                                ##
## Redistribution  and  use  in  source   and  binary  forms,   with  or  without ##
## modification,  are permitted  provided that  the following conditions are met: ##
##   * Redistributions   of  source   code  must  retain   the   above  copyright ##
##     notice,  this   list   of   conditions   and   the  following  disclaimer. ##
##   * Redistributions  in  binary  form  must  reproduce  the  above   copyright ##
##     notice, this  list  of  conditions  and the  following  disclaimer in  the ##
##     documentation and/or  other  materials  provided  with  the  distribution. ##
##   * Neither the name of the University of British Columbia (UBC) nor the names ##
##     of   its   contributors  may  be  used  to  endorse  or   promote products ##
##     derived from  this  software without  specific  prior  written permission. ##
##                                                                                ##
## THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" ##
## AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE ##
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE ##
## DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE ##
## FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL ##
## DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR ##
## SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER ##
## CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, ##
## OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE ##
## OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. ##
####################################################################################

####################################################################################
##                      Priority Encoder Recursive Generator                      ##
##                                                                                ##
##    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    ##
##     SRAM-based BCAM; The University of British Columbia (UBC), April 2014      ##
####################################################################################

####################################################################################
## USAGE:                                                                         ##
## ./pe <encoder width> <register inputs ?> <register outputs ?> \                ##
##      <combinatorial max depth> <mux type> <top module suffex>                  ##
##     - Encoder width is a positive integer                                      ##
##     - Register inputs/outputs is a binary (0/1) indicating if inputs/outputs   ##
##       should be registerd for pipelining                                       ##
##     - combinatorial maximum depth is acheived by pipelining                    ##
##     - Mux type should be "CASE", "IFELSE" or "AS5EXT"                          ##
##       - "CASE"  : standard binary 4->1 mux using case statement                ##
##       - "IFELSE": using if/else statement                                      ##
##       - "AS5EXT": Altera's StratixV extended ALM (7LUT)                        ##
##     - Top module name and file will be "<top module suffex>"                ##
## EXAMPLES:                                                                      ##
## ./pe 1024 1 1 2 CASE cam                                                       ##
##     - Will generate Verilog files for a 1K wide priority encoder               ##
##     - Registered inputs and outputs; maximum two stages deep logic             ##
##     - Muxes are implemented using case statement                               ##
##     - Top level name will be pe1024_cam and will be located in pe1024_cam.v    ##
##                                                                                ##
## The following files and directories will be created:                           ##
## - pe<width>_<suffex>.v: priority encoder top module file                       ##
## - pe<i>.v             : i = 4, 16, 64, 256, 1024... recursive priority encoder ##
####################################################################################

################################## ARGUMENTS CHECK #################################

# require exactly 6 arguments
if (${#argv} != 6) then
    printf '\x1b[%i;3%im' 1 1
    printf 'Error: Exactly 6 argument are required\n'
    printf '\x1b[0m'
    goto errorMessage
endif

# priority encoder width
# check argument correctness (positive integer number)
if ( (`echo ${argv[1]} | egrep -c '^[0-9]+$'` != 1) || (${argv[1]} < 2) ) then
  printf '\x1b[%i;3%im' 1 1
  printf "Error (${argv[1]}): Priority encoder width must be possitive integer number\n"
  printf '\x1b[0m'
  goto errorMessage
endif
@ PEW = ${argv[1]}

# register inputs? (binary)
# check argument correctness (binary 0/1)
if ( (${argv[2]} != "0") & (${argv[2]} != "1") )then
  printf '\x1b[%i;3%im' 1 1
  printf "Error (${argv[2]}): Register inputs? should be a binary 0/1\n"
  printf '\x1b[0m'
  goto errorMessage
endif
@ RI = ${argv[2]}

# # register outputs? (binary)
# check argument correctness (binary 0/1)
if ( (${argv[3]} != "0") & (${argv[3]} != "1") )then
  printf '\x1b[%i;3%im' 1 1
  printf "Error (${argv[3]}): Register outputs? should be a binary 0/1\n"
  printf '\x1b[0m'
  goto errorMessage
endif
@ RO = ${argv[3]}

# combinatorial maximum depth
# check argument correctness (positive integer number)
if ((`echo ${argv[4]} | egrep -c '^[0-9]+$'` != 1) || (${argv[4]} < 1) ) then
  printf '\x1b[%i;3%im' 1 1
  printf "Error (${argv[4]}): Combinatorial maximum depth must be possitive integer number\n"
  printf '\x1b[0m'
  goto errorMessage
endif
@ CMD = ${argv[4]}

# mux implementation
# check argument correctness ("CASE", "IFELSE", "AS5EXT")
if ( (${argv[5]} != "CASE") && (${argv[5]} != "IFELSE") && (${argv[5]} != "AS5EXT") ) then
  printf '\x1b[%i;3%im' 1 1
  printf 'Error (%s): Mux type should be "CASE", "IFELSE", or "AS5EXT" \n' ${argv[5]}
  printf '\x1b[0m'
  goto errorMessage
endif
set MUX = ${argv[5]}

# top module suffex
set TMS = ${argv[6]}

################################## ARGUMENTS CHECK #################################

# upper(log2(width))
@ j = 2
@ l2w = 1
while ($j < $PEW)
  @ j = $j * 2
  @ l2w++
end

# reserved keywords
set ELSE = "else"

# wide recursive priority encoder based on narrower priority encoder
printf "" >! ${TMS}.v

@ i = 1
@ l2i = 0
@ l4i = 0
while ($i < $PEW)
  @ ip  = $i
  @ i   = $i   * 4
  @ l2i = $l2i + 2
  @ l4i = $l4i + 1

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
// pe${i}_${TMS}: recursive priority encoder based; Automatically generated
// Ameer Abedlhadi ; April 2014 - The University of British Columbia
// i: $i, l2i: $l2i, l4i: $l4i
module pe${i}_${TMS}(input clk, input rst, input [$i-1:0] oht, output [$l2i-1:0] bin, output vld);
EOV
#####################################################################################

  if ($i == 4) then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  assign {bin,vld} = {!(oht[0]||oht[1]),!oht[0]&&(oht[1]||!oht[2]),|oht};
EOV
#####################################################################################

  else

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // recursive calls for four narrower (fourth the inout width) priority encoders
  wire [$l2i-3:0] binI[3:0];
  wire [   3:0] vldI     ;
  pe${ip}_${TMS} pe${ip}_${TMS}_in0(clk, rst, oht[  $i/4-1:0        ],binI[0],vldI[0]);
  pe${ip}_${TMS} pe${ip}_${TMS}_in1(clk, rst, oht[  $i/2-1:  $i/4 ],binI[1],vldI[1]);
  pe${ip}_${TMS} pe${ip}_${TMS}_in2(clk, rst, oht[3*$i/4-1:  $i/2 ],binI[2],vldI[2]);
  pe${ip}_${TMS} pe${ip}_${TMS}_in3(clk, rst, oht[  $i  -1:3*$i/4 ],binI[3],vldI[3]);
  // register input priority encoders outputs if pipelining is required; otherwise assign only
  wire [$l2i-3:0] binII[3:0];
  wire [   3:0] vldII     ;
EOV
#####################################################################################

    if ( ( ( $l4i - 1 ) % $CMD ) == 0 ) then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  reg  [$l2i-3:0] binIR[3:0];
  reg  [   3:0] vldIR     ;
  always @(posedge clk, posedge rst)
    if (rst) {binIR[3],binIR[2],binIR[1],binIR[0],vldIR} <= {(4*($l2i-1)){1'b0}};
    $ELSE     {binIR[3],binIR[2],binIR[1],binIR[0],vldIR} <= {binI[3],binI[2],binI[1],binI[0],vldI};
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binIR[3],binIR[2],binIR[1],binIR[0],vldIR};
EOV
#####################################################################################

    else

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  assign {binII[3],binII[2],binII[1],binII[0],vldII} = {binI[3],binI[2],binI[1],binI[0],vldI};
EOV
#####################################################################################

    endif

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // output pe4 to generate indices from valid bits
  pe4_${TMS} pe4_${TMS}_out0(clk,rst,vldII,bin[$l2i-1:$l2i-2],vld);
EOV
#####################################################################################

    if      ($MUX == "AS5EXT") then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // generate stratixv_lcell_comb for extended 7LUT to implement the mux
  wire [$l2i-3:0] binO;
  genvar gi;
  generate
    for (gi=0 ; gi<($l2i-2) ; gi=gi+1) begin: LUTgi
      stratixv_lcell_comb #(
        .lut_mask    (64'hF0F0FF00F0F0CACA),
        .shared_arith("off"               ),
        .extended_lut("on"                ),
        .dont_touch  ("off"               )
      )
      stratixv_lcell_ext_mux_inst (
        .dataa       (binII[3][gi]        ),
        .datab       (binII[2][gi]        ),
        .datac       (vldII[2]            ),
        .datad       (binII[1][gi]        ),
        .datae       (vldII[0]            ),
        .dataf       (vldII[1]            ),
        .datag       (binII[0][gi]        ),
        .cin         (1'b0                ),
        .sharein     (1'b0                ),
        .combout     (binO[gi]            ),
        .sumout      (                    ),
        .cout        (                    ),
        .shareout    (                    )
      );
    end
  endgenerate
EOV
#####################################################################################

    else if ($MUX == "IFELSE") then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // implement the mux with a 7-inputs ALM in extended mode for each output
  reg [$l2i-3:0] binO;
  always @(*)
    if      (vldII[0]) binO = binII[0];
    $ELSE if (vldII[1]) binO = binII[1];
    $ELSE if (vldII[2]) binO = binII[2];
    $ELSE               binO = binII[3];
EOV
#####################################################################################

    else

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // a 4->1 mux to steer indices from the narrower pe's
  reg [$l2i-3:0] binO;
  always @(*)
    case (bin[$l2i-1:$l2i-2])
      2'b00: binO = binII[0];
      2'b01: binO = binII[1];
      2'b10: binO = binII[2];
      2'b11: binO = binII[3];
  endcase
EOV
#####################################################################################

    endif

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  assign bin[$l2i-3:0] = binO;
EOV
#####################################################################################

  endif

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
endmodule

EOV
#####################################################################################

end

# priority encoder top module file

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
// ${TMS}.v: priority encoder top module file
// Automatically generated for priority encoder design
// Ameer Abedlhadi; April 2014 - University of British Columbia

module ${TMS}(input clk, input rst, input [$PEW-1:0] oht, output [$l2w-1:0] bin, output vld);
EOV
#####################################################################################

if ($RI == "1") then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // register input (oht)
  reg [$PEW-1:0] ohtR;
  always @(posedge clk, posedge rst)
    if (rst) ohtR <= {$PEW{1'b0}};
    $ELSE    ohtR <= oht;
EOV
#####################################################################################

else

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  wire [$PEW-1:0] ohtR = oht;
EOV
#####################################################################################

endif

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  wire [$l2w-1:0] binII;
  wire          vldI ;
  // instantiate peiority encoder
EOV
#####################################################################################

if ($i > $PEW) then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  wire [$i-1:0] ohtI = {{($i-$PEW){1'b0}},ohtR};
  wire [$l2i-1:0] binI ;
  pe${i}_${TMS} pe${i}_${TMS}_0(clk,rst,ohtI,binI,vldI);
  assign binII = binI[$l2w-1:0];
EOV
#####################################################################################

else

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  pe${i}_${TMS} pe${i}_${TMS}_0(clk,rst,ohtR,binII,vldI);
EOV
#####################################################################################

endif

if ($RO == "1") then

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  // register outputs (bin, vld)
  reg [$l2w-1:0] binIIR;
  reg          vldIR ;
  always @(posedge clk, posedge rst)
    if (rst) {binIIR,vldIR} <= {($l2w+1){1'b0}};
    $ELSE    {binIIR,vldIR} <= {binII,vldI};
  assign {bin,vld} = {binIIR,vldIR};
EOV
#####################################################################################

else

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
  assign {bin,vld} = {binII ,vldI };
EOV
#####################################################################################

endif

###################################### VERILOG ######################################
cat >> ${TMS}.v << EOV
endmodule
EOV
#####################################################################################

goto scriptEnd

################################## ERROR MESSAGE ####################################

errorMessage:
printf '\x1b[%i;3%im' 1 1
cat << EOH
USAGE:
./pe <encoder width> <register inputs ?> <register outputs ?> \
     <combinatorial max depth> <mux type> <top module suffex>
    - Encoder width is a positive integer
    - Register inputs/outputs is a binary (0/1) indicating if inputs/outputs
      should be registerd for pipelining
    - combinatorial maximum depth is acheived by pipelining
    - Mux type should be "CASE", "IFELSE" or "AS5EXT"
      - "CASE"  : standard binary 4->1 mux using case statement
      - "IFELSE": using if/else statement
      - "AS5EXT": Altera's StratixV extended ALM (7LUT)
    - Top module name and file will be "<top module suffex>"
EXAMPLES:
./pe 1024 1 1 2 CASE cam                                       
    - Will generate Verilog files for a 1K wide priority encoder
    - Registered inputs and outputs; maximum two stages deep logic
    - Muxes are implemented using case statement
    - Top level name will be pe1024_cam and will be located in pe1024_cam.v

The following files and directories will be created:
- pe<width>_<suffex>.v: priority encoder top module file
- pe<i>.v             : i = 4, 16, 64, 256, 1024... recursive priority encoder
EOH
printf '\x1b[0m'
scriptEnd:

