function [] =plot_eviction_tracking_results(varargin)
%takes arguments cache_level lease_policy dataset_size and optionally an array of numbers corresponding to the benchmarks we want to plot in alphanumerical order
%e.g no clam small [2,5,8] which plots single level cache eviction tracking data for CLAM for 3mm, bicg and floyd-warshall

% initialize workspace
	if usejava('desktop')
			clc;
			close all;
	end

% added dependency directories


%get paths
t=which('plot_tracking_results');
tracking_dir=[t(1:end-23),'eviction_tracking/'];

base_path=t(1:end-71);
base_data_dir=[base_path,'software/fpga_proxy/results/track/'];

if(nargin<1)
multi_level_ans=questdlg("Plot Eviction tracking results for two-level cache?","cache level",'yes','no','no');
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

file_list=dir([full_path,'*.csv']);

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
current_tracking_file=strcat(full_path,benchmark,'.csv');
[evict_status,trace]=extract_eviction_tracking_data_all(current_tracking_file);
trace_millions =trace/1000000;
clear trace


figure();
X=[0 X;0 X];
Y=[0.9*ones(1,length(X));1.1ones(1,length(X))];
Z=[evict_status;evict_status];
surf(X,Y,Z);
view([0 90]);
h=gca;
h.YLim=[.9,1.1];
h.XLim=[0,max(X(1,:))]
set (h,'YTick',[]);
ylabel("Expiration type");
xlabel("logical time");
t=colorbar;
t.TicksMode='manual';
t.Ticks=[0 1 2];
t.TickLabelsMode='manual';
t.TickLabels=["random-eviction","single-expiry","multi-expiry"];
set(gcf, 'Position',[0,0,1920,1080]);     % [low left x, low left y, top right x, top right y]
   
        file_name=strcat(tracking_dir,data_name,"/",benchmark,".png");
        export_fig(sprintf("%s",file_name),'-q101','-png','-p.01');
         
close(gcf)
clear trace_millions evict_status
end
