function [data, filenames, policy_names] = extract_data_sets(path)

results = readtable(path,'Delimiter',',','ReadVariableNames',false);

data = table2array(results(:,2:end));
filenames = table2array(results(:,1));

% vacancy rate and multivacancy rate
data(:,17) = 100*(data(:,9) ./ data(:,7));
%data(:,18) = 100*(data(:,10) ./ data(:,7));

% add in columns for cache structure and replacement policy
data(:,13) = bitand(data(:,12),hex2dec('F0000000'),'uint32');
data(:,13) = bitshift(data(:,13),-28);
data(:,14) = bitand(data(:,12),hex2dec('0000000F'),'uint32');

data(:,25) = data(:,7)./data(:,6);

% convert id to policy string
policy_names = {};
for i = 1:length(data(:,1))
    
    % assign numerics per structure
    if      (data(i,12) == 0) data(i,16) = 1;
    elseif  (data(i,12) == 8) data(i,16) = 2;
    elseif  (data(i,12) == 4) data(i,16) = 3;
    elseif  (data(i,12) == 2) data(i,16) = 4;
    else                      data(i,16) = NaN;
    end
        
    % assign numerics per policy
    if (data(i,12) == 2)
        data(i,15) = 1;
        policy_names{i} = "LRU";
        
    elseif (data(i,12) == 3)
        data(i,15) = 2;
        policy_names{i} = "PLRU";
        
    elseif (data(i,12) == 26)
        data(i,15) = 3;
        policy_names{i} = "PRL_2";
        
    elseif (data(i,12) == 36)
        data(i,15) = 4;
        policy_names{i} = "PRL_5";
        
    elseif (data(i,12) == 46)
        data(i,15) = 5;
        policy_names{i} = "PRL_10";
        
    elseif (data(i,12) == 56)
        data(i,15) = 6;
        policy_names{i} = "PRL_20";
        
    end
        
%     elseif (data(i,12) == 3)
%         data(i,15) = 2;
%         policy_names{i} = "pLRU";
%         
%     elseif (data(i,12) == 5)
%         data(i,15) = 3;
%         policy_names{i} = "SRRIP";
%         
%     elseif (data(i,12) == 6)
%         %data(i,15) = 5;
%         data(i,15) = 2;
%         policy_names{i} = "LEASE";
%         
%     elseif (data(i,12) == 8)
%         data(i,15) = 4;
%         policy_names{i} = "FUL";
%     % bens
%     elseif (data(i,12) == 16)
%         data(i,15) = 3;
%         %data(i,15) = 6;
%         policy_names{i} = "BEN_MIN";
%     elseif (data(i,12) == 26)
%         data(i,15) = 4;
%         %data(i,15) = 7;
%         policy_names{i} = "BEN_MEDIAN";
%         
%     elseif (data(i,12) == 36)
%         data(i,15) = 5;
%         policy_names{i} = "CARL-STRICT";
%         
    % defaults
%     elseif (data(i,12) == 9)
%         data(i,15) = 2;
%         policy_names{i} = "0x0";
%     elseif (data(i,12) == 19)
%         data(i,15) = 3;
%         policy_names{i} = "0x1";
%     elseif (data(i,12) == 29)
%         data(i,15) = 4;
%         policy_names{i} = "0x10";
%     elseif (data(i,12) == 39)
%         data(i,15) = 5;
%         policy_names{i} = "0x100";
%     elseif (data(i,12) == 49)
%         data(i,15) = 6;
%         policy_names{i} = "0x1000";
%     elseif (data(i,12) == 59)
%         data(i,15) = 7;
%         policy_names{i} = "0xFFFFFF";
%     else
%         data(i,12) = NaN;
%         policy_names{i} = "Unknown";
%     end
end

end