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
base_data_dir=[base_path,'software/fpga_proxy/results/evict_track/'];

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



%get data set size
if(nargin<2)
	dataset_size=lower(cell2mat(inputdlg("Give dataset size, you'd like to plot: ")));
else
	dataset_size=lower(varargin{2});
end 
if isempty(dataset_size)
	if usejava('desktop')
		return;
	else
		quit;
	end
end

	data_name=dataset_size;
	if contains(dataset_size,'small')
		data_search='';
	else
		data_search=['_',dataset_size];
	end
if(multi_level)
	data_name=[data_name,'_multi_level'];
end
  % if directory for term doesn't exist, create it.
     if(exist([tracking_dir,data_name,'/'],'dir')~=7)
         mkdir([tracking_dir,data_name,'/']);
     end
 set(0,'DefaultFigureVisible','on')

	policies=["CLAM","PRL","SHEL","C-SHEL"];
benchmark_names=["2mm"	"3mm"	"atax"	"bicg"	"cholesky"	"correlation" ...
"covariance"	"deriche"	"doitgen"	"durbin"	"floyd-warshall" ...
	"gemm"	"gemver"	"gesummv"	"gramschmidt"	"jacobi-1d"	"mvt" ...
	"nussinov"	"seidel-2d"	"symm"	"syr2k"	"syrk"	"trisolv"	"trmm"	"adi" ...
	"fdtd-2d"	"heat-3d"	"jacobi-2d"	"lu"	"ludcmp"];
for bench_index=15:length(benchmark_names)
	file_list=[];
	for j=1:length(policies)
file_list=[file_list, dir([base_data_dir,convertStringsToChars(policies(j)),convertStringsToChars(data_search),'/',convertStringsToChars(benchmark_names(bench_index)),'.csv'])];
end
clear r max_traces;
if (file_list(1).bytes==0)
 	continue
 	end
figure();
hold on;
scatter(NaN,NaN,'filled');
scatter(NaN,NaN,'filled');
scatter(NaN,NaN,'filled');
scatter(NaN,NaN,'filled');
legend('AutoUpdate', 'Off');
h=gca;
map=[0,1,0;0.1020,0.4118,0.0235;1.0000,0.6078,0.0196;1,0,0];
h.Colormap=map;
h.ColorOrder=map;


for i=1:length(file_list)
	clear trace_millions evict_status
 	
% extract delimited fields
benchmark=file_list(i).name(1:end-4);
current_tracking_file=strcat(file_list(i).folder,'/',file_list(i).name);
[evict_status,trace]=extract_eviction_tracking_data_all(current_tracking_file);
evict_status2=transpose(evict_status);

trace=double(convertCharsToStrings(trace));
no_evict=transpose(setdiff(0:1:max(trace),trace)/1000000);
trace_millions =transpose(trace/1000000);
random_vals=trace_millions(evict_status2==2);
single_expiry_vals=trace_millions(evict_status2==1);
multi_expiry_vals=trace_millions(evict_status2==0);
g=[repmat(map(1,:),length(no_evict),1);repmat(map(2,:),length(single_expiry_vals),1);repmat(map(3,:),length(multi_expiry_vals),1);repmat(map(4,:),length(random_vals),1)];
x=[no_evict;single_expiry_vals';multi_expiry_vals';random_vals'];
y=ones(max(trace)+1,1);
scatter(x,y,'|','SizeData',8192);


% scatter(no_evict,ones(1,length(no_evict))*(i)*.5,'|','SizeData',8192);
% scatter(single_expiry_vals,ones(1,length(single_expiry_vals))*(i)*.5,'|','SizeData',8192)
% scatter(multi_expiry_vals,ones(1,length(multi_expiry_vals))*(i)*.5,'|','SizeData',8192)
% scatter(random_vals,ones(1,length(random_vals))*i*.5,'|','SizeData',8192)
max_traces(i)=max(trace_millions);
r(i)=text(max(trace_millions)*.5,1*i*.5-.2,policies(i),'FontSize',16);

end
for k=1:length(max_traces)
pos=r(k).Position;
r(k).Position=[max(max_traces)/2,pos(2),pos(3)];
end
h.XLim=[0,max(max_traces)];
h.YLim=[.25,i*.5+.2];
set (h,'YTick',[]);
ylabel("Expiration Type",'FontSize',18);
xlabel("Logical Time (millions)",'FontSize',18);
legend("no-evict","single-expiry","multi-expiry","random-eviction");
set(gcf, 'Position',[0,0,1920,1080]);     % [low left x, low left y, top right x, top right y]
   
        file_name=strcat(tracking_dir,data_name,"/",benchmark,".png");
        export_fig(sprintf("%s",file_name),'-q101','-png','-p.01');
         
close(gcf)

end