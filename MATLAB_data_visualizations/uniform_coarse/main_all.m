% init workspace
close all; clearvars; clc;

% benchmark directories
dir_bm(1) = "nussinov/";
dir_bm(2) = "floyd-warshall/";
dir_bm(3) = "matrix2/";
dir_bm(4) = "matrix3/";
dir_bm(5) = "atax/";
dir_bm(6) = "bicg/";
dir_bm(7) = "doitgen/";
dir_bm(8) = "mvt/";

% base directory
dir_base = "small/";
file_lru = "results_lru.txt";
file_random = "results_random.txt";
file_lease = "results_lease_random.txt";

% extract all benchmark results
for i = 1:8
    lru_results{i} = extract(dir_base+dir_bm(i)+file_lru);
    random_results{i} = extract(dir_base+dir_bm(i)+file_random);
    lease_results{i} = extract(dir_base+dir_bm(i)+file_lease);
    lease_results_sorted{i} = sortrows(lease_results{i}, 15);
end   


% plot all miss rates normalized to their lru miss rate
figure();
    for i = 1:7
        plot( lease_results_sorted{i}(:,15), lease_results_sorted{i}(:,14)/lru_results{i}(14), 'LineWidth',2 ); hold on;
    end
    plot( lease_results_sorted{8}(:,15), lease_results_sorted{8}(:,14)/lru_results{8}(14),'k', 'LineWidth',2 ); hold on;
    legend(dir_bm);
    grid on;
    xlabel('Equivalent Lease Size');
    ylabel('Miss rate as a factor normalized to LRU');
    ax = gca;
    ax.XRuler.Exponent = 0;

% function to extract information
function [struct] = extract(path)

results = readtable(path,'Delimiter',',','ReadVariableNames',false);

struct = table2array(results(:,2:end));

struct(:,13) = struct(:,1) / (20*10^6);
struct(:,14) = 100*(struct(:,6) ./ struct(:,5));

struct(:,15) = struct(:,8) .* (struct(:,12)+1);

end
