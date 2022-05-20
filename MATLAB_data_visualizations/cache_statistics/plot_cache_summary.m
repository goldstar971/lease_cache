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
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/misses/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/misses/']);
	end
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/contention/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/contention/']);
	end
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/clock_cycles/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/clock_cycles/']);
	end
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/miss_ratios/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/miss_ratios/']);
	end
	if(exist([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/delta_scatter/'],'dir')~=7)
		mkdir([base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/delta_scatter/']);
	end

	%benchmarks to ignore for small dataset size
	small_benchmarks=[''];%["jacobi-1d","trisolv","gesummv",'durbin'];

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
	%make sure in alphabetical order
	benchmark_names=sort(unique(benchmarks));
	

	for i = 1:length(benchmark_names)
	    data_bm{i} = parse_name(data, transpose(benchmarks), benchmark_names(i));
	end

	%rearrange benchmarks so cross scoped RIs are on right and non cross scoped
	%are on left
	
		re_index=[1,2,4:1:11,13:1:17,19,23:1:30,3,12,18,20,21,22];
	
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

	%not used because graphs end up being saved very distorted.
%		if ~usejava('desktop')
	%		set(0,'DefaultFigureVisible','off');	
%		end

% Get predicted misses data
	temp_file=[cache_stats_dir,'temp.csv'];
	%generate CSV file with all miss data
	system(['echo "Size, Policy, Dataset_Size, benchmark_name, predicted_misses" >',temp_file]);
gen_predictive_miss_command=['grep -rnw "predicted miss" ',base_path,'software/CLAM/leases/**/**/**/**/*leases' ...
' |sed ''s/^.*_llt_entries\/\([0-9]\+\)blocks\/[0-9]\+ways\/\([A-Z\-]\+\)_*\([a-z]*\)\/\([a-z0-9\-]\+\)_.*_leases.*: \([0-9]\+\)$/\1,\2,\3,\4,\5/'' '...
' | sed ''s/,,/,small,/'' >> ', temp_file];
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
			projected_misses=[];
			if(i==1)
				num_benchmarks=length(data_bm_single_scope);
				used_policies=size(data_bm_single_scope{1},1);
				if(h==1)
					used_policies=used_policies+1;
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_single_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,21+offset)];
						miss_ratios{i}=[miss_ratios{i},sorted_benchmark(:,7+offset)./(sorted_benchmark(:,7+offset)+sorted_benchmark(:,6+offset))];
			    		projected_misses(j)=data_table2.predicted_misses(strcmp(data_table2.Policy(:),lease_policies(1))...
				 		&strcmp(data_table2.benchmark_name(:),benchmark_names_single(j))); 
						%normalized by plru
						projected_misses(j)=projected_misses(j)/PLRU_single_scope{j}(7+offset);
				 	end
				 	plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2};projected_misses];
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
					used_policies=used_policies+1;
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_multi_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,21+offset)];
						miss_ratios{i}=[miss_ratios{i},sorted_benchmark(:,7+offset)./(sorted_benchmark(:,7+offset)+sorted_benchmark(:,6+offset))];
			    		projected_misses(j)=data_table2.predicted_misses(strcmp(data_table2.Policy(:),lease_policies(1))...
				 		&strcmp(data_table2.benchmark_name(:),benchmark_names_multi(j))); 
				 		%normalized by plru
						projected_misses(j)=projected_misses(j)/PLRU_multi_scope{j}(7+offset);
						%resort 
				 	end
				 	plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2};projected_misses];
				else
					for j=1:num_benchmarks
						sorted_benchmark=sortrows(data_bm_multi_scope{j},17+offset);
						plru_normed_data{i+(h-1)*2}=[plru_normed_data{i+(h-1)*2},sorted_benchmark(:,22+offset)];
					end
				end
			end
		% graphic

			fig((h-1)*2+i)=figure();
			set(0,'currentfigure',fig((h-1)*2+i));
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
			set(gca,'xtick',[1:1:num_benchmarks+1]);
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
			if(i==2)
				xline(num_benchmarks+1-6.5,'r');
			end
			grid on
			xCnt = cell2mat(get(b,'XData')) + cell2mat(get(b,'XOffset'));
			if used_policies>3
				txt_size=7;
			else
				txt_size=11;
			end
			%display normalized values that exceed 1.2 as text on the inside of the top of each bar
			for j=1:used_policies
				if check_if_light_or_dark(t(j,:).*255); txtcolor=[0 0 0]; else; txtcolor=[.85,.85,.85]; end
				for k=1:num_benchmarks
					if(plru_normed_data{i+(h-1)*2}(j,k)>max(ylim))
						max_val=max(ylim);
						text(xCnt(j,k),max_val*.2+(max_val*.6)*j/(used_policies+1),strip(num2str(round(plru_normed_data{i+(h-1)*2}(j,k),3)),'left','0'),'HorizontalAlignment',...
						'right','VerticalAlignment','middle','FontSize',txt_size,'Rotation',90,'Color',txtcolor);
					end
				end
			end
			if (h==1)
				legend(convertStringsToChars([lease_policies(1:size(plru_normed_data{i+(h-1)*2},1)-1),"CARL"]),'Orientation','vertical','FontSize',14,'Location','northeastoutside');
			else 
				legend(convertStringsToChars(lease_policies(1:size(plru_normed_data{i+(h-1)*2},1))),'Orientation','vertical','FontSize',14,'Location','northeastoutside');
			end
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
						%equation for positioning found using linear regression on emperically generated results
							raw_misses.Position=[(z-1)-0.01789*num_benchmarks+.82316,-.14];
						else
							raw_misses.FontSize=12;
						%equation for positioning found using linear regression on emperically generated results
							raw_misses.Position=[(z-1)-0.025*num_benchmarks + 0.985,-.14];
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
							raw_misses.Position=[(z-1)-0.01789*num_benchmarks+.82316,-.14];
						else
							raw_misses.FontSize=12;
							raw_misses.Position=[(z-1)-0.025*num_benchmarks + 0.985,-.14];
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
							raw_cycles.Position=[(z-1)-0.01789*num_benchmarks+.82316,-.14];
						else
							raw_cycles.FontSize=12;
							raw_cycles.Position=[(z-1)-0.025*num_benchmarks + 0.985,-.14];
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
							raw_cycles.Position=[(z-1)-0.01789*num_benchmarks+.82316,-.14];
						else
							raw_cycles.FontSize=12;
							raw_cycles.Position=[(z-1)-0.025*num_benchmarks + 0.985,-.14];
						end
						raw_cycles.Color=[0 0 0];
					end
				end
			end

			geomean_values=transpose(geomean(transpose(plru_normed_data{i+(h-1)*2})));
			if(h==1)
				fprintf(fileID,"\nGeomean values for %s normalized misses: ",convertStringsToChars(num_scope(i)));
				for j=1:size(plru_normed_data{i+(h-1)*2},1)
					if(j==1)
						fprintf(fileID,"%s: %f ","CARL",geomean_values(1));
					else 
						fprintf(fileID,"%s: %.5f ",lease_policies(j-1),geomean_values(j));
					end
				end
				fig((h-1)*2+i);
				export_fig -c[inf inf inf inf] -q101 temp.png
				move_path=[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/misses/',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'];
				system(strcat("mv temp.png ",move_path))
				close(fig((h-1)*2+i));
			elseif(h==2)
				fprintf(fileID,"\nGeomean values for %s normalized clock cycles: ",convertStringsToChars(num_scope(i)));
				for j=1:size(plru_normed_data{i+(h-1)*2},1)
					fprintf(fileID,"%s: %.5f ",lease_policies(j),geomean_values(j));
				end
				fig((h-1)*2+i);
				export_fig -c[inf inf inf inf] -q101 temp.png
				move_path=[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/clock_cycles/',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'];
				system(strcat("mv temp.png ",move_path))
				close(fig((h-1)*2+i));
			end
		end
	end
	fprintf(fileID,"\n\n");
	fclose(fileID);



%iterate over single scope and multi scope benchmarks
	for i=1:2
		projected_misses=[];
		actual_misses=[];
		random_evictions=[];
		if(i==1)
			benchmark_names_to_plot=[benchmark_names_single,'GEOMEAN'];
			used_policies=size(data_bm_single_scope{1},1);
			data_to_plot=[data_bm_single_scope];
			num_benchmarks=length(benchmark_names_to_plot);
			plru_data=PLRU_single_scope;
		else
			benchmark_names_to_plot=[benchmark_names_multi,'GEOMEAN'];
			used_policies=size(data_bm_multi_scope{1},1);
			data_to_plot=[data_bm_multi_scope];
			num_benchmarks=length(benchmark_names_to_plot);
			plru_data=PLRU_multi_scope;
		end	
		for j=1:num_benchmarks-1
		%sort rows into correct lease policy order
			sorted_benches=sortrows(data_to_plot{j},17+offset);
			%iterate over used policies
			for k=1:used_policies
			    projected_misses(j,k)=data_table2.predicted_misses(strcmp(data_table2.Policy(:),lease_policies(k))...
				 &strcmp(data_table2.benchmark_name(:),benchmark_names_to_plot(j)))/plru_data{j}(7+offset); 
			actual_misses(j,k)=sorted_benches(k,7+offset);
			random_evictions(j,k)=sorted_benches(k,13+offset);
			end
		end
		projected_misses(j+1,1)=geomean(projected_misses(projected_misses(:,1)>0));


		fig(i)=figure();

			set(0,'currentfigure',fig(i));
		ax1=subplot(2,1,1);
		set(fig(i),'units','normalized','outerposition',[0 0 1 1]);
		pos=ax1.Position;
		ax1.Position=[.05,pos(2)+.04,pos(3)+.075,pos(4)];
		bar_data=random_evictions./actual_misses;
		bar_data2=[];
		for k=1:used_policies
			bar_data2(:,k)=[bar_data(:,k);geomean(bar_data(bar_data(:,k)>0,k))];
		end
		
		b=bar(bar_data2);
			t=colormap(parula(length(b)));
				for v=1:length(b)
				b(v).FaceColor=t(v,:);
				end
		set(gca,'xtick',[1:1:num_benchmarks]);
		set(ax1,'xticklabel',benchmark_names_to_plot,'FontSize',14);
		xtickangle(gca,45);
		ylim([0, max(max(random_evictions./actual_misses))*1.2]);
		grid on
		ylabel("Ratio of random evictions to misses")

		
		%add normalized misses subplot to contention plot 
		plru_miss_ratios=[];
		normed_CLAM_projected_misses=projected_misses(:,1)';

		
		ax2=subplot(2,1,2);
		fig_pos=ax2.Position;
		ax2.Position=[.05,fig_pos(2)+.04,fig_pos(3)+.075,fig_pos(4)];
		bar_data=[plru_normed_data{i},geomean(plru_normed_data{i}')'];
		

		b=bar(transpose(bar_data));
		
		ylabel('Policy Miss Count Normalized to PLRU Misses');
		set(gca,'xtick',[1:1:num_benchmarks+1]);
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
		if(i==2)
			xline(num_benchmarks+1-6.5,'r');
		end
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
			%put absolute plru numbers for clock cycles or misses under benchmark name.
			plru_data2=[];
			for z=1:num_benchmarks-1
				plru_data2(z,:)=plru_data{z};
			end
			plru_misses=plru_data2(:,7+offset);
			plru_misses=[plru_misses;round(geomean(plru_misses))];
% 					for z=1:length(plru_misses)
% 						raw_plru_misses=text(0,0,strcat('(',num2str(plru_misses(z)),')'),'HorizontalAlignment','left'...
% 						,'VerticalAlignment','bottom');
% 						raw_plru_misses.Rotation=45;
% 						if strcmp(dataset_size,'large')
% 							raw_plru_misses.FontSize=10;
% 						%equation for positioning found using linear regression on emperically generated results
% 							raw_plru_misses.Position=[(z-1)-0.01789*num_benchmarks+.82316,-.19];
% 						else
% 							raw_plru_misses.FontSize=12;
% 						%equation for positioning found using linear regression on emperically generated results
% 							raw_plru_misses.Position=[(z-1)-0.025*num_benchmarks + 0.085,-.19];
% 						end
% 						raw_plru_misses.Color=[0 0 0];
% 					end

	legend_cell_ar=convertStringsToChars([lease_policies(1:used_policies),"CARL"]);
	leg=legend(legend_cell_ar,'Location','southeastoutside','Orientation','vertical','FontSize',14);
	leg_pos=leg.Position;
	leg.Position=[(leg_pos(1)+.08) leg_pos(2)+.35, leg_pos(3), leg_pos(4)];
	fig(i)
	export_fig -c[inf inf inf inf] -q101 temp.png
	move_path=[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/contention/',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'];
	system(strcat("mv temp.png ",move_path))
	close(fig(i));

	% plot miss ratios
	%get PLRU miss ratios
	for j=1:num_benchmarks-1
			plru_miss_ratios(j)=plru_data{j}(7+offset)/(plru_data{j}(7+offset)+plru_data{j}(6+offset));
		end
	fig(2+i)=figure();
	set(0,'currentfigure',fig(2+i));
	set(fig(2+i), 'Position',[0,0,1080,1920]);
	b=bar([miss_ratios{i},geomean(miss_ratios{i}')';plru_miss_ratios,geomean(plru_miss_ratios)']');
	t=colormap(parula(length(b)-1));
		for v=1:length(b)-1
			b(v).FaceColor=t(v,:);
		end
		b(end).FaceColor=[0,0,0];
		t=[t;b(end).FaceColor];
	ylabel('Policy Miss ratios');
	set(gca,'xtick',[1:1:num_benchmarks+1]);
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
	fig(2+i);
	export_fig -c[inf inf inf inf] -q101 temp.png
	move_path=[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/miss_ratios/',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'];
	system(strcat("mv temp.png ",move_path))
	close(fig(2+i));

	%plot scatter plots of ratio of random evictions to misses against delta between normalized projected and actual misses 
	bar_data=random_evictions./actual_misses;
		bar_data2=[];
		for k=1:used_policies
			bar_data2(:,k)=[bar_data(:,k);geomean(bar_data(bar_data(:,k)>0,k))];
		end
	results_delta=[actual_misses;geomean(actual_misses)]./repmat(plru_misses,1,used_policies);
		fig(3+i)=figure();
	set(0,'currentfigure',fig(3+i));
	set(fig(3+i),'units','normalized','outerposition',[0 0 1 1]);
	hold on
	for k=1:used_policies
	s(k)=scatter(results_delta(:,k),bar_data2(:,k),'filled','SizeData',100);
	end
	t=colormap(parula(length(s)));
		for v=1:length(s)
			s(v).CData=t(v,:);
		end
	grid on
	ylabel("Ideal $\Delta$ Actual",'Interpreter','latex','FontSize',14);
	xlabel("Ratio of random evictions to misses",'FontSize',14);
	title("Ideality Deviation vs. % of Forced Evictions",'FontSize',16);
	grid on;
	legend_cell_ar=convertStringsToChars(lease_policies(1:used_policies));
	legend(legend_cell_ar,'Location','northeastoutside','Orientation','vertical','FontSize',14);
	export_fig -c[inf inf inf inf] -q101 temp.png
	move_path=[base_save_path,'cache_statistics/cache_statistics_graphs/',convertStringsToChars(num_level(multi_level+1)),'/delta_scatter/',convertStringsToChars(num_scope(i)),'_',dataset_size,'.png'];
	system(strcat("mv temp.png ",move_path))
	close(fig(3+i));
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
