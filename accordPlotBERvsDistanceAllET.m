function [hFig, allResults] = accordPlotBERvsDistanceAllET()
% accordPlotBERvsDistanceAllET - Plot BER vs Distance for all 5 encoding techniques
%
%   [hFig, allResults] = accordPlotBERvsDistanceAllET()
%
% Decodes all single-distance results for ET1–ET5 using accordDecodeET,
% then plots BER (y-axis) vs Distance (x-axis) with 5 continuous curves.
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x5}, each cell is the struct array from accordDecodeET

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    etLabels = {'et1', 'et2', 'et3', 'et4', 'et5'};
    numET    = length(etLabels);

    % --- colours ---
    colours = [0.00 0.45 0.74;   % blue
               0.85 0.33 0.10;   % orange
               0.93 0.69 0.13;   % yellow-gold
               0.49 0.18 0.56;   % purple
               0.47 0.67 0.19];  % green

    % --- decode all ETs ---
    allResults = cell(1, numET);
    for i = 1:numET
        fprintf('\n########## %s ##########\n', upper(etLabels{i}));
        allResults{i} = accordDecodeET(etLabels{i});
    end

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'BER vs Distance – All Encoding Techniques', ...
        'Units', 'pixels', 'Position', [80 80 900 550]);
    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    plotHandles   = gobjects(1, numET);
    legendEntries = cell(1, numET);

    for i = 1:numET
        res = allResults{i};

        % Filter out entries with empty BER (failed decodes)
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).threshold);
        end
        res = res(valid);

        if isempty(res)
            fprintf('No valid data for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        distances = [res.distance];
        bers      = [res.BER];

        % Sort by distance
        [distances, si] = sort(distances);
        bers = bers(si);

        % Interpolate for smooth curve
        dFine = linspace(min(distances), max(distances), 200);
        bFine = interp1(distances, bers, dFine, 'pchip');

        % Plot smooth curve
        h = plot(ax, dFine, bFine, '-', ...
            'Color', colours(i,:), 'LineWidth', 1.8);
        % Plot data points on top
        plot(ax, distances, bers, 'o', ...
            'Color', colours(i,:), 'MarkerSize', 7, ...
            'MarkerFaceColor', colours(i,:), 'MarkerEdgeColor', 'w', ...
            'HandleVisibility', 'off');
        plotHandles(i) = h(1);
        legendEntries{i} = upper(etLabels{i});
    end

    hold(ax, 'off');

    xlabel(ax, 'Distance (cm)', 'FontSize', 12);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 12);
    title(ax, 'BER vs Distance for All Encoding Techniques', ...
        'FontSize', 14, 'FontWeight', 'bold');

    % Only include valid handles in legend
    validH = plotHandles ~= 0 & isvalid(plotHandles);
    lgd = legend(ax, plotHandles(validH), legendEntries(validH), ...
        'Location', 'northwest', 'FontSize', 11);
    set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);

    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % Y limits
    ylim(ax, [0 0.55]);

    % Nice x ticks at the distances
    set(ax, 'XTick', [5 10 20 30 50]);
end
