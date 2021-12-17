%function [] =plot_cache_summary(varargin)
% initialize workspace
clear all;
	if usejava('desktop')
			clc;
			close all;
	end

	t=which('plot_cache_summary');
	cache_stats_dir=t(1:end-20);
	addpath([cache_stats_dir,'src']);
	base_path=t(1:end-64);
	lease_policies=["CLAM","PRL","SHEL","C-SHEL"];

	multi_level_ans=questdlg("Plot statistics for two-level cache?","Cache structure",'yes','no','no');
	if(strcmp(multi_level_ans,'no'))
		multi_level=0;
	elseif(strcmp(multi_level_ans,'yes'))
		multi_level=1;
	end
	
	%types of caches and benchmarks
	num_scope=["single_scope","multi_scope"];
	num_level=["single_level","multi_level"];
	
	rates=[64,128,256,512,1024];
	seeds=[1,2,3,4,5];

	%if multi-level then L2 results are 4 entries down from where L1 results
	%would be
%get predicted misses
cache_sizes=[128,512];
dataset_size=["small","medium"];
single_scope_benchmarks=["atax" "bicg" "cholesky" "doitgen" "durbin" "floyd-warshall" "gemm" "gesummv" "gramschmidt" "jacobi-1d" "nussinov" "seidel-2d" "symm" "syr2k" "syrk" "trisolv" "trmm"];
cache_level_str=["","_multi_level"];

base_save_path=[base_path,'/MATLAB_data_visualizations/'];

 		%make needed output directories if they don't already exist
 		if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/'],'dir')~=7)
 			mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/']);
 		end
 		if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/'],'dir')~=7)
 			mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/']);
		end
		%make needed output directories if they don't already exist
 		if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/sensitivity/'],'dir')~=7)
 			mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/sensitivity/']);
 		end
 		
		

	for size_index=1:2
		%grab and organize projected misses data
		file_path=[base_path,'software/fpga_proxy/results/cache/sensitivity_results/predicted_misses',convertStringsToChars(cache_level_str(multi_level+1)),'.txt'];
		projected_misses_table_all=readtable(file_path);
		%grab data from correct cache size and split based on dataset size
		pm_table=projected_misses_table_all(strcmp(projected_misses_table_all.Dataset_Size,dataset_size(size_index))&projected_misses_table_all.cache_size==cache_sizes(multi_level+1),:);
		%get benchmark names
	    benchmark_names=sort(unique(pm_table.benchmark_name));
		benchmark_names_single=benchmark_names(ismember(benchmark_names,single_scope_benchmarks));
		benchmark_names_multi=benchmark_names(~ismember(benchmark_names,single_scope_benchmarks));
		%loop over benchmarks
		for benchmark_index=1:length(benchmark_names)
			% loop over rates
			for rate_index=1:5
				%loop over seeds
				for seed_index=1:5
					if(any(strcmp(benchmark_names(benchmark_index),benchmark_names_single)))
						single_scope_projected_data{benchmark_index,rate_index}=pm_table.predicted_misses(strcmp(pm_table.benchmark_name,benchmark_names(benchmark_index))...
						&pm_table.rate==rates(rate_index));
					else
						multi_scope_projected_data{benchmark_index,rate_index}=pm_table.predicted_misses(strcmp(pm_table.benchmark_name,benchmark_names(benchmark_index))...
						&pm_table.rate==rates(rate_index));
					end
				end
			end
		end
		%remove empty cells
		
		single_scope_projected_data(cellfun('isempty',single_scope_projected_data(:,1)),:)=[];
			multi_scope_projected_data(cellfun('isempty',multi_scope_projected_data(:,1)),:)=[];

		%get plru and benchmark run data
	 		if(strcmp(dataset_size(size_index),'small'))
	 				file_path=[base_path,'software/fpga_proxy/results/cache/sensitivity_results/results_sensitivity.txt']; 	
			else
					file_path=[base_path,'software/fpga_proxy/results/cache/sensitivity_results/results_medium_sensitivity.txt'];
			end
				results_table_all=readtable(file_path);
				plru_table=results_table_all(results_table_all.rate==0&results_table_all.seed==0,:);
				results_table=results_table_all(strcmp(results_table_all.dataset_size,dataset_size(size_index)),:);
			%loop over policies
			for policy_index=1:length(lease_policies)
				%loop over benchmarks
				for benchmark_index=1:length(benchmark_names)
				% loop over rates
					for rate_index=1:5
						%loop over seeds
						for seed_index=1:5
							if(any(strcmp(benchmark_names(benchmark_index),benchmark_names_single)))
								indexes=strcmp(results_table.benchmark,benchmark_names(benchmark_index))...
								&results_table.rate==rates(rate_index)&strcmp(results_table.policy,lease_policies(policy_index));
								single_scope_results_data{policy_index}{benchmark_index,rate_index}=results_table.cache1_misses(indexes);
							else
								indexes=strcmp(results_table.benchmark,benchmark_names(benchmark_index))...
								&results_table.rate==rates(rate_index)&strcmp(results_table.policy,lease_policies(policy_index));
								multi_scope_results_data{policy_index}{benchmark_index,rate_index}=results_table.cache1_misses(indexes);
							end
						end
					end
				end
			end
			%remove empty cells
			for policy_index=1:2
			single_scope_results_data{policy_index}(cellfun('isempty',single_scope_results_data{policy_index}(:,1)),:)=[];
			multi_scope_results_data{policy_index}(cellfun('isempty',multi_scope_results_data{policy_index}(:,1)),:)=[];
			end
			%normalize all miss values
			for benchmark_index=1:length(benchmark_names)
				plru_indexes=strcmp(plru_table.benchmark,benchmark_names(benchmark_index));
				plru_miss_value=plru_table.cache1_misses(plru_indexes);
				single_scope_index=find(strcmp(benchmark_names(benchmark_index),benchmark_names_single)==1);
				multi_scope_index=find(strcmp(benchmark_names(benchmark_index),benchmark_names_multi)==1);
				if(single_scope_index)
					plru_total_references_single_scope(single_scope_index)=plru_table.cache1_hits(plru_indexes)+plru_miss_value;
				single_scope_projected_data(single_scope_index,:)=cellfun(@(x,y) x/plru_miss_value,  ...
					single_scope_projected_data(single_scope_index,:),'UniformOutput',false);
				else
					
					plru_total_references_multi_scope(multi_scope_index)=plru_table.cache1_hits(plru_indexes)+plru_miss_value;
				multi_scope_projected_data(multi_scope_index,:)=cellfun(@(x,y) x/plru_miss_value,...
					multi_scope_projected_data(multi_scope_index,:),'UniformOutput',false);
				end
				for policy_index=1:length(lease_policies)
					if(single_scope_index)
						single_scope_results_data{policy_index}(single_scope_index,:)=cellfun(@(x,y) x/plru_miss_value,  ...
					single_scope_results_data{policy_index}(single_scope_index,:),'UniformOutput',false);
					else
						multi_scope_results_data{policy_index}(multi_scope_index,:)=cellfun(@(x,y) x/plru_miss_value,...
					multi_scope_results_data{policy_index}(multi_scope_index,:),'UniformOutput',false);
					end
				end
			end
			plot_types=["CARL",lease_policies];
			
			for policy_index=1:length(plot_types)
				for scope_index=1:length(num_scope)
					box_plot_data=[];
					if(num_scope(scope_index)=="single_scope")
						benchmark_labels=benchmark_names_single;
					else
						benchmark_labels=benchmark_names_multi;
					end
					if(policy_index==1)
						if(num_scope(scope_index)=="single_scope")
							for j=1:size(single_scope_projected_data,1)
								box_plot_data=[box_plot_data,NaN(5,1),cell2mat(single_scope_projected_data(j,:))];
							end
						else
							for j=1:size(multi_scope_projected_data,1)
								box_plot_data=[box_plot_data,NaN(5,1),cell2mat(multi_scope_projected_data(j,:))];
							end
						end
					else
						if(num_scope(scope_index)=="single_scope")
							for j=1:length(benchmark_labels)
								box_plot_data=[box_plot_data,NaN(5,1),cell2mat(single_scope_results_data{policy_index-1}(j,:))];
							end
						else
							for j=1:length(benchmark_labels)
								box_plot_data=[box_plot_data,NaN(5,1),cell2mat(multi_scope_results_data{policy_index-1}(j,:))];
							end
						end
					end
						
						
							
				% create box plots
				fig=figure()
				t=colormap(parula(length(seeds)));
				set(fig,'Position',[0,0,1080,1920]);
				hold on
				%draw invisble plots to get legend entries
				for i = 1:length(rates)
					plot(NaN,1,'color', t(i,:), 'LineWidth', 4);
				end
				legend("64 accesses/sample","128 accesses/sample","256  accesses/sample","512  accesses/sample","1024  accesses/sample",...
			'Location','northeastoutside','Orientation','Vertical');
				
				%add NAN padding so actual data isn't right against the edge
				box_plot_data=[box_plot_data,NaN(5,1)];
				
				
				T=[ones(1,3);t;ones(1,3);t;ones(1,3);t;ones(1,3);t;ones(1,3);t;ones(1,3)];
				labels=repmat("",1,length(box_plot_data));
				for i=1:length(benchmark_labels)
					labels((i-1)*6+4)=benchmark_labels(i);
				end
				boxplot(box_plot_data,'colors',T,'plotstyle','compact','labels',labels)
			
				
				%get total number of references to place underneath label
				if (scope_index==1)
					plru_total_references=plru_total_references_single_scope;
				else
					plru_total_references=plru_total_references_multi_scope;
				end
				r=findobj('Type','text','-not',{'String',''});
				for label_index=1:length(r)
						%adjust undesired defaults for labels
					
					pos=r(label_index).Position;
					new_pos=[pos(1),pos(2)*1.5,pos(3)];
					set(r(label_index),'Rotation',90,'FontSize',14,'HorizontalAlignment','center');
					set(r(label_index),'Position',new_pos);
					references=text(0,0,strcat('(',num2str(plru_total_references(label_index)),')'),'HorizontalAlignment','left'...
							,'VerticalAlignment','top','Units','points');
						references.Position=[r(label_index).Position(1)+.30*(r(1).Position(1)-r(2).Position(1)),r(1).Position(2)];
							references.Rotation=90;
				end
				grid on
				ylabel('Policy Miss Count Normalized to PLRU Misses');
				title(['Sensitivity analysis for ',convertStringsToChars(plot_types(policy_index)),' at different sampling rates'])

				
				
				saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),...
					'/sensitivity/',convertStringsToChars(plot_types(policy_index)),'_',convertStringsToChars(num_scope(scope_index)),'_',convertStringsToChars(dataset_size(size_index)),'.png'])
				close(fig);
			end % for num scopes
		end % for policy
	end %for size



