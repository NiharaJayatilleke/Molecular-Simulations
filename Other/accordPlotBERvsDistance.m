function hFig = accordPlotBERvsDistance(config_filename, result_filename, distances)
% accordPlotBERvsDistance - Plot BER vs Distance for molecular communication
%   hFig = accordPlotBERvsDistance('et1_distance_5_10_20', 'et1_distance_5_10_20', [5, 10, 20])
%
% INPUTS
%   config_filename - name of the config file (without path, without .txt)
%   result_filename - name of the result file (without path, without _SEED1.txt)
%   distances       - array of distances in cm for each passive actor
%
% OUTPUTS
%   hFig - handle to plotted figure

    % Get the root directory (where this script lives)
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    
    % Add required paths
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    
    % Change to AcCoRD root directory
    cd(accordRoot);
    
    fprintf('AcCoRD paths loaded.\n');
    
    % Get BER values from accordBER
    BERs = accordBER(config_filename, result_filename);
    
    % Create figure
    hFig = figure('Color', 'w');
    
    % Plot BER vs Distance
    semilogy(distances, BERs, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
        'MarkerFaceColor', 'b', 'Color', 'b');
    
    % Labels and formatting
    xlabel('Distance (cm)', 'FontSize', 12);
    ylabel('Bit Error Rate (BER)', 'FontSize', 12);
    title('BER vs Distance - ET1', 'FontSize', 14);
    grid on;
    
    % Set axis properties
    ax = gca;
    ax.Color = 'w';           % White plot area background
    ax.FontSize = 11;
    ax.XColor = 'k';          % Black X-axis
    ax.YColor = 'k';          % Black Y-axis
    ax.GridColor = [0.5 0.5 0.5];  % Gray grid lines
    
    % Add data point labels
    for i = 1:length(distances)
        text(distances(i), BERs(i) * 1.3, sprintf('%.4f', BERs(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10);
    end
    
    % Print results
    fprintf('\n=== BER vs Distance ===\n');
    for i = 1:length(distances)
        fprintf('Distance %d cm: BER = %.4f\n', distances(i), BERs(i));
    end

end
