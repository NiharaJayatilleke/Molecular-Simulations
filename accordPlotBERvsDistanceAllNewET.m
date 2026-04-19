function [hFig, allResults] = accordPlotBERvsDistanceAllNewET()
% accordPlotBERvsDistanceAllET - Plot BER vs Distance for selected encoding techniques
%
%   [hFig, allResults] = accordPlotBERvsDistanceAllNewET()
%
% Decodes single-distance results for ET1–ET5 and ET8 using accordDecodeET,
% then plots BER (y-axis) vs Distance (x-axis) with one curve per technique.
%
% Legend labels:
%   ET1 -> ISI-mtg
%   ET2 -> RLIM
%   ET3 -> Mod. Huffman
%   ET4 -> (4,2,1)
%   ET5 -> SEC
%   ET8 -> ARLIM
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x6}, each cell is the struct array from accordDecodeET

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    etLabels     = {'et1',       'et2',   'et3',           'et4',     'et5',  'et8'  };
    legendLabels = {'ET1 - ISI-mtg',   'ET2 - RLIM',  'ET3 - Mod. Huffman',  'ET4 - (4,2,1)', 'ET5 - SEC', 'ARLIM'};
    numET        = length(etLabels);

    % --- colours (one per ET, in etLabels order) ---
    colours = [0.00 0.45 0.74;   % blue        – ET1 / ISI-mtg
               0.85 0.33 0.10;   % orange      – ET2 / RLIM
               0.93 0.69 0.13;   % yellow-gold – ET3 / Mod. Huffman
               0.49 0.18 0.56;   % purple      – ET4 / (4,2,1)
               0.47 0.67 0.19;   % green       – ET5 / SEC
               0.10 0.60 0.10];  % dark green  – ET8 / ARLIM
    markerStyles = {'o', 's', 'd', '^', 'v', 'h'};

    % --- decode selected ETs ---
    allResults = cell(1, numET);
    for i = 1:numET
        fprintf('\n########## %s ##########\n', upper(etLabels{i}));
        try
            allResults{i} = accordDecodeET(etLabels{i});
        catch ME
            fprintf('Skipping %s: %s\n', upper(etLabels{i}), ME.message);
            allResults{i} = struct([]);
        end
    end

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'BER vs Distance – Selected Encoding Techniques', ...
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

        if numel(distances) >= 3
            dFine = linspace(min(distances), max(distances), 200);
            bFine = interp1(distances, bers, dFine, 'pchip');
        else
            dFine = distances;
            bFine = bers;
        end

        % Smooth curve with separate markers for a cleaner publication look.
        h = plot(ax, dFine, bFine, '-', ...
            'Color', colours(i,:), 'LineWidth', 2.0);
        plot(ax, distances, bers, ...
            'LineStyle', 'none', ...
            'Marker', markerStyles{i}, ...
            'Color', colours(i,:), ...
            'MarkerSize', 8, ...
            'LineWidth', 1.2, ...
            'MarkerFaceColor', 'w', ...
            'MarkerEdgeColor', colours(i,:), ...
            'HandleVisibility', 'off');
        plotHandles(i)   = h(1);
        legendEntries{i} = legendLabels{i};
    end

    hold(ax, 'off');

    xlabel(ax, 'Distance (cm)', 'FontSize', 12);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 12);
    % title(ax, 'BER vs Distance for All Encoding Techniques', ...
        % 'FontSize', 14, 'FontWeight', 'bold');

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