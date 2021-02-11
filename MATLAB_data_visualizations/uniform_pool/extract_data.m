function [data, filenames] = extract_data(path)

results = readtable(path,'Delimiter',',','ReadVariableNames',false);

data = table2array(results(:,2:end));
filenames = table2array(results(:,1));

% derived data
data(:,21) = data(:,4) ./ (20*10^6);             % time [s]
data(:,22) = 100*(data(:,12) ./ data(:,11));     % miss ratio [%]
data(:,23) = (data(:,16)+1) .* data(:,17);       % equivalent lease 
data(:,24) = data(:,18) .* (-1).^data(:,19);     % numeric pool value
data(:,25) = 100*(data(:,14) ./ (data(:,14) + data(:,15)));     % replacements are of expired leases

end
