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

	
	
	
	%open geomean file and output header describing the data being visualized 
	fileID=fopen(geomean_file_path,'a');
	fprintf(fileID,"Plotting done on %d/%d/%d at %d:%d:%d\n",time(1),time(2),time(3),time(4),time(5),fix(time(6)));
	fprintf(fileID,"%s cache data for %s dataset",num_level(multi_level+1),dataset_size);

	%plot normalized misses or normalized clock cycles
	plru_normed_data=cell(4,1);
	miss_ratios=cell(2,1);
	for h=1:2
		%plot for single or multi scope benchmarks
		for i=1:2
			if(i==1)
				num_benchmarks=length(data_bm_single_scope);
				used_policies=size(data_bm_single_scope{1},1);
				if(h==1)
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_single_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,21+offset)];
						miss_ratios{i}=[miss_ratios{i},sorted_benchmark(:,7+offset)./(sorted_benchmark(:,7+offset)+sorted_benchmark(:,6+offset))];
					end
				else
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_single_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,22+offset)];
					end
				end
			else
				num_benchmarks=length(data_bm_multi_scope);
				used_policies=size(data_bm_multi_scope{1},1);
				if(h==1)
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_multi_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,21+offset)];
						miss_ratios{i}=[miss_ratios{i},sorted_benchmark(:,7+offset)./(sorted_benchmark(:,7+offset)+sorted_benchmark(:,6+offset))];
					end
				else
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_multi_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,22+offset)];
					end
				end
			end
		% graphic
			fig((h-1)*2+i)=figure();
			set(fig((h-1)*2+i), 'Position',[0,0,1080,1920]);
			b=bar(transpose([plru_normed_data{i+(h-1)*2},transpose(geomean(transpose(plru_normed_data{i+(h-1)*2})))]));
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
			if used_policies+1>3
				txt_size=8;
			else
				txt_size=11;
			end
			%display normalized values that exceed 1.2 as text on the inside of the top of each bar
			for j=1:used_policies
				if check_if_light_or_dark(t(j,:).*255); txtcolor=[0 0 0]; else; txtcolor=[.85,.85,.85]; end
				for k=1:num_benchmarks
					if(plru_normed_data{i+(h-1)*2}(j,k)>max(ylim))
						max_val=max(ylim);
						text(xCnt(j,k),max_val*.2+(max_val*.6)*j/used_policies,strip(num2str(round(plru_normed_data{i+(h-1)*2}(j,k),3)),'left','0'),'HorizontalAlignment',...
						'right','VerticalAlignment','middle','FontSize',txt_size,'Rotation',90,'Color',txtcolor);
					end
				end
			end
			legend(convertStringsToChars(lease_policies(1:size(plru_normed_data{i+(h-1)*2},1))),'Orientation','vertical','FontSize',14,'Location','northeastoutside');
			PLRU_array_data=[];
			%put absolute plru numbers for clock cycles or misses under
			%benchmark name.
			if(h==1)
				if(i==1)
					for z=1:num_benchmarks
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
					
					for z=1:num_benchmarks
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
					for z=1:num_benchmarks
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
					for z=1:num_benchmarks
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
			geomean_values=transpose(geomean(transpose(plru_normed_data{i+(h-1)*2})));
			if(h==1)
				fprintf(fileID,"\nGeomean values for %s normalized misses: ",convertStringsToChars(num_scope(i)));
				for j=1:size(plru_normed_data{i+(h-1)*2},1)
					fprintf(fileID,"%s: %.5f ",lease_policies(j),geomean_values(j));
				end

				saveas(fig((h-1)*2+i),[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/misses_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
				close(fig((h-1)*2+i));
			elseif(h==2)
				fprintf(fileID,"\nGeomean values for %s normalized clock cycles: ",convertStringsToChars(num_scope(i)));
				for j=1:size(plru_normed_data{i+(h-1)*2},1)
					fprintf(fileID,"%s: %.5f ",lease_policies(j),geomean_values(j));
				end
				saveas(fig((h-1)*2+i),[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/clock_cycles_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
				close(fig((h-1)*2+i));
			end
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
		projected_misses=[];
		actual_misses=[];
		random_evictions=[];
		if(i==1)
			benchmark_names_to_plot=benchmark_names_single;
			used_policies=size(data_bm_single_scope{1},1);
			data_to_plot=data_bm_single_scope;
			num_benchmarks=length(data_bm_single_scope);
			plru_data=PLRU_single_scope;
		else
			benchmark_names_to_plot=benchmark_names_multi;
			used_policies=size(data_bm_multi_scope{1},1);
			data_to_plot=data_bm_multi_scope;
			num_benchmarks=length(data_bm_multi_scope);
			plru_data=PLRU_multi_scope;
		end	
		for j=1:num_benchmarks
		%sort rows into correct lease policy order
			sorted_benches=sortrows(data_to_plot{j},17+offset);
			%iterate over used policies
			for k=1:used_policies
			    projected_misses(j,k)=data_table2.predicted_misses(strcmp(data_table2.Policy(:),lease_policies(k))...
				 &strcmp(data_table2.benchmark_name(:),benchmark_names_to_plot(j))); 
			actual_misses(j,k)=sorted_benches(k,7+offset);
			random_evictions(j,k)=sorted_benches(k,13+offset);
			end
		end
		if(~any(any(random_evictions./actual_misses)))
			return
		end
		fig(i)=figure();
		ax1=subplot(2,2,1);
		set(fig(i),'units','normalized','outerposition',[0 0 1 1]);
		pos=ax1.Position;
		ax1.Position=[.05,pos(2)+.04,pos(3)+.075,pos(4)];
		b=bar(random_evictions./actual_misses);
			t=colormap(parula(length(b)));
				for v=1:length(b)
				b(v).FaceColor=t(v,:);
				end
		set(ax1,'xticklabel',benchmark_names_to_plot,'FontSize',14);
		xtickangle(gca,45);
		ylim([0, max(max(random_evictions./actual_misses))*1.2]);
		grid on
		ylabel("Ratio of random evictions to misses")

		ax3=subplot(2,2,[2,4]);
		fig_pos=ax3.Position;
		ax3.Position=[fig_pos(1)-.05,fig_pos(2)+.04,fig_pos(3)+.05,fig_pos(4)];
		percent_error=(projected_misses-actual_misses)./projected_misses;
		b=bar(percent_error);
			ylim([-.6,.6]);
		t=colormap(parula(length(b)));
				for v=1:length(b)
				b(v).FaceColor=t(v,:);
				end

		xCnt = cell2mat(get(b,'XData')) + cell2mat(get(b,'XOffset'));
			%display normalized values that exceed min or max as text on
			%the inside of each bar staggered per policy
			for j=1:used_policies
						if check_if_light_or_dark(t(j,:).*255); txtcolor=[0 0 0]; else; txtcolor=[.85,.85,.85]; end
				for k=1:num_benchmarks
					if(percent_error(k,j)>max(ylim))
						max_val=max(ylim);
						text(xCnt(j,k),max_val*.2+(max_val*.6)*j/used_policies,strip(num2str(round(percent_error(k,j),3)),'left','0'),'HorizontalAlignment',...
						'right','VerticalAlignment','middle','FontSize',9,'Rotation',90,'Color',txtcolor);
					elseif(percent_error(k,j)<min(ylim))
						min_val=min(ylim);
						text(xCnt(j,k),min_val*.2+(min_val*.6)*j/used_policies,strip(num2str(round(percent_error(k,j),3)),'left','0'),'HorizontalAlignment',...
							'right','VerticalAlignment','middle','FontSize',9,'Rotation',270,'Color',txtcolor);
					end
				end
			end
		
		
		set(ax3,'xticklabel',[benchmark_names_to_plot],'FontSize',14);
		xtickangle(ax3,45);
		grid on
		label_pos=ylabel("Percent error between projected and actual misses");
		%add normalized misses subplot to contention plot with added normalized
		%bar for projected CLAM misses.
		plru_miss_ratios=[];
		%normalize projected misses by PLRU misses and get PLRU miss ratios
		for j=1:num_benchmarks
			normed_CLAM_projected_misses(j)=projected_misses(j,1)/plru_data{j}(7+offset);
			%if hits are actually total references (old way)
			plru_miss_ratios(j)=plru_data{j}(7+offset)/(plru_data{j}(7+offset)+plru_data{j}(6+offset));
		end
		ax2=subplot(2,2,3);
		fig_pos=ax2.Position;
		ax2.Position=[.05,fig_pos(2)+.04,fig_pos(3)+.075,fig_pos(4)];
		bar_data=[plru_normed_data{i};normed_CLAM_projected_misses];
		b=bar(transpose(bar_data));
		
		ylabel('Policy Miss Count Normalized to PLRU Misses');
		set(gca,'xticklabel',benchmark_names_to_plot,'FontSize',14);
		t=colormap(parula(length(b)-1));
		for v=1:length(b)-1
			b(v).FaceColor=t(v,:);
		end
		b(end).FaceColor=[0,0,0];
		t=[t;b(end).FaceColor];
		xtickangle(gca,45);
		ylim([0,1.2]);
		xlim=get(gca,'xlim');
		hold on
		legend('AutoUpdate', 'Off')
		yline(1,'k-');
		grid on
		xCnt = cell2mat(get(b,'XData')) + cell2mat(get(b,'XOffset'));
		if used_policies+1>3
			txt_size=8;
		else
			txt_size=11;
		end
		%display normalized values that exceed 1.2 as text on the inside of the top of each bar
		for j=1:used_policies+1
			if check_if_light_or_dark(t(j,:).*255); txtcolor=[0 0 0]; else; txtcolor=[.85,.85,.85]; end
			for k=1:num_benchmarks
				if(bar_data(j,k)>max(ylim))
					max_val=max(ylim);
					text(xCnt(j,k),max_val*.2+(max_val*.6)*j/(used_policies+1),strip(num2str(round(bar_data(j,k),3)),'left','0'),'HorizontalAlignment',...
					'right','VerticalAlignment','middle','FontSize',txt_size,'Rotation',90,'Color',txtcolor);
				end
			end
		end
	legend_cell_ar=convertStringsToChars(lease_policies(1:used_policies));
	legend_cell_ar{length(legend_cell_ar)+1}='Proj\_CLAM';
	leg=legend(legend_cell_ar,'Location','southeastoutside','Orientation','vertical','FontSize',14);
	leg_pos=leg.Position;
	leg.Position=[(leg_pos(1)*.5+.72) leg_pos(2)+.4, leg_pos(3), leg_pos(4)];
	saveas(fig(i),[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/contention_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
	close(fig(i));

	% plot miss ratios

	fig(2+i)=figure();
	set(fig(2+i), 'Position',[0,0,1080,1920]);
	b=bar(transpose([miss_ratios{i};plru_miss_ratios]));
	t=colormap(parula(length(b)-1));
		for v=1:length(b)-1
			b(v).FaceColor=t(v,:);
		end
		b(end).FaceColor=[0,0,0];
		t=[t;b(end).FaceColor];
	ylabel('Policy Miss ratios');
	set(gca,'xticklabel',benchmark_names_to_plot,'FontSize',14);
	xtickangle(gca,45);
	ylim([0:1]);
	legend('AutoUpdate', 'Off')
	yticks([0:.05:1]);
	yline(.05,'k-');
	grid on;
	legend_cell_ar=convertStringsToChars(lease_policies(1:used_policies));
	legend_cell_ar{length(legend_cell_ar)+1}='PLRU';
	legend(legend_cell_ar,'Location','northeastoutside','Orientation','vertical','FontSize',14);
	saveas(fig(2+i),[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/miss_ratios_',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'])
	close(fig(2+i));
	end
end


function[answer]=check_if_light_or_dark(rgb)


hsp = sqrt(0.299 * (rgb(1)^2) + 0.587 * (rgb(2)^2) + 0.114 * (rgb(3)^2));
    if (hsp>127.5)
        answer= 1;
	else
        answer= 0;
	end
end
