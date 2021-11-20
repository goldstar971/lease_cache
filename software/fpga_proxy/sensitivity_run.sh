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
sample_rates=( 64 128 256 512 1024 )
seeds=( 1 2 3 4 5 )

goto_proxy
mkdir -p ./results/cache/sensitivity_results
read -p "program device? (y/n)" response 
if [ "$response" == "y" ]; then
program_lease_scope
fi

#Clear non plru results
  head -n 30 results/cache/results.txt > temp.txt
 cat temp.txt >results/cache/results.txt 
 head -n 30 results/cache/results_medium.txt > temp.txt
 cat temp.txt >results/cache/results_medium.txt
 rm temp.txt  

read -p "clear sensitivity results? (y/n): " response
read -p "medium data set size? (y/n): " response2

if [ "$response" == "y" ]; then 
    if [ "$response2" == "y" ]; then 
         echo "seed,rate,policy,dataset_size,benchmark,cache0_hits,cache0_misses,cache0_writebacks,clock_cycles,cache0_ID,cache1_hits,\
cache1_misses,cache1_writebacks,cache1_expired_leases,cache1_multi_expired,cache1_default_renewals,cache1_default_misses,\
cache1_random_evicts,cache1_ID"> results/cache/sensitivity_results/results_medium_sensitivity.txt 
sed 's/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program/0,0,\1,\3,\4/' results/cache/results_medium.txt \
 >>results/cache/sensitivity_results/results_medium_sensitivity.txt
    else
        echo "seed,rate,policy,dataset_size,benchmark,cache0_hits,cache0_misses,cache0_writebacks,clock_cycles,cache0_ID,cache1_hits,\
cache1_misses,cache1_writebacks,cache1_expired_leases,cache1_multi_expired,cache1_default_renewals,cache1_default_misses,\
cache1_random_evicts,cache1_ID"> results/cache/sensitivity_results/results_sensitivity.txt 
sed 's/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program/0,0,\1,\3,\4/' results/cache/results.txt \
| sed "s/,,/,small,/" >>results/cache/sensitivity_results/results_sensitivity.txt
fi

echo "seed,rate,cache_size,Policy,Dataset_Size,benchmark_name,predicted_misses" > results/cache/sensitivity_results/predicted_misses.txt
fi

 music_4='/home/matthew/Music/Unknown/magia_live.mp3'

play_command='audacious'

 for seed in "${seeds[@]}"; do
     echo "seed is: $seed";
     for rate in "${sample_rates[@]}"; do
            echo "rate is: $rate";
            # if [[   $seed -ne 1 || ( $seed -eq 1 && $rate -le 64 ) ]];  then
            #      continue
            #  fi
         (gen_leases -m no -r $rate -s $seed)
         #signal that script is awaiting user push of reset button
         "$play_command" "$music_4" > /dev/null 2>&1 & 

           echo "please reset the fpga then press any key to continue"
           read -n 1;
           if [ "$response2" == "y" ]; then 
                       run_proxy -c "SCRIPT run_all_C-SHEL_medium";#:SCRIPT run_all_SHEL_medium:SCRIPT run_all_PRL_medium";
            tail -n +31 results/cache/results_medium.txt |sed "s/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program/$seed,$rate,\1,\3,\4/"\
          >> results/cache/sensitivity_results/results_medium_sensitivity.txt 
          head -n 30 results/cache/results_medium.txt > temp.txt
        cat temp.txt >results/cache/results_medium.txt
          else
            run_proxy -c "SCRIPT run_all_C-SHEL";#:SCRIPT run_all_SHEL:SCRIPT run_all_PRL";
             tail -n +31 results/cache/results.txt |sed "s/^[^,]*\/\([0-9a-zA-Z\-]*\)\(_\([0-9a-zA-Z]*\)\)*\/\(.*\)\/program/$seed,$rate,\1,\3,\4/" | sed "s/,,/,small,/" \
>>results/cache/sensitivity_results/results_sensitivity.txt
   head -n 30 results/cache/results.txt > temp.txt
        cat temp.txt >results/cache/results.txt 
          fi
        rm temp.txt  
        grep -rnw "predicted miss" /home/matthew/Documents/Thesis_stuff/software/CLAM/leases/**/*CLAM* \
     | sed 's/.*entries\/\([0-9]*\).*ways_\([A-Za-z\-]*\)_*\([a-zA-Z]*\|\)\/\([0-9A-Za-z\-]*\).*:\s*\([0-9]*\)$/\1,\2,\3,\4,\5/' \
     | sed 's/,,/,small,/'|sed "s/\(.*\)/$seed,$rate,\1/" >>  results/cache/sensitivity_results/predicted_misses.txt
    done
 done
