# compiler options
CXX=g++ -g -O3 -std=c++11

# project directories
SRC_DIR=./src
INC_DIR=./include
SHARED_LIB_DIR=/opt/intelFPGA_lite/18.1/quartus/linux64
BUILD_DIR=./bin

# options
INCFLAGS=-I$(INC_DIR)
LDFLAGS=-L$(SHARED_LIB_DIR) -Wl,-rpath=$(SHARED_LIB_DIR)
LDLIBS=-ljtag_atlantic -ljtag_client

all:
	$(CXX) $(INCFLAGS) $(SRC_DIR)/*.c $(LDFLAGS) $(LDLIBS) -o $(BUILD_DIR)/main
multi_level:
	$(CXX) $(INCFLAGS) $(SRC_DIR)/*.c $(LDFLAGS) $(LDLIBS) -DMULTI_LEVEL_CACHE -o $(BUILD_DIR)/main

pre_process:
	$(CXX) $(INCFLAGS) $(SRC_DIR)/*.c $(LDFLAGS) $(LDLIBS) -E > pre_process.txt


