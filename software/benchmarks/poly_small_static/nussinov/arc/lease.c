static int lease_config[16] __attribute__ ((section (".lease_config"))) __attribute__ ((__used__)) = {
	0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 100,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
};

static int lease_pc[64] __attribute__ ((section (".lease_pc"))) __attribute__ ((__used__)) = {
	0x00000630, 0x0000063c, 0x00000654, 0x00000664, 0x00000688, 0x00000694, 0x000006bc, 0x000006c8, 0x000006e4, 0x000006f0,
	0x00000714, 0x00000720, 0x00000760, 0x0000076c, 0x00000788, 0x00000798, 0x000007a0, 0x000007a8, 0x000007b4, 0x000007bc,
	0x000007f4, 0x00000800, 0x00000844, 0x000008ac, 0x000008b8, 0x000008d0, 0x000008dc, 0x000008f8, 0x00000904, 0x0000092c,
	0x00000938, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000
};

static int lease_val[64] __attribute__ ((section (".lease_val"))) __attribute__ ((__used__)) = {
	0x00000002, 0x00000008, 0x00000002, 0x00000125, 0x00000002, 0x00000006, 0x00000002, 0x00000008, 0x00000002, 0x00000011,
	0x00000002, 0x00000009, 0x00000002, 0x0000000e, 0x00000002, 0x00000281, 0x00000002, 0x00000486, 0x00000002, 0x0000045e,
	0x00000002, 0x00000008, 0x00000002, 0x00000002, 0x0000000c, 0x00000002, 0x0000044a, 0x00000002, 0x0000059e, 0x00000002,
	0x0000000d, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0x00000000, 0x00000000
};

