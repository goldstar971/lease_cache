#include <iostream>
#include <fstream>
#include <limits>
#include "reference_lease_set_shel.h"
using namespace std;


uint32_t get_set(uint32_t n_block_capacity, uint32_t idx_tag, uint32_t n_way){
// n_block_capacity:        number of blocks that fit into cache memory 
// idx_tag:                 access physical index (i.e. tag - subset of target address)
// n_way:                   set associativity of cache (i.e. (n_way = 2) => two-way set associative)
//                          note: if (n_way == cache_block_capacity) => fully associative

    // use bit mask to isolate the part of the address that constrains set placement
    if (n_way != n_block_capacity){
        return idx_tag & ((n_block_capacity / n_way) - 1);
    }
    // if fully associative then all blocks placed into same set
    else {
        return 0;
    }
}


void process(string fileName, int num_way, int num_capacity) {

    ifstream ifs;
    ifs.open(fileName, ifstream::in);
    set<int> phase_ids;
    uint64_t ip;
    uint64_t ri;
    uint64_t time;
    uint64_t tag;
    
    uint64_t sample_count = 0;
    uint64_t start_time = numeric_limits<uint64_t>::max();
    uint64_t end_time = numeric_limits<uint64_t>::min();
    
    while (ifs.good()) {
        ifs >> hex >> ip;
        ifs.get();
        ifs >> hex >> ri;
        ifs.get();
        ifs >> hex >> tag;
        ifs.get();
        ifs >> dec >> time;
        ifs.get();
        if (ifs.eof()) {
            break;
        }
        
        uint64_t cur_phase = (ip & 0xFF000000) >> 24;
        phase_ids.insert(cur_phase);
        
        sample_count++;
        start_time = min(start_time, time);
        end_time = max(end_time, time);
    }
    
    uint64_t sample_distance = 1000;
    if (sample_count > 0) {
        sample_distance = (end_time - start_time) / (sample_count);
    }
    
    for (uint64_t phase_id : phase_ids) {
        
        ifs.clear();
        ifs.seekg(0, ios::beg);
        uint64_t sample_count_cur_phase = 0;
        
        while (ifs.good()) {
            ifs >> hex >> ip;
            ifs.get();
            ifs >> hex >> ri;
            ifs.get();
            ifs >> hex >> tag;
            ifs.get();
            ifs >> dec >> time;
            ifs.get();
            if (ifs.eof()) {
                break;
            }
            if (ri>2147483647){
                ri=0xFFFFEEEE;
            }
            
            uint64_t cur_phase = (ip & 0xFF000000) >> 24;
            ip = ip & 0x00FFFFFF;
        
            if (cur_phase != phase_id)
                continue;
            
            sample_count_cur_phase++;
            
            uint64_t cset = get_set(num_capacity, tag, num_way);
            
            // Accumulate RI to hist
            if (RI_set.find(ip) != RI_set.end()) {
               
                if ((*RI_set[ip]).find(cset) != (*RI_set[ip]).end()) {
                    if ((*(*RI_set[ip])[cset]).find(ri) != (*(*RI_set[ip])[cset]).end()) {
                        (*(*RI_set[ip])[cset])[ri] += 1;
                       } else  {

                        (*(*RI_set[ip])[cset])[ri] = 1;
                    }
                } else {
                    (*RI_set[ip])[cset] = new map<uint64_t, uint64_t>;
                    (*(*RI_set[ip])[cset])[ri] = 1;
                }
            } else {
                RI_set[ip] = new map<uint64_t, map<uint64_t, uint64_t>* >;
                (*RI_set[ip])[cset] = new map<uint64_t, uint64_t>;
                (*(*RI_set[ip])[cset])[ri] = 1;
            }
        }
        
        refT = sample_count_cur_phase * sample_distance;
        cout << "Finished phase " << phase_id << " with refT " << refT << " >>>>>>>>>>>" << endl;
        
        OSL_ref(num_capacity, num_capacity / num_way, sample_distance, phase_id);
        OSL_reset();
    }
    
    ifs.close();
    
    dumpLeasesFormated();
    //dumpLeasesFormantedWithLimitedEntry(128);
}

int main(int argc, char** argv) {
    
    string fileName;
     int c, num_capacity,num_way;
    if (argc != 4) {
        cout << "executable takes two arguments: sample file, cache size(KB)";
    } else {
        fileName = argv[1];
        num_capacity=stoi(argv[2]);
        num_way=stoi(argv[3]);
	}
    
    // data block size is 8 Byte
    process(fileName,num_way,num_capacity);
    return 0;
}
