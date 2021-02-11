% initialize workspace
close all; clearvars; clc;

% added dependency directories
addpath("./src");

% user selections
% -------------------------------------------------------------------------
file = "stencil_nominal";
file_path_carl = strcat("./stencil/carl/",file,".txt");
%file_path_prl = strcat("./prl/",file,"_small_rand.txt");

% extract delimited fields
[average_carl,exp_mat_carl,trace_carl] = extract_tracking_data_2(file_path_carl,128);
%[average_prl,exp_mat_prl,trace_prl] = extract_tracking_data_2(file_path_prl,128);
lines_arr = 1:128;
trace_millions = trace_carl / 1000000;

%mean_carl = movmean(average_carl.exp,128);
%mean_prl = movmean(average_prl.exp,128);

% graphic
figure();
set(gcf, 'Position',[100,100,1000,600]);
%     subplot(2,3,1);
%         plot(trace_millions,average_carl.exp);
%         hold on;
%         %plot(trace_millions,mean_carl,'r');
%         ylabel('Vacant/Expired Cache Blocks');
%         axis tight;
%         xlabel('Millions of accesses');
%         title('CARL - Aggregate Cache Vacancy');
        %ylim([0 40]);
        %legend('Raw','Mean Filtered')

    %subplot(2,3,2:3);
        s = surface(trace_millions,1:128,exp_mat_carl.fin');
        s.EdgeColor = 'none';
        axis tight;
        %title('CARL - Individual Cache Line Status');
        ylabel('Cache Line');
        xlabel('Millions of accesses');
        ax = gca;
        ax.XAxis.Exponent = 0;
        caxis([0, 3]);
%         colorbar('Ticks',[0,1,2,3],...
%                 'TickLabels',{'Lease > 65535','Near-immediate Reuse','Immediate Reuse','Expired'},...
%                 'Location','westoutside');
            xlim([0 5]);
            
        %pos = get(s,'Position');
        %set(ax_1,'Position',[pos(1) 1.05*pos(2) pos(3) .95*pos(4)]);
            
            cb = colorbar('Ticks',[0,1,2,3],...
                 'TickLabels',{'Near-future Reuse','Near-immediate Reuse','Immediate Reuse','Expired'},...
                 'FontSize',10,...
                 'Location','southoutside');%,...
        %cb.Position = [.15 .06 .725 .0213];
            %'TickLabels',{'Lease > 65535','65535 > Lease > 255','255 > Lease > 0','Expired'},...
            %caxis([0, 3]);
%     subplot(2,3,4);
%         plot(trace_millions,average_prl.exp);
%         hold on;
%         %plot(trace_millions,mean_prl,'r');
%         ylabel('Vacant/Expired Cache Blocks');
%         axis tight;
%         xlabel('Millions of accesses');
%         title('PRL - Aggregate Cache Vacancy');
%         %ylim([0 40]);
%         %legend('Raw','Mean Filtered')
% 
%     subplot(2,3,5:6);
%         s = surface(trace_millions,1:128,exp_mat_prl.fin');
%         s.EdgeColor = 'none';
%         axis tight;
%         title('PRL - Individual Cache Line Status');
%         ylabel('Cache Line');
%         xlabel('Millions of accesses');
%         ax = gca;
%         ax.XAxis.Exponent = 0;
%         colorbar('Ticks',[0,1,2,3],...
%                 'TickLabels',{'Lease > 65535','65535 > Lease > 255','255 > Lease > 0','Expired'},...
%                 'Location','westoutside');
%             %caxis([0, 3]);
%             colormap(parula(3));
            

            
            
            
            
            
            
            
            
            
            
            
            