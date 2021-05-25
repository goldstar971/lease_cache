% initialize workspace
close all; clearvars; clc;
map=[255,226,114;
253,211,109;
250,197,104;
248,182,100;
246,167,95;
244,152,90;
241,138,85;
239,123,80;
237,108,75;
235,93,71;
232,79,66;
230,64,61;
222,63,64;
215,62,67;
207,61,70;
199,60,73;
191,59,76;
184,59,79;
176,58,82;
168,57,85;
160,56,88;
153,55,91;
145,54,94;
140,55,95;
134,57,97;
129,58,98;
124,59,100;
118,61,101;
113,62,103;
107,64,104;
102,65,106;
97,66,107;
91,68,109;
86,69,110;
]./255;

% added dependency directories
addpath("./src");
base_path=[getenv('HOME'),'/Documents/Thesis_stuff/'];
base_data_dir=[base_path,'software/fpga_proxy/results/track/'];
base_save_dir=[base_path,'MATLAB_data_visualizations/art_contest/'];

benchmark_type=inputdlg("Give name of the benchmark type for which you'd like to plot tracker results: ",'s');
if(strcmp(benchmark_type{1},'carl'))
	full_path=[base_save_dir,cell2mat(benchmark_type),'/'];
else
	full_path=[base_data_dir,cell2mat(benchmark_type),'/'];
end
file_list=dir([full_path,'*.txt']);

 % if directory for term doesn't exist, create it.
    if(exist([base_save_dir,cell2mat(benchmark_type),'/'],'dir')~=7)
        mkdir([base_save_dir,cell2mat(benchmark_type),'/']);
    end
set(0,'DefaultFigureVisible','off')
for i=1:length(file_list)
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
colormap(map);
set(gcf, 'Position',[0,0,3840,2160]);     % [low left x, low left y, top right x, top right y]
        s = surface(trace_millions,1:128,exp_mat.fin');
        s.EdgeColor = 'none';
        axis tight;
       
        ax = gca;
		
        ax.XAxis.Exponent = 0;
		outerpos = ax.OuterPosition;
		ti = ax.TightInset; 
		left = outerpos(1) + ti(1);
		bottom = outerpos(2) + ti(2);
		ax_width = outerpos(3) - ti(1) - ti(3);
		ax_height = outerpos(4) - ti(2) - ti(4);
		ax.Position = [left bottom ax_width ax_height];
		%caxis([0,3]);

		  saveas(gcf,strcat(base_save_dir,benchmark_type,"/",benchmark,".png"))
			close(gcf)
       
       
        
end

            

            
            
            
            
            
            