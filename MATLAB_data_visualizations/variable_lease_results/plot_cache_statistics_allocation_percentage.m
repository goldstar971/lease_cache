% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data");

% user selections
% -------------------------------------------------------------------------
file_path=[getenv('HOME'),'/Documents/Thesis_stuff/software/fpga_proxy/results/cache/results.txt'];
base_save_path=strcat(getenv('HOME'),'/Documents/Thesis_stuff/MATLAB_data_visualizations/');

% smart stuff
% -------------------------------------------------------------------------

% extract data
[data,filenames,policies] = extract_data_allocation_percentage(file_path);
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

		 bar(data_bm{i}(not(isnan(data_bm{i}(:,9))),9), data_bm{i}(not(isnan(data_bm{i}(:,9))),7));
		 ylabel("Total Cache Misses");
		title(benchmark_names{i});

		xlabel("Cross RUI type with allocation percentage");
		set(gca,'xticklabel',{'no\_cross\_rui','10','30','50','80'},'XTickLabelRotation',45);
		grid on;
		ax = gca;
		ax.YRuler.Exponent = 0;

end
for i=1:5
		saveas(figure(i),strcat(base_save_path,'variable_lease_results/cache_statistics_graphs/benchmark_results_misses_pg',num2str(i),'.png'))
		close(figure(i))
end