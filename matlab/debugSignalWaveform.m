%% debugSignalWaveform.m
% Visualize the received signal to understand the data better

% Load one result file
resultFile = '/Users/nihara/Downloads/AcCoRD-1.4.2/et1_distance_5_10_20_out.mat';
load(resultFile, 'data');

fprintf('=== Signal Waveform Analysis ===\n\n');

% Parameters from config
actionInterval = 2.0;  % Receiver samples every 2 seconds
symbolDuration = 300.0;  % Each bit lasts 300 seconds
samplesPerBit = symbolDuration / actionInterval;  % = 150 samples per bit

fprintf('Receiver sampling interval: %.1f s\n', actionInterval);
fprintf('Symbol duration: %.1f s\n', symbolDuration);
fprintf('Samples per bit: %.0f\n', samplesPerBit);

% TX bits for ET1
txBits = [0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0];
numBits = length(txBits);
fprintf('Number of TX bits: %d\n', numBits);

% Distance labels
distanceLabels = [5, 10, 20];

figure('Position', [100, 100, 1200, 800]);

for actorIdx = 1:3
    distCm = distanceLabels(actorIdx);
    
    % Get cumulative counts
    countData = data.passiveRecordCount{actorIdx};
    cumulativeCount = squeeze(countData(1, 1, :))';
    
    % Convert to per-interval (differential) counts
    diffCount = [cumulativeCount(1), diff(cumulativeCount)];
    
    % Time axis
    numPoints = length(diffCount);
    time = (0:numPoints-1) * actionInterval;
    
    fprintf('\n--- Passive Actor %d (Distance %d cm) ---\n', actorIdx, distCm);
    fprintf('Total data points: %d\n', numPoints);
    fprintf('Time range: 0 to %.1f seconds\n', time(end));
    fprintf('Max differential count: %.2f\n', max(diffCount));
    fprintf('Mean differential count: %.2f\n', mean(diffCount));
    
    % Sum molecules per bit period
    bitsToShow = min(numBits, floor(numPoints / samplesPerBit));
    sumPerBit = zeros(1, bitsToShow);
    maxPerBit = zeros(1, bitsToShow);
    
    for b = 1:bitsToShow
        startIdx = round((b-1) * samplesPerBit) + 1;
        endIdx = min(round(b * samplesPerBit), numPoints);
        sumPerBit(b) = sum(diffCount(startIdx:endIdx));
        maxPerBit(b) = max(diffCount(startIdx:endIdx));
    end
    
    fprintf('Sum per bit (first 10): %s\n', mat2str(round(sumPerBit(1:min(10,bitsToShow)))));
    fprintf('TX bits (first 10):     %s\n', mat2str(txBits(1:min(10,bitsToShow))));
    
    % Plot
    subplot(3, 2, (actorIdx-1)*2 + 1);
    plot(time(1:min(3000,numPoints)), diffCount(1:min(3000,numPoints)));
    xlabel('Time (s)');
    ylabel('Molecules per interval');
    title(sprintf('Passive Actor %d (%d cm) - Differential counts', actorIdx, distCm));
    grid on;
    
    % Add vertical lines for bit boundaries
    hold on;
    for b = 1:min(10, bitsToShow)
        xline(b * symbolDuration, 'r--', 'Alpha', 0.3);
    end
    hold off;
    
    subplot(3, 2, (actorIdx-1)*2 + 2);
    bar(1:bitsToShow, sumPerBit);
    hold on;
    % Mark TX bit '1' positions
    ones_idx = find(txBits(1:bitsToShow) == 1);
    scatter(ones_idx, sumPerBit(ones_idx), 100, 'r', 'filled');
    hold off;
    xlabel('Bit index');
    ylabel('Total molecules in bit period');
    title(sprintf('Sum per bit period (red = TX bit 1)'));
    grid on;
    legend('Sum per bit', 'TX bit = 1');
end

sgtitle('Signal Analysis for ET1 at Different Distances');

%% Suggest thresholds based on data
fprintf('\n=== Threshold Suggestions ===\n');
for actorIdx = 1:3
    distCm = distanceLabels(actorIdx);
    
    countData = data.passiveRecordCount{actorIdx};
    cumulativeCount = squeeze(countData(1, 1, :))';
    diffCount = [cumulativeCount(1), diff(cumulativeCount)];
    numPoints = length(diffCount);
    
    bitsToShow = min(numBits, floor(numPoints / samplesPerBit));
    sumPerBit = zeros(1, bitsToShow);
    
    for b = 1:bitsToShow
        startIdx = round((b-1) * samplesPerBit) + 1;
        endIdx = min(round(b * samplesPerBit), numPoints);
        sumPerBit(b) = sum(diffCount(startIdx:endIdx));
    end
    
    % Separate by TX bit value
    sum_when_0 = sumPerBit(txBits(1:bitsToShow) == 0);
    sum_when_1 = sumPerBit(txBits(1:bitsToShow) == 1);
    
    fprintf('\nDistance %d cm:\n', distCm);
    fprintf('  When TX=0: mean=%.1f, max=%.1f\n', mean(sum_when_0), max(sum_when_0));
    fprintf('  When TX=1: mean=%.1f, min=%.1f\n', mean(sum_when_1), min(sum_when_1));
    fprintf('  Suggested threshold: %.1f (midpoint)\n', (mean(sum_when_0) + mean(sum_when_1))/2);
end
