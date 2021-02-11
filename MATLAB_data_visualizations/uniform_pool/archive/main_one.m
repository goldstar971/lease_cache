% init workspace
close all; clearvars; clc;

% files, selections, etc
dir_base = "small_bicg_pool/";
%bm_strs = ["nussinov","floyd-warshall","matrix2","matrix3","atax","bicg","doitgen","mvt"];
bm_strs = ["bicg"];

% gather files
%[results_random, results_random_strs] = extract(dir_base+"results_random.txt");
[results_lru, results_lru_strs] = extract(dir_base+"results_lru.txt");
[results_lease_random0, results_lease_random_strs0] = extract(dir_base+"results_lease_pool_0_true.txt");
[results_lease_random2, results_lease_random_strs2] = extract(dir_base+"results_lease_pool_2_true.txt");
[results_lease_random4, results_lease_random_strs4] = extract(dir_base+"results_lease_pool_4_true.txt");
[results_lease_random8, results_lease_random_strs8] = extract(dir_base+"results_lease_pool_8_true.txt");
[results_lease_random16, results_lease_random_strs16] = extract(dir_base+"results_lease_pool_16_true.txt");

[results_lease_random0f, results_lease_random_strs0f] = extract(dir_base+"results_lease_pool_0_false.txt");
[results_lease_random2f, results_lease_random_strs2f] = extract(dir_base+"results_lease_pool_2_false.txt");
[results_lease_random4f, results_lease_random_strs4f] = extract(dir_base+"results_lease_pool_4_false.txt");
[results_lease_random8f, results_lease_random_strs8f] = extract(dir_base+"results_lease_pool_8_false.txt");
[results_lease_random16f, results_lease_random_strs16f] = extract(dir_base+"results_lease_pool_16_false.txt");

% extract benchmark results
k = 1;
for i = 1:size(results_lru(:,1))
    
    % random
%     for a = 1:size(results_random_strs)
%         if ( contains(results_random_strs{a}, bm_strs(i)) )
%             random_bm{i} = results_random(a,:);
%         end
%     end
    
    % lru
    for b = 1:size(results_lru_strs)
        if ( contains(results_lru_strs{b}, bm_strs(i)) )
            lru_bm{i} = results_lru(b,:);
        end
    end

    % collect benchmark results
%     for j = 1:size(results_lease_random_strs)
%         if ( contains(results_lease_random_strs{j}, bm_strs(i)) )
%             idx(j,i) = 1;
% 
%         else idx(j,i) = 0;
%         end
%     end
% 
%     lease_bm{i} = results_lease_random((idx(:,i) == 1),:);
%     lease_bm_sorted{i} = sortrows(lease_bm{i}, 15);
    %k = k + 1;

end

% benchmark performance graphics
figure();
    subplot(1,2,1);
        plot(results_lease_random0(:,15), results_lease_random0(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random2(:,15), results_lease_random2(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random4(:,15), results_lease_random4(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random8(:,15), results_lease_random8(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random16(:,15), results_lease_random16(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
    
        legend("Pool = 0: Evict Largest", "Pool = 2: Evict Largest", "Pool = 4: Evict Largest", ...
           "Pool = 8: Evict Largest", "Pool = 16: Evict Largest");
        grid on;
        xlabel('Equivalent Lease Size');
        ylabel('Miss rate as a factor normalized to LRU');
        ax = gca;
        ax.XRuler.Exponent = 0;
        ylim([0.9 1.8]);
        %xlim([0 20000]);
        title("Evict Largest Remaining Lease in the Random Pool Policy");
        
    subplot(1,2,2);
        plot(results_lease_random0f(:,15), results_lease_random0f(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random2f(:,15), results_lease_random2f(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random4f(:,15), results_lease_random4f(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random8f(:,15), results_lease_random8f(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        plot(results_lease_random16f(:,15), results_lease_random16f(:,14)/lru_bm{i}(14), 'LineWidth',2  ); hold on;
        
        legend("Pool = 0: Evict Smallest", "Pool = 2: Evict Smallest", "Pool = 4: Evict Smallest", ...
           "Pool = 8: Evict Smallest", "Pool = 16: Evict Smallest");
        grid on;
        xlabel('Equivalent Lease Size');
        ylabel('Miss rate as a factor normalized to LRU');
        ax = gca;
        ax.XRuler.Exponent = 0;
        ylim([0.9 1.8]);
        title("Evict Smallest Remaining Lease in the Random Pool Policy");
    


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