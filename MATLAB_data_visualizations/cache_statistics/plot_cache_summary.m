% initialize workspace
close all; clearvars; clc;
addpath("./src");
% user selections
% -------------------------------------------------------------------------

base_path=[getenv('HOME'),'/Documents/Thesis_stuff/'];
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

%rearrange benchmarks so cross scoped RIs are on right and non cross scoped
%are on left
re_index=[1,2,4:1:11,13:1:17,19,23:1:30,3,12,18,20,21,22];
data_bm=data_bm(re_index);
benchmark_names=benchmark_names(re_index);

%normalize by plru
for i = 1:length(benchmark_names)
    data_bm{i} = plru_norm(data_bm{i});
end


%seperate PLRU data
PLRU_data=cellfun(@(x) x(x(:,16)<2,:),data_bm,'UniformOutput',false);
data_bm=cellfun(@(x) x(x(:,16)>1,:),data_bm,'UniformOutput',false);




%remove benchmarks we don't care about
data_bm(ismember(benchmark_names,small_benchmarks))=[];
PLRU_data(ismember(benchmark_names,small_benchmarks))=[];
benchmark_names(ismember(benchmark_names,small_benchmarks))=[];



%split remaining benchmarks into single and multi scope benchmarks
data_bm_single_scope=data_bm(ismember(benchmark_names,single_scope_benchmarks));
benchmark_names_single=benchmark_names(ismember(benchmark_names,single_scope_benchmarks));
data_bm_single_scope=cellfun(@(x) x(x(:,16)<4,:),data_bm_single_scope,'UniformOutput',false);
data_bm_multi_scope=data_bm(~ismember(benchmark_names,single_scope_benchmarks));
benchmark_names_multi=benchmark_names(~ismember(benchmark_names,single_scope_benchmarks));
PLRU_single_scope=PLRU_data(ismember(benchmark_names,single_scope_benchmarks));
PLRU_multi_scope=PLRU_data(~ismember(benchmark_names,single_scope_benchmarks));
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
			else
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_single_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,18)];
				end
			end
		else
			if(h==1)
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_multi_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,17)];
				end
			else
				bar_ydata=[];
				for j=1:length(data_bm_single_scope)
					sorted_benchmark=sortrows(data_bm_multi_scope{j},16);
					bar_ydata=[bar_ydata,sorted_benchmark(:,18)];
				end
			end
		end
	% graphic
		fig=figure(1);
		set(fig, 'Position',[0,0,1080,1920]);
		bar_ydata=[bar_ydata,geomean((bar_ydata)')'];
		b=bar(transpose(bar_ydata));
		t=colormap(parula(10));
		for v=1:length(b)
		b(v).FaceColor=t(floor(10/length(b))*v,:);
		end
		
		if(h==1)
			ylabel('Policy Miss Count Normalized to PLRU Misses');
		else
			ylabel('Time of execution in Clock cycles normalized to PLRU clock cycles');
		end
		if(i==1)
			set(gca,'xticklabel',[benchmark_names_single,'GEOMEAN'],'FontSize',14);
		else
			set(gca,'xticklabel',[benchmark_names_multi,'GEOMEAN'],'FontSize',14);
		end
		xtickangle(gca,45);
		ylim([0,1.2]);
		xlim=get(gca,'xlim');
		hold on
		legend('AutoUpdate', 'Off')
		yline(1,'k-');
		grid on
		xCnt = cell2mat(get(b,'XData')) + cell2mat(get(b,'XOffset'));
		
		for j=1:size(bar_ydata,2)
			for k=1:size(bar_ydata,1)
				if(bar_ydata(k,j)>max(ylim))
					r=text(xCnt(k,j),min(bar_ydata(k,j),1.2),strip(num2str(round(bar_ydata(k,j),3)),'left','0'),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12);
				end
			end
		end
		if(i==1)
			legend({'PRL','CLAM'},'Orientation','horizontal','FontSize',14);
			
		
		else
			legend({'PRL','CLAM','SHEL','C-SHEL',},'Orientation','horizontal','FontSize',14);
			
		end 
		
		if(h==1)
			if(i==1)
				for z=1:length(benchmark_names_single)
				PLRU_array_data(z,:)=PLRU_single_scope{z};
				end
				misses=PLRU_array_data(:,7);
				misses=[misses;round(geomean(misses))];
				for z=1:length(misses)
					raw_misses=text(0,0,strcat('(',num2str(misses(z)),')'),'Units','Pixels');
					raw_misses.Rotation=45;
					raw_misses.Position=[15+(z-1)*60,-55];
					raw_misses.FontSize=12;
					raw_misses.Color=[0 0 0];
				end
			else
				for z=1:length(benchmark_names_multi)
				PLRU_array_data(z,:)=PLRU_multi_scope{z};
				end
				misses=PLRU_array_data(:,7);
				misses=[misses;round(geomean(misses))];
				for z=1:length(misses)
					raw_misses=text(0,0,strcat('(',num2str(misses(z)),')'),'Units','Pixels');
					raw_misses.Rotation=45;
					raw_misses.Position=[15+(z-1)*60,-55];
					raw_misses.FontSize=13;
					raw_misses.Color=[0 0 0];
				end
			end
		else
			if(i==1)
				for z=1:length(benchmark_names_single)
				PLRU_array_data(z,:)=PLRU_single_scope{z};
				end
				cycles=PLRU_array_data(:,4);
				cycles=[cycles;round(geomean(cycles))];
				for z=1:length(cycles)
					raw_cycles=text(0,0,strcat('(',num2str(cycles(z)),')'),'Units','Pixels');
					raw_cycles.Rotation=45;
					raw_cycles.Position=[15+(z-1)*60,-55];
					raw_cycles.FontSize=13;
					raw_cycles.Color=[0 0 0];
				end
			else
				for z=1:length(benchmark_names_multi)
				PLRU_array_data(z,:)=PLRU_multi_scope{z};
				end
				cycles=PLRU_array_data(:,4);
				cycles=[cycles;round(geomean(cycles))];
				for z=1:length(cycles)
					raw_cycles=text(0,0,strcat('(',num2str(cycles(z)),')'),'Units','Pixels');
					raw_cycles.Rotation=45;
					raw_cycles.Position=[15+(z-1)*60,-55];
					raw_cycles.FontSize=12;
					raw_cycles.Color=[0 0 0];
				end
			end
		end
		
		
		
		
		if(h==1)
			saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/benchmark_normalized_misses_',convertStringsToChars(num_scope(i)),'.png'])
		elseif(h==2)
			saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/benchmark_normalized_clock_cycles_',convertStringsToChars(num_scope(i)),'.png'])
		end
		close(fig)
	end
end
