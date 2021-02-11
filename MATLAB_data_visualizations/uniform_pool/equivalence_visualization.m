% initialize workspace
close all; clearvars; clc;

% user selections
% -------------------------------------------------------------------------
dir = "small/";
test = ["floyd","nussinov","matrix2","matrix3","doitgen","bicg","atax","mvt"];
range_bound = .1;   % .1 is sweet spot
range0 = [0 3 7];
range1 = [0 -3 -7];

line_types = ['-','--','--'];
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
test_runs0 = get_tests(parsed_data_ful{1}, range0, 'ascend');
test_runs1 = get_tests(parsed_data_ful{1}, range1, 'descend');

test_runs2 = get_tests(parsed_data_ful{2}, range0, 'ascend');
test_runs3 = get_tests(parsed_data_ful{2}, range1, 'descend');

test_runs4 = get_tests(parsed_data_ful{3}, range0, 'ascend');
test_runs5 = get_tests(parsed_data_ful{3}, range1, 'descend');

test_runs6 = get_tests(parsed_data_ful{4}, range0, 'ascend');
test_runs7 = get_tests(parsed_data_ful{4}, range1, 'descend');

test_runs8 = get_tests(parsed_data_ful{5}, range0, 'ascend');
test_runs9 = get_tests(parsed_data_ful{5}, range1, 'descend');

test_runs10 = get_tests(parsed_data_ful{6}, range0, 'ascend');
test_runs11 = get_tests(parsed_data_ful{6}, range1, 'descend');

test_runs12 = get_tests(parsed_data_ful{7}, range0, 'ascend');
test_runs13 = get_tests(parsed_data_ful{7}, range1, 'descend');

test_runs14 = get_tests(parsed_data_ful{8}, range0, 'ascend');
test_runs15 = get_tests(parsed_data_ful{8}, range1, 'descend');

% PAPER GRAPHIC
% -----------------------------------------------------------------------------------------------
f = figure('Position',[100,100,700,650]);

    fax = gca;
    xB = .05;
    yB = .9;

    % nussinov
    % -----------------------
    h1 = subplot(4,4,1);
        for i = 1:size(range0(:))
            plot(test_runs0{i}(:,23),test_runs0{i}(:,22)/parsed_data_lru{1}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.95 1.4]);
        %title('Nussinov SRL','FontWeight','Normal');
        %annotation(gca,'textbox',[0,1,0,0],'String','LRL');
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
    h2 = subplot(4,4,2);
        for i = 1:size(range1(:))        
            plot(test_runs1{i}(:,23),test_runs1{i}(:,22)/parsed_data_lru{1}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;
        end
        ylim([.95 1.4]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Nussinov LRL','FontWeight','Normal');
        
    % floyd
    % -----------------------
    h3 = subplot(4,4,3);
        for i = 1:size(range0(:))
            plot(test_runs2{i}(:,23),test_runs2{i}(:,22)/parsed_data_lru{2}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.4 1]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Floyd-Warshall SRL','FontWeight','Normal');
    h4 = subplot(4,4,4);
        for i = 1:size(range1(:))        
            plot(test_runs3{i}(:,23),test_runs3{i}(:,22)/parsed_data_lru{2}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.4 1]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Floyd-Warshall LRL','FontWeight','Normal');
        
    % matrix 2
    % -----------------------
    h5 = subplot(4,4,5);
        for i = 1:size(range0(:))
            plot(test_runs4{i}(:,23),test_runs4{i}(:,22)/parsed_data_lru{3}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('2mm SRL','FontWeight','Normal');
        %t=text(1000,0,'FUL Miss Ratio Normalized to LRU Miss Ratio','Rotation',90);
    h6 = subplot(4,4,6);
        for i = 1:size(range1(:))        
            plot(test_runs5{i}(:,23),test_runs5{i}(:,22)/parsed_data_lru{3}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('2mm LRL','FontWeight','Normal');
        
    % matrix 3
    % -----------------------
    h7 = subplot(4,4,7);
        for i = 1:size(range0(:))
            plot(test_runs6{i}(:,23),test_runs6{i}(:,22)/parsed_data_lru{4}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('3mm SRL','FontWeight','Normal');
    h8 = subplot(4,4,8);
        for i = 1:size(range1(:))        
            plot(test_runs7{i}(:,23),test_runs7{i}(:,22)/parsed_data_lru{4}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.9 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('3mm LRL','FontWeight','Normal');
        
    % doitgen
    % -----------------------
    h9 = subplot(4,4,9);
        for i = 1:size(range0(:))
            plot(test_runs8{i}(:,23),test_runs8{i}(:,22)/parsed_data_lru{5}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.95 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Doitgen SRL','FontWeight','Normal');
    h10 = subplot(4,4,10);
        for i = 1:size(range1(:))        
            plot(test_runs9{i}(:,23),test_runs9{i}(:,22)/parsed_data_lru{5}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.95 2]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Doitgen LRL','FontWeight','Normal');
        
    % bicg
    % -----------------------
    h11 = subplot(4,4,11);
        for i = 1:size(range0(:))
            plot(test_runs10{i}(:,23),test_runs10{i}(:,22)/parsed_data_lru{6}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.95 1.4]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Bicg SRL','FontWeight','Normal');
        
    h12 = subplot(4,4,12);
        for i = 1:size(range1(:))        
            plot(test_runs11{i}(:,23),test_runs11{i}(:,22)/parsed_data_lru{6}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.95 1.4]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Bicg LRL','FontWeight','Normal');
        
    % atax
    % -----------------------
    h13 = subplot(4,4,13);
        for i = 1:size(range0(:))
            plot(test_runs12{i}(:,23),test_runs12{i}(:,22)/parsed_data_lru{7}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.95 1.3]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Atax SRL','FontWeight','Normal');
        
    h14 = subplot(4,4,14);
        for i = 1:size(range1(:))        
            plot(test_runs13{i}(:,23),test_runs13{i}(:,22)/parsed_data_lru{7}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.95 1.3]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Atax LRL','FontWeight','Normal');
        
    % mvt
    % -----------------------
    h15 = subplot(4,4,15);
        for i = 1:size(range0(:))
            plot(test_runs14{i}(:,23),test_runs14{i}(:,22)/parsed_data_lru{8}(1,22),line_types(i),...
            'LineWidth',line_widths(i)); hold on;                 
        end
        ylim([.2 1]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
        %title('Mvt SRL','FontWeight','Normal');
        
    h16 = subplot(4,4,16);
        for i = 1:size(range1(:))        
            plot(test_runs15{i}(:,23),test_runs15{i}(:,22)/parsed_data_lru{8}(1,22),...
            'LineWidth',line_widths(i)); hold on;         
        end
        ylim([.2 1]);
        yax=get(gca,'ylim');
        xax=get(gca,'xlim');
            text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'LRL');
        %title('Mvt LRL','FontWeight','Normal');
        
        
        
        
    height = .15;
    width = .2;
    set(h1, 'Position', [.08, .8, width, height]);
    set(h2, 'Position', [.08+.21, .8, width, height]);
    set(h3, 'Position', [.55, .8, width, height]);
    set(h4, 'Position', [.55+.21, .8, width, height]);
    
    
    set(h5, 'Position', [.08, .6, width, height]);
    set(h6, 'Position', [.08+.21, .6, width, height]);
    set(h7, 'Position', [.55, .6, width, height]);
    set(h8, 'Position', [.55+.21, .6, width, height]);
    
    set(h9, 'Position', [.08, .4, width, height]);
    set(h10, 'Position', [.08+.21, .4, width, height]);
    set(h11, 'Position', [.55, .4, width, height]);
    set(h12, 'Position', [.55+.21, .4, width, height]);
    
    set(h13, 'Position', [.08, .2, width, height]);
    set(h14, 'Position', [.08+.21, .2, width, height]);
    set(h15, 'Position', [.55, .2, width, height]);
    set(h16, 'Position', [.55+.21, .2, width, height]);
        
    legend({'Random','Pool = 4','Pool = 8'},'Location','southoutside','Orientation','horizontal');
    
    annotation('textbox', [0.4, 0.05, 0.1, 0.1],'LineStyle','none', 'String', "FUL Full Lease Length"); 
    
    ax = findobj(f,'Type','Axes');
    for i=1:length(ax)
        ax(i).XRuler.Exponent = 0;
        %xlabel(ax(i),"FUL Full Lease Length");
        xlim(ax(i),[0 65020]);
        xticks(ax(i),[0 25000 50000])
        
        if mod(i,2) == 1
            set(ax(i),'YTick',[]);
        end
        
        % set limits and stuff
        %yax=get(ax(i),'ylim');
        %xax=get(ax(i),'xlim');
        %    text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
       
    end
    
    ax1 = axes('Position',[0.03 0.35 .6 .6],'Box','off','visible', 'off');
    text(ax1, 0, 0, 'FUL Miss Ratio Normalized to LRU Miss Ratio','Rotation',90);  
    
    %yax=get(gca,'ylim');
    %xax=get(gca,'xlim');
    %text(xB*(xax(2)-xax(1)),yB*(yax(2)-yax(1))+yax(1),'SRL');
    
    % plot titles
    annotation(f,'textbox',...
        [0.235285714285714 0.941538461538462 0.107571428571429 0.0415384615384615],...
        'String',{'Nussinov'},...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.683857142857143 0.94 0.107571428571429 0.0415384615384617],...
        'String','Floyd-Warshall',...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.252428571428571 0.741538461538461 0.107571428571428 0.0415384615384614],...
        'String','2mm',...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.722428571428571 0.743076923076923 0.107571428571429 0.0415384615384614],...
        'String','3mm',...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.238142857142857 0.541538461538461 0.107571428571429 0.0415384615384614],...
        'String','Doitgen',...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.728142857142857 0.543076923076923 0.107571428571429 0.0415384615384614],...
        'String','Bicg',...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.255285714285714 0.34 0.107571428571428 0.0415384615384615],...
        'String','Atax',...
        'LineStyle','none',...
        'FitBoxToText','off');
    annotation(f,'textbox',...
        [0.729571428571428 0.34 0.107571428571429 0.0415384615384615],...
        'String','Mvt',...
        'LineStyle','none',...
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
        
        
        
