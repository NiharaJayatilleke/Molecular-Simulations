%% analyzeSymbolDurationComparison.m
% Analyze results from et1_symbol_duration_comparison
% Plots 3 curves for symbol durations 300s, 400s, 500s at 10cm receiver

%% Configuration
resultFile = '/Users/nihara/Downloads/AcCoRD-1.4.2/et1_symbol_duration_comparison_out.mat';

% TX bits (same for all 3 transmitters)
txBits = [0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0];
numBits = length(txBits);

% Symbol durations and their time windows
symbolDurations = [300, 400, 500];  % seconds
startTimes = [0, 12000, 27000];     % seconds (when each TX starts)

% Receiver sampling interval
actionInterval = 2.0;

%% Load data
load(resultFile, 'data');

% Get receiver data (passive actor 1 - the 10cm receiver)
% Note: First 3 actors are transmitters, 4th is receiver
% But in passiveRecordCount, receivers are indexed separately
passiveActorIdx = 1;  % Only one receiver

countData = data.passiveRecordCount{passiveActorIdx};
cumulativeCount = squeeze(countData(1, 1, :))';

% Convert to differential counts
diffCount = [cumulativeCount(1), diff(cumulativeCount)];
numPoints = length(diffCount);

% Time axis
time = (0:numPoints-1) * actionInterval;

fprintf('=== Symbol Duration Comparison Analysis ===\n');
fprintf('Total data points: %d\n', numPoints);
fprintf('Total time: %.1f seconds\n', time(end));

%% Analyze each symbol duration
figure('Position', [100, 100, 1200, 800], 'Color', 'w');

colors = {'b', 'r', 'g'};
BER_results = zeros(1, 3);

for sd = 1:3
    symbolDuration = symbolDurations(sd);
    startTime = startTimes(sd);
    endTime = startTime + symbolDuration * numBits + 2000;  % Add buffer
    
    samplesPerSymbol = symbolDuration / actionInterval;
    
    % Find time window indices
    startIdx = round(startTime / actionInterval) + 1;
    endIdx = min(round(endTime / actionInterval), numPoints);
    
    % Extract data for this time window
    windowDiffCount = diffCount(startIdx:endIdx);
    windowTime = time(startIdx:endIdx) - startTime;  % Relative time
    
    fprintf('\n--- Symbol Duration: %d s ---\n', symbolDuration);
    fprintf('Time window: %.0f to %.0f seconds\n', startTime, endTime);
    fprintf('Samples per symbol: %.0f\n', samplesPerSymbol);
    
    % Calculate sum per bit
    rxSum = zeros(1, numBits);
    for i = 1:numBits
        bitStartIdx = round((i-1) * samplesPerSymbol) + 1;
        bitEndIdx = min(round(i * samplesPerSymbol), length(windowDiffCount));
        if bitStartIdx <= length(windowDiffCount)
            rxSum(i) = sum(windowDiffCount(bitStartIdx:bitEndIdx));
        end
    end
    
    % Find optimal threshold
    sum_when_0 = rxSum(txBits == 0);
    sum_when_1 = rxSum(txBits == 1);
    threshold = (mean(sum_when_0) + mean(sum_when_1)) / 2;
    
    % Decode and compute BER
    rxBits = rxSum > threshold;
    errors = sum(rxBits ~= txBits);
    BER_results(sd) = errors / numBits;
    
    fprintf('Threshold: %.1f\n', threshold);
    fprintf('BER: %.4f (%d errors)\n', BER_results(sd), errors);
    fprintf('Mean when TX=0: %.1f, Mean when TX=1: %.1f\n', mean(sum_when_0), mean(sum_when_1));
    
    % Plot waveform
    subplot(2, 2, sd);
    plot(windowTime, windowDiffCount, colors{sd}, 'LineWidth', 0.5);
    hold on;
    % Add bit boundaries
    for b = 1:min(10, numBits)
        xline(b * symbolDuration, 'k--', 'Alpha', 0.3);
    end
    hold off;
    xlabel('Time (s)');
    ylabel('Molecules per interval');
    title(sprintf('Symbol Duration = %d s (BER = %.4f)', symbolDuration, BER_results(sd)));
    grid on;
    xlim([0, symbolDuration * 12]);  % Show first 12 bits
end

% Plot BER comparison
subplot(2, 2, 4);
bar(symbolDurations, BER_results, 'FaceColor', [0.3 0.6 0.9]);
xlabel('Symbol Duration (s)');
ylabel('Bit Error Rate');
title('BER vs Symbol Duration at 10cm');
grid on;

% Add value labels on bars
for i = 1:3
    text(symbolDurations(i), BER_results(i) + 0.01, sprintf('%.4f', BER_results(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

sgtitle('Symbol Duration Comparison - Receiver at 10cm', 'FontSize', 14);

%% Plot all three on same time axis (optional)
figure('Position', [150, 150, 1000, 400], 'Color', 'w');

% Plot full waveform with colored regions
plot(time, diffCount, 'k', 'LineWidth', 0.5);
hold on;

% Highlight time windows
colors_fill = {[0.8 0.8 1], [1 0.8 0.8], [0.8 1 0.8]};
yLims = ylim;
for sd = 1:3
    startTime = startTimes(sd);
    endTime = startTime + symbolDurations(sd) * numBits;
    patch([startTime startTime endTime endTime], [yLims(1) yLims(2) yLims(2) yLims(1)], ...
        colors_fill{sd}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

legend('Received Signal', 'SD=300s', 'SD=400s', 'SD=500s', 'Location', 'best');
xlabel('Time (s)');
ylabel('Molecules per interval');
title('Full Simulation Timeline with Symbol Duration Windows');
grid on;
hold off;

%% Summary
fprintf('\n=== Summary ===\n');
fprintf('Symbol Duration | BER\n');
fprintf('----------------|--------\n');
for sd = 1:3
    fprintf('%14d s | %.4f\n', symbolDurations(sd), BER_results(sd));
end
