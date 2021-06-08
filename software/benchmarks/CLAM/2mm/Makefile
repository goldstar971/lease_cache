# directories for compiler
INC_PATH=../../include/
LD_PATH=../../ld/riscv_bare.ld
LD_PATH_SCOPE=../../ld/riscv_bare_scope.ld
RISCV_GCC_PATH=/home/matthew/opt/xPacks/@xpack-dev-tools/riscv-none-embed-gcc/8.3.0-2.3.1/.content/bin

# set compiler options
INC=-I $(INC_PATH)
LD=-T $(LD_PATH)
LD_SCOPE=-T $(LD_PATH_SCOPE)
OPTS=--specs=nosys.specs -march=rv32imf -mabi=ilp32f -mdiv -mfdiv -$(opt_level) \
-fno-tree-slp-vectorize -fno-tree-loop-vectorize -fno-tree-vectorize 

pre_process:
	$(RISCV_GCC_PATH)/riscv-none-embed-gcc $(INC) $(OPTS) $(LD) $(INC_PATH)/*.c *.c -E -DSMALL_DATASET -DDATA_TYPE_IS_FLOAT -DINTEGER_SUPPORT -lm >> preprocess.txt

no_scope:
#riscv-none-embed-gcc $(INC) $(OPTS) $(LD) $(INC_PATH)/*.c *.c -o program.elf -DSMALL_DATASET -DDATA_TYPE_IS_FLOAT -DINTEGER_SUPPORT -lm
	$(RISCV_GCC_PATH)/riscv-none-embed-gcc $(INC) $(OPTS) $(LD) $(INC_PATH)/*.c *.c -o program.elf -DSMALL_DATASET -DDATA_TYPE_IS_FLOAT -DINTEGER_SUPPORT -lm

# convert to binary file
	$(RISCV_GCC_PATH)/riscv-none-embed-objcopy program.elf -O binary program.txt

#$(RISCV_GCC_PATH)/riscv-none-embed-objcopy -O ihex program.elf output.hex
#srec_cat program.txt -binary -o program.mif -mif

# extract file information for compression
	readelf program.elf -l > program_info.txt

# compress into transferable binary
	python2 ../../../python/elf_compress/main.py

# clean up
	rm program.txt


scope:
	$(RISCV_GCC_PATH)/riscv-none-embed-gcc $(INC) $(OPTS) $(LD_SCOPE) $(INC_PATH)/*.c *.c -o program.elf -DSMALL_DATASET -DDATA_TYPE_IS_FLOAT -DINTEGER_SUPPORT -lm
	$(RISCV_GCC_PATH)/riscv-none-embed-objcopy program.elf -O binary program.txt
	readelf program.elf -l > program_info.txt
	python2 ../../../python/elf_compress/main.py
	$(RISCV_GCC_PATH)/riscv-none-embed-objdump -D program.elf > disassembly.txt
	rm program.txt

dis:
	$(RISCV_GCC_PATH)/riscv-none-embed-objdump -D program.elf > disassembly.txt
