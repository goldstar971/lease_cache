% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data/memsys_fa_prl_phases_06082020/");

% user selections
% -------------------------------------------------------------------------
file_path = "data.txt";
benchmark_names = ["atax","doitgen","floyd-warshall","matrix2","matrix3","mvt","nussinov"];

% smart stuff
% -------------------------------------------------------------------------

% extract data
[data,filenames,policies] = extract_data_phases(file_path);

for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, filenames, benchmark_names(i));
end

% graphic
figure();
    for i = 4:length(benchmark_names)
        subplot(2,2,i-3);
            bar(data_bm{i}(:,15), data_bm{i}(:,7));
            if (i == 4)
                ylabel_str = sprintf("%s\n%s","2mm","Cache Misses");
            elseif (i == 5)
                ylabel_str = sprintf("%s\n%s","3mm","Cache Misses");
            else
                ylabel_str = sprintf("%s\n%s",benchmark_names{i},"Cache Misses");
            end
                ylabel(ylabel_str);
                set(gca,'xticklabel',{'LRU','CARL',"PRL-2",'PRL-5','PRL-10','PRL-20'});
                grid on;
                ax = gca;
                ax.YRuler.Exponent = 0;
                grid off;
                
                str_1 = compose("%.3g\n",100-data_bm{i}(2:end,17));
                str_2 = compose("\n%.3g",data_bm{i}(2:end,18));
                t = text(2:length(data_bm{i}(:,7)),data_bm{i}(2:end,7), ...
                            str_1, ...
                            'vert','middle','horiz','center',...
                            'color','black',...
                            'fontweight','bold'); 
                t2 = text(2:length(data_bm{i}(:,7)),data_bm{i}(2:end,7), ...
                            str_2, ...
                            'vert','middle','horiz','center',...
                            'color','white',...
                            'fontweight','bold');
                
                %set(gca,'box','off');
                %set(gca,'XTick',[]);
                
                set(gca,'FontSize',10)
%                 if (i == length(benchmark_names))
%                     xlabel('Cache Policy');
%                 end
                
                 if ((i == 4) || (i == 6))
                     ylim([0 1.2*max(data_bm{i}(:,7))])
                 end
                 
                 if (i == 4)
                     ylim([10000 1.1*max(data_bm{i}(:,7))]);
                 elseif (i == 5)
                     ylim([20000 1.1*max(data_bm{i}(:,7))]);
                 elseif (i == 6)
                     ylim([0 1.1*max(data_bm{i}(:,7))]);
                 elseif (i == 7)
                     ylim([100000 1.1*max(data_bm{i}(:,7))]);
                 end
    end