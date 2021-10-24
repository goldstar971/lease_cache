`ifndef _CACHE_H_
`define _CACHE_H_



`define CACHE_WORDS_PER_BLOCK 				16					// 16 words/block
`define BW_BLOCK 							4
`define	N_CACHE_BLOCKS 	 	2**7

// cache software information


`define LEASE_CONFIG_BASE_B 				29'h01ff0000
`define LEASE_CONFIG_BASE_W 				27'h007fc000
`define LEASE_REF_ADDR_BASE_B 				29'h01ff0040
`define LEASE_REF_ADDR_BASE_W 				24'h007fc010

// misc cache information
// ---------------------------------------------------------------------
`define ID_CACHE_RANDOM 					32'h00000000
`define ID_CACHE_FIFO 						32'h00000001
`define ID_CACHE_LRU 						32'h00000002
`define ID_CACHE_MRU 						32'h00000003
`define ID_CACHE_PLRU	 					32'h00000004
`define ID_CACHE_SRRIP	 					32'h00000005
`define ID_CACHE_LEASE 						32'h00000006
`define ID_CACHE_LEASE_DUAL 				32'h00000007
`define ID_CACHE_DLEASE 	 				32'h00000008
`define ID_CACHE_SAMPLER 					32'h0000000F

`define ID_CACHE_FULLY_ASSOCIATIVE 			32'h00000000
`define ID_CACHE_1WAY_SET_ASSOCIATIVE 		32'h10000000
`define ID_CACHE_2WAY_SET_ASSOCIATIVE 		32'h20000000
`define ID_CACHE_4WAY_SET_ASSOCIATIVE 		32'h40000000
`define ID_CACHE_8WAY_SET_ASSOCIATIVE 		32'h80000000


`include "../../../internal/cache/lib/cache_performance_controller.v"

`endif // _CACHE_H_
