SRC_DIR=./src
BIN_DIR=./bin

SAMPLE_ALL_SMALL=../fpga_proxy/results/sample/CLAM/rate_$(RATE)/seed_$(SEED)
SAMPLE_ALL_PHASE_SMALL=../fpga_proxy/results/sample/SHEL/rate_$(RATE)/seed_$(SEED)

SAMPLE_ALL_MEDIUM=../fpga_proxy/results/sample/CLAM_medium/rate_$(RATE)/seed_$(SEED)
SAMPLE_ALL_PHASE_MEDIUM=../fpga_proxy/results/sample/SHEL_medium/rate_$(RATE)/seed_$(SEED)


SAMPLE_ALL_LARGE=../fpga_proxy/results/sample/CLAM_large/rate_$(RATE)/seed_$(SEED)
SAMPLE_ALL_PHASE_LARGE=../fpga_proxy/results/sample/SHEL_large/rate_$(RATE)/seed_$(SEED)


SAMPLE_ALL_EXTRA_LARGE=../fpga_proxy/results/sample/CLAM_extra_large/rate_$(RATE)/seed_$(SEED)
SAMPLE_ALL_PHASE_EXTRA_LARGE=../fpga_proxy/results/sample/SHEL_extra_large/rate_$(RATE)/seed_$(SEED)

RESULT_DIR=./leases


all_bench =  deriche lu ludcmp cholesky adi 2mm 3mm atax bicg correlation covariance durbin doitgen fdtd-2d gemm gemver gesummv gramschmidt heat-3d jacobi-1d jacobi-2d mvt nussinov seidel-2d symm syr2k syrk trisolv trmm floyd-warshall  
multi_bench = mvt covariance correlation heat-3d jacobi-2d gemver 2mm fdtd-2d 3mm adi lu ludcmp  deriche
clean: 
	rm -rf $(BIN_DIR)/*

rl_set_c_shel: src/reference_lease_set_c_shel.h src/rl_set_main_c_shel.cpp
	sed -i "4s/\(.*\)/#include \"reference_lease_set_c_shel.h\"/" src/rl_set_main_c_shel.cpp
	sed -i "6s/\(.*\)\n.*/\1\n#include <algorithm>/" src/reference_lease_set_c_shel.h
	g++ -std=c++11 $(SRC_DIR)/rl_set_main_c_shel.cpp -O3 -o $(BIN_DIR)/rl_set_c_shel
rl_set_shel: src/reference_lease_set_shel.h src/rl_set_main_shel.cpp
	sed -i "4s/\(.*\)/#include \"reference_lease_set_shel.h\"/" src/rl_set_main_shel.cpp
	sed -i "6s/\(.*\)\n.*/\1\n#include <algorithm>/" src/reference_lease_set_shel.h
	g++ -std=c++11 $(SRC_DIR)/rl_set_main_shel.cpp -O3 -o $(BIN_DIR)/rl_set_shel
	

run_all_small: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_SMALL)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_SMALL)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;

run_all_medium: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_MEDIUM)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_MEDIUM)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;

run_all_large: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_LARGE)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_LARGE)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;


run_all_extra_large: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_EXTRA_LARGE)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_EXTRA_LARGE)/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;

run_all_small_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_SMALL)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_SMALL)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;

run_all_medium_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_MEDIUM)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_MEDIUM)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;

run_all_large_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_LARGE)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_LARGE)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;
run_all_extra_large_multi_level: src/lib.rs src/main.rs Cargo.toml
	for i in $(all_bench); do \
		cargo run --release  $(SAMPLE_ALL_EXTRA_LARGE)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -p   > /dev/null ; \
	done & \
	for i in $(multi_bench); do \
		cargo run --release  $(SAMPLE_ALL_PHASE_EXTRA_LARGE)_multi_level/$${i}.txt $(RESULT_DIR) -s $(CAPACITY) -c   > /dev/null ; \
	done & \
	wait;


