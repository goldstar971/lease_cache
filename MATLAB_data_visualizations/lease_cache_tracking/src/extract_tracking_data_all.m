function [avg, mat, trace] = extract_tracking_data_all(path, cache_size,data_file_size)

% read data from file as table
%  if(cache_size==512)
%  	results = readtable(path,'Delimiter',',','ReadVariableNames',false,...
%                      'Format','%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
%  else
%  	results = readtable(path,'Delimiter',',','ReadVariableNames',false,...
%                      'Format','%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
% end
	
if(data_file_size=="large")
	interval=30;
elseif(data_file_size=="very_large")
	interval=100;
else
	interval=1;
end
% extract table to array
% columns 7 and 8 are not needed (referece trace will not be larger than
% a 64bit number for simple examples

ds = datastore(path,'TreatAsMissing','NA','RowDelimiter','\n');
%set correct format specifiers
for i=1:length(ds.SelectedFormats)
ds.SelectedFormats{i}='%s';
end
data=[];
trace=[];
ds.ReadSize=200000;


% create matrix of the individual cache line bits of columns 1:4
% row cache_size is number of trace samples
% col cache_size is the number of cache lines
% lowest index of mat is cache line 0
mat_low = [];
mat_mid = [];
mat_upp = [];
mat_exp = [];
mat_fin = [];
while(hasdata(ds))
	[results,info]=read(ds);
	data_frame=[];
	fprintf("reading data %f%% complete\n",info.Offset/info.FileSize*100);
	for i=1:width(results)-3
		% normal extractions
	
		if (i ~= width(results)-3)
			data_frame=[data_frame,hex2dec(table2array(results(1:interval:end,i)))];
		% cast reference lengths 
		else 
			trace=[trace;hex2dec(table2array(results(1:interval:end,i))) + 2^32 *... 
						hex2dec(table2array(results(1:interval:end,i+1)))];
		end
	end
	mat_low_temp=int8(zeros(length(data_frame(:,1)),cache_size));;
	mat_mid_temp=int8(zeros(length(data_frame(:,1)),cache_size));;
	mat_upp_temp=int8(zeros(length(data_frame(:,1)),cache_size));;
	mat_exp_temp=int8(zeros(length(data_frame(:,1)),cache_size));;
	for i=1:(cache_size/32)       % raw data iterator
    
		% create bit mask for isolating 
		bit_mask = 1;

		for j=1:32  % bit width iterator

			% mask out bit and shift to lsb position
			% create new mask after
			mat_low_temp(:,j+32*(i-1)) = int8(bitshift(bitand(data_frame(:,i), bit_mask),-(j-1)));
			mat_mid_temp(:,j+32*(i-1)) = int8(bitshift(bitand(data_frame(:,i+cache_size/32), bit_mask),-(j-1)));
			mat_upp_temp(:,j+32*(i-1)) = int8(bitshift(bitand(data_frame(:,i+cache_size/32*2), bit_mask),-(j-1)));
			mat_exp_temp(:,j+32*(i-1)) = int8(~(mat_low_temp(:,j+32*(i-1)) | mat_mid_temp(:,j+32*(i-1)) | mat_upp_temp(:,j+32*(i-1))));

			

			bit_mask = bitshift(bit_mask,1);
		end  
	end

mat_low=[mat_low;mat_low_temp];
mat_mid=[mat_mid;mat_mid_temp];
mat_upp=[mat_upp;mat_upp_temp];
mat_exp=[mat_exp;mat_exp_temp];

	
end
clear results data_frame





mat_fin=int8(zeros(length(mat_low(:,1)),cache_size));
for i = 1: length(mat_fin(:,1))
    for j = 1: length(mat_fin(1,:))
        
        if(mat_upp(i,j) == 1) 
            mat_fin(i,j) = 0;
        elseif (mat_mid(i,j) == 1) 
            mat_fin(i,j) = 1; 
        elseif (mat_low(i,j) == 1) 
            mat_fin(i,j) = 2;
        else 
            mat_fin(i,j) = 3;
        end
        
    end
end






% create an average utilization vector at each trace sample
%for i = 1:length(mat_low(:,1))
 %   avg.low(i,1) = sum(mat_low(i,:));
%end
%mat.low = mat_low;
clear mat_low
%for i = 1:length(mat_mid(:,1))
%      avg.mid(i,1) = sum(mat_mid(i,:));
%end
%mat.mid = mat_mid;
clear mat_mid
%for i = 1:length(mat_uppp(:,1))
%     avg.upp(i,1) = sum(mat_uppp(i,:));
%end
%mat.upp = mat_upp;
clear mat_upp
for i = 1:length(mat_exp(:,1))
    avg.exp(i,1) = sum(mat_exp(i,:));
end
%mat.exp = mat_exp;
clear mat_exp

mat.fin = mat_fin;
 
   
end
