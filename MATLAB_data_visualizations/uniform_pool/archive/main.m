% init workspace
close all; clearvars; clc;

% base directory
dir_base = "small/";
dir_sub = "mvt/";

% open files
results_lru = extract(dir_base+dir_sub+"results_lru.txt");
results_random = extract(dir_base+dir_sub+"results_random.txt");
results_lease_random = extract(dir_base+dir_sub+"results_lease_random.txt");
results_lease_random_sorted = sortrows(results_lease_random, 15);


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
    case "lease coarseness"
        n = 12;
    case "time"
        n = 13;
    case "miss rate"
        n = 14;
    
end

% create lru isoline
%if (dir_sub == "nussinov/") id_index = 1;
%elseif (dir_sub == "floyd-warshall/") id_index = 2;
%elseif (dir_sub == "matrix2/") id_index = 3; end;
    
x = 0:1:511;
y_lru = results_lru(1,n)*ones(1,512);
y_random = results_random(1,n)*ones(1,512);

% parse by id
idx_0 = results_lease_random(:,12) == 0;
idx_1 = results_lease_random(:,12) == 1;
idx_3 = results_lease_random(:,12) == 3;
idx_7 = results_lease_random(:,12) == 7;
idx_15 = results_lease_random(:,12) == 15;
idx_31 = results_lease_random(:,12) == 31;
idx_63 = results_lease_random(:,12) == 63;
idx_127 = results_lease_random(:,12) == 127;

% graphic
figure();
    subplot(2,1,1);
        plot(x,y_lru,'--','LineWidth',3); hold on;
        plot(x,y_random,'--','LineWidth',3); hold on;

        plot(results_lease_random(idx_0,8), results_lease_random(idx_0,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_1,8), results_lease_random(idx_1,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_3,8), results_lease_random(idx_3,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_7,8), results_lease_random(idx_7,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_15,8), results_lease_random(idx_15,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_31,8), results_lease_random(idx_31,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_63,8), results_lease_random(idx_63,n),'MarkerSize',8,'LineWidth',2); hold on;
        plot(results_lease_random(idx_127,8), results_lease_random(idx_127,n),'--','MarkerSize',8,'LineWidth',2); hold on;

            xlabel('Lease Size');
            ylabel(plot_option);
            grid on;
            %axis tight;
            title(dir_sub);
            legend('LRU Baseline','Random Baseline',...
            'Lease Coarseness = 0','Lease Coarseness = 2',...
            'Lease Coarseness = 4','Lease Coarseness = 8',...
            'Lease Coarseness = 16','Lease Coarseness = 32',...
            'Lease Coarseness = 64','Lease Coarseness = 128');
    subplot(2,1,2);
        plot(results_lease_random_sorted(:,15), results_lease_random_sorted(:,n)/(results_lru(n)));
        %plot(results_lease_random(:,15), results_lease_random(:,n)/(results_lru(n)),'o');
            grid on;
            xlabel('Equivalent Lease Size');
            ylabel(plot_option+' normalized to LRU');
            ax = gca;
            ax.XRuler.Exponent = 0;
            

% cummulative figure

        
% analytics
% ---------------------------------------------------------
%lre_lru = results(idx,:);
%mre_lru = results(~idx,:);

% for i = 1:size(lre_lru(:,1))
%     % miss rate
%     if (lre_lru(i,13) ~= results_lru(id_index,13))
%         disp("lre_lru index:"+num2str(i)+" - miss rate");
%     end
% end
% 
% for i = 1:size(mre_lru(:,1))
%     % miss rate
%     if (mre_lru(i,13) <= results_lru(id_index,13))
%         disp("mre_lru index:"+num2str(i)+" - miss rate");
%     end
% end
    
    
% function to extract information
function [struct] = extract(path)

results = readtable(path,'Delimiter',',','ReadVariableNames',false);

struct = table2array(results(:,2:end));

struct(:,13) = struct(:,1) / (20*10^6);
struct(:,14) = 100*(struct(:,6) ./ struct(:,5));

struct(:,15) = struct(:,8) .* (struct(:,12)+1);

end



