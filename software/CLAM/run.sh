rm -f leases/*_*_lease*
unset rate multi_level seed

#get options
while getopts "m:r:s:" option; do
    case "$option" in
        r ) rate="$OPTARG";;
        s ) seed="$OPTARG";;
        m ) multi_level="$OPTARG";;
        * ) exit 1;;
    esac
done
#set defaults if not used
rate=${rate-256}
seed=${seed-1}
multi_level=${multi_level-no}

echo $rate
echo $seed
echo $multi_level



if [[ "$multi_level" == "yes" ]]; then
	 make run_all_small_multi_level CAPACITY=512 RATE=$rate SEED=$seed 
	 mv leases/*_prl*  "./leases/128_llt_entries/512blocks_512ways_PRL/"
	 	mv leases/*_c-shel* "./leases/128_llt_entries/512blocks_512ways_C-SHEL/"
	 	 mv leases/*_shel* "./leases/128_llt_entries/512blocks_512ways_SHEL/"
	 	 mv leases/*_clam* "./leases/128_llt_entries/512blocks_512ways_CLAM/"
	 make run_all_medium_multi_level CAPACITY=512 RATE=$rate SEED=$seed 
	  mv leases/*_prl*  "./leases/128_llt_entries/512blocks_512ways_PRL_medium/"
	 	 mv leases/*_c-shel* "./leases/128_llt_entries/512blocks_512ways_C-SHEL_medium/"
	 	 mv leases/*_shel_* "./leases/128_llt_entries/512blocks_512ways_SHEL_medium/"
	 	 mv leases/*_clam_* "./leases/128_llt_entries/512blocks_512ways_CLAM_medium/"
	 make run_all_large_multi_level CAPACITY=512 RATE=$rate SEED=$seed
	 mv leases/*_prl*  "./leases/128_llt_entries/512blocks_512ways_PRL_large/"
		mv leases/*_c-shel* "./leases/128_llt_entries/512blocks_512ways_C-SHEL_large/"
	 	mv leases/*_shel* "./leases/128_llt_entries/512blocks_512ways_SHEL_large/"
	mv leases/*_clam* "./leases/128_llt_entries/512blocks_512ways_CLAM_large/"
#		
#make run_all_extra_large_multi_level CAPACITY=512 RATE=$rate SEED=$seed WAYS=512
#mv leases/*_c_shel* "./leases/128_llt_entries/512blocks_512ways_C-SHEL_extra_large/"
#mv leases/*_shel* "./leases/128_llt_entries/512blocks_512ways_SHEL_extra_large/"
#mv leases/*_clam* "./leases/128_llt_entries/512blocks_512ways_CLAM_extra_large/"
#mv leases/*_prl*  "./leases/128_llt_entries/512blocks_512ways_PRL_extra_large/"



 else 
make run_all_small CAPACITY=128 RATE=$rate SEED=$seed
	mv leases/*_prl*  "./leases/128_llt_entries/128blocks_128ways_PRL/"
		#mv leases/*_c-shel* "./leases/128_llt_entries/128blocks_128ways_C-SHEL/"
		mv leases/*_shel* "./leases/128_llt_entries/128blocks_128ways_SHEL/"
		mv leases/*_clam* "./leases/128_llt_entries/128blocks_128ways_CLAM/"
	 make run_all_medium CAPACITY=128 RATE=$rate SEED=$seed 
	 mv leases/*_prl*  "./leases/128_llt_entries/128blocks_128ways_PRL_medium/"
	# 	mv leases/*_c-shel* "./leases/128_llt_entries/128blocks_128ways_C-SHEL_medium/"
	 	mv leases/*_shel* "./leases/128_llt_entries/128blocks_128ways_SHEL_medium/"
	 	mv leases/*_clam* "./leases/128_llt_entries/128blocks_128ways_CLAM_medium/"
#	make run_all_large CAPACITY=128 RATE=$rate SEED=$seed 
#	mv leases/*_prl*  "./leases/128_llt_entries/128blocks_128ways_PRL_large/"
#	 	mv leases/*_c-shel* "./leases/128_llt_entries/128blocks_128ways_C-SHEL_large/"
#	 	mv leases/*_shel* "./leases/128_llt_entries/128blocks_128ways_SHEL_large/"
#	 	mv leases/*_clam* "./leases/128_llt_entries/128blocks_128ways_CLAM_large/"
#make run_all_extra_large CAPACITY=128 RATE=$rate SEED=$seed 
#mv leases/*_c_shel* "./leases/128_llt_entries/128blocks_128ways_C-SHEL_extra_large/"
#mv leases/*_shel* "./leases/128_llt_entries/128blocks_128ways_SHEL_extra_large/"
#mv leases/*_clam* "./leases/128_llt_entries/128blocks_128ways_CLAM_extra_large/"
#mv leases/*_prl*  "./leases/128_llt_entries/128blocks_128ways_PRL_extra_large/"

fi