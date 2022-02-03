# directories for compiler
INC_PATH=../../include/
COMPRESS_BIN=/target/release
COMPRESS_BASE_DIR=$(CLAM_path)/software/benchmarks/elf_compress
LD_PATH_SCOPE=../../ld/riscv_bare_scope.ld
RISCV_GCC_PATH=~/.local/xPacks/@xpack-dev-tools/riscv-none-embed-gcc/8.3.0-2.3.1/.content/bin

# set compiler .localions
INC=-I $(INC_PATH)
LD_SCOPE=-T $(LD_PATH_SCOPE)
OPTS=--specs=nosys.specs -march=rv32imf -mabi=ilp32f -mdiv -mfdiv -$(.local_level) \
-fno-tree-slp-vectorize -fno-tree-loop-vectorize -fno-tree-vectorize 

pre_process:
	$(RISCV_GCC_PATH)/riscv-none-embed-gcc $(INC) $(OPTS) $(LD_SCOPE) $(INC_PATH)/*.c *.c -E -DSMALL_DATASET -DDATA_TYPE_IS_FLOAT -DINTEGER_SUPPORT -lm >> preprocess.txt
$(COMPRESS_BASE_DIR)/$(COMPRESS_BIN)/elf_compress: $(COMPRESS_BASE_DIR)/src/lib.rs $(COMPRESS_BASE_DIR)/src/main.rs
	cargo build --release --manifest-path $(COMPRESS_BASE_DIR)/Cargo.toml
	

scope: $(COMPRESS_BASE_DIR)/$(COMPRESS_BIN)/elf_compress
	$(RISCV_GCC_PATH)/riscv-none-embed-gcc $(INC) $(OPTS) $(LD_SCOPE) $(INC_PATH)/*.c *.c -o program.elf -DSMALL_DATASET -DDATA_TYPE_IS_FLOAT -DINTEGER_SUPPORT -lm
	# convert to binary file
	$(RISCV_GCC_PATH)/riscv-none-embed-objcopy program.elf -O binary program.txt
	# extract file information for compression
	readelf program.elf -l > program_info.txt
	# compress into transferable binary
	$(COMPRESS_BASE_DIR)$(COMPRESS_BIN)/elf_compress
	$(RISCV_GCC_PATH)/riscv-none-embed-objdump -D program.elf > disassembly.txt
	# clean up
	rm -f program.txt

dis:
	$(RISCV_GCC_PATH)/riscv-none-embed-objdump -D program.elf > disassembly.txt
