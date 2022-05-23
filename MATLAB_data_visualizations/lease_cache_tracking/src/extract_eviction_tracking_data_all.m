function [evict_status, trace] = extract_eviction_tracking_data_all(path)


% extract table to array


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
evict_status=[];
while(hasdata(ds))
	[results,info]=read(ds);
	data_frame=[];
	fprintf("reading data %f%% complete\n",info.Offset/info.FileSize*100);
	for i=1:width(results)-1
		% normal extractions
		if (i ~= width(results)-1)
			data_frame=[data_frame,hex2dec(table2array(results(1:end,i)))];
		% cast reference lengths 
		else 
			trace=[trace;hex2dec(table2array(results(1:end,i))) + 2^32 *... 
						hex2dec(table2array(results(1:end,i+1)))];
		end
	end
	evict_status=[evict_status,uint8(data_frame)];
end








   
end
