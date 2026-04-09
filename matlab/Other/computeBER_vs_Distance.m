%% computeBER_vs_Distance.m
% Compute and plot BER vs Distance for all 5 encoding techniques
% Creates a single graph with 5 curves showing how BER changes with distance
%
% Run from matlab/ directory or add it to path first:
%   addpath('/Users/nihara/Downloads/AcCoRD-1.4.2/matlab')

%% ========================================
%% CONFIGURATION - EXTRACTED FROM CONFIG FILES
%% ========================================

% Number of encoding techniques
numTechniques = 5;

% Receiver distances (from config: 5cm, 10cm, 20cm)
% Passive actors 1, 2, 3 correspond to these distances
distances_cm = [5, 10, 20];
numDistances = length(distances_cm);

% TECHNIQUE-SPECIFIC PARAMETERS (extracted from et*_distance_5_10_20.txt configs)

% Transmitted bit patterns for each technique
txBits_all = {
    [0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0],  % ET1 - 32 bits
    [0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1,0],  % ET2 - 48 bits
    [0,1,0,0,0,0],  % ET3 - 6 bits
    [0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0,0],  % ET4 - 32 bits
    [0,1,0,1,1,0,0,1,0,1,0,1,1,0,0,1,0,0,0,1,0,0,1,1,0,1,1,0,0,0,1,0,0,1,0,1,1,0,0,1,0,1,0,1,1,0,0,1]   % ET5 - 48 bits
};

% Symbol duration (seconds per bit) - All techniques use 300s Action Interval
symbolDuration_all = [
    300.0,    % ET1
    300.0,    % ET2
    300.0,    % ET3
    300.0,    % ET4
    300.0     % ET5
];

% Detection threshold - Using FIXED threshold for all distances
% This simulates a real receiver that doesn't adapt to distance
% Using a threshold optimized for 5cm (closest distance) to show degradation
%
% Option 1: Use threshold optimized for closest distance (5cm)
%           This will show increasing BER as distance increases
% Option 2: Use a single "compromise" threshold
%
% Format: threshold_matrix(technique, distance)
% Each row is a technique, each column is a distance (5cm, 10cm, 20cm)

% FIXED threshold approach - same value for all distances
fixedThreshold = 500;  % A compromise threshold - adjust to see different behavior

threshold_matrix = [
    fixedThreshold, fixedThreshold, fixedThreshold;    % ET1
    fixedThreshold, fixedThreshold, fixedThreshold;    % ET2
    fixedThreshold, fixedThreshold, fixedThreshold;    % ET3
    fixedThreshold, fixedThreshold, fixedThreshold;    % ET4
    fixedThreshold, fixedThreshold, fixedThreshold     % ET5
];

%% ========================================
%% FILE SETUP
%% ========================================

% Result files (absolute paths)
resultFiles = {
    '/Users/nihara/Downloads/AcCoRD-1.4.2/et1_distance_5_10_20_out.mat',
    '/Users/nihara/Downloads/AcCoRD-1.4.2/et2_distance_5_10_20_out.mat',
    '/Users/nihara/Downloads/AcCoRD-1.4.2/et3_distance_5_10_20_out.mat',
    '/Users/nihara/Downloads/AcCoRD-1.4.2/et4_distance_5_10_20_out.mat',
    '/Users/nihara/Downloads/AcCoRD-1.4.2/et5_distance_5_10_20_out.mat'
};

% Labels for legend
techniqueLabels = {'ET1', 'ET2', 'ET3', 'ET4', 'ET5'};

%% ========================================
%% COMPUTE BER FOR ALL TECHNIQUES AND DISTANCES
%% ========================================

fprintf('=== Computing BER vs Distance for %d Encoding Techniques ===\n\n', numTechniques);

% BER matrix: rows = techniques, columns = distances
BER_matrix = zeros(numTechniques, numDistances);

for tech = 1:numTechniques
    fprintf('--- Technique %d (%s) ---\n', tech, techniqueLabels{tech});
    fprintf('Bits: %d, Symbol Duration: %.1f s\n', ...
        length(txBits_all{tech}), symbolDuration_all(tech));
    
    for d = 1:numDistances
        currentThreshold = threshold_matrix(tech, d);
        fprintf('  Distance %d cm (Threshold: %d): ', distances_cm(d), currentThreshold);
        
        try
            % Compute BER using technique-specific parameters
            % d corresponds to passive actor index (1=5cm, 2=10cm, 3=20cm)
            BER_matrix(tech, d) = computeBER(resultFiles{tech}, ...
                txBits_all{tech}, ...
                symbolDuration_all(tech), ...
                currentThreshold, ...  % Use distance-specific threshold
                d, ...    % passive actor index = distance index
                1);       % molecule type index
        catch ME
            warning('Error: %s', ME.message);
            BER_matrix(tech, d) = NaN;
        end
    end
    fprintf('\n');
end

%% ========================================
%% PLOT: BER vs Distance (5 curves)
%% ========================================

figure('Color', 'w', 'Position', [100, 100, 800, 600]);

% Colors and markers for each technique
colors = {'b', 'r', 'g', 'm', 'c'};
markers = {'o', 's', 'd', '^', 'v'};
lineStyles = {'-', '-', '-', '-', '-'};

hold on;
for tech = 1:numTechniques
    plot(distances_cm, BER_matrix(tech, :), ...
        [lineStyles{tech} markers{tech}], ...
        'Color', colors{tech}, ...
        'LineWidth', 2, ...
        'MarkerSize', 10, ...
        'MarkerFaceColor', colors{tech}, ...
        'DisplayName', techniqueLabels{tech});
end
hold off;

% Formatting
xlabel('Distance (cm)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Bit Error Rate (BER)', 'FontSize', 14, 'FontWeight', 'bold');
title('BER vs Distance for Different Encoding Techniques', 'FontSize', 16, 'FontWeight', 'bold');
legend('show', 'Location', 'best', 'FontSize', 12);
grid on;
set(gca, 'FontSize', 12, 'LineWidth', 1.5);

% Set axis limits
xlim([min(distances_cm)-1, max(distances_cm)+1]);
ylim([0, min(1, max(BER_matrix(:))*1.2 + 0.05)]);  % Cap at 1.0

% Add minor grid
set(gca, 'XMinorGrid', 'on', 'YMinorGrid', 'on');

%% ========================================
%% PLOT: BER vs Distance (Log scale - optional)
%% ========================================

figure('Color', 'w', 'Position', [150, 150, 800, 600]);

hold on;
for tech = 1:numTechniques
    semilogy(distances_cm, BER_matrix(tech, :) + 1e-10, ...  % Add small value to avoid log(0)
        [lineStyles{tech} markers{tech}], ...
        'Color', colors{tech}, ...
        'LineWidth', 2, ...
        'MarkerSize', 10, ...
        'MarkerFaceColor', colors{tech}, ...
        'DisplayName', techniqueLabels{tech});
end
hold off;

% Formatting
xlabel('Distance (cm)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Bit Error Rate (BER) - Log Scale', 'FontSize', 14, 'FontWeight', 'bold');
title('BER vs Distance (Log Scale)', 'FontSize', 16, 'FontWeight', 'bold');
legend('show', 'Location', 'best', 'FontSize', 12);
grid on;
set(gca, 'FontSize', 12, 'LineWidth', 1.5);
set(gca, 'YScale', 'log');

xlim([min(distances_cm)-1, max(distances_cm)+1]);

%% ========================================
%% DISPLAY SUMMARY TABLE
%% ========================================

fprintf('\n=== BER Summary Table ===\n');
fprintf('%-10s | ', 'Technique');
for d = 1:numDistances
    fprintf('%8d cm | ', distances_cm(d));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 12 + numDistances*12));

for tech = 1:numTechniques
    fprintf('%-10s | ', techniqueLabels{tech});
    for d = 1:numDistances
        fprintf('%10.4f | ', BER_matrix(tech, d));
    end
    fprintf('\n');
end

%% ========================================
%% SAVE RESULTS
%% ========================================

% Uncomment to save:
% save('BER_vs_Distance_results.mat', 'BER_matrix', 'distances_cm', 'techniqueLabels', ...
%     'txBits_all', 'threshold_all', 'symbolDuration_all');
% fprintf('\nResults saved to BER_vs_Distance_results.mat\n');

% Uncomment to save figures:
% saveas(gcf, 'BER_vs_Distance_log.png');
% saveas(figure(1), 'BER_vs_Distance_linear.png');
% fprintf('Figures saved.\n');
