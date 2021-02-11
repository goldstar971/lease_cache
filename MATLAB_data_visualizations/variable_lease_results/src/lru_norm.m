function [data_set_mod] = lru_norm(data_set)

% preinitialize
%idx = zeros(size(filenames,1),1);
%sub_d

% first find the lru performance
lru_misses = 0;
for i = 1:size(data_set)
    if (data_set(i,15) == 1) 
        lru_misses = data_set(i,7);
        lru_miss_ratio = data_set(i,19);
        lru_time = data_set(i,21);
    end
end

% normalize all other policys' misses (as a percentage to lru)
for i = 1:size(data_set)
    %data_set(i,17) = 100 * -(data_set(i,7) - lru_misses) / lru_misses;
    data_set(i,17) = data_set(i,7) / lru_misses;
    data_set(i,20) = data_set(i,19) / lru_miss_ratio;
    data_set(i,22) = 100*(data_set(i,21) - lru_time) / lru_time;
end

% return
data_set_mod = data_set;

% loop through all strings searching for partial matches
% for i = 1:size(filenames)
%     
%     if ( contains(filenames(i), search_string) )
%         idx(i,1) = 1;
%         %sub_data = [sub_data
%     else
%         idx(i,1) = 0;
%     end
% end
% 
% sub_data = data(idx==1,:);

end