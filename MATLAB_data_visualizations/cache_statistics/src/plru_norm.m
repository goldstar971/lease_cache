function [data_set_mod] = plru_norm(data_set,offset)



% preinitialize
%idx = zeros(size(filenames,1),1);
%sub_d

% first find the lru performance
plru_misses = 0;
for i = 1:size(data_set)
    if (data_set(i,16+offset) == 1) 
        plru_misses = data_set(i,7+offset);
		plru_cycles = data_set(i,4);
	end
end

% normalize all other policys' misses (as a percentage to lru)
for i = 1:size(data_set)
    data_set(i,20+offset) = data_set(i,7+offset) / plru_misses;
	data_set(i,21+offset) = data_set(i,4) / plru_cycles;
end

% return
data_set_mod = data_set;



end