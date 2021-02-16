% initialize workspace
close all; clearvars; clc;

% settings/configurations
set(0,'DefaultLegendAutoUpdate','off');     % stops legend auto add/update

% added dependency directories
addpath("./src");
addpath("./data/fa_memsys_05302020");

% user selections
% -------------------------------------------------------------------------
file_path = "data.txt";
benchmark_names = ["atax","doitgen","floyd-warshall","matrix2","matrix3","mvt","nussinov"];
benchmark_names_vec = {'atax','doitgen','floyd-warshall','2mm','3mm','mvt','nussinov'};

% smart stuff
% -------------------------------------------------------------------------

% extract data
[data,filenames,policies] = extract_data(file_path);

for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, filenames, benchmark_names(i));
end

% normalize each set to LRU
for i = 1:length(benchmark_names)
    data_bm{i} = lru_norm(data_bm{i});
end

% group into similar bins
bin1 = [data_bm{1}(:,17)'; data_bm{2}(:,17)'; data_bm{3}(:,17)'];
bin2 = [data_bm{4}(:,17)'; data_bm{5}(:,17)'];
bin3 = [data_bm{6}(:,17)'; data_bm{7}(:,17)'];

% graphic
figure();
    bar([bin1; bin2; bin3]);
        ylabel('Policy Miss Count Normalized to LRU Misses');
        ylim([0 1.3]);
            set(gca,'xticklabel',benchmark_names_vec);
        legend({'LRU','pLRU','SRRIP','FUL','CARL','PRL'},'Orientation','horizontal');
        %legend({'LRU','pLRU','SRRIP','CARL','CARL-FIXED SIZE','FUL'},'Orientation','horizontal');
        
        xlim=get(gca,'xlim');
        hold on
        plot(xlim,[1 1],'k--');
        
% figure();
%     for i = 1:length(benchmark_names)
%         subplot(2,4,i);
%             bar(data_bm{i}(:,14), data_bm{i}(:,17));
%             title(benchmark_names{i});
%             ylabel("Cache Misses");
%             xlabel("Cache Replacement Policy");
%             set(gca,'xticklabel',{'LRU','pLRU','SRRIP','CARL'});
%             grid on;
%             ax = gca;
%             ax.YRuler.Exponent = 0;
%             %set(gca,'YScale','log')
%             %ylim([0 10000]);
%             ylim([-20 100]);
%     end