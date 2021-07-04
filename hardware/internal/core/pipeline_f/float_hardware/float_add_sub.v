// megafunction wizard: %ALTERA_FP_FUNCTIONS v18.1%
// GENERATION: XML
// float_add_sub.v

// Generated using ACDS version 18.1 625

`timescale 1 ps / 1 ps
module float_add_sub (
		input  wire        clk,    //    clk.clk
		input  wire        areset, // areset.reset
		input  wire [31:0] a,      //      a.a
		input  wire [31:0] b,      //      b.b
		output wire [31:0] q,      //      q.q
		input  wire        opSel   //  opSel.opSel
	);

	float_add_sub_0002 float_add_sub_inst (
		.clk    (clk),    //    clk.clk
		.areset (areset), // areset.reset
		.a      (a),      //      a.a
		.b      (b),      //      b.b
		.q      (q),      //      q.q
		.opSel  (opSel)   //  opSel.opSel
	);

endmodule
// Retrieval info: <?xml version="1.0"?>
//<!--
//	Generated by Altera MegaWizard Launcher Utility version 1.0
//	************************************************************
//	THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//	************************************************************
//	Copyright (C) 1991-2021 Altera Corporation
//	Any megafunction design, and related net list (encrypted or decrypted),
//	support information, device programming or simulation file, and any other
//	associated documentation or information provided by Altera or a partner
//	under Altera's Megafunction Partnership Program may be used only to
//	program PLD devices (but not masked PLD devices) from Altera.  Any other
//	use of such megafunction design, net list, support information, device
//	programming or simulation file, or any other related documentation or
//	information is prohibited for any other purpose, including, but not
//	limited to modification, reverse engineering, de-compiling, or use with
//	any other silicon devices, unless such use is explicitly licensed under
//	a separate agreement with Altera or a megafunction partner.  Title to
//	the intellectual property, including patents, copyrights, trademarks,
//	trade secrets, or maskworks, embodied in any such megafunction design,
//	net list, support information, device programming or simulation file, or
//	any other related documentation or information provided by Altera or a
//	megafunction partner, remains with Altera, the megafunction partner, or
//	their respective licensors.  No other licenses, including any licenses
//	needed under any third party's intellectual property, are provided herein.
//-->
// Retrieval info: <instance entity-name="altera_fp_functions" version="18.1" >
// Retrieval info: 	<generic name="FUNCTION_FAMILY" value="ARITH" />
// Retrieval info: 	<generic name="ARITH_function" value="ADDSUB" />
// Retrieval info: 	<generic name="CONVERT_function" value="FXP_FP" />
// Retrieval info: 	<generic name="ALL_function" value="ADD" />
// Retrieval info: 	<generic name="EXP_LOG_function" value="EXPE" />
// Retrieval info: 	<generic name="TRIG_function" value="SIN" />
// Retrieval info: 	<generic name="COMPARE_function" value="MIN" />
// Retrieval info: 	<generic name="ROOTS_function" value="SQRT" />
// Retrieval info: 	<generic name="fp_format" value="single" />
// Retrieval info: 	<generic name="fp_exp" value="8" />
// Retrieval info: 	<generic name="fp_man" value="23" />
// Retrieval info: 	<generic name="exponent_width" value="23" />
// Retrieval info: 	<generic name="frequency_target" value="50" />
// Retrieval info: 	<generic name="latency_target" value="2" />
// Retrieval info: 	<generic name="performance_goal" value="frequency" />
// Retrieval info: 	<generic name="rounding_mode" value="nearest with tie breaking away from zero" />
// Retrieval info: 	<generic name="faithful_rounding" value="false" />
// Retrieval info: 	<generic name="gen_enable" value="false" />
// Retrieval info: 	<generic name="divide_type" value="0" />
// Retrieval info: 	<generic name="select_signal_enable" value="true" />
// Retrieval info: 	<generic name="scale_by_pi" value="false" />
// Retrieval info: 	<generic name="number_of_inputs" value="2" />
// Retrieval info: 	<generic name="trig_no_range_reduction" value="false" />
// Retrieval info: 	<generic name="report_resources_to_xml" value="false" />
// Retrieval info: 	<generic name="fxpt_width" value="32" />
// Retrieval info: 	<generic name="fxpt_fraction" value="0" />
// Retrieval info: 	<generic name="fxpt_sign" value="1" />
// Retrieval info: 	<generic name="fp_out_format" value="single" />
// Retrieval info: 	<generic name="fp_out_exp" value="8" />
// Retrieval info: 	<generic name="fp_out_man" value="23" />
// Retrieval info: 	<generic name="fp_in_format" value="single" />
// Retrieval info: 	<generic name="fp_in_exp" value="8" />
// Retrieval info: 	<generic name="fp_in_man" value="23" />
// Retrieval info: 	<generic name="enable_hard_fp" value="true" />
// Retrieval info: 	<generic name="manual_dsp_planning" value="true" />
// Retrieval info: 	<generic name="forceRegisters" value="1111" />
// Retrieval info: 	<generic name="selected_device_family" value="Cyclone V" />
// Retrieval info: 	<generic name="selected_device_speedgrade" value="7" />
// Retrieval info: </instance>
// IPFS_FILES : float_add_sub.vo
// RELATED_FILES: float_add_sub.v, dspba_library_package.vhd, dspba_library.vhd, float_add_sub_0002.vhd
