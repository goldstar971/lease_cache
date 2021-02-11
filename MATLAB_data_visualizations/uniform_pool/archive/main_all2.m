% init workspace
close all; clearvars; clc;

% files, selections, etc
dir_base = "small/";
bm_strs = ["nussinov","floyd-warshall","matrix2","matrix3","atax","bicg","doitgen","mvt"];

% gather files
[results_random, results_random_strs] = extract(dir_base+"results_random.txt");
[results_lru, results_lru_strs] = extract(dir_base+"results_lru.txt");
[results_lease_random, results_lease_random_strs] = extract(dir_base+"results_lease_random.txt");

% extract benchmark results
k = 1;
for i = 1:size(results_lru(:,1))
    
    % random
    for a = 1:size(results_random_strs)
        if ( contains(results_random_strs{a}, bm_strs(i)) )
            random_bm{i} = results_random(a,:);
        end
    end
    
    % lru
    for b = 1:size(results_lru_strs)
        if ( contains(results_lru_strs{b}, bm_strs(i)) )
            lru_bm{i} = results_lru(b,:);
        end
    end

    % collect benchmark results
    for j = 1:size(results_lease_random_strs)
        if ( contains(results_lease_random_strs{j}, bm_strs(i)) )
            idx(j,i) = 1;

        else idx(j,i) = 0;
        end
    end

    lease_bm{i} = results_lease_random((idx(:,i) == 1),:);
    lease_bm_sorted{i} = sortrows(lease_bm{i}, 15);
    %k = k + 1;

end

% benchmark performance graphics
figure();
    for (i = 1:size(results_lru_strs)-1)
    %for (i = 1:4)
        p = plot( lease_bm_sorted{i}(:,15), lease_bm_sorted{i}(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
%         if (i == 3)
%             %delete(p);
%             set(p,'Visible','off')
%        end
    end
    plot( lease_bm_sorted{8}(:,15), lease_bm_sorted{8}(:,14)/lru_bm{8}(14),'k', 'LineWidth',2  );
    legend(bm_strs);
    grid on;
    xlabel('Equivalent Lease Size');
    ylabel('Miss rate as a factor normalized to LRU');
    ax = gca;
    ax.XRuler.Exponent = 0;
    ylim([0 2]);
    %xlim([0 20000]);
    
    


% function to extract information
function [struct, struct_strings] = extract(path)

%results = readtable(path);
results = readtable(path,'Delimiter',',','ReadVariableNames',false);

struct = table2array(results(:,2:end));
%x = importdata(path);
%struct = x.data;
%struct_strings = x.textdata;

struct(:,13) = struct(:,1) / (20*10^6);
struct(:,14) = 100*(struct(:,6) ./ struct(:,5));

struct(:,15) = struct(:,8) .* (struct(:,12)+1);

struct_strings = table2array(results(:,1));

end