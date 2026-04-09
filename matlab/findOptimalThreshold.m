function [optimalThreshold, thresholdInfo] = findOptimalThreshold(resultFile, txBits, symbolDuration, passiveActorIdx, molIdx)
%
% findOptimalThreshold - Automatically determine the best detection threshold
%
% USAGE:
%   threshold = findOptimalThreshold(resultFile, txBits, symbolDuration)
%   threshold = findOptimalThreshold(resultFile, txBits, symbolDuration, passiveActorIdx)
%   [threshold, info] = findOptimalThreshold(...)
%
% INPUTS:
%   resultFile      - Path to .mat result file
%   txBits          - Vector of transmitted bits (0s and 1s)
%   symbolDuration  - Duration of each symbol/bit in seconds
%   passiveActorIdx - (Optional) Passive actor index. Default: 1
%   molIdx          - (Optional) Molecule type index. Default: 1
%
% OUTPUTS:
%   optimalThreshold - The threshold that minimizes BER
%   thresholdInfo    - Struct with detailed analysis info
%
% EXAMPLE:
%   txBits = [0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0];
%   [thresh, info] = findOptimalThreshold('et1_distance_5_10_20_out.mat', txBits, 300, 1);

% Defaults
if nargin < 4, passiveActorIdx = 1; end
if nargin < 5, molIdx = 1; end

% Ensure file has .mat extension
if ~endsWith(resultFile, '.mat')
    if ~endsWith(resultFile, '_out')
        resultFile = strcat(resultFile, '_out');
    end
    resultFile = strcat(resultFile, '.mat');
end

% Load data
load(resultFile, 'data');

% Extract counts
countData = data.passiveRecordCount{passiveActorIdx};
cumulativeCount = squeeze(mean(countData(:, molIdx, :), 1));
cumulativeCount = cumulativeCount(:)';

% Convert cumulative to differential
diffCount = [cumulativeCount(1), diff(cumulativeCount)];

% Calculate sum per symbol
actionInterval = 2.0;  % Receiver sampling interval
samplesPerSymbol = symbolDuration / actionInterval;
numBits = length(txBits);
numPoints = length(diffCount);

rxSum = zeros(1, numBits);
for i = 1:numBits
    startIdx = round((i-1) * samplesPerSymbol) + 1;
    endIdx = min(round(i * samplesPerSymbol), numPoints);
    if startIdx <= numPoints
        rxSum(i) = sum(diffCount(startIdx:endIdx));
    end
end

% Separate by TX bit value
sum_when_0 = rxSum(txBits == 0);
sum_when_1 = rxSum(txBits == 1);

% Calculate statistics
mean_0 = mean(sum_when_0);
mean_1 = mean(sum_when_1);
std_0 = std(sum_when_0);
std_1 = std(sum_when_1);
min_1 = min(sum_when_1);
max_0 = max(sum_when_0);

% Method 1: Midpoint threshold
midpointThreshold = (mean_0 + mean_1) / 2;

% Method 2: Search for minimum BER threshold
testThresholds = linspace(min(rxSum), max(rxSum), 1000);
berValues = zeros(size(testThresholds));

for t = 1:length(testThresholds)
    thresh = testThresholds(t);
    rxBits = rxSum > thresh;
    berValues(t) = sum(rxBits ~= txBits) / numBits;
end

[minBER, minIdx] = min(berValues);
minBERThreshold = testThresholds(minIdx);

% Method 3: Maximum margin threshold (midpoint between max_0 and min_1)
marginThreshold = (max_0 + min_1) / 2;

% Choose the best one (minimum BER threshold)
optimalThreshold = minBERThreshold;

% Store info
thresholdInfo.rxSum = rxSum;
thresholdInfo.txBits = txBits;
thresholdInfo.sum_when_0 = sum_when_0;
thresholdInfo.sum_when_1 = sum_when_1;
thresholdInfo.mean_0 = mean_0;
thresholdInfo.mean_1 = mean_1;
thresholdInfo.std_0 = std_0;
thresholdInfo.std_1 = std_1;
thresholdInfo.min_1 = min_1;
thresholdInfo.max_0 = max_0;
thresholdInfo.midpointThreshold = midpointThreshold;
thresholdInfo.marginThreshold = marginThreshold;
thresholdInfo.minBERThreshold = minBERThreshold;
thresholdInfo.minBER = minBER;
thresholdInfo.testThresholds = testThresholds;
thresholdInfo.berValues = berValues;

% Display results
fprintf('\n=== Threshold Analysis for Passive Actor %d ===\n', passiveActorIdx);
fprintf('\nReceived Signal Statistics:\n');
fprintf('  When TX=0: mean=%.1f, std=%.1f, max=%.1f\n', mean_0, std_0, max_0);
fprintf('  When TX=1: mean=%.1f, std=%.1f, min=%.1f\n', mean_1, std_1, min_1);
fprintf('  Separation: %.1f (mean1 - mean0)\n', mean_1 - mean_0);

fprintf('\nThreshold Methods:\n');
fprintf('  1. Midpoint (mean0+mean1)/2:  %.1f\n', midpointThreshold);
fprintf('  2. Margin (max0+min1)/2:      %.1f\n', marginThreshold);
fprintf('  3. Min BER search:            %.1f (BER=%.4f)\n', minBERThreshold, minBER);

fprintf('\nRecommended threshold: %.1f\n', optimalThreshold);

% Optional: Plot
if nargout == 0 || true
    figure('Position', [100, 100, 1000, 400]);
    
    subplot(1,2,1);
    hold on;
    bar(find(txBits==0), rxSum(txBits==0), 'b', 'DisplayName', 'TX=0');
    bar(find(txBits==1), rxSum(txBits==1), 'r', 'DisplayName', 'TX=1');
    yline(optimalThreshold, 'g--', 'LineWidth', 2, 'DisplayName', sprintf('Threshold=%.0f', optimalThreshold));
    hold off;
    xlabel('Bit Index');
    ylabel('Received Sum');
    title('Received Signal per Bit');
    legend('Location', 'best');
    grid on;
    
    subplot(1,2,2);
    plot(testThresholds, berValues, 'b-', 'LineWidth', 1.5);
    hold on;
    plot(minBERThreshold, minBER, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    hold off;
    xlabel('Threshold');
    ylabel('BER');
    title('BER vs Threshold');
    grid on;
    
    sgtitle(sprintf('Threshold Analysis - Passive Actor %d', passiveActorIdx));
end

end
