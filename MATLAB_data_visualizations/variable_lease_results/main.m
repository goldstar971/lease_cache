% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data");

% user selections
% -------------------------------------------------------------------------
file_path = "results_fa_0.txt";
benchmark_names = ["atax","doitgen","floyd-warshall","matrix2","matrix3","mvt","nussinov"];

% smart stuff
% -------------------------------------------------------------------------

% extract data
[data,filenames,policies] = extract_data(file_path);

for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, filenames, benchmark_names(i));
end

% graphic
figure();
    for i = 1:length(benchmark_names)
        subplot(2,4,i);
            bar(data_bm{i}(:,12), data_bm{i}(:,7));
            title(benchmark_names{i});
            ylabel("Cache Misses");
            xlabel("Cache Replacement Policy");
            set(gca,'xticklabel',{'LRU','SRRIP','CARL OPT'});
            grid on;
            ax = gca;
            ax.YRuler.Exponent = 0;
    end