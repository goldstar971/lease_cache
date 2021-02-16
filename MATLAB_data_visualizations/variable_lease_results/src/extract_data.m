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
    
    % assign numerics per structure
    if      (data(i,11) == 5) data(i,16) = 5;
    elseif  (data(i,11) == 8) data(i,16) = 3;
    elseif  (data(i,11) == 4) data(i,16) = 1;
    elseif  (data(i,11) == 7) data(i,16) = 4;
	elseif  (data(i,11) == 6) data(i,16) = 2;
	elseif  (data(i,11) ==2)  data(i,16) = 6;
	else            data(i,16)=nan;
    end
        
    % assign numerics per policy
    if (data(i,11) == 2)
        data(i,15) = 1;
        policy_names{i} = "LRU";
        
    elseif (data(i,11) == 4)
        data(i,15) = 2;
        policy_names{i} = "pLRU";
	elseif (data(i,11) ==6)
		data(i,15) = 3;
        policy_names{i} = "CARL";
	elseif (data(i,11) ==8)
		data(i,15) = 3;
        policy_names{i} = "CARL-scope";
        
    elseif (data(i,11) == 5)
        data(i,15) = 3;
        policy_names{i} = "SRRIP";
        
    % bens
    elseif (data(i,11) == 16)
        data(i,15) = 3;
        %data(i,15) = 6;
        policy_names{i} = "BEN_MIN";
    elseif (data(i,11) == 26)
        data(i,15) = 4;
        %data(i,15) = 7;
        policy_names{i} = "BEN_MEDIAN";
        
    elseif (data(i,11) == 36)
        data(i,15) = 5;
        policy_names{i} = "CARL-STRICT";
        
    % defaults
    elseif (data(i,11) == 9)
        data(i,15) = 2;
        policy_names{i} = "0x0";
    elseif (data(i,11) == 19)
        data(i,15) = 3;
        policy_names{i} = "0x1";
    elseif (data(i,11) == 29)
        data(i,15) = 4;
        policy_names{i} = "0x10";
    elseif (data(i,11) == 39)
        data(i,15) = 5;
        policy_names{i} = "0x100";
    elseif (data(i,11) == 49)
        data(i,15) = 6;
        policy_names{i} = "0x1000";
    elseif (data(i,11) == 59)
        data(i,15) = 7;
        policy_names{i} = "0xFFFFFF";
    else
        data(i,15) = NaN;
        policy_names{i} = "Unknown";
    end
end

end