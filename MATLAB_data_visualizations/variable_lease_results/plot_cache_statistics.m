% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data");

% user selections
% -------------------------------------------------------------------------
file_path=[getenv('HOME'),'/Documents/Thesis_stuff/software/fpga_proxy/results/cache/results.txt'];


% smart stuff
% -------------------------------------------------------------------------

% extract data
[data,filenames,policies] = extract_data(file_path);
%get benchmark names
for i=1:length(filenames)
	benchmarks(i)=regexp(filenames{i},"/benchmarks/poly_small.*\/(.*)\/program",'tokens');
end
benchmarks=string(benchmarks);
benchmark_names=unique(benchmarks);

for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, transpose(benchmarks), benchmark_names(i));
end
set(0,'DefaultFigureVisible','off')
% graphic
j=1;
    for i = 1:length(benchmark_names)
		if(mod(i,6)==1)
			fig(j)=figure(j);
			j=j+1;
			set(gcf, 'Position',[100,100,1000,600]);
		end
        subplot(2,3,i-(j-2)*6);
            bar(data_bm{i}(:,16), data_bm{i}(:,7));
            title(benchmark_names{i});
            ylabel("Cache Misses");
            xlabel("Cache Replacement Policy");
            set(gca,'xticklabel',{'PLRU','CARL','CARL\_SCOPE'});
            grid on;
            ax = gca;
            ax.YRuler.Exponent = 0;
		
	end
	for i=1:5
		saveas(figure(i),strcat("../variable_lease_results/cache_statistics_graphs/benchmark_results_pg",num2str(i),".png"))
		close(figure(i))
	end