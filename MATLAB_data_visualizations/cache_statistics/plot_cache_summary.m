function [] =plot_cache_summary(varargin)
% initialize workspace
	if usejava('desktop')
			clc;
			close all;
	end

	t=which('plot_cache_summary');
	cache_stats_dir=t(1:end-20);
	addpath([cache_stats_dir,'src']);
	base_path=t(1:end-64);

	geomean_file_path=[cache_stats_dir,'geomean.txt'];


	time=clock;

	% user selections
	% -------------------------------------------------------------------------

	%if a data set size argument hasn't been passed to the function
	if(nargin<1)
	dataset_size=inputdlg("Give dataset size for the benchmark results which you'd like to plot: ",'s');
	dataset_size=lower(cell2mat(dataset_size));
	else
	dataset_size=lower(varargin{1});
	end 
	if isempty(dataset_size)
		if usejava('desktop')
			return;
		else
			quit;
		end
	end

	%if the number of levels in the cache hasn't been passed to the function
	if(nargin<2)
	multi_level_ans=questdlg("Plot statistics for two-level cache?","Cache structure",'yes','no','no');
	else
	multi_level_ans=lower(varargin{2});
	end
	if isempty(multi_level_ans)
		if usejava('desktop')
			return;
		else
			quit;
		end
	end
	lease_policies=["CLAM","PRL","SHEL","C-SHEL"];


	
	if(strcmp(multi_level_ans,'no'))
		multi_level=0;
	elseif(strcmp(multi_level_ans,'yes'))
		multi_level=1;
	end
	%types of caches and benchmarks
	num_scope=["single_scope","multi_scope"];
	num_level=["single_level","multi_level"];

	%if multi-level then L2 results are 4 entries down from where L1 results
	%would be

	if(multi_level)
		offset=4;
	else
		offset=0;
	end

	%get results to plot
	if(strcmp(dataset_size,'small'))
		if(multi_level)
			file_path=[base_path,'software/fpga_proxy/results/cache/results_multi_level.txt'];
		else
			file_path=[base_path,'software/fpga_proxy/results/cache/results.txt'];
		end
	else
		if(multi_level)
			file_path=[base_path,'software/fpga_proxy/results/cache/results_',dataset_size,'_multi_level.txt'];
		else
			file_path=[base_path,'software/fpga_proxy/results/cache/results_',dataset_size,'.txt'];
		end
	end

	base_save_path=[base_path,'/MATLAB_data_visualizations/'];

	%make needed output directories if they don't already exist
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/']);
	end
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/']);
	end


	%benchmarks to ignore for small dataset size
	small_benchmarks=["jacobi-1d","trisolv","gesummv",'durbin'];

	single_scope_benchmarks=["atax" "bicg" "cholesky" "doitgen" "durbin" "floyd-warshall" "gemm" "gesummv" "gramschmidt" "jacobi-1d" "nussinov" "seidel-2d" "symm" "syr2k" "syrk" "trisolv" "trmm"];

	% extract data
	try
		[data,filenames,policies] = extract_data(file_path,offset);
	catch
		display("Invalid dataset size specified: allowed values are 'small', 'medium', 'large', and 'extra_large' ");
		if usejava('desktop')
			return;
		else
			pause(5);
			quit;
		end
	end
	%get benchmark names
	for i=1:length(filenames)
		benchmarks(i)=regexp(filenames{i},"/benchmarks/.*\/(.*)\/program",'tokens');
	end
	benchmarks=string(benchmarks);
	benchmark_names=unique(benchmarks);

	for i = 1:length(benchmark_names)
	    data_bm{i} = parse_name(data, transpose(benchmarks), benchmark_names(i));
	end

	%rearrange benchmarks so cross scoped RIs are on right and non cross scoped
	%are on left
	if(strcmp(dataset_size,'large'))
		re_index=[1,2,4:1:10,12:1:16,18,22:1:29,3,11,17,19,20,21];
	else
		re_index=[1,2,4:1:11,13:1:17,19,23:1:30,3,12,18,20,21,22];
	end
	data_bm=data_bm(re_index);
	benchmark_names=benchmark_names(re_index);

	%remove benchmarks too small to be meaningful
	data_bm(ismember(benchmark_names,small_benchmarks))=[];
	benchmark_names(ismember(benchmark_names,small_benchmarks))=[];


	%normalize by plru
	for i = 1:length(benchmark_names)
	    data_bm{i} = plru_norm(data_bm{i},offset);
	end

	%seperate PLRU data
	PLRU_data=cellfun(@(x) x(x(:,17+offset)<2,:),data_bm,'UniformOutput',false);
	data_bm=cellfun(@(x) x(x(:,17+offset)>1,:),data_bm,'UniformOutput',false);

	%split remaining benchmarks into single and multi scope benchmarks
	data_bm_single_scope=data_bm(ismember(benchmark_names,single_scope_benchmarks));
	benchmark_names_single=benchmark_names(ismember(benchmark_names,single_scope_benchmarks));
	data_bm_single_scope=cellfun(@(x) x(x(:,17+offset)<4,:),data_bm_single_scope,'UniformOutput',false);
	data_bm_multi_scope=data_bm(~ismember(benchmark_names,single_scope_benchmarks));
	data_bm_multi_scope=cellfun(@(x) x(x(:,17+offset)>1,:),data_bm_multi_scope,'UniformOutput',false);
	benchmark_names_multi=benchmark_names(~ismember(benchmark_names,single_scope_benchmarks));
	PLRU_single_scope=PLRU_data(ismember(benchmark_names,single_scope_benchmarks));
	PLRU_multi_scope=PLRU_data(~ismember(benchmark_names,single_scope_benchmarks));
	% don't display figures if we are running from command line

	%if usejava('desktop')
		set(0,'DefaultFigureVisible','on')
	%else
	%	set(0,'DefaultFigureVisible','off')
	%end
	
	
	%open geomean file and output header describing the data being visualized 
	fileID=fopen(geomean_file_path,'a');
	fprintf(fileID,"Plotting done on %d/%d/%d at %d:%d:%d\n",time(1),time(2),time(3),time(4),time(5),fix(time(6)));
	fprintf(fileID,"%s cache data for %s dataset",num_level(multi_level+1),dataset_size);

	%plot normalized misses or normalized clock cycles
	for h=1:2
		%plot for single or multi scope benchmarks
		for i=1:2
			if(i==1)
				if(h==1)
					bar_ydata=[];
					for j=1:length(data_bm_single_scope)
						sorted_benchmark=sortrows(data_bm_single_scope{j},17+offset);
						bar_ydata=[bar_ydata,sorted_benchmark(:,21+offset)];
					end
				else
					bar_ydata=[];
					for j=1:length(data_bm_single_scope)
						sorted_benchmark=sortrows(data_bm_single_scope{j},17+offset);
						bar_ydata=[bar_ydata,sorted_benchmark(:,22+offset)];
					end
				end
			else
				if(h==1)
					bar_ydata=[];
					for j=1:length(data_bm_multi_scope)
						sorted_benchmark=sortrows(data_bm_multi_scope{j},17+offset);
						bar_ydata=[bar_ydata,sorted_benchmark(:,21+offset)];
					end
				else
					bar_ydata=[];
					for j=1:length(data_bm_multi_scope)
						sorted_benchmark=sortrows(data_bm_multi_scope{j},17+offset);
						bar_ydata=[bar_ydata,sorted_benchmark(:,22+offset)];
					end
				end
			end
		% graphic
			fig=figure(1);
			set(fig, 'Position',[0,0,1080,1920]);
			bar_ydata=[bar_ydata,transpose(geomean(transpose(bar_ydata)))];
			b=bar(transpose(bar_ydata));
			t=colormap(parula(length(b)));
			for v=1:length(b)
			b(v).FaceColor=t(v,:);
			end
			
			if(h==1)
				ylabel('Policy Miss Count Normalized to PLRU Misses');
			else
				ylabel('Time of execution in Clock cycles normalized to PLRU clock cycles');
			end

			if(i==1)
				

				set(gca,'xticklabel',[benchmark_names_single,'GEOMEAN'],'FontSize',14);
			else
				set(gca,'xticklabel',[benchmark_names_multi,'GEOMEAN'],'FontSize',14);
			end
			xtickangle(gca,45);
			ylim([0,1.2]);
			xlim=get(gca,'xlim');
			hold on
			legend('AutoUpdate', 'Off')
			yline(1,'k-');
			grid on
			xCnt = cell2mat(get(b,'XData')) + cell2mat(get(b,'XOffset'));
			%display normalized values that exceed 1.2 as text on the inside of the top of each bar
			for j=1:size(bar_ydata,2)
				for k=1:size(bar_ydata,1)
					if(bar_ydata(k,j)>max(ylim))
						r=text(xCnt(k,j),min(bar_ydata(k,j),1.2),strip(num2str(round(bar_ydata(k,j),3)),'left','0'),'HorizontalAlignment','right','VerticalAlignment','middle','FontSize',12,'Rotation',90);
					end
				end
			end
			legend(convertStringsToChars(lease_policies(1:size(bar_ydata,1))),'Orientation','vertical','FontSize',14,'Location','northeastoutside');
			PLRU_array_data=[];
			%put absolute plru numbers for clock cycles or misses under
			%benchmark name.
		
			if(h==1)
				if(i==1)
					for z=1:length(benchmark_names_single)
						PLRU_array_data(z,:)=PLRU_single_scope{z};
					end
						misses=PLRU_array_data(:,7+offset);
						misses=[misses;round(geomean(misses))];
					for z=1:length(misses)
						raw_misses=text(0,0,strcat('(',num2str(misses(z)),')'),'HorizontalAlignment','left'...
						,'VerticalAlignment','bottom');
						raw_misses.Rotation=45;
						if strcmp(dataset_size,'large')
							raw_misses.FontSize=10;
							raw_misses.Position=[z-.3,-.14];
						else
							raw_misses.FontSize=12;
							raw_misses.Position=[z-.3,-.14];
						end
						raw_misses.Color=[0 0 0];
					end
				else
					for z=1:length(benchmark_names_multi)
						PLRU_array_data(z,:)=PLRU_multi_scope{z};
					end
						misses=PLRU_array_data(:,7+offset);
						misses=[misses;round(geomean(misses))];
					for z=1:length(misses)
						raw_misses=text(0,0,strcat('(',num2str(misses(z)),')'),'HorizontalAlignment','left'...
						,'VerticalAlignment','bottom');
						raw_misses.Rotation=45;
						if strcmp(dataset_size,'large')
							raw_misses.FontSize=10;
							raw_misses.Position=[z-.3,-.14];
						else
							raw_misses.FontSize=12;
							raw_misses.Position=[z-.3,-.14];
						end
						raw_misses.Color=[0 0 0];
					end
				end
			else
				if(i==1)
					for z=1:length(benchmark_names_single)
					PLRU_array_data(z,:)=PLRU_single_scope{z};
					end
					cycles=PLRU_array_data(:,4);
					cycles=[cycles;round(geomean(cycles))];
					for z=1:length(cycles)
						raw_cycles=text(0,0,strcat('(',num2str(cycles(z)),')'),...
						'VerticalAlignment','Bottom','HorizontalAlignment','left');
						raw_cycles.Rotation=45;
						if strcmp(dataset_size,'large')
							raw_cycles.FontSize=10;
							raw_cycles.Position=[z-.3,-.14];
						else
							raw_cycles.FontSize=12;
							raw_cycles.Position=[z-.3,-.14];
						end
						raw_cycles.Color=[0 0 0];
					end
				else
					for z=1:length(benchmark_names_multi)
					PLRU_array_data(z,:)=PLRU_multi_scope{z};
					end
					cycles=PLRU_array_data(:,4);
					cycles=[cycles;round(geomean(cycles))];
					for z=1:length(cycles)
						raw_cycles=text(0,0,strcat('(',num2str(cycles(z)),')'),...
						'VerticalAlignment','Bottom','HorizontalAlignment','left');
						raw_cycles.Rotation=45;
						if strcmp(dataset_size,'large')
							raw_cycles.FontSize=10;
							raw_cycles.Position=[z-.3,-.14];
						else
							raw_cycles.FontSize=12;
							raw_cycles.Position=[z-.3,-.14];
						end
						raw_cycles.Color=[0 0 0];
					end
				end
			end
			
			if(h==1)
				fprintf(fileID,"\nGeomean values for %s normalized misses: ",convertStringsToChars(num_scope(i)));
				for j=1:size(bar_ydata,1)
					fprintf(fileID,"%s: %.5f ",lease_policies(j),bar_ydata(j,end));
				end

				saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/misses_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
			elseif(h==2)
				fprintf(fileID,"\nGeomean values for %s normalized clock cycles: ",convertStringsToChars(num_scope(i)));
				for j=1:size(bar_ydata,1)
					fprintf(fileID,"%s: %.5f ",lease_policies(j),bar_ydata(j,end));
				end
				saveas(fig,[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/clock_cycles_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
			end
			close(fig)
		end
	end
	fprintf(fileID,"\n\n");
	fclose(fileID);


	% Generate predicted misses graph
	temp_file=[cache_stats_dir,'temp.csv'];
	%generate CSV file with all miss data
	system(['echo "Size, Policy, Dataset_Size, benchmark_name, predicted_misses" >',temp_file]);
	gen_predictive_miss_command=['grep -rnw "predicted miss" /home/matthew/Documents/Thesis_stuff/software/CLAM/leases/**/' ...
	'| sed ''s/.*entries\/\([0-9]*\).*ways_\([A-Za-z\-]*\)_*\([a-zA-Z]*\|\)\/\([0-9A-Za-z\-]*\).*:\s*\([0-9]*\)$/\1,\2,\3,\4,\5/'' ' ...
	'| sed ''s/,,/,small,/'' >> ', temp_file];
	system(gen_predictive_miss_command);
	%import the miss data to a table 
	data_table=readtable(temp_file);
	%delete file (the actual misses chance with tweaks in policy so no point in
	%saving it.
	system(['rm ',temp_file]);
	cache_sizes=[128,512];
	%get the subset of the table with the correct cache size
	data_table1=data_table(data_table.Size==cache_sizes(multi_level+1),:);
	%get the subset of the table with the correct data set size
	data_table2=data_table1(strcmp(data_table1.Dataset_Size,dataset_size),:);

%iterate over single scope and multi scope benchmarks
	for i=1:2
		projected_misses=[]
		actual_misses=[]
		random_evictions=[]
		if(i==1)
			benchmark_names_to_plot=benchmark_names_single;
			used_policies=size(data_bm_single_scope{1},1);
		else
			benchmark_names_to_plot=benchmark_names_multi;
			used_policies=size(data_bm_multi_scope{1},1);
		end	
		for j=1:length(benchmark_names_to_plot)
		%sort rows into correct lease policy order
			sorted_benches=sortrows(data_bm_single_scope{i},17+offset);
			%iterate over used policies
			for k=1:length(used_policies)
			    projected_misses(j,k)=data_table2.predicted_misses(strcmp(data_table2.Policy(:),lease_policies(k))...
				 &strcmp(data_table2.benchmark_name(:),benchmark_names_to_plot(j))); 
			actual_misses(j,k)=sorted_benches(k,7+offset);
			random_evictions(j,k)=sorted_benches(k,13+offset);
			end
		end
		if(~any(any(random_evictions./actual_misses)))
			return
		end

		fig(1)=subplot(1,2,1);
		figure('units','normalized','outerposition',[0 0 1 1]);
		pos=fig(1).Position;
		fig(1).Position=[.05,pos(2),pos(3)+.075,pos(4)];
		b=bar(random_evictions./actual_misses);
		legend(convertStringsToChars(lease_policies(1:used_policies),'Orientation','vertical','FontSize',14,'Location','eastoutside');
		t=colormap(parula(length(b)));
				for v=1:length(b)
				b(v).FaceColor=t(v,:);
				end
		set(gca,'xticklabel',[benchmark_names_to_plot],'FontSize',14);
		xtickangle(gca,45);
		ylim([0, max(max(random_evictions./actual_misses))*1.2]);
		xlim=get(gca,'xlim');
		grid on
		ylabel("Ratio of random evictions to misses")

		fig(2)=subplot(1,2,2);
		fig_pos=fig(2).Position;
		fig(2).Position=[fig_pos(1)-.05,fig_pos(2),fig_pos(3)+.05,fig_pos(4)];
		 neg_array=zeros(size(projected_misses,1),size(projected_misses,2));
		pos_array=zeros(size(projected_misses,1),size(projected_misses,2));
		percent_error=(projected_misses-actual_misses)./projected_misses;
		for y=1:size(percent_error,1)
			for r=1:size(percent_error,2)
				if(percent_error(y,r)<0)
					neg_array(y,r)=abs(percent_error(y,r));
				else
					pos_array(y,r)=percent_error(y,r);
				end
			end
		end
		b=[];
		b=[b,bar(pos_array)];
		hold on
		b=[b,bar(neg_array)];
		hold off
		t=colormap(parula(length(b)));
				for v=1:length(b)
				b(v).FaceColor=t(v,:);
				end

		fig(2).YScale='log';
		legend_names=[];
		err_sign=["+error","-error"];

		for j=1:2
			for k=1:size(projected_misses,2)
				legend_names=[legend_names,strcat(err_sign{j}," ",lease_policies(k))];
			end
		end
		leg=legend(convertStringsToChars(legend_names),'Location','eastoutside','Orientation','vertical','FontSize',14);
		leg_pos=leg.Position;
		leg.Position=[(leg_pos(1)*.5+.5) leg_pos(2), leg_pos(3), leg_pos(4)];
		set(gca,'xticklabel',[benchmark_names_to_plot],'FontSize',14);
		xtickangle(gca,45);
		xlim=get(gca,'xlim');
		grid on
		label_pos=ylabel("Percent error between projected and actual misses (log)");
		saveas(gcf,[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/contention_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
		close(gcf)
	end
end
