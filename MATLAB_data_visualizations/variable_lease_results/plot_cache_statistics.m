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

for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, filenames, benchmark_names(i));
end

% graphic
figure();
    for i = 1:length(benchmark_names)
        subplot(2,4,i);
            bar(data_bm{i}(:,16), data_bm{i}(:,7));
            title(benchmark_names{i});
            ylabel("Cache Misses");
            xlabel("Cache Replacement Policy");
            set(gca,'xticklabel',{'PLRU','CARL','CARL_SCOPE'});
            grid on;
            ax = gca;
            ax.YRuler.Exponent = 0;
    end