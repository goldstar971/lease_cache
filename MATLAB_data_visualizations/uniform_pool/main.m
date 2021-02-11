% initialize workspace
close all; clearvars; clc;

% user selections
% -------------------------------------------------------------------------


% smart stuff
% -------------------------------------------------------------------------

% fixed params
%path = dir+name;
%path_lru = dir+"results_lru.txt";


% extract data
[data,filenames] = extract_data("results.txt");

% [~, parsed_data] = parse_name(data, filenames, type);
% 
% [data4_1,filenames4_1] = extract_data(path+"_4_1.txt");
% [~, parsed_data4_1] = parse_name(data4_1, filenames4_1, type);
% 
% [data4_0,filenames4_0] = extract_data(path+"_4_0.txt");
% [~, parsed_data4_0] = parse_name(data4_0, filenames4_0, type);
% 
% [data_lru,filenames_lru] = extract_data(path_lru);
% [~, parsed_data_lru] = parse_name(data_lru, filenames_lru, type);
% 
% % graphic/s
% % ------------------------------------------------
% figure();
%     %subplot(2,4,1);
%     plot(parsed_data(:,23),parsed_data(:,22)/parsed_data_lru(1,22),'LineWidth',2); hold on;
%     plot(parsed_data4_1(:,23),parsed_data4_1(:,22)/parsed_data_lru(1,22), 'LineWidth',2); hold on;
%     plot(parsed_data4_0(:,23),parsed_data4_0(:,22)/parsed_data_lru(1,22),'LineWidth',2); hold on;
%         grid on;
%         xlabel('Equivalent Lease Size');
%         ylabel('Miss rate as a factor normalized to LRU');
%         ax = gca;
%         ax.XRuler.Exponent = 0;
%         legend("Nominal","Pool=4 - Most","Pool=4 - Least");
        