`ifndef _CACHE_H_
`define _CACHE_H_

// system wide general memory parameters
// ---------------------------------------------------------------------
`define BW_BTYE_ADDR 						26 					// 64MB
`define BW_WORD_ADDR 						24 					// 16MW (W = 32b)

`define CACHE_WORDS_PER_BLOCK 				16					// 16 words/block
`define BW_BLOCK 							4
`define	N_CACHE_BLOCKS 	 	2**7

// cache software information
// ---------------------------------------------------------------------
//`define LEASE_CONFIG_BASE_B	 				26'h01FFFDC0 		// base address of configuration subpartition
//`define LEASE_CONFIG_BASE_W  				24'h007FFF70
//`define LEASE_ADDR_BASE_B 	 				26'h01FFFE00		// base address of lease reference address subpartition
//`define LEASE_ADDR_BASE_W 	 				24'h007FFF80
//`define LEASE_VALUE_BASE_B 	 				26'h01FFFF00 		// base address of lease value subpartition
//`define LEASE_VALUE_BASE_W 	 				24'h007FFFC0

`define LEASE_CONFIG_BASE_B 				26'h01FFF5C0
`define LEASE_CONFIG_BASE_W 				24'h007FFD70
`define LEASE_REF_ADDR_BASE_B 				26'h01FFF600
`define LEASE_REF_ADDR_BASE_W 				24'h007FFD80
`define LEASE_REF_LEASE0_BASE_B 			26'h01FFF800
`define LEASE_REF_LEASE0_BASE_W 			24'h007FFE00
`define LEASE_REF_LEASE1_BASE_B 			26'h01FFFB00
`define LEASE_REF_LEASE1_BASE_W 			24'h007FFEC0
`define LEASE_REF_LEASE0_PROB_BASE_B 		26'h01FFFD00
`define LEASE_REF_LEASE0_PROB_BASE_W 		24'h007FFF40


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

`endif // _CACHE_H_
