% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
addpath("./scan_v2/");

% user selections
% -------------------------------------------------------------------------
file_path = "data.txt";

% extract delimited fields
[average,exp_mat,trace] = extract_tracking_data_2(file_path);
lines_arr = 1:128;
trace_millions = trace / 1000000;

average_mean = movmean(average,50);

% graphic
figure();
    subplot(2,1,1);
        plot(trace_millions,average);
        hold on;
        plot(trace_millions,average_mean,'r');
        ylabel('Vacant/Expired Cache Blocks');
        axis tight;
        xlabel('Millions of references');
        title('Aggregate Cache Vacancy');
    subplot(2,1,2);
        s = surface(trace_millions,1:128,exp_mat');
        s.EdgeColor = 'none';
        axis tight;
        ax = gca;
        ax.XAxis.Exponent = 0;
        title('Individual Cache Line Status');
        ylabel('Cache Line');
        xlabel('Millions of references');   
        colorbar('Ticks',[0,1],...
            'TickLabels',{'Not-Expired','Expired'},...
            'Location','southoutside');