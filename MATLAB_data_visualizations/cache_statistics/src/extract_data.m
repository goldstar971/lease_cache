function [data, filenames, policy_names] = extract_data(path,offset)



results = readtable(path,'Delimiter',',','ReadVariableNames',false);

data = table2array(results(:,2:end));
filenames = table2array(results(:,1));

% vacancy rate and multivacancy rate
data(:,17+offset) = 100*(data(:,9+offset) ./ data(:,7+offset));
data(:,18+offset) = 100*(data(:,10+offset) ./ data(:,7+offset));



% add in columns for cache structure and replacement policy
data(:,13+offset) = bitand(data(:,11+offset),hex2dec('F0000000'),'uint32');
data(:,13+offset) = bitshift(data(:,12+offset),-28);
data(:,14+offset) = bitand(data(:,11+offset),hex2dec('0000000F'),'uint32');

% convert id to policy string
policy_names = {};
for i = 1:length(data(:,1))
    % assign numerics per policy
    
   if (data(i,12+offset) == 4)
        data(i,16+offset) = 1;
        policy_names{i} = "pLRU";
	elseif (contains(filenames{i},"C-SHEL"))
		data(i,16+offset) = 5;
        policy_names{i} = "C-SHEL";
	elseif  (contains(filenames{i},"CLAM"))
	   data(i,16+offset)=2;
	   policy__names{i} = "CLAM";
	elseif (contains(filenames{i},"SHEL"))
		data(i,16+offset) =4;
		policy_names{i}= "SHEL";
	elseif (contains(filenames{i},"PRL"))
		data(i,16+offset) = 3;
        policy_names{i} = "PRL";
    else
        data(i,16+offset) = NaN;
        policy_names{i} = "Unknown";
    end
end

end
