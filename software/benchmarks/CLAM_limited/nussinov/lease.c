#include "stdint.h"

static uint32_t lease[16380] __attribute__ ((section (".lease"))) __attribute__ ((__used__)) = {
// lease header
	0x00000001,	// default lease
	0x00000080,	// table size (128)
	0x007fc010,	// phase 0 base addr pointer
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
	0x00000000,	// unused
// phase 0
	//reference address
	0x00000b24, 0x00000624, 0x0000062c, 0x00000634, 0x00000640, 0x00000648, 0x00000654, 0x00000658, 0x00000664, 0x0000066c,
	0x0000067c, 0x000006b0, 0x000006bc, 0x000006c4, 0x000006d4, 0x000006d8, 0x000006e4, 0x000006ec, 0x000006f8, 0x000006fc,
	0x00000704, 0x0000070c, 0x00000718, 0x00000720, 0x0000072c, 0x00000730, 0x00000740, 0x00000748, 0x00000754, 0x00000788,
	0x00000798, 0x000007a0, 0x000007ac, 0x000007b0, 0x000007bc, 0x000007c4, 0x000007d0, 0x000007d4, 0x000007dc, 0x000007e4,
	0x000007ec, 0x000007f4, 0x000007fc, 0x00000808, 0x00000810, 0x0000081c, 0x00000820, 0x00000830, 0x00000838, 0x00000848,
	0x0000084c, 0x00000850, 0x00000858, 0x00000860, 0x00000864, 0x0000086c, 0x000008c0, 0x000008d0, 0x000008d8, 0x000008e8,
	0x000008ec, 0x000008f0, 0x000008f8, 0x00000900, 0x00000904, 0x0000090c, 0x00000930, 0x0000093c, 0x00000944, 0x00000950,
	0x00000958, 0x00000978, 0x00000994, 0x000009a4, 0x000009e8, 0x000009f0, 0x00000a04, 0x00000a18, 0x00000a24, 0x00000a28,
	0x00000a30, 0x00000a38, 0x00000a44, 0x00000a4c, 0x00000a58, 0x00000a5c, 0x00000a68, 0x00000a70, 0x00000a7c, 0x00000a80,
	0x00000a90, 0x00000a98, 0x00000aa4, 0x00000adc, 0x00000ae8, 0x00000af0, 0x00000afc, 0x00000b00, 0x00000b10, 0x00000b18,
	0x00000b2c, 0x00000b38, 0x00000b40, 0x00000b4c, 0x00000b50, 0x00000b58, 0x00000b5c, 0x00000b60, 0x00000b68, 0x00000b70,
	0x00000b74, 0x00000b78, 0x00000b8c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	//lease0 value
	0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x0000000c, 0x00000001, 0x00000001, 0x00000002,
	0x00000004, 0x00000001, 0x00000001, 0x00000002, 0x000002c7, 0x00000001, 0x00000001, 0x00000002, 0x00000006, 0x00000001,
	0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x0000000c, 0x00000001, 0x00000001, 0x00000002, 0x00000004, 0x00000001,
	0x00000001, 0x00000002, 0x00000dbc, 0x00000001, 0x00000001, 0x00000002, 0x00000009, 0x00000001, 0x00000001, 0x00000001,
	0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x00000018, 0x00000001, 0x00000001, 0x00000002, 0x0000000a,
	0x00000001, 0x00000002, 0x0000000a, 0x00000001, 0x00000002, 0x0000000a, 0x00000001, 0x00000001, 0x00000002, 0x000011ad,
	0x00000001, 0x00000002, 0x0000111a, 0x00000001, 0x00000002, 0x000010e2, 0x00000001, 0x00000001, 0x00000002, 0x00000008,
	0x00000001, 0x0000000c, 0x00000002, 0x00000004, 0x00000001, 0x00000002, 0x00000001, 0x00000002, 0x0000000d, 0x00000001,
	0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x00000014, 0x00000001, 0x00000001, 0x00000002, 0x00000008, 0x00000001,
	0x00000001, 0x00000002, 0x00000008, 0x00000001, 0x00000001, 0x00000002, 0x000011e0, 0x00000001, 0x00000001, 0x00000002,
	0x00000001, 0x00000001, 0x00000002, 0x00000011, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001,
	0x00000001, 0x00000001, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	//lease1 value
	0x00001368, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	//lease0 probability
	0x00000000, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff
};