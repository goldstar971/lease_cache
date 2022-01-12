program_lease_scope_multi_level (){
    path_start=$CLAM_path
    (cd "$path_start/hardware/top/system_fa_dynamic_lease_multi_level/project/output_files/"
    /opt/intelFPGA_lite/18.1/quartus/bin/quartus_pgm -c USB-BlasterII -m JTAG -o "P;top.sof")
}



program_plru_multi_level (){
    path_start=$CLAM_path
    (cd "$path_start/hardware/top/system_fa_PLRU_multi_level/project/output_files/"
    /opt/intelFPGA_lite/18.1/quartus/bin/quartus_pgm -c USB-BlasterII -m JTAG -o "P;top.sof")
}




program_lease_scope (){
    path_start=$CLAM_path
    (cd "$path_start/hardware/top/system_fa_dynamic_lease_perfected/project/output_files/"
    /opt/intelFPGA_lite/18.1/quartus/bin/quartus_pgm -c USB-BlasterII -m JTAG -o "P;top.sof")
}




program_plru (){
    path_start=$CLAM_path
    (cd "$path_start/hardware/top/system_fa_plru_perfected/project/output_files/"
    /opt/intelFPGA_lite/18.1/quartus/bin/quartus_pgm -c USB-BlasterII -m JTAG -o "P;top.sof")
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
    if [[ "$multi_level" == "yes" ]]; then
    ./post 128 512 512  >/dev/null 2>&1;
    else 
    ./post 128 128 128 >/dev/null 2>&1;
    fi
}

function goto_proxy {
    path_start=$CLAM_path
    cd "$path_start/software/fpga_proxy"
}
function run_proxy {
    path_start=$CLAM_path
    goto_proxy;
    if [[ "$#" == 2 ]]; then
        ./bin/main $1 "$2";
    elif [[ "$#" == 0 ]]; then
        ./bin/main;
    fi
}
trap 'cat saved_results.txt >results/cache/results"$data_size""$cache_level".txt && rm saved_results.txt && exit 0' SIGINT




sample_rates=( 64 128 256 512 1024 )
seeds=( 1 2 3 4 5 )

goto_proxy
mkdir -p ./results/cache/sensitivity_results
read  -p "Multi_level? (y/n)" multi_level 
 read -p "program device? (y/n)" response 

 if [ "$response" == "y" ]; then
     if [ "$multi_level" == "y" ]; then 
        make multi_level
         program_lease_scope_multi_level
     else 
        make
         program_lease_scope
     fi
 fi

 

read -p "medium data set size? (y/n): " response2

if [ "$response2" == "y" ]; then 
    data_size="_medium"
else 
    data_size=""
fi 

if [ "$multi_level" == "y" ]; then
	cache_level="_multi_level"
else
	cache_level=""
fi
 rm -f temp.txt  
 cat results/cache/results"$data_size""$cache_level".txt > saved_results.txt 
 head -n 30 results/cache/results"$data_size""$cache_level".txt > temp.txt
 cat temp.txt >results/cache/results"$data_size""$cache_level.txt"
 rm temp.txt  



read -p "run SHEL? (y/n)"  SHEL 
read -p "Run PRL? (y/n)" PRL
read -p "Run C-SHEL? (y/n)" CSHEL

run_command="run_proxy -c \"SCRIPT run_all_CLAM""$data_size"
if [ "$CSHEL" == "y" ]; then 
    run_command="$run_command"":SCRIPT run_all_C-SHEL""$data_size"
fi 

if [ "$PRL" == "y" ]; then 
    run_command="$run_command"":SCRIPT run_all_PRL""$data_size"
fi 

if [ "$SHEL" == "y" ]; then 
    run_command="$run_command"":SCRIPT run_all_SHEL""$data_size"
fi 

run_command="$run_command""\"" 

read -p "clear sensitivity results? (y/n): " response


if [ "$response" == "y" ]; then 
    if [ "$multi_level" == "y" ]; then 
        echo "seed,rate,policy,dataset_size,benchmark,cache0_hits,cache0_misses,cache0_writebacks,clock_cycles,cache0_ID,cache1_hits,\
cache1_misses,cache1_writebacks,cache1_ID,cacheL2_hits,cacheL2_misses,cacheL2_writebacks,cacheL2_expired_leases,cacheL2_multi_expired,\
cacheL2_default_renewals,cacheL2_default_misses,\
cacheL2_random_evicts,cacheL2_ID"> results/cache/sensitivity_results/results"$data_size"_sensitivity_multi_level.txt 
sed 's/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program/0,0,\1,\3,\4/' results/cache/results"$data_size"_multi_level.txt \
 |sed 's/,,/,small,/'>>results/cache/sensitivity_results/results"$data_size"_sensitivity_multi_level.txt
    else
         echo "seed,rate,policy,dataset_size,benchmark,cache0_hits,cache0_misses,cache0_writebacks,clock_cycles,cache0_ID,cache1_hits,\
cache1_misses,cache1_writebacks,cache1_expired_leases,cache1_multi_expired,cache1_default_renewals,cache1_default_misses,\
cache1_random_evicts,cache1_ID"> results/cache/sensitivity_results/results"$data_size"_sensitivity.txt 
sed 's/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program/0,0,\1,\3,\4/' results/cache/results"$data_size".txt \
|sed 's/,,/,small,/' >>results/cache/sensitivity_results/results"$data_size"_sensitivity.txt
    fi
fi


 for seed in "${seeds[@]}"; do
     for rate in "${sample_rates[@]}"; do
	
	read -p  "seed is: $seed rate is $rate. Type \"y\" to skip else press any key." skip

	if [ "$skip" == "y" ];  then
		continue
	fi
         if [ "$multi_level" == "y" ]; then 
            (gen_leases -m yes -r $rate -s $seed)
        else 
             (gen_leases -m no -r $rate -s $seed)
        fi
         #signal that script is awaiting user push of reset button
            success="n" 
        while [ "$success" != "y" ]; do
           echo "please reset the fpga then press any key to continue"
           read -n 1;
           eval "$run_command"
           read -p "succeded (y/n)" success
       done
           tail -n +31 results/cache/results"$data_size""$cache_level".txt \
            |sed "s/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program,\([^,]*,[^,]*,[^,]*\),[^,]*,\(.*\)/$seed,$rate,\1,\3,\4,\5,5,\6/"\
            |sed 's/,,/,small,/' >> results/cache/sensitivity_results/results"$data_size"_sensitivity"$cache_level".txt 
          head -n 30 results/cache/results"$data_size""$cache_level".txt > temp.txt
        cat temp.txt >results/cache/results"$data_size""$cache_level".txt
        rm temp.txt    
 done
done
#restore run results.
cat saved_results.txt >results/cache/results""$data_size""$cache_level"".txt
rm saved_results.txt
