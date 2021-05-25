% initialize workspace
close all; clearvars; clc;
addpath("./src");
% user selections
% -------------------------------------------------------------------------

base_path=[getenv('HOME'),'/Documents/SHEL/'];
file_path=[base_path,'software/fpga_proxy/results/cache/results.txt'];
base_save_path=[base_path,'/MATLAB_data_visualizations/'];
small_benchmarks=["jacobi-1d","trisolv","gesummv",'durbin'];
num_scope=["single_scope","multi_scope"];
single_scope_benchmarks=["atax" "bicg" "cholesky" "doitgen" "floyd-warshall" "gemm" "gesummv" "gramschmidt" "jacobi-1d" "nussinov" "seidel-2d" "symm" "syr2k" "syrk" "trisolv" "trmm"];

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

%normalize by plru
for i = 1:length(benchmark_names)
    data_bm{i} = plru_norm(data_bm{i});
end
%rearrange benchmarks so cross scoped RIs are on right and non cross scoped
%are on left
re_index=[1,2,4:1:11,13:1:17,19,23:1:30,3,12,18,20,21,22];
data_bm=data_bm(re_index);
benchmark_names=benchmark_names(re_index);
%delete PLRU data
data_bm=cellfun(@(x) x(x(:,16)>1,:),data_bm,'UniformOutput',false);


%remove benchmarks we don't care about
data_bm(ismember(benchmark_names,small_benchmarks))=[];
benchmark_names(ismember(benchmark_names,small_benchmarks))=[];

%split remaining benchmarks into single and multi scope benchmarks
data_bm_single_scope=data_bm(ismember(benchmark_names,single_scope_benchmarks));
benchmark_names_single=benchmark_names(ismember(benchmark_names,single_scope_benchmarks));
data_bm_single_scope=cellfun(@(x) x(x(:,16)<4,:),data_bm_single_scope,'UniformOutput',false);
data_bm_multi_scope=data_bm(~ismember(benchmark_names,single_scope_benchmarks));
benchmark_names_multi=benchmark_names(~ismember(benchmark_names,single_scope_benchmarks));

set(0,'DefaultFigureVisible','on')
for h=1:2
	for i=1:2
		if(i==1)
			if(h==1)
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_single_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,17)];
				end
			elseif(h==2)
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_single_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,18)];
				end
			else
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_single_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,19)];
				end
			end
		else
			if(h==1)
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_multi_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,17)];
				end
			elseif(h==2)
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_multi_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,18)];
				end
			else
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_multi_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,19)];
				end
			end
		end
	% graphic
		fig=figure(1);
		set(fig, 'Position',[0,0,1080,1920]);
		b=bar(transpose(bar_ydata));
		if(h==1)
			ylabel('Policy Miss Count Normalized to PLRU Misses');
		elseif(h==2)
			ylabel('Time of execution in Clock cycles normalized to PLRU clock cycles');
		else
			ylabel('Time of execution in Clock cycles normalized to PLRU clock cycles with miss penalty');
		end
		if(i==1)
			set(gca,'xticklabel',benchmark_names_single,'FontSize',14);
		else
			set(gca,'xticklabel',benchmark_names_multi,'FontSize',14);
		end
		xtickangle(gca,45);
		ylim([0,1.2]);
		xlim=get(gca,'xlim');
		hold on
		legend('AutoUpdate', 'Off')
		yline(1,'k--');
		xCnt = cell2mat(get(b,'XData')) + cell2mat(get(b,'XOffset'));
		
		for j=1:size(bar_ydata,2)
			for k=1:size(bar_ydata,1)
				if(bar_ydata(k,j)>max(ylim))
					r=text(xCnt(k,j),min(bar_ydata(k,j),1.2),strip(num2str(round(bar_ydata(k,j),3)),'left','0'),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12);
				end
			end
		end
		if(i==1)
			legend({'CLAM','PRL'},'Orientation','horizontal','FontSize',14);
		else
			legend({'CLAM','PRL','SHEL','C-SHEL',},'Orientation','horizontal','FontSize',14);
		end
		if(h==1)
			saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/benchmark_normalized_misses_',convertStringsToChars(num_scope(i)),'.png'])
		elseif(h==2)
			saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/benchmark_normalized_clock_cycles_',convertStringsToChars(num_scope(i)),'.png'])
		else
			saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/benchmark_normalized_clock_cycles_adjusted_',convertStringsToChars(num_scope(i)),'.png'])
		end
		close(fig)
	end
end
