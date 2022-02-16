#!/bin/bash


# raw lease dump file directories
if [[ "$1" == "" || "$2" == "" || "$3" == "" ]]; then
	echo "must give lease lookup table size, cache size, and number of ways";
	exit 1;
fi

FILES=leases/"$1"_llt_entries/"$2"blocks/"$3"ways/**/*.c
OUT=./output

# process
for f in $FILES
do
	lease_dir="$(basename "$(dirname -- "$f")")"
	filename=$(basename "$f") 
	benchmark_name=$(sed 's/_[^_]*_lease.*//'<<< "$filename")
	cp "$f" ../benchmarks/$lease_dir/$benchmark_name/lease_scope.c
done


make_benchmarks (){
#compile in parallel in a subshell
(variant=$(pwd |sed -n 's/.*\/\([0-9A-Za-z_]*\)/\1/p');
for i in *; do 
	#only compile multi scope benchmarks for shel or C-SHEL
	if [[ "$variant" == "SHEL"* || "$variant" == "C-SHEL"* ]]; then
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" && "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin" ]]; then
                cd  "$i" 

				make scope -s opt_level=O3 >/dev/null&
				cd .. 
            fi;
   elif [[ -d "$i" ]]; then
            cd  "$i" 
			make scope -s  opt_level=O3>/dev/null&
			cd .. 
   fi;
done)
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
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" && "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin" ]]; then
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
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" && "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin" ]]; then
                echo TRACK ../benchmarks/"$variant"/"$i"/program >> "$file_path"/"$script_name";
			fi;
        else
                echo TRACK ../benchmarks/"$variant"/"$i"/program >> "$file_path"/"$script_name";
		fi;
    done
}

make_run_all_plru_script () 
{ 
	variant=$(pwd |sed -n 's/.*\/\([0-9A-Za-z_]*\)/\1/p');
	if [[ "$1" == "" ]]; then
		script_name=run_all_plru.pss
		command_begin="RUN ../benchmarks/SHEL/"
	else
		script_name=run_all_plru_"$1".pss;
		command_begin="RUN ../benchmarks/SHEL_""$1""/"
	fi;
    file_path=../../fpga_proxy/scripts/;
    rm -f "$file_path"/"$script_name";
    for i in *;
    do
	            echo "$command_begin""$i""/program" >> "$file_path"/"$script_name";
    done
}


(cd ../benchmarks/SHEL/ && make_run_all_plru_script)
(cd ../benchmarks/SHEL_medium/ && make_run_all_plru_script medium)
(cd ../benchmarks/SHEL_large/ && make_run_all_plru_script large)
(cd ../benchmarks/CLAM/ && make_benchmarks    && make_run_all_script && make_track_all_script)
(cd ../benchmarks/SHEL/ && make_benchmarks   && make_run_all_script && make_track_all_script)
(cd ../benchmarks/C-SHEL/ && make_benchmarks   && make_run_all_script && make_track_all_script)
(cd ../benchmarks/PRL/ && make_benchmarks   && make_run_all_script && make_track_all_script)
(cd ../benchmarks/CLAM_medium/ && make_benchmarks    && make_run_all_script && make_track_all_script) 
(cd ../benchmarks/SHEL_medium/ && make_benchmarks   && make_run_all_script && make_track_all_script)
(cd ../benchmarks/C-SHEL_medium/ && make_benchmarks   && make_run_all_script && make_track_all_script)
(cd ../benchmarks/PRL_medium/ && make_benchmarks   && make_run_all_script && make_track_all_script)
(cd ../benchmarks/CLAM_large/ && make_benchmarks    && make_run_all_script && make_track_all_script) 
(cd ../benchmarks/SHEL_large/ && make_benchmarks   && make_run_all_script && make_track_all_script) 
(cd ../benchmarks/C-SHEL_large/ && make_benchmarks   && make_run_all_script && make_track_all_script) 
(cd ../benchmarks/PRL_large/ && make_benchmarks   && make_run_all_script && make_track_all_script)
#(cd ../benchmarks/CLAM_extra_large/ && make_benchmarks   && make_run_all_script && make_track_all_script) 
#(cd ../benchmarks/SHEL_extra_large/ && make_benchmarks  && make_run_all_script && make_track_all_script) 
#(cd ../benchmarks/C-SHEL_extra_large/ && make_benchmarks  && make_run_all_script && make_track_all_script) 
#(cd ../benchmarks/PRL_extra_large/ && make_benchmarks  && make_run_all_script && make_track_all_script)