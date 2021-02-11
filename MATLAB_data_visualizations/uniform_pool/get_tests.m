function [tests_cells] = get_tests(tests_all, range, direction, sortby)

% first determine how many unique polarity+pool combos there are - column
% 18

groups = [];
for i=1:size(tests_all(:,1))
    if ~ismember(tests_all(i,24), groups )
        groups = [groups;  tests_all(i,24)];
    end
end

% cardinally sort
groups = sort(groups, direction);

n = 1;
for i=1:size(groups)
    if ismember(groups(i),range)
        tests_cells{n} = tests_all(tests_all(:,24) == groups(i),:);
        n = n + 1;
    end
end

if sortby > 0
    for i=1:size(tests_cells(:))
        tests_cells{i} = sortrows(tests_cells{i},sortby);
    end
end

end

