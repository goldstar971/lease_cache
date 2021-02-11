function [pool_id, range_percentage] = find_range(lru_data,ful_data,bound)

% make check bound a normalized factor
check_bound = 1 + (bound / 100);

% first determine how many discrete pool+polarity matches there are
pool_id = [];
for i = 1:size(ful_data(:,24))
    if ~ismember(ful_data(i,24), pool_id)
        pool_id = [pool_id; ful_data(i,24)];
    end
end

% calculate percentages
range_percentage = [];
for i = 1:size(pool_id)
    
    % sub-separate data by the pool_id
    sub_data = ful_data(ful_data(:,24)==pool_id(i),:);
    
    % normalize ful miss rate to lru
    miss_norm = sub_data(:,22) / lru_data(1,22);
    
    % go through miss rates comparing to lru miss rate
    n_within_range = 0;
    for j = 1:size(sub_data(:,1))

        if miss_norm(j) < check_bound
            n_within_range = n_within_range + 1;
        end
        
    end
    
    range_percentage = [range_percentage; n_within_range/j];
    
end

% sort the returns
temp_mat = [pool_id, range_percentage];
temp_mat_sorted = sortrows(temp_mat, 1);

pool_id = temp_mat_sorted(:,1);
range_percentage = temp_mat_sorted(:,2);

end

