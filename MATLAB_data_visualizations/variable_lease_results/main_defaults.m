% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data/var_different_defaults_05282020/");

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
            %bar(data_bm{i}(:,14), data_bm{i}(:,7));
            bar(data_bm{i}(:,7));
                title(benchmark_names{i});
                ylabel("Cache Misses");
                %xlabel("Lease Cache Associativity");
                xlabel("Policy/Default Lease Value (hex) if CARL");
                %set(gca,'xticklabel',{'LRU','CARL','BMIN','BMED'});
                %set(gca,'xticklabel',{'FA','8WAY','4WAY','2WAY'});
                set(gca,'xticklabel',{'LRU','0','1','10','100','1000','FFFFFF'});
                set(gca,'FontSize',8)
                grid on;
                ax = gca;
                ax.YRuler.Exponent = 0;
                
                %str = compose("%.3g",data_bm{i}(:,16));
                %t = text(1:length(data_bm{i}(:,7)),data_bm{i}(:,7), ...
                %            str, ...
                %            'vert','bottom','horiz','center'); 
                box off
    end