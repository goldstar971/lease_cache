% initialize workspace
close all; clearvars; clc;

% settings/configurations
set(0,'DefaultLegendAutoUpdate','off');     % stops legend auto add/update

% added dependency directories
addpath("./src");
addpath("./data/scope_08112020");

% user selections
% -------------------------------------------------------------------------
file_path = "data.txt";
benchmark_names = ["atax","doitgen","floyd-warshall","matrix2","matrix3","mvt","nussinov"];
benchmark_names_vec = {'atax','doitgen','floyd-warshall','2mm','3mm','mvt','nussinov'};

% smart stuff
% -------------------------------------------------------------------------

% extract data
[data,filenames,policies] = extract_data_summary(file_path);

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

bin1a = [data_bm{1}(:,22)'; data_bm{2}(:,22)'; data_bm{3}(:,22)'];
bin2a = [data_bm{4}(:,22)'; data_bm{5}(:,22)'];
bin3a = [data_bm{6}(:,22)'; data_bm{7}(:,22)'];

binX = [bin1; bin2; bin3];
binXa = [bin1a; bin2a; bin3a];

% graphic
figure();
    %subplot(2,1,1);
    bar([bin1; bin2; bin3]);
        %ylabel('Policy Miss Count Normalized to LRU Misses');
        %ylabel(['Policy Miss Ratio Normalized' newline 'to LRU Miss Ratio']);
        ylabel(['Policy Miss Ratio Normalized to LRU Miss Ratio']);
        ylim([0 1.5]);
            set(gca,'xticklabel',benchmark_names_vec);
        legend({'LRU','CARL','PRL-5','CARL-SCOPE'},'Orientation','horizontal');
        xlim=get(gca,'xlim');
        hold on
        plot(xlim,[1 1],'k--');
        set(gca,'FontSize',12);
        
%         delta = .3;
%         
%         for i = 1:7
%             %str = compose("%.3g\n",data_bm{i}(2:end,22));
%             str = sprintf('%0.3g',data_bm{i}(2:end,22));
%             %t = text(2:length(data_bm{i}(:,17)),data_bm{i}(2:end,17), ...
%             t = text([i],max(data_bm{i}(2:end,17)), ...
%                             str, ...
%                             'vert','middle','horiz','center',...
%                             'color','black',...
%                             'fontweight','bold');
%         end
% subplot(2,1,2);
%     bar(-binXa);
%         %ylabel('Policy Miss Count Normalized to LRU Misses');
%         ylabel(['Exe. Time Improvement' newline 'Over LRU [%]']);
%         ylim([-1 1]);
%             set(gca,'xticklabel',benchmark_names_vec);
%         legend({'LRU','CARL','PRL-5','CARL-SCOPE'},'Orientation','horizontal');
%         xlim=get(gca,'xlim');
%         set(gca,'FontSize',12);
        
%         delta = .3;
%         
%         for i = 1:7
%             %str = compose("%.3g\n",data_bm{i}(2:end,22));
%             str = sprintf('%0.3g',data_bm{i}(2:end,22));
%             %t = text(2:length(data_bm{i}(:,17)),data_bm{i}(2:end,17), ...
%             t = text([i],max(data_bm{i}(2:end,17)), ...
%                             str, ...
%                             'vert','middle','horiz','center',...
%                             'color','black',...
%                             'fontweight','bold');
%         end

