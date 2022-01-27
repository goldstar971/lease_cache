make_benchmarks (){
#compile in parallel in a subshell
(variant=$(pwd |sed -n 's/.*\/\([0-9A-Za-z_]*\)/\1/p');
for i in *; do 
	#only compile multi scope benchmarks for shel or C-SHEL
	if [[ "$variant" == "SHEL"* || "$variant" == "C-SHEL"* ]]; then
            if [[ -d "$i" && "$i" != "atax" && "$i" != "bicg" && "$i" != "cholesky" && "$i" != "floyd-warshall" && "$i" != "gemm" && "$i" != "gesummv" && "$i" != "gramschmidt" && "$i" != "jacobi-1d" && "$i" != "nussinov" && "$i" != "seidel-2d" && "$i" != "symm" && "$i" != "syr2k" && "$i" != "syrk" && "$i" != "trisolv" && "$i" != "trmm" && "$i" != "doitgen" && "$i" != "durbin" ]]; then
                cd  "$i" 
				rm program*
				make scope -s opt_level=O3 >/dev/null&
				cd .. 
            fi;
   elif [[ -d "$i" ]]; then
            cd  "$i" 
			rm program*
			make scope -s  opt_level=O3>/dev/null&
			cd .. 
   fi;
done)
}

(cd CLAM/ && make_benchmarks    ) 
(cd SHEL/ && make_benchmarks   ) 
(cd C-SHEL/ && make_benchmarks   ) 
(cd PRL/ && make_benchmarks   ) 
(cd CLAM_medium/ && make_benchmarks    ) 
(cd SHEL_medium/ && make_benchmarks   ) 
(cd C-SHEL_medium/ && make_benchmarks   ) 
(cd PRL_medium/ && make_benchmarks   ) 
(cd CLAM_large/ && make_benchmarks    ) 
(cd SHEL_large/ && make_benchmarks   ) 
(cd C-SHEL_large/ && make_benchmarks   ) 
(cd PRL_large/ && make_benchmarks   ) 
(cd CLAM_extra_large/ && make_benchmarks   ) 
(cd SHEL_extra_large/ && make_benchmarks  ) 
(cd C-SHEL_extra_large/ && make_benchmarks  ) 
(cd PRL_extra_large/ && make_benchmarks  ) 

