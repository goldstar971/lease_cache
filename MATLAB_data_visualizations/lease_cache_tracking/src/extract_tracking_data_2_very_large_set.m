function [avg, mat, trace] = extract_tracking_data_2(path, size)

% read data from file as table
results = readtable(path,'Delimiter',',','ReadVariableNames',false,...
                    'Format','%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');

% extract table to array
% columns 7 and 8 are not needed (referece trace will not be larger than
% a 64bit number for simple examples
for i=1:width(results)-3
    % normal extractions
    if (i ~= width(results)-3)
        data(:,i) = hex2dec(table2array(results(1:60:end,i)));
    % cast reference lengths 
    else 
        data(:,i) = hex2dec(table2array(results(1:60:end,i))) + 2^32 *... 
                    hex2dec(table2array(results(1:60:end,i+1)));
    end
end

trace = data(:,end);

% create matrix of the individual cache line bits of columns 1:4
% row size is number of trace samples
% col size is the number of cache lines
% lowest index of mat is cache line 0
mat_low = zeros(length(data(:,1)),128);
mat_mid = zeros(length(data(:,1)),128);
mat_upp = zeros(length(data(:,1)),128);
mat_exp = zeros(length(data(:,1)),128);
mat_fin = zeros(length(data(:,1)),128);

for i=1:4       % raw data iterator
    
    % create bit mask for isolating 
    bit_mask = 1;
    
    for j=1:32  % bit width iterator

        % mask out bit and shift to lsb position
        % create new mask after
        mat_low(:,j+32*(i-1)) = bitshift(bitand(data(:,i), bit_mask),-(j-1));
        mat_mid(:,j+32*(i-1)) = bitshift(bitand(data(:,i+4), bit_mask),-(j-1));
        mat_upp(:,j+32*(i-1)) = bitshift(bitand(data(:,i+8), bit_mask),-(j-1));
        mat_exp(:,j+32*(i-1)) = ~(mat_low(:,j+32*(i-1)) | mat_mid(:,j+32*(i-1)) | mat_upp(:,j+32*(i-1)));
        
%         if(mat_upp(:,j+32*(i-1)) == 1) 
%             mat_fin(:,j+32*(i-1)) = 3;
%         elseif (mat_mid(:,j+32*(i-1)) == 1) 
%             mat_fin(:,j+32*(i-1)) = 2; 
%         elseif (mat_mid(:,j+32*(i-1)) == 1) 
%             mat_fin(:,j+32*(i-1)) = 1;
%         else 
%             mat_fin(:,j+32*(i-1)) = 0;
%         end
        
        bit_mask = bitshift(bit_mask,1);
    end  
end

clear results data
for i = 1: length(mat_fin(:,1))
    for j = 1: length(mat_fin(1,:))
        
        if(mat_upp(i,j) == 1) 
            mat_fin(i,j) = 0;
        elseif (mat_mid(i,j) == 1) 
            mat_fin(i,j) = 1; 
        elseif (mat_low(i,j) == 1) 
            mat_fin(i,j) = 2;
        else 
            mat_fin(i,j) = 3;
        end
        
    end
end






% create an average utilization vector at each trace sample
for i = 1:length(mat_low(:,1))
    avg.low(i,1) = sum(mat_low(i,:));
end
mat.low = mat_low;
clear mat_low
for i = 1:length(mat_mid(:,1))
      avg.mid(i,1) = sum(mat_mid(i,:));
end
mat.mid = mat_mid;
clear mat_mid
for i = 1:length(mat_upp(:,1))
     avg.upp(i,1) = sum(mat_upp(i,:));
end
mat.upp = mat_upp;
clear mat_upp
for i = 1:length(mat_exp(:,1))
    avg.exp(i,1) = sum(mat_exp(i,:));
end
mat.exp = mat_exp;
clear mat_exp

mat.fin = mat_fin;
 
   
end
