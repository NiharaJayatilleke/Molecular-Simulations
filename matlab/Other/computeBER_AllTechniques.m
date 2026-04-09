%% computeBER_AllTechniques.m
% Compute and plot BER for all 5 encoding techniques across distances
%
% Run from matlab/ directory or add it to path first:
%   addpath('/Users/nihara/Downloads/AcCoRD-1.4.2/matlab')

%% ========================================
%% CONFIGURATION - EXTRACTED FROM CONFIG FILES
%% ========================================

% Number of encoding techniques
numTechniques = 5;

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

% Detection threshold (molecule count) for each technique
% NOTE: These need tuning based on your actual received signal levels!
% Start with these estimates, then adjust based on the plotted waveforms
% Tip: Plot the signals first using accordMultiPlot to see typical peak values
threshold_all = [
    100,    % ET1 - adjust based on observed signal
    100,    % ET2 - adjust based on observed signal
    100,    % ET3 - adjust based on observed signal
    100,    % ET4 - adjust based on observed signal
    100     % ET5 - adjust based on observed signal
];

% Receiver distances (from config: 5cm, 10cm, 20cm)
% Receivers are passive actors 1, 2, 3 in order
distances_cm = [5, 10, 20];

% Which passive actor to analyze (1=5cm, 2=10cm, 3=20cm)
passiveActorToUse = 1;  % Change this to analyze different distances

%% ========================================
%% FILE SETUP
%% ========================================

% Result files are in parent directory (root of AcCoRD)
% Using absolute paths to avoid path issues
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
%% OPTION 1: Single file per technique (multiple distances in one file)
%% Use this if each _out.mat file contains results for all distances
%% ========================================

fprintf('=== Computing BER for %d Encoding Techniques ===\n\n', numTechniques);
fprintf('Using Passive Actor %d (distance: %d cm)\n\n', passiveActorToUse, distances_cm(passiveActorToUse));

BER = zeros(numTechniques, 1);

for tech = 1:numTechniques
    fprintf('--- Technique %d ---\n', tech);
    fprintf('Symbol Duration: %.1f s, Threshold: %d molecules, Bits: %d\n', ...
        symbolDuration_all(tech), threshold_all(tech), length(txBits_all{tech}));
    
    try
        % Compute BER using technique-specific parameters
        BER(tech) = computeBER(resultFiles{tech}, ...
            txBits_all{tech}, ...
            symbolDuration_all(tech), ...
            threshold_all(tech), ...
            passiveActorToUse, ...  % passive actor index
            1);  % molecule type index
    catch ME
        warning('Error processing %s: %s', resultFiles{tech}, ME.message);
        BER(tech) = NaN;
    end
    
    fprintf('\n');
end

%% ========================================
%% OPTION 2: Separate files per distance
%% Uncomment this section if you have separate files like:
%% et1_distance_5_out.mat, et1_distance_10_out.mat, etc.
%% ========================================

% BER_byDistance = zeros(numTechniques, length(distances_um));
% 
% for tech = 1:numTechniques
%     for d = 1:length(distances_um)
%         dist = distances_um(d);
%         
%         % Construct filename - adjust pattern as needed
%         resultFile = sprintf('../et%d_distance_%d_out', tech, dist);
%         
%         fprintf('Processing: %s\n', resultFile);
%         
%         try
%             BER_byDistance(tech, d) = computeBER(resultFile, txBits, symbolDuration, threshold);
%         catch ME
%             warning('Error: %s', ME.message);
%             BER_byDistance(tech, d) = NaN;
%         end
%     end
% end
% 
% %% Plot BER vs Distance
% figure('Color', 'w');
% hold on;
% colors = {'b', 'r', 'g', 'm', 'c'};
% markers = {'o', 's', 'd', '^', 'v'};
% 
% for tech = 1:numTechniques
%     semilogy(distances_um, BER_byDistance(tech,:), ...
%         ['-' markers{tech}], ...
%         'Color', colors{tech}, ...
%         'LineWidth', 1.5, ...
%         'MarkerSize', 8, ...
%         'MarkerFaceColor', colors{tech}, ...
%         'DisplayName', techniqueLabels{tech});
% end
% 
% xlabel('Distance (\mum)', 'FontSize', 12);
% ylabel('Bit Error Rate (BER)', 'FontSize', 12);
% title('BER vs Distance for Different Encoding Techniques', 'FontSize', 14);
% legend('show', 'Location', 'best');
% grid on;
% set(gca, 'YScale', 'log');  % Logarithmic Y-axis for BER
% hold off;

%% ========================================
%% PLOT: BER Comparison Bar Chart
%% ========================================

figure('Color', 'w');
bar(BER);
set(gca, 'XTickLabel', techniqueLabels);
xlabel('Encoding Technique', 'FontSize', 12);
ylabel('Bit Error Rate (BER)', 'FontSize', 12);
title('BER Comparison Across Encoding Techniques', 'FontSize', 14);
grid on;

% Add value labels on bars
for i = 1:length(BER)
    if ~isnan(BER(i))
        text(i, BER(i) + 0.01, sprintf('%.3f', BER(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10);
    end
end

%% ========================================
%% Display Summary Table
%% ========================================

fprintf('\n=== BER Summary ===\n');
fprintf('%-10s | %s\n', 'Technique', 'BER');
fprintf('------------------\n');
for tech = 1:numTechniques
    fprintf('%-10s | %.4f\n', techniqueLabels{tech}, BER(tech));
end

%% Save results
% save('BER_results.mat', 'BER', 'techniqueLabels', 'txBits', 'threshold', 'symbolDuration');
% fprintf('\nResults saved to BER_results.mat\n');
