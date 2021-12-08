SRC_DIR=./src
BIN_DIR=./bin

SAMPLE_ALL_SMALL=../fpga_proxy/results/sample/CLAM
SAMPLE_ALL_PHASE_SMALL=../fpga_proxy/results/sample/SHEL

SAMPLE_ALL_MEDIUM=../fpga_proxy/results/sample/CLAM_medium
SAMPLE_ALL_PHASE_MEDIUM=../fpga_proxy/results/sample/SHEL_medium

SAMPLE_ALL_LARGE=../fpga_proxy/results/sample/CLAM_large
SAMPLE_ALL_PHASE_LARGE=../fpga_proxy/results/sample/SHEL_large


SAMPLE_ALL_EXTRA_LARGE=../fpga_proxy/results/sample/CLAM_extra_large
SAMPLE_ALL_PHASE_EXTRA_LARGE=../fpga_proxy/results/sample/SHEL_extra_large


RESULT_DIR=./leases


all_bench =  deriche lu ludcmp cholesky adi 2mm 3mm atax bicg correlation covariance durbin doitgen fdtd-2d gemm gemver gesummv gramschmidt heat-3d jacobi-1d jacobi-2d mvt nussinov seidel-2d symm syr2k syrk trisolv trmm floyd-warshall  
multi_bench = mvt covariance correlation heat-3d jacobi-2d gemver 2mm fdtd-2d 3mm adi lu ludcmp  deriche
clean: 
	rm -rf $(BIN_DIR)/*

clam: src/lib.rs src/main.rs  
	cargo build --release 


run_all_small: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam $(SAMPLE_ALL_SMALL)//rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_SMALL)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;

run_all_medium: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_MEDIUM)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_MEDIUM)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;

run_all_large: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_LARGE)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_LARGE)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;


run_all_extra_large: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_EXTRA_LARGE)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_EXTRA_LARGE)/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;

run_all_small_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_SMALL)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_SMALL)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;

run_all_medium_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_MEDIUM)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_MEDIUM)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;

run_all_large_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_LARGE)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_LARGE)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;
run_all_extra_large_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		./target/release/clam  $(SAMPLE_ALL_EXTRA_LARGE)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		./target/release/clam  $(SAMPLE_ALL_PHASE_EXTRA_LARGE)_multi_level/rate_$(RATE)/seed_$(SEED)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -S $(WAYS) -c   > /dev/null ; \
	done & \
	wait;


