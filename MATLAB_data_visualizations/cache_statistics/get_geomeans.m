% initialize workspace
close all; clearvars; clc;
addpath("./src");
% user selections
% -------------------------------------------------------------------------

base_path=[getenv('HOME'),'/Documents/SHEL/'];
file_path=[base_path,'software/fpga_proxy/results/cache/results.txt'];
base_save_path=[base_path,'/MATLAB_data_visualizations/'];
single_scope_benchmarks=["atax" "bicg" "cholesky" "doitgen" "floyd-warshall" "gemm" "gesummv" "gramschmidt" "jacobi-1d" "nussinov" "seidel-2d" "symm" "syr2k" "syrk" "trisolv" "trmm"];
cyclic_benchmarks=["jacobi-2d","lu","ludcmp","heat-3d","adi"];
cyclic_or_single_scope_benchmarks=[single_scope_benchmarks,cyclic_benchmarks];
% extract data
[data,filenames,policies] = extract_data(file_path);
%get benchmark names
for i=1:length(filenames)
	benchmarks(i)=regexp(filenames{i},"/benchmarks/.*\/(.*)\/program",'tokens');
end
benchmarks=string(benchmarks);
benchmark_names=unique(benchmarks);

for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, transpose(benchmarks), benchmark_names(i));
end

for i = 1:length(benchmark_names)
    data_bm{i} = plru_norm(data_bm{i});
end

for i=1:length(data_bm)
sorted_benchmark=sortrows(data_bm{i},16);
PLRU_misses(i)=sorted_benchmark(1,17);
CLAM_misses(i)=sorted_benchmark(2,17);
PRL_misses(i)=sorted_benchmark(3,17);
SHEL_misses(i)=sorted_benchmark(4,17);
C_SHEL_misses(i)=sorted_benchmark(5,17);
end

plru_geomean=geomean(PLRU_misses);
prl_geomean=geomean(PRL_misses);
clam_geomean=geomean(CLAM_misses);
C_shel_geomean_cyclic=geomean(C_SHEL_misses(ismember(benchmark_names,cyclic_benchmarks)));
plru_geomean_cyclic=geomean(PLRU_misses(ismember(benchmark_names,cyclic_benchmarks)));
shel_geomean_cyclic=geomean(SHEL_misses(ismember(benchmark_names,cyclic_benchmarks)));
shel_geomean=geomean(SHEL_misses(~ismember(benchmark_names,single_scope_benchmarks)));
plru_geomean_multi_scope=geomean(PLRU_misses(~ismember(benchmark_names,single_scope_benchmarks)));
prl_geomean_cyclic=geomean(PRL_misses(ismember(benchmark_names,cyclic_benchmarks)));
prl_multi_scope_geomean=geomean(PRL_misses(~ismember(benchmark_names,single_scope_benchmarks)));
clam_multi_scope_geomean=geomean(CLAM_misses(~ismember(benchmark_names,single_scope_benchmarks)));
plru_geomean_non_cyclic_multi_scope=geomean(PLRU_misses(~ismember(benchmark_names,cyclic_or_single_scope_benchmarks)));
plru_geomean_single_scope=geomean(PLRU_misses(ismember(benchmark_names,cyclic_or_single_scope_benchmarks)));
shel_geomean_non_cyclic=geomean(SHEL_misses(~ismember(benchmark_names,cyclic_or_single_scope_benchmarks)));
prl_single_scope_geomean=geomean(PRL_misses(ismember(benchmark_names,single_scope_benchmarks)));
clam_single_scope_geomean=geomean(CLAM_misses(ismember(benchmark_names,single_scope_benchmarks)));

geomean_diff_cshel_cyc=(plru_geomean_cyclic-C_shel_geomean_cyclic)/plru_geomean_cyclic*100;
geomean_diff_shel_cyc=(plru_geomean_cyclic-shel_geomean_cyclic)/plru_geomean_cyclic*100;
geomean_diff_prl_cyc=(plru_geomean_cyclic-prl_geomean_cyclic)/plru_geomean_cyclic*100;
geomean_diff_prl_multi_scope=(plru_geomean_multi_scope-prl_multi_scope_geomean)/plru_geomean_multi_scope*100;
geomean_diff_clam_multi_scope=(plru_geomean_multi_scope-clam_multi_scope_geomean)/plru_geomean_multi_scope*100;
geomean_diff_prl_single_scope=(plru_geomean_single_scope-prl_single_scope_geomean)/plru_geomean_single_scope*100;
geomean_diff_clam_single_scope=(plru_geomean_single_scope-clam_single_scope_geomean)/plru_geomean_single_scope*100;
geomean_diff_shel_multi_scope=(plru_geomean_multi_scope-shel_geomean)/plru_geomean_multi_scope*100;
geomean_diff_prl=(plru_geomean-prl_geomean)/plru_geomean*100;
geomean_diff_clam=(plru_geomean-clam_geomean)/plru_geomean*100;
geomean_diff_shel_noncyc=(plru_geomean_non_cyclic_multi_scope-shel_geomean_non_cyclic)/plru_geomean_non_cyclic_multi_scope*100;