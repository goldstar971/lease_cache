rm -f leases/*_*_lease*
unset rate multi_level seed ways
unset OPTIND
#get options
while getopts "m:r:s:w:l:" option; do
	case "$option" in
        l ) llt_size="$OPTARG";;
        r ) rate="$OPTARG";;
        s ) seed="$OPTARG";;
        m ) multi_level="$OPTARG";;
       	w ) ways="$OPTARG";;
		* ) exit 1;;
    esac
done
#set defaults if not used
rate=${rate-256}
seed=${seed-1}
multi_level=${multi_level-no}
llt_size=${llt_size-128}
policies=( "CLAM" "SHEL" "C-SHEL" "PRL" )
sizes=( "" "_medium" "_large" )

make clam

if [[ "$multi_level" == "yes" ]]; then
	capacity=512
	ways=${ways-$capacity}
else 
	capacity=128
	ways=${ways-$capacity}
fi


for policy in "${policies[@]}"; do  
	for size in "${sizes[@]}"; do 
		potential_dir="./leases/""$llt_size""_llt_entries/""$capacity""blocks/""$ways""ways/""$policy$size"
		if [[ -d "./leases/"$llt_size"_llt_entries/"$capacity"blocks/"$ways"ways/"$policy$size"" ]]; then 
			:
		else 
			mkdir -p "./leases/"$llt_size"_llt_entries/"$capacity"blocks/"$ways"ways/"$policy$size""; 
		fi
		echo 
	done; 
done; 


if [[ "$multi_level" == "yes" ]]; then
	make run_all_small_multi_level CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
	 mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/PRL/"
	 	mv leases/*_c-shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/C-SHEL/"
	 	 mv leases/*_shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/SHEL/"
	 	 mv leases/*_clam* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/CLAM/"
	 make run_all_medium_multi_level CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
	  mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/PRL_medium/"
	  	 mv leases/*_c-shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/C-SHEL_medium/"
	  	 mv leases/*_shel_* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/SHEL_medium/"
	  	 mv leases/*_clam_* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/CLAM_medium/"
	 make run_all_large_multi_level CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
	 mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/PRL_large/"
		mv leases/*_c-shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/C-SHEL_large/"
	 	mv leases/*_shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/SHEL_large/"
	mv leases/*_clam* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/CLAM_large/"
#make run_all_extra_large_multi_level CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
#mv leases/*_c_shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/C-SHEL/"
#mv leases/*_shel* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/SHEL_extra_large/"
#mv leases/*_clam* "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/CLAM_extra_large/"
#mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/512blocks/"$ways"ways/PRL_extra_large/"



 else 
	ways=${ways-128}
	make run_all_small CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
	mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/PRL/"
		mv leases/*_c-shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/C-SHEL/"
		mv leases/*_shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/SHEL/"
		mv leases/*_clam* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/CLAM/"
#	 make run_all_medium CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
#	 mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/PRL_medium/"
#	 	mv leases/*_c-shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/C-SHEL_medium/"
#	 	mv leases/*_shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/SHEL_medium/"
#mv leases/*_clam* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/CLAM_medium/"
#	make run_all_large CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
#	 mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/PRL_large/"
#	  	mv leases/*_c-shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/C-SHEL_large/"
#	  	mv leases/*_shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/SHEL_large/"
#	  	mv leases/*_clam* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/CLAM_large/"
#make run_all_extra_large CAPACITY=$capacity RATE=$rate SEED=$seed WAYS=$ways
#mv leases/*_c_shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/C-SHEL_extra_large/"
#mv leases/*_shel* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/SHEL_extra_large/"
#mv leases/*_clam* "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/CLAM_extra_large/"
#mv leases/*_prl*  "./leases/"$llt_size"_llt_entries/128blocks/"$ways"ways/PRL_extra_large/"

fi
