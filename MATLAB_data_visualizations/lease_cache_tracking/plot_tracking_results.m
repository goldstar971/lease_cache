function [] =plot_tracking_results(varargin)
%takes arguments cache_level lease_policy dataset_size and optionally an array of numbers corresponding to the benchmarks we want to plot in alphanumerical order
%e.g no clam small [2,5,8] which plots single level cache tracking data for CLAM for 3mm, bicg and floyd-warshall

% initialize workspace
	if usejava('desktop')
			clc;
			close all;
	end

% added dependency directories


%get paths
t=which('plot_tracking_results');
tracking_dir=t(1:end-23);
addpath([tracking_dir,'src']);

base_path=t(1:end-71);
base_data_dir=[base_path,'software/fpga_proxy/results/track/'];

if(nargin<1)
multi_level_ans=questdlg("Plot tracking results for two-level cache?","cache level",'yes','no','no');
else
multi_level_ans=lower(varargin{1});
end

if ~strcmp(multi_level_ans,'yes')&& ~strcmp(multi_level_ans,'no')
	if usejava('desktop')
		return;
	else
		quit;
	end
end


%get number of levels in the cache structure
if(strcmp(multi_level_ans,'no'))
	multi_level=0;
else
	multi_level=1;
end
if(multi_level)
	cache_size=512; % number of lines in 2 level cache
else
    cache_size=128;
end

%get lease policy 
if(nargin<2)
	lease_algorithm=upper(cell2mat(inputdlg("Give type of lease algorithm for which you'd like to plot tracker results: ",'s')));
else
	lease_algorithm=upper(varargin{2});
end
if isempty(lease_algorithm)
	if usejava('desktop')
		return;
	else
		quit;
	end
end


%get data set size
if(nargin<3)
	dataset_size=lower(cell2mat(inputdlg("Give dataset size, you'd like to plot: ")));
else
	dataset_size=lower(varargin{3});
end 
if isempty(dataset_size)
	if usejava('desktop')
		return;
	else
		quit;
	end
end
if contains(dataset_size,'small')
	data_name=lease_algorithm;
else
	data_name=[lease_algorithm,'_',dataset_size];
end

if(multi_level)
	data_name=[data_name,'_multi_level'];
else
	data_name=data_name;
end
full_path=[base_data_dir,data_name,'/'];

file_list=dir([full_path,'*.txt']);

 % if directory for term doesn't exist, create it.
    if(exist([tracking_dir,data_name,'/'],'dir')~=7)
        mkdir([tracking_dir,data_name,'/']);
    end
set(0,'DefaultFigureVisible','off')

if(nargin<4)
	benchmark_index_2_plot=[1:1:length(file_list)];
else
	benchmark_index_2_plot=varargin{4};
end

for i=benchmark_index_2_plot
	display([num2str(i),':',file_list(i).name(1:end-4)]);
% extract delimited fields
benchmark=file_list(i).name(1:end-4);
current_tracking_file=strcat(full_path,benchmark,'.txt');
if(contains(benchmark,'adi'))
	[average,exp_mat,trace]=extract_tracking_data_all(current_tracking_file,cache_size,'large');
else
	[average,exp_mat,trace]=extract_tracking_data_all(current_tracking_file,cache_size,'small');
end
trace_millions =trace/1000000;
clear trace
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
        ylim([0 cache_size]);
    clear average.exp
    ax_2=subplot(1,3,2:3);
        s = surface(trace_millions,1:cache_size,exp_mat.fin');
	clear exp_mat.fin
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
         saveas(gcf,strcat(tracking_dir,data_name,"/",benchmark,".png"))
close(gcf)
clear trace_millions average  exp_mat trace
end

            

            
            
            
            
            
            
