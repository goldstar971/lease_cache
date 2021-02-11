% init workspace
close all; clearvars; clc;

% base directory
dir_base = "small/";
dir_sub = "matrix2/";
dir_file = "results.txt";
dir = dir_base+dir_sub+dir_file;

% open files
results_lru = extract(dir_base+"results_lru.txt");
results_random = extract(dir_base+"results_random.txt");
results_lease_random = extract(dir_base+"results_lease_random.txt");
results_lease_random_2 = extract(dir_base+"results_lease_random_2.txt");
results_lease_random_4 = extract(dir_base+"results_lease_random_4.txt");
results_lease_random_8 = extract(dir_base+"results_lease_random_8.txt");
results_lease_random_16 = extract(dir_base+"results_lease_random_16.txt");
results_lease_random_32 = extract(dir_base+"results_lease_random_32.txt");
results_lease_random_64 = extract(dir_base+"results_lease_random_64.txt");
results_lease_random_128 = extract(dir_base+"results_lease_random_128.txt");
results = extract(dir);

% plot parameter
% ------------------------------------
plot_option = "miss rate";
n = 0;
switch plot_option
    case "cycles"
        n = 1;
    case "inst hit"
        n = 2;
    case "inst miss" 
        n = 3;
    case "inst wb" 
        n = 4;
    case "data hit"
        n = 5;
    case "data miss" 
        n = 6;
    case "data wb" 
        n = 7;
    case "lease value"
        n = 8;
    case "cache id"
        n = 9;
    case "expired replacements"
        n = 10;
    case "default replacements"
        n = 11;
    case "time"
        n = 12;
    case "miss rate"
        n = 13;
    
end

% create lru isoline
if (dir_sub == "nussinov/") id_index = 1;
elseif (dir_sub == "floyd-warshall/") id_index = 2;
elseif (dir_sub == "matrix2/") id_index = 3; end;
    
x = 0:1:511;
y_lru = results_lru(id_index,n)*ones(1,512);
y_random = results_random(id_index,n)*ones(1,512);

% parse by id
idx = results(:,9) < 2;

% graphic
figure();
    plot(x,y_lru,'--','LineWidth',3); hold on;
    plot(x,y_random,'--','LineWidth',3); hold on;
    plot(results_lease_random(:,8), results_lease_random(:,n),'g','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_2(:,8), results_lease_random_2(:,n),'m','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_4(:,8), results_lease_random_4(:,n),'k','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_8(:,8), results_lease_random_8(:,n),'c','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_16(:,8), results_lease_random_16(:,n),'r','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_32(:,8), results_lease_random_32(:,n),'y','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_64(:,8), results_lease_random_64(:,n),'b','MarkerSize',8,'LineWidth',2); hold on;
    plot(results_lease_random_128(:,8), results_lease_random_128(:,n),'k','MarkerSize',8,'LineWidth',2); hold on;
    %plot(results(idx,8), results(idx,n),'d','MarkerSize',8,'LineWidth',3); hold on;
    %plot(results(~idx,8), results(~idx,n),'kx','MarkerSize',8,'LineWidth',3); hold on;
        xlabel('Lease Size');
        ylabel(plot_option);
        grid on;
        legend('LRU Baseline','Random Baseline',...
        'Lease Coarseness = 0','Lease Coarseness = 2',...
        'Lease Coarseness = 4','Lease Coarseness = 8',...
        'Lease Coarseness = 16','Lease Coarseness = 32',...
        'Lease Coarseness = 64','Lease Coarseness = 128');
        %legend('LRU Baseline','Random Baseline','LRE-LRU','MRE-LRU');
        
% analytics
% ---------------------------------------------------------
lre_lru = results(idx,:);
mre_lru = results(~idx,:);

for i = 1:size(lre_lru(:,1))
    % miss rate
    if (lre_lru(i,13) ~= results_lru(id_index,13))
        disp("lre_lru index:"+num2str(i)+" - miss rate");
    end
end

for i = 1:size(mre_lru(:,1))
    % miss rate
    if (mre_lru(i,13) <= results_lru(id_index,13))
        disp("mre_lru index:"+num2str(i)+" - miss rate");
    end
end
    
    
% function to extract information
function [struct] = extract(path)

results = readtable(path);

struct = table2array(results(:,2:end));

struct(:,12) = struct(:,1) / (20*10^6);
struct(:,13) = 100*(struct(:,6) ./ struct(:,5));

end



