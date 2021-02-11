% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");

% user selections
% -------------------------------------------------------------------------
% file = "3mm";
% file_path_carl = strcat("./carl/",file,"_small_rand.txt");
% file_path_prl = strcat("./prl/",file,"_small_rand.txt");
data_folder1="./carl";
data_folder2="../variable_lease_results/data/fa_scope_lease_tracker_results";
benchmark_names = ["atax","doitgen","floyd-warshall","2mm","3mm","mvt","nussinov"];


algor2="CARL\_scope";
algor1="CARL";
for i=1:7
    
    file_path_carl=strcat(data_folder1,"/",benchmark_names(i),"_small_rand.txt");
	file_path_carl_scope=strcat(data_folder2,"/",benchmark_names(i),"_scope_lease_results.txt");

% extract delimited fields
if(strcmp(benchmark_names(i),'floyd-warshall')||strcmp(benchmark_names(i),'nussinov'))
	[average_carl,exp_mat_carl,trace_carl]=extract_tracking_data_2_large_set(file_path_carl,128);
else
	[average_carl,exp_mat_carl,trace_carl]=extract_tracking_data_2_small_set(file_path_carl,128);
end
trace_millions_carl =trace_carl/1000000;
mean_carl =movmean(average_carl.exp,128);
if(strcmp(benchmark_names(i),'floyd-warshall')||strcmp(benchmark_names(i),'nussinov'))
	[average_carl_scope,exp_mat_carl_scope,trace_carl_scope]=extract_tracking_data_2_large_set(file_path_carl_scope,128);
else
	[average_carl_scope,exp_mat_carl_scope,trace_carl_scope]=extract_tracking_data_2_small_set(file_path_carl_scope,128);
end
trace_millions_carl_scope =trace_carl_scope/1000000;
mean_carl_scope =movmean(average_carl_scope.exp,128);

figure();
set(gcf, 'Position',[100,100,1000,600]);     % [low left x, low left y, top right x, top right y]
    ax_1=subplot(2,3,1);
        plot(trace_millions_carl,average_carl.exp);
        hold on;
        ylabel('Vacant/Expired Cache Blocks');
        axis tight;
        xlabel('Millions of accesses');
        title(strcat(algor1,'-Aggregate Cache Vacancy'));
        ylim([0 128]);
    ax_2=subplot(2,3,2:3);
        s = surface(trace_millions_carl,1:128,exp_mat_carl.fin');
        s.EdgeColor = 'none';
        axis tight;
        title(strcat(algor1,'-Individual Cache Line Status'));
        ylabel('Cache Line');
        xlabel('Millions of accesses');
        ax = gca;
        ax.XAxis.Exponent = 0;
		caxis([0,3]);

	 ax_3=subplot(2,3,4);
        plot(trace_millions_carl_scope,average_carl_scope.exp);
        hold on;
        ylabel('Vacant/Expired Cache Blocks');
        axis tight;
        xlabel('Millions of accesses');
        title(strcat(algor2,'-Aggregate Cache Vacancy'));
        ylim([0 128]);

    ax_4=subplot(2,3,5:6);
        s = surface(trace_millions_carl_scope,1:128,exp_mat_carl_scope.fin');
        s.EdgeColor = 'none';
        axis tight;
        title(strcat(algor2,'-Individual Cache Line Status'));
        ylabel('Cache Line');
        xlabel('Millions of accesses');
        ax = gca;
        ax.XAxis.Exponent = 0;
            caxis([0, 3]);		
		        pos = get(ax_1,'Position');
        set(ax_1,'Position',[pos(1) 1.05*pos(2) pos(3) .95*pos(4)]);
        pos = get(ax_2,'Position');
        set(ax_2,'Position',[pos(1) 1.05*pos(2) pos(3) .95*pos(4)]);
        pos = get(ax_3,'Position');
        set(ax_3,'Position',[pos(1) 1.5*pos(2) pos(3) .95*pos(4)]);
        pos = get(ax_4,'Position');
        set(ax_4,'Position',[pos(1) 1.5*pos(2) pos(3) .95*pos(4)]);
        
        cb = colorbar('Ticks',[0,1,2,3],...
                 'TickLabels',{'Long Lease','Medium Lease','Short Lease','Expired'},...
                 'FontSize',10,...
                 'Location','south');
        cb.Position = [.15 .06 .725 .0213];
         saveas(gcf,strcat("../variable_lease_results/variable_lease_spectrum_graphs/","tracker_results_",benchmark_names(i),".png"))
close(gcf)
end

            

            
            
            
            
            
            