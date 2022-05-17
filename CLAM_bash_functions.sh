#!/bin/bash
function matlab_path_setup { 
	path_start=$CLAM_path
	
	path1="$path_start/MATLAB_data_visualizations/"
	matlab -nodesktop -r "r=genpath('$path1');addpath(r);savepath;quit"
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
	        * ) return 0;;
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

	./run.sh -m $multi_level -r $rate -s $seed -l $llt_size -w $ways;
	if [[ "$multi_level" == "yes" ]]; then
	./post.sh 128 512 512 
	else 
	./post.sh 128 128 128 
	fi
}
function plot_cache_statistics {
	if [ "$#" -eq 2 ]; then
		matlab -nodesktop -r "plot_cache_summary "$1" "$2"; quit";
	elif [ "$#" -eq 1 ]; then
		matlab -nodesktop -r "plot_cache_summary "$1" "$2"; quit";
	else
		matlab -nodesktop -r "plot_cache_summary; quit";
	fi
}
function generate_cache_spectrums {

	if [ "$#" -eq 4 ]; then 
		matlab -nodesktop -r "plot_tracking_results('"$1"','"$2"','"$3"',"$4"); quit"
	elif [ "$#" -eq 3 ]; then
		matlab -nodesktop -r "plot_tracking_results  "$1" "$2" "$3"; quit"
	elif [ "$#" -eq 2 ]; then
		matlab -nodesktop -r "plot_tracking_results  "$1" "$2"; quit"
	elif [ "$#" -eq 1 ]; then
		matlab -nodesktop -r "plot_tracking_results  "$1"; quit"
	else
		matlab -nodesktop -r "plot_tracking_results; quit";
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

function make_proxy {
	path_start=$CLAM_path
	if [[ "$1" == "multi-level" ]]; then
		(cd "$path_start/software/fpga_proxy" && make multi_level);
	else
		(cd "$path_start/software/fpga_proxy" && make);
	fi
}
function open_plru {
	path_start=$CLAM_path

	(cd $path_start/hardware/top/system_fa_plru_perfected/project
		/opt/intelFPGA_lite/18.1/quartus/bin/quartus --64bit *.qpf);
}
function open_lease {
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_plru_perfected/project
		/opt/intelFPGA_lite/18.1/quartus/bin/quartus --64bit *.qpf);
}
function open_lease_scope {
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_dynamic_lease_perfected/project
		/opt/intelFPGA_lite/18.1/quartus/bin/quartus --64bit *.qpf);
}


function open_lease_scope_multi_level {
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_dynamic_lease_multi_level/project
		/opt/intelFPGA_lite/18.1/quartus/bin/quartus --64bit *.qpf);
}


function open_plru_multi_level {
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_PLRU_multi_level/project
		/opt/intelFPGA_lite/18.1/quartus/bin/quartus --64bit *.qpf);
}
make_benchmarks (){
shopt -s nocasematch
(for i in *; do 

	if [ -d "$i" ]; then  
		cd  "$i" 

		make scope -s opt_level=O3 >/dev/null &
		cd ..; 
	fi
	
done)
shopt -u nocasematch
}

make_run_all_script () 
{ 
    variant=$(pwd |sed -n 's/.*\/\([0-9A-Za-z_]*\)/\1/p');
    script_name=run_all_"$variant".pss;
    file_path=../../fpga_proxy/scripts/;
    rm -f "$file_path"/"$script_name";
    for i in *;
    do
        if [[ "$variant" == "SHEL"* || "$variant" == "C-SHEL"* ]]; then
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" \
            	&& "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin"  ]]; then
			    echo RUN ../benchmarks/"$variant"/"$i"/program >> "$file_path"/"$script_name";
            fi;
        else
            	echo RUN ../benchmarks/"$variant"/"$i"/program >> "$file_path"/"$script_name";
        fi;
    done

}


make_track_all_script () 
{ 
    variant=$(pwd |sed -n 's/.*\/\([0-9A-Za-z_]*\)/\1/p');
    script_name=track_all_"$variant".pss;
    file_path=../../fpga_proxy/scripts/;
    rm -f "$file_path"/"$script_name";
    for i in *;
    do
        if [[ "$variant" == "SHEL"* || "$variant" == "C-SHEL"* ]]; then
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" \
            	&& "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin" ]]; then
                echo TRACK ../benchmarks/"$variant"/"$i"/program $1>> "$file_path"/"$script_name";
            fi;
        else
            	echo TRACK ../benchmarks/"$variant"/"$i"/program $1>> "$file_path"/"$script_name";
        fi;
    done

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


compile_lease_scope (){
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_dynamic_lease_perfected/project
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_map --read_settings_files=on --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_fit --read_settings_files=off --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_asm --read_settings_files=off --write_settings_files=off top -c top)
}

compile_plru (){
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_plru_perfected/project
	
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_map --read_settings_files=on --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_fit --read_settings_files=off --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_asm --read_settings_files=off --write_settings_files=off top -c top)
}




compile_lease_scope_multi_level (){
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_dynamic_lease_multi_level/project
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_map --read_settings_files=on --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_fit --read_settings_files=off --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_asm --read_settings_files=off --write_settings_files=off top -c top)
}

compile_plru_multi_level (){
	path_start=$CLAM_path
	(cd $path_start/hardware/top/system_fa_PLRU_multi_level/project
	
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_map --read_settings_files=on --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_fit --read_settings_files=off --write_settings_files=off top -c top
	/opt/intelFPGA_lite/18.1/quartus/bin/quartus_asm --read_settings_files=off --write_settings_files=off top -c top)
}
