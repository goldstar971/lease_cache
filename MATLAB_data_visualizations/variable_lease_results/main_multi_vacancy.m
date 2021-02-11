% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data/fixed_v3_var_06022020/");

% user selections
% -------------------------------------------------------------------------
file_path = "data.txt";
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
                set(gca,'xticklabel',{'LRU','CARL',"PRL-MIN",'PRL-MED','CARL-STRICT'});
                %set(gca,'xticklabel',{'FA','8WAY','4WAY','2WAY'});
                grid on;
                ax = gca;
                ax.YRuler.Exponent = 0;
                
                str = compose("%.3g\n%.3g",data_bm{i}(:,17),data_bm{i}(:,18));
                t = text(1:length(data_bm{i}(:,7)),data_bm{i}(:,7), ...
                            str, ...
                            'vert','middle','horiz','center'); 
                box off
                set(gca,'FontSize',6)
    end