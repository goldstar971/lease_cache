



program_plru (){
    cwd=${PWD}
    if [[ "$cwd" =~ "SHEL" && "$cwd" != *"Thesis_stuff"* ]]; then
        path_start="$HOME/Documents/SHEL";
    else
        path_start="$HOME/Documents/Thesis_stuff";
    fi
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

run_proxy () 
{ 
    cwd=${PWD};
    if [[ "$cwd" =~ "SHEL" && "$cwd" != *"Thesis_stuff"* ]]; then
        path_start="$HOME/Documents/SHEL";
    else
        path_start="$HOME/Documents/Thesis_stuff";
    fi;
    goto_proxy;
    if [[ "$#" == 2 ]]; then
        ./bin/main $1 "$2";
    else
        if [[ "$#" == 0 ]]; then
            ./bin/main;
        fi;
    fi
}

goto_proxy () 
{ 
    cwd=${PWD};
    if [[ "$cwd" =~ "SHEL" && "$cwd" != *"Thesis_stuff"* ]]; then
        path_start="$HOME/Documents/SHEL";
    else
        path_start="$HOME/Documents/Thesis_stuff";
    fi;
    cd "$path_start/software/fpga_proxy"
}
 music_4='/home/matthew/Music/Unknown/magia_live.mp3'

play_command='audacious'
program_plru
sample_rates=( 64 128 256 512 1024 )
seeds=( 1 2 3 4 5 )
for seed in "${seeds[@]}"; do
    for rate in "${sample_rates[@]}"; do
(cd ../benchmarks/SHEL/ && make_sample_all_script $rate $seed);
(cd ../benchmarks/CLAM/ && make_sample_all_script $rate $seed);
(cd ../benchmarks/SHEL_medium/ && make_sample_all_script $rate $seed);
(cd ../benchmarks/CLAM_medium/ && make_sample_all_script $rate $seed);
           

"$play_command" "$music_4" > /dev/null 2>&1 & 

               echo "please reset the fpga then press any key to continue\n"
          read -n 1;
        run_proxy -c "SCRIPT sample_all_SHEL:SCRIPT sample_all_CLAM:SCRIPT sample_all_CLAM_medium:SCRIPT sample_all_SHEL_medium";
            echo "rate is: $rate"
    done
    echo "seed is: $seed";
done