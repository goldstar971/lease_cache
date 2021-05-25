clear
base_path=[getenv('HOME'),'/Documents/Thesis_stuff/'];
base_data_path=[base_path,'software/fpga_proxy/results/sample/'];
base_path_lease_refs=[base_path,'software/benchmarks/'];
benchmarks=["poly_small_float/atax","poly_small_float/doitgen" ...
	,"poly_small_float/durbin","poly_small_float/mvt", ...
	"poly_small_float/trisolv","poly_small_static/nussinov"];
for i=1:length(benchmarks)
	benchmark_type_name=convertStringsToChars(benchmarks(i));
	temp=importdata([base_path_lease_refs,benchmark_type_name,'/lease.c']);
	if(contains(benchmarks(i),'static'))
		temp=temp(7:19);
	else
		temp=temp(22:34);
	end
	ref_temp=[];
	for j=1:length(temp)
		temp_split=split(temp{j},',');
		if(length(temp_split)==11)
			ref_temp=[ref_temp;temp_split(1:10)];
		else
			ref_temp=[ref_temp;temp_split(1:8)];
		end
	end
	for j=1:length(ref_temp)
		
		lease_refs{j,i}=ref_temp{j}(end-7:end);
	end
end
ref_in_llt=zeros(length(benchmarks),1);
benchmark_refs=cell(length(benchmarks),1);
percent_refs_in_llt=zeros(length(benchmarks),1);
for i=1:length(benchmarks)
	benchmark_type_name=convertStringsToChars(benchmarks(i));
	ref_struc=importdata([base_data_path,benchmark_type_name,'.txt']);
	benchmark_refs{i}=ref_struc.textdata(:,1);
	current_refs=benchmark_refs{i};
	current_lease_refs=lease_refs(:,i);
	for j=1:length(current_refs)
		ref_in_llt(i)=ref_in_llt(i)+ismember(current_refs{j},lease_refs(:,i));
	end
	percent_refs_in_llt(i)=ref_in_llt(i)/length(benchmark_refs{i});
end
