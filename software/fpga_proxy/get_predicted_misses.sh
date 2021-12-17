function goto_proxy {
    path_start=$CLAM_path
    cd "$path_start/software/fpga_proxy"
}
function gen_leases {
    unset rate multi_level seed llt_size ways
	local OPTIND
#get options
    while getopts "m:r:s:l:w:" option; do
        case "$option" in
            r ) rate="$OPTARG";;
            s ) seed="$OPTARG";;
            m ) multi_level="$OPTARG";;
            l ) llt_size="$OPTARG";;
            w ) ways="$OPTARG";;
            * ) exit 1;;
        esac
    done
    #set defaults if not used
    rate=${rate-256}
    seed=${seed-1}
    multi_level=${multi_level-no}
    if [[ "$multi_level" == "yes" ]]; then
        ways=${ways-512};
    else
        ways=${ways-128};
    fi
    llt_size=${llt_size-128}

     path_start=$CLAM_path
    
    cd "$path_start/software/CLAM";
    ./run.sh -m $multi_level -r $rate -s $seed -l $llt_size -w $ways >/dev/null 2>&1 ;
}

sample_rates=( 64 128 256 512 1024 )
seeds=( 1 2 3 4 5 )
goto_proxy
mkdir -p ./results/cache/sensitivity_results
read  -p "Multi_level? (y/n)" multi_level 
read  -p "Clear_predicted_misses? (y/n)" clear
if [ "$clear" == "y" ]; then  
    echo "seed,rate,num_ways,cache_size,policy,dataset_Size,benchmark_name,predicted_misses" > results/cache/sensitivity_results/predicted_misses.txt
fi
if [ "$multi_level" == "y" ]; then
	cache_level="_multi_level"
    num_blocks="512"
else
	cache_level=""
    num_blocks="128"
fi
 for seed in "${seeds[@]}"; do
     for rate in "${sample_rates[@]}"; do
     	 if [ "$multi_level" == "y" ]; then 
            (gen_leases -m yes -r $rate -s $seed)
        else 
             (gen_leases -m no -r $rate -s $seed)
        fi

		grep -rnw "predicted miss" $path_start/software/CLAM/leases/**/"$num_blocks"blocks/**/*CLAM* | sed "/large/d" \
        | sed 's/^.*_llt_entries\/\([0-9]\+\)blocks\/\([0-9]\+\)ways\/\([A-Z\-]\+\)_*\([a-z]*\)\/\([a-z0-9\-]\+\)_.*_leases.*: \([0-9]\+\)$/\2,\1,\3,\4,\5,\6/' \
        | sed 's/,,/,small,/'|sed "s/\(.*\)/$seed,$rate,\1/" >>  results/cache/sensitivity_results/predicted_misses.txt
    done
done
