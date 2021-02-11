function [avg, mat, trace] = extract_tracking_data(path)

% read data from file as table
results = readtable(path,'Delimiter',',','ReadVariableNames',false);

% extract table to array
% columns 7 and 8 are not needed (referece trace will not be larger than
% a 64bit number for simple examples
for i=1:width(results)-3
    % normal extractions
    if (i ~= width(results)-3)
        data(:,i) = hex2dec(table2array(results(:,i)));
    % cast reference lengths 
    else 
        data(:,i) = hex2dec(table2array(results(:,i))) + 2^32 *... 
                    hex2dec(table2array(results(:,i+1)));
    end
end

trace = data(:,end);

% create matrix of the individual cache line bits of columns 1:4
% row size is number of trace samples
% col size is the number of cache lines
% lowest index of mat is cache line 0
mat = zeros(length(data(:,1)),128);

for i=1:4       % raw data iterator
    
    % create bit mask for isolating 
    bit_mask = 1;
    
    for j=1:32  % bit width iterator

        % mask out bit and shift to lsb position
        % create new mask after
        mat(:,j+32*(i-1)) = bitshift(bitand(data(:,i), bit_mask),-(j-1));
        bit_mask = bitshift(bit_mask,1);
    end  
end

% create an average utilization vector at each trace sample
for i = 1:length(mat(:,1))
    avg(i,1) = sum(mat(i,:));
end

% return the matrix and

end
