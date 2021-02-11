% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data");

% user selections
% -------------------------------------------------------------------------
file_path = "results_lease_only_0.txt";
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
            bar(data_bm{i}(:,15), data_bm{i}(:,7));
                title(benchmark_names{i});
                ylabel("Cache Misses");
                xlabel("Lease Cache Associativity");
                %set(gca,'xticklabel',{'LRU','SRRIP','CARL OPT'});
                set(gca,'xticklabel',{'FA','8WAY','4WAY','2WAY'});
                grid on;
                ax = gca;
                ax.YRuler.Exponent = 0;
    end