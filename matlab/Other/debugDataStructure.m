%% debugDataStructure.m
% Debug script to understand the data structure in the result files

% Load one result file
resultFile = '/Users/nihara/Downloads/AcCoRD-1.4.2/et1_distance_5_10_20_out.mat';
load(resultFile, 'data');

fprintf('=== Data Structure Analysis ===\n\n');

% Basic info
fprintf('Number of passive actors recorded: %d\n', data.numPassiveRecord);
fprintf('Passive Actor IDs: %s\n', mat2str(data.passiveRecordID));
fprintf('Number of realizations: %d\n', data.numRepeat);

fprintf('\n--- Per Passive Actor Info ---\n');
for i = 1:data.numPassiveRecord
    fprintf('\nPassive Actor %d (ID=%d):\n', i, data.passiveRecordID(i));
    fprintf('  Time recorded: %d\n', data.passiveRecordBTime(i));
    fprintf('  Max count length: %d\n', data.passiveRecordMaxCountLength(i));
    fprintf('  Num molecule types: %d\n', data.passiveRecordNumMolType(i));
    
    % Check count data shape
    countData = data.passiveRecordCount{i};
    fprintf('  Count data size: %s\n', mat2str(size(countData)));
    
    % Show some sample counts
    if ndims(countData) == 3
        avgCount = squeeze(mean(countData(:, 1, :), 1));
    else
        avgCount = squeeze(mean(countData, 1));
    end
    fprintf('  Avg count (first 10 points): %s\n', mat2str(avgCount(1:min(10,length(avgCount))), 3));
    fprintf('  Max avg count: %.2f\n', max(avgCount));
    fprintf('  Mean avg count: %.2f\n', mean(avgCount));
end

fprintf('\n--- Comparing counts across passive actors ---\n');
fprintf('(These should be DIFFERENT if they represent different distances)\n\n');

for i = 1:data.numPassiveRecord
    countData = data.passiveRecordCount{i};
    if ndims(countData) == 3
        avgCount = squeeze(mean(countData(:, 1, :), 1));
    else
        avgCount = squeeze(mean(countData, 1));
    end
    fprintf('Passive Actor %d - Sum of counts: %.0f, Max: %.2f\n', i, sum(avgCount), max(avgCount));
end

fprintf('\n--- Time data check ---\n');
if data.passiveRecordBTime(1)
    timeData = data.passiveRecordTime{1};
    fprintf('Time data size: %s\n', mat2str(size(timeData)));
    if ~isempty(timeData)
        time = squeeze(timeData(1,:));
        fprintf('Time range: %.2f to %.2f seconds\n', min(time), max(time));
        fprintf('Time step: %.2f seconds\n', time(2)-time(1));
    end
else
    fprintf('Time was NOT recorded with observations\n');
    fprintf('Need to generate time based on Action Interval\n');
end
