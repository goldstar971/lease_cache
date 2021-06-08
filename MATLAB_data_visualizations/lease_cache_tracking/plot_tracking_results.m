% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");
base_path=[getenv('HOME'),'/Documents/Thesis_stuff/'];
base_data_dir=[base_path,'software/fpga_proxy/results/track/'];
base_save_dir=[base_path,'MATLAB_data_visualizations/lease_cache_tracking/'];

benchmark_type=inputdlg("Give name of the benchmark type for which you'd like to plot tracker results: ",'s');

full_path=[base_data_dir,cell2mat(benchmark_type),'/'];

file_list=dir([full_path,'*.txt']);

 % if directory for term doesn't exist, create it.
    if(exist([base_save_dir,cell2mat(benchmark_type),'/'],'dir')~=7)
        mkdir([base_save_dir,cell2mat(benchmark_type),'/']);
    end
set(0,'DefaultFigureVisible','off')
for i=1:length(file_list)
	display(i);
% extract delimited fields
benchmark=file_list(i).name(1:end-4);
current_tracking_file=strcat(full_path,benchmark,'.txt');
if(contains(benchmark,'floyd-warshall'))
	[average,exp_mat,trace]=extract_tracking_data_2_large_set(current_tracking_file,128);
else
	[average,exp_mat,trace]=extract_tracking_data_2_small_set(current_tracking_file,128);
end
trace_millions =trace/1000000;
mean =movmean(average.exp,128);


figure();
set(gcf, 'Position',[100,100,1000,600]);     % [low left x, low left y, top right x, top right y]
    ax_1=subplot(1,3,1);
        plot(trace_millions,average.exp);
        hold on;
        ylabel('Vacant/Expired Cache Blocks');
        axis tight;
        xlabel('Millions of accesses');
        title('-Aggregate Cache Vacancy');
        ylim([0 128]);
    ax_2=subplot(1,3,2:3);
        s = surface(trace_millions,1:128,exp_mat.fin');
        s.EdgeColor = 'none';
        axis tight;
        title('Individual Cache Line Status');
        ylabel('Cache Line');
        xlabel('Millions of accesses');
        ax = gca;
        ax.XAxis.Exponent = 0;
		caxis([0,3]);

		pos = get(ax_1,'Position');
        set(ax_1,'Position',[pos(1) 1.20*pos(2) pos(3) .99*pos(4)],'FontSize',13);
        pos = get(ax_2,'Position');
        set(ax_2,'Position',[pos(1) 1.20*pos(2) pos(3) .99*pos(4)],'FontSize',13);
       
        cb = colorbar('Ticks',[0,1,2,3],...
                 'TickLabels',{'Long Lease','Medium Lease','Short Lease','Expired'},...
                 'FontSize',13,...
                 'Location','south');
        cb.Position = [.15 .035 .725 .0213];
         saveas(gcf,strcat(base_save_dir,benchmark_type,"/",benchmark,".png"))
close(gcf)
end

            

            
            
            
            
            
            
