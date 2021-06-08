#include "stdint.h"

static uint32_t lease[16380] __attribute__ ((section (".lease"))) __attribute__ ((__used__)) = {
// lease header
	0x00000001,	// default lease
	0x00000100,	// table size (256)
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
	0x00000b80, 0x00000630, 0x000007e4, 0x000007e8, 0x000007f8, 0x00000800, 0x00000808, 0x00000814, 0x00000818, 0x00000820,
	0x00000824, 0x00000830, 0x00000834, 0x00000840, 0x00000844, 0x0000084c, 0x00000854, 0x00000860, 0x0000086c, 0x00000870,
	0x00000878, 0x00000880, 0x0000088c, 0x00000890, 0x00000894, 0x00000898, 0x0000089c, 0x000008a4, 0x000008ac, 0x000008b8,
	0x000008bc, 0x000008c0, 0x000008c8, 0x000008cc, 0x000008d0, 0x000008d8, 0x000008e8, 0x000008f8, 0x00000904, 0x00000918,
	0x0000091c, 0x00000924, 0x00000928, 0x00000934, 0x00000938, 0x00000944, 0x00000948, 0x00000950, 0x00000958, 0x00000964,
	0x00000970, 0x00000974, 0x00000978, 0x0000097c, 0x00000984, 0x0000098c, 0x00000998, 0x0000099c, 0x000009a0, 0x000009a4,
	0x000009a8, 0x000009b0, 0x000009b8, 0x000009c4, 0x000009c8, 0x000009cc, 0x000009d4, 0x000009d8, 0x000009e0, 0x000009e8,
	0x000009ec, 0x000009f0, 0x00000a00, 0x00000a08, 0x00000a10, 0x00000a18, 0x00000a24, 0x00000a28, 0x00000a30, 0x00000a38,
	0x00000a44, 0x00000a4c, 0x00000a54, 0x00000a5c, 0x00000a64, 0x00000a70, 0x00000a74, 0x00000a7c, 0x00000a80, 0x00000a84,
	0x00000a8c, 0x00000a94, 0x00000a98, 0x00000aac, 0x00000ab0, 0x00000ac0, 0x00000ac8, 0x00000ad0, 0x00000adc, 0x00000ae0,
	0x00000ae8, 0x00000aec, 0x00000af8, 0x00000afc, 0x00000b08, 0x00000b0c, 0x00000b14, 0x00000b1c, 0x00000b28, 0x00000b34,
	0x00000b38, 0x00000b40, 0x00000b48, 0x00000b54, 0x00000b58, 0x00000b5c, 0x00000b60, 0x00000b64, 0x00000b6c, 0x00000b74,
	0x00000b84, 0x00000b88, 0x00000b90, 0x00000b94, 0x00000b98, 0x00000ba0, 0x00000bc4, 0x00000be0, 0x00000be4, 0x00000bec,
	0x00000bf0, 0x00000bfc, 0x00000c00, 0x00000c0c, 0x00000c10, 0x00000c18, 0x00000c20, 0x00000c2c, 0x00000c38, 0x00000c3c,
	0x00000c40, 0x00000c44, 0x00000c4c, 0x00000c54, 0x00000c60, 0x00000c64, 0x00000c68, 0x00000c6c, 0x00000c70, 0x00000c78,
	0x00000c80, 0x00000c8c, 0x00000c90, 0x00000c94, 0x00000c9c, 0x00000ca0, 0x00000ca8, 0x00000cb0, 0x00000cc8, 0x00000cd0,
	0x00000cd8, 0x00000ce0, 0x00000cec, 0x00000cf0, 0x00000cf8, 0x00000d00, 0x00000d0c, 0x00000d14, 0x00000d1c, 0x00000d24,
	0x00000d2c, 0x00000d38, 0x00000d3c, 0x00000d44, 0x00000d48, 0x00000d4c, 0x00000d54, 0x00000d5c, 0x00000d60, 0x00000d64,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	//lease0 value
	0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x0000000b, 0x00000004, 0x0000000f, 0x00000001, 0x00000002,
	0x00000002, 0x00000002, 0x00000002, 0x0000001a, 0x00000001, 0x00000002, 0x00000004, 0x00000002, 0x0000000b, 0x00000002,
	0x00000007, 0x00000002, 0x00000010, 0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x00000007, 0x00000002, 0x00000014,
	0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x00000004, 0x00000001, 0x00000006, 0x00000001, 0x00000004, 0x00000002,
	0x00000007, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000006, 0x00000002, 0x00000006, 0x00000002,
	0x0000000d, 0x00000002, 0x00000006, 0x00000002, 0x00000007, 0x00000002, 0x0000001d, 0x00000003, 0x00000001, 0x00000005,
	0x00000002, 0x00000010, 0x00000003, 0x00000010, 0x00000004, 0x00000001, 0x00000001, 0x00000002, 0x00000001, 0x00000001,
	0x00000004, 0x00000005, 0x00000001, 0x00000002, 0x00000004, 0x00000002, 0x00000011, 0x00000002, 0x00000004, 0x00000002,
	0x00000011, 0x00000003, 0x00000001, 0x00000006, 0x00000002, 0x00000011, 0x00000001, 0x00000001, 0x00000002, 0x00000004,
	0x00000001, 0x00000001, 0x00000002, 0x00000001, 0x00000001, 0x00000002, 0x0000000b, 0x00000004, 0x0000000f, 0x00000001,
	0x00000002, 0x00000002, 0x00000002, 0x00000002, 0x0000001a, 0x00000001, 0x00000002, 0x00000004, 0x00000002, 0x0000000b,
	0x00000002, 0x00000007, 0x00000002, 0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x00000007, 0x00000002,
	0x00000001, 0x00000001, 0x00000001, 0x00000002, 0x00000004, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001,
	0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000005, 0x00000002, 0x00000006, 0x00000004, 0x0000000d, 0x00000001,
	0x00000005, 0x00000002, 0x00000007, 0x00000005, 0x000015cb, 0x00000001, 0x00000001, 0x00000005, 0x00000002, 0x00000010,
	0x00000003, 0x00000000, 0x00000008, 0x00000001, 0x00000001, 0x00000009, 0x00000001, 0x00000001, 0x00000001, 0x00000002,
	0x00000004, 0x00000002, 0x00000011, 0x00000002, 0x00000004, 0x00000002, 0x00000011, 0x00000003, 0x00000001, 0x00000006,
	0x00000002, 0x00000011, 0x00000001, 0x00000001, 0x00000002, 0x00000002, 0x00000001, 0x00000001, 0x00000002, 0x00000003,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	//lease1 value
	0x0000173f, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
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
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	//lease0 probability
	0x00000158, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
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
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff,
	0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff, 0x000001ff
};