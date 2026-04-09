function [hFig, hAxes, thresholds] = accordPlotThreshold(filename)
% accordPlotThreshold - Plot AcCoRD results with threshold lines
%   [hFig, hAxes, thresholds] = accordPlotThreshold('et1_distance_5_10_20')
%
% INPUTS
%   filename - name of the simulation file (without path)
%
% OUTPUTS
%   hFig       - handle to plotted figure
%   hAxes      - handle to axes in plotted figure
%   thresholds - threshold values for each passive actor

    % Get the root directory (where this script lives)
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    
    % Add required paths
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    
    % Change to AcCoRD root directory
    cd(accordRoot);
    
    fprintf('AcCoRD paths loaded.\n');
    
    % Plot using accordRunLog
    [hFig, hAxes] = accordRunLog(filename);
    
    % Get thresholds from accordDecode
    [thresholds, ~, ~] = accordDecode(filename);
    
    % Get x-axis limits for drawing horizontal lines
    xlims = xlim(hAxes);
    
    % Colors for threshold lines (matching the plot colors)
    colors = {'k', 'b', 'r', 'g', 'm', 'c'};
    
    % Draw threshold lines for each passive actor
    hold(hAxes, 'on');
    for i = 1:length(thresholds)
        threshold = thresholds(i);
        color = colors{mod(i-1, length(colors)) + 1};
        
        % Draw horizontal dashed line at threshold
        hLine = plot(hAxes, xlims, [threshold threshold], ...
            '--', 'Color', color, 'LineWidth', 1.5);
        
        % Add label
        text(hAxes, xlims(2), threshold, ...
            sprintf(' Threshold %d: %.0f', i, threshold), ...
            'Color', color, 'FontSize', 9, ...
            'VerticalAlignment', 'middle');
    end
    hold(hAxes, 'off');
    
    fprintf('\n=== Thresholds plotted ===\n');
    for i = 1:length(thresholds)
        fprintf('PassiveActor %d: %.2f\n', i, thresholds(i));
    end

end
