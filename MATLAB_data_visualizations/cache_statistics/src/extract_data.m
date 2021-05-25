function [data, filenames, policy_names] = extract_data(path)

results = readtable(path,'Delimiter',',','ReadVariableNames',false);

data = table2array(results(:,2:end));
filenames = table2array(results(:,1));

% vacancy rate and multivacancy rate
data(:,17) = 100*(data(:,9) ./ data(:,7));
data(:,18) = 100*(data(:,10) ./ data(:,7));



% add in columns for cache structure and replacement policy
data(:,13) = bitand(data(:,11),hex2dec('F0000000'),'uint32');
data(:,13) = bitshift(data(:,12),-28);
data(:,14) = bitand(data(:,11),hex2dec('0000000F'),'uint32');

% convert id to policy string
policy_names = {};
for i = 1:length(data(:,1))
    % assign numerics per policy
    
   if (data(i,12) == 4)
        data(i,16) = 1;
        policy_names{i} = "pLRU";
	elseif (contains(filenames{i},"C-SHEL"))
		data(i,16) = 5;
        policy_names{i} = "C-SHEL";
	elseif  (contains(filenames{i},"CLAM"))
	   data(i,16)=3;
	   policy__names{i} = "CLAM";
	elseif (contains(filenames{i},"SHEL"))
		data(i,16) =4;
		policy_names{i}= "SHEL";
	elseif (contains(filenames{i},"PRL"))
		data(i,16) = 2;
        policy_names{i} = "PRL";
    else
        data(i,16) = NaN;
        policy_names{i} = "Unknown";
    end
end

end
