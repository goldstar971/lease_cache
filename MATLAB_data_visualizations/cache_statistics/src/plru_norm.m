function [data_set_mod] = plru_norm(data_set)

% preinitialize
%idx = zeros(size(filenames,1),1);
%sub_d

% first find the lru performance
plru_misses = 0;
for i = 1:size(data_set)
    if (data_set(i,16) == 1) 
        plru_misses = data_set(i,7);
		plru_cycles = data_set(i,4);
		plru_adjusted_cycles=data_set(i,4)+10*data_set(i,7);
    end
end

% normalize all other policys' misses (as a percentage to lru)
for i = 1:size(data_set)
    %data_set(i,17) = 100 * -(data_set(i,7) - lru_misses) / lru_misses;
    data_set(i,17) = data_set(i,7) / plru_misses;
	data_set(i,18) = data_set(i,4) / plru_cycles;
	data_set(i,19)= (data_set(i,4)+10*data_set(i,7))/plru_adjusted_cycles;
end

% return
data_set_mod = data_set;



end