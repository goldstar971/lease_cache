% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./data/PRL_set_assoc_07072020");

% user selections
% -------------------------------------------------------------------------
file_path = "fa_results.txt";
file_path2 = "set_results.txt";
file_path3 = "carl_set_results.txt";
benchmark_names = ["atax","doitgen","floyd-warshall","matrix2","matrix3","mvt","nussinov"];
benchmark_names_vec = {'atax','doitgen','floyd-warshall','2mm','3mm','mvt','nussinov'};

% extract data
[data,filenames,policies] = extract_data_sets(file_path);
[data2,filenames2,policies2] = extract_data_sets(file_path2);
[data3,filenames3,policies3] = extract_data_sets(file_path3);

%data3 = [zeros(7,17);data3];
%filenames3 = [filenames3(1:7);filenames3];



for i = 1:length(benchmark_names)
    data_bm{i} = parse_name(data, filenames, benchmark_names(i));
    data_bm2{i} = parse_name(data2, filenames2, benchmark_names(i));
    data_bm3{i} = parse_name(data3, filenames3, benchmark_names(i));
end

% graphic
figure();
    for i = 1:7
        subplot(4,2,i)
            %bar([data_bm{i}(:,7)';data_bm2{i}(:,7)';data_bm3{i}(:,7)']');
            bar([data_bm{i}(:,7)';data_bm2{i}(:,7)']');
                set(gca,'xticklabel',{'2way','4way','8way','FA'});      
                title(benchmark_names(i));
                ax = gca;
                ax.YRuler.Exponent = 0;
                
                %str_1 = compose("%.3g/%.3g/%.3g\n",data_bm{i}(1:end,17),data_bm2{i}(1:end,17),data_bm3{i}(1:end,17));
                str_1 = compose("%.3g/%.3g\n",100-data_bm{i}(1:end,17),100-data_bm2{i}(1:end,17));
                
                temp_max = max(data_bm{i}(1:end,7),data_bm2{i}(1:end,7));
                %temp_max2 = max(temp_max, data_bm3{i}(1:end,7));
                temp_max2 = temp_max;
                
                ylim([0 1.3*max(temp_max2)]);
                
                t = text(1:length(data_bm{i}(:,7)),temp_max2, ...
                            str_1, ...
                            'vert','middle','horiz','center',...
                            'fontsize',8,...
                            'color','black');%,...
                            %'fontweight','bold'); 
                if (i == 7)
                    legend('CARL','PRL-Spatial');
                end
                
                ylabel('Miss Count');
                
    end