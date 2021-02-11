% initialize workspace
close all; clearvars; clc;

% user selections
% -------------------------------------------------------------------------
dir = "small/";
test = ["floyd","nussinov","matrix2","matrix3","doitgen","bicg","atax","mvt"];
range_bound = .1;   % .1 is sweet spot
range0 = [0 3 7];
range1 = [0 -3 -7];

line_types = ['-','-','-'];
line_widths = [2,2,2];
% -------------------------------------------------------------------------



% derived settings
path_random = dir+"results_ful.txt";
path_ful = dir+"results_ful.txt";
path_lru = dir+"results_lru.txt";

% extract matrix results

[data_ful,filenames_ful] = extract_data(path_ful);
[data_lru,filenames_lru] = extract_data(path_lru);

for i=1:size(test(:))

% extract a specific test 
[~, parsed_data_ful{i}] = parse_name(data_ful, filenames_ful, test(i));
[~, parsed_data_lru{i}] = parse_name(data_lru, filenames_lru, test(i));

% determine the percentage of the equivalent lease range that is within
% range bound at least
[pool_ids{i}, range_percentages{i}] = find_range(parsed_data_lru{i}, parsed_data_ful{i}, range_bound);

end

% signel figure plots
test_runs0 = get_tests(parsed_data_ful{1}, range0, 'ascend',23);
test_runs1 = get_tests(parsed_data_ful{1}, range1, 'descend',23);

test_runs2 = get_tests(parsed_data_ful{2}, range0, 'ascend',23);
test_runs3 = get_tests(parsed_data_ful{2}, range1, 'descend',23);

test_runs4 = get_tests(parsed_data_ful{3}, range0, 'ascend',23);
test_runs5 = get_tests(parsed_data_ful{3}, range1, 'descend',23);

test_runs6 = get_tests(parsed_data_ful{4}, range0, 'ascend',23);
test_runs7 = get_tests(parsed_data_ful{4}, range1, 'descend',23);

test_runs8 = get_tests(parsed_data_ful{5}, range0, 'ascend',23);
test_runs9 = get_tests(parsed_data_ful{5}, range1, 'descend',23);

test_runs10 = get_tests(parsed_data_ful{6}, range0, 'ascend',23);
test_runs11 = get_tests(parsed_data_ful{6}, range1, 'descend',23);

test_runs12 = get_tests(parsed_data_ful{7}, range0, 'ascend',23);
test_runs13 = get_tests(parsed_data_ful{7}, range1, 'descend',23);

test_runs14 = get_tests(parsed_data_ful{8}, range0, 'ascend',23);
test_runs15 = get_tests(parsed_data_ful{8}, range1, 'descend',23);

% PAPER GRAPHIC
% -----------------------------------------------------------------------------------------------
wFig = 850;
hFig = 1000;
f = figure('Position',[100,100,wFig,hFig]);

    fax = gca;
    xB = .05;
    yB = .8;
    
    x_lru = 0:65020:65020;
    y_lru = [1000,1000];
    
    ylim_high = 110;
    ylim_low = -10;
    

    % nussinov
    % -----------------------
    h1 = subplot(8,2,1);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs0{i}(:,23),test_runs0{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 1.4]);
        %title('Nussinov SRL','FontWeight','Normal');
        %annotation(gca,'textbox',[0,1,0,0],'String','LRL');
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
    h2 = subplot(8,2,2);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs1{i}(:,23),test_runs1{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 1.4]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Nussinov LRL','FontWeight','Normal');
        
    % floyd
    % -----------------------
    h3 = subplot(8,2,3);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs2{i}(:,23),test_runs2{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.4 1.15]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Floyd-Warshall SRL','FontWeight','Normal');
    h4 = subplot(8,2,4);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs3{i}(:,23),test_runs3{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.4 1.15]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Floyd-Warshall LRL','FontWeight','Normal');
        
    % matrix 2
    % -----------------------
    h5 = subplot(8,2,5);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs4{i}(:,23),test_runs4{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('2mm SRL','FontWeight','Normal');
        %t=text(1000,0,'FUL Miss Ratio Normalized to LRU Miss Ratio','Rotation',90);
    h6 = subplot(8,2,6);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs5{i}(:,23),test_runs5{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('2mm LRL','FontWeight','Normal');
        
    % matrix 3
    % -----------------------
    h7 = subplot(8,2,7);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs6{i}(:,23),test_runs6{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('3mm SRL','FontWeight','Normal');
    h8 = subplot(8,2,8);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs7{i}(:,23),test_runs7{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('3mm LRL','FontWeight','Normal');
        
    % doitgen
    % -----------------------
    h9 = subplot(8,2,9);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs8{i}(:,23),test_runs8{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Doitgen SRL','FontWeight','Normal');
    h10 = subplot(8,2,10);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs9{i}(:,23),test_runs9{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Doitgen LRL','FontWeight','Normal');
        
    % bicg
    % -----------------------
    h11 = subplot(8,2,11);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs10{i}(:,23),test_runs10{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 1.4]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Bicg SRL','FontWeight','Normal');
        
    h12 = subplot(8,2,12);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs11{i}(:,23),test_runs11{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 1.4]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Bicg LRL','FontWeight','Normal');
        
    % atax
    % -----------------------
    h13 = subplot(8,2,13);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs12{i}(:,23),test_runs12{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 1.3]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Atax SRL','FontWeight','Normal');
        
    h14 = subplot(8,2,14);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs13{i}(:,23),test_runs13{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.95 1.3]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Atax LRL','FontWeight','Normal');
        
    % mvt
    % -----------------------
    h15 = subplot(8,2,15);
        plot(x_lru,y_lru,'k--'); hold on;
        for i = 1:size(range0(:))
            plot(test_runs14{i}(:,23),test_runs14{i}(:,25),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([ylim_low ylim_high]);
        %ylim([.2 1.2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Mvt SRL','FontWeight','Normal');
        
    h16 = subplot(8,2,16);
        plot(x_lru,y_lru,'k--','HandleVisibility','off'); hold on;
        for i = 1:size(range1(:))        
            plot(test_runs15{i}(:,23),test_runs15{i}(:,25),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([ylim_low ylim_high]);
        %ylim([.2 1.2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Mvt LRL','FontWeight','Normal');
        
        
        
        
    height = .075;
    width = .4;
    
    top = .875;
    delta = top / 8;
    
    set(h3, 'Position', [.1, top, width, height]);
    set(h4, 'Position', [.1+.42, top, width, height]);
    
    set(h15, 'Position', [.1, top-1*delta, width, height]);
    set(h16, 'Position', [.1+.42, top-1*delta, width, height]);
    
    set(h5, 'Position', [.1, top-2*delta, width, height]);
    set(h6, 'Position', [.1+.42, top-2*delta, width, height]);
    
    set(h7, 'Position', [.1, top-3*delta, width, height]);
    set(h8, 'Position', [.1+.42, top-3*delta, width, height]);
    
    set(h13, 'Position', [.1, top-4*delta, width, height]);
    set(h14, 'Position', [.1+.42, top-4*delta, width, height]);
    
    set(h11, 'Position', [.1, top-5*delta, width, height]);
    set(h12, 'Position', [.1+.42, top-5*delta, width, height]);
    
    set(h9, 'Position', [.1, top-6*delta, width, height]);
    set(h10, 'Position', [.1+.42, top-6*delta, width, height]);
    
    set(h1, 'Position', [.1, top-7*delta, width, height]);
    set(h2, 'Position', [.1+.42, top-7*delta, width, height]);
        
    %legend({'LRU','Random','Pool Size 4','Pool Size 8'},'Location','southoutside','Orientation','horizontal');
    legend({'Random','Pool Size 4','Pool Size 8'},'Location','southoutside','Orientation','horizontal');
    
    annotation('textbox', [0.44, 0.00, 0.1, 0.1],'LineStyle','none', 'String', "FUL Lease Length"); 
    
    ax = findobj(f,'Type','Axes');
    for i=1:length(ax)
        ax(i).XRuler.Exponent = 0;
        %xlabel(ax(i),"FUL Full Lease Length");
        xlim(ax(i),[0 65020]);
        xticks(ax(i),[0 25000 50000])
        
        if mod(i,2) == 1
            set(ax(i),'YTick',[]);
        end
        
        %ylim(ax(i),[-10 110]);
        
        % set limits and stuff
        %yax=get(ax(i),'ylim');
        %xax=get(ax(i),'xlim');
        %    text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
       
    end
    
    ax1 = axes('Position',[0.05 0.45 .6 .6],'Box','off','visible', 'off');
    text(ax1, 0, 0, 'FUL Vacancy Likelihood [%]','Rotation',90);  
    
    %yax=get(gca,'ylim');
    %xax=get(gca,'xlim');
    %text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
    
    % plot titles
    title_top = .93;
    annotation(f,'textbox',...
        [.455,title_top,0.107571428571429,0.0415384615384617],...
        'String',{'Nussinov'},...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-1*delta,0.107571428571429,0.0415384615384617],...
        'String','Mvt',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-2*delta,0.107571428571429,0.0415384615384617],...
        'String','2mm',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-3*delta,0.107571428571429,0.0415384615384617],...
        'String','3mm',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-4*delta,0.107571428571429,0.0415384615384617],...
        'String','Atax',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-5*delta,0.107571428571429,0.0415384615384617],...
        'String','Bicg',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-6*delta,0.107571428571429,0.0415384615384617],...
        'String','Doitgen',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [.455,title_top-7*delta,0.107571428571429,0.0415384615384617],...
        'String','Floyd-Warshall',...
        'LineStyle','none','HorizontalAlignment','Center',...
        'FitBoxToText','off');
        
        

% extract test into discrete pool runs
% figure();
%     for i=1:size(test(:))
%         plot(pool_ids{i}, range_percentages{i},'LineWidth',2); hold on;
%     end
%         grid on;
%         legend(test);
%         ylabel("Range of Leases within at least LRU Performance");
%         xlabel(["Pool Size";
%                 "(-): Largest Remaining Lease Replacement Policy";
%                 "(+): Smallest Remaining Lease Replacement Policy"]);
%         ylim([0 1.1]);
        
        
        
