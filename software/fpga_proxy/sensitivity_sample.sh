
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
make_sample_all_script () 
{ 
    variant=$(pwd |sed -n 's/.*\/\([0-9A-Za-z_]*\)/\1/p');
    script_name=sample_all_"$variant".pss;
    file_path=../../fpga_proxy/scripts/;
    rm -f "$file_path"/"$script_name";
    for i in *;
    do
        if [[ "$variant" == "SHEL"* || "$variant" == "C-SHEL"* ]]; then
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" \
            	&& "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin" ]]; then
                echo SAMPLE ../benchmarks/"$variant"/"$i"/program $1 $2>> "$file_path"/"$script_name";
            fi;
        else
            	echo SAMPLE ../benchmarks/"$variant"/"$i"/program $1 $2>> "$file_path"/"$script_name";
        fi;
    done

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

 read -p "multi_level? (y/n)" multi_level
 read -p "use lease cache for single level sampling? (y/n)" lease_cache
 goto_proxy

 if [ "$multi_level" == "y" ]; then 
    make multi_level
    program_plru_multi_level
else 
    make
    if [ "$lease_cache" == "y" ]; then
        program_lease_scope 
    else 
        program_plru
    fi
fi

sample_rates=( 64 128 256 512 1024 )
seeds=( 1 2 3 4 5 )
for seed in "${seeds[@]}"; do
    for rate in "${sample_rates[@]}"; do
	
	read -p  "seed is: $seed rate is $rate. Skip? (y/n)" skip

	if [ "$skip" == "y" ];  then
		continue
	fi

(cd ../benchmarks/SHEL/ && make_sample_all_script $rate $seed);
(cd ../benchmarks/CLAM/ && make_sample_all_script $rate $seed);
(cd ../benchmarks/SHEL_medium/ && make_sample_all_script $rate $seed);
(cd ../benchmarks/CLAM_medium/ && make_sample_all_script $rate $seed);
           
	success="n"
     while [ "$success" != "y" ]; do
           echo "please reset the fpga then press any key to continue"
           read -n 1
           run_proxy -c "SCRIPT sample_all_SHEL:SCRIPT sample_all_CLAM:SCRIPT sample_all_CLAM_medium:SCRIPT sample_all_SHEL_medium" 
			"$play_command" "$music_4" > /dev/null 2>&1 & 
	   	if [ "$?" == 0 ]; then
			success="y"
		else
			success="n"
		fi 
	done
done
done
