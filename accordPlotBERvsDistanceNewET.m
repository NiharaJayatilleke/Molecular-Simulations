function [hFig, allResults] = accordPlotBERvsDistanceNewET()
% accordPlotBERvsDistanceNewET - Plot BER vs Distance for all encoding techniques
%
%   [hFig, allResults] = accordPlotBERvsDistanceNewET()
%
% Plots ET2, ET4, ET6, ET7, ET8 in full colour (primary curves) and
% ET1, ET3, ET5 in faded/desaturated versions of their colours (background curves).
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x8}, each cell is the struct array from accordDecodeET

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    etLabels = {'et1', 'et2', 'et3', 'et4', 'et5', 'et6', 'et7', 'et8'};
    legendLabels = {'ET1 - ISI-mtg',      'ET2 - RLIM', ...
                    'ET3 - Mod. Huffman', 'ET4 - (4,2,1)', ...
                    'ET5 - SEC',          'ET6 - ARLIM-v1', ...
                    'ET7 - ARLIM-v2',     'ET8 - ARLIM'};
    numET = length(etLabels);

    primaryETs    = {'et2', 'et4', 'et6', 'et7', 'et8'};
    backgroundETs = {'et1', 'et3', 'et5'};

    % --- full-saturation colours (one per ET, order matches etLabels) ---
    colours = [0.00 0.45 0.74;   % blue        – ET1
               0.85 0.33 0.10;   % orange      – ET2
               0.93 0.69 0.13;   % yellow-gold – ET3
               0.49 0.18 0.56;   % purple      – ET4
               0.47 0.67 0.19;   % green       – ET5
               0.30 0.75 0.93;   % cyan        – ET6
               0.64 0.08 0.18;   % dark red    – ET7
               0.10 0.60 0.10];  % dark green  – ET8
    markerStyles = {'o', 's', 'd', '^', 'v', '>', 'p', 'h'};

    fadeFactor = 0.45;

    % --- decode all ETs ---
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
    hFig = figure('Color', 'w', 'Name', 'BER vs Distance – All Encoding Techniques', ...
        'Units', 'pixels', 'Position', [80 80 900 550]);
    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    % Use explicit cell arrays instead of gobjects so every handle is tracked
    plotHandles   = cell(1, numET);
    legendEntries = cell(1, numET);

    % ---- Draw background (faded) ETs first ----
    for i = 1:numET
        if ~ismember(etLabels{i}, backgroundETs)
            continue;
        end

        res = allResults{i};
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).threshold);
        end
        res = res(valid);
        if isempty(res), continue; end

        distances = [res.distance];
        bers      = [res.BER];
        [distances, si] = sort(distances);
        bers = bers(si);

        if numel(distances) >= 3
            dFine = linspace(min(distances), max(distances), 200);
            bFine = interp1(distances, bers, dFine, 'pchip');
        else
            dFine = distances;
            bFine = bers;
        end

        fadedColour       = colours(i,:) + fadeFactor * (1 - colours(i,:));
        fadedMarkerColour = min(colours(i,:) + (fadeFactor + 0.10) * (1 - colours(i,:)), 1);

        h = plot(ax, dFine, bFine, '--', ...
            'Color', fadedColour, 'LineWidth', 1.4);
        plot(ax, distances, bers, ...
            'LineStyle', 'none', ...
            'Marker', markerStyles{i}, ...
            'Color', fadedColour, ...
            'MarkerSize', 6, ...
            'LineWidth', 0.8, ...
            'MarkerFaceColor', 'w', ...
            'MarkerEdgeColor', fadedMarkerColour, ...
            'HandleVisibility', 'off');
        plotHandles{i}   = h(1);
        legendEntries{i} = legendLabels{i};
    end

    % ---- Draw primary (full colour) ETs on top ----
    for i = 1:numET
        if ~ismember(etLabels{i}, primaryETs)
            continue;
        end

        res = allResults{i};
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).threshold);
        end
        res = res(valid);
        if isempty(res), continue; end

        distances = [res.distance];
        bers      = [res.BER];
        [distances, si] = sort(distances);
        bers = bers(si);

        if numel(distances) >= 3
            dFine = linspace(min(distances), max(distances), 200);
            bFine = interp1(distances, bers, dFine, 'pchip');
        else
            dFine = distances;
            bFine = bers;
        end

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
        plotHandles{i}   = h(1);
        legendEntries{i} = legendLabels{i};
    end

    hold(ax, 'off');

    xlabel(ax, 'Distance (cm)', 'FontSize', 12);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 12);
    % title(ax, 'BER vs Distance for All Encoding Techniques', ...
        % 'FontSize', 14, 'FontWeight', 'bold');

    % Collect only the slots that were actually filled
    filledIdx = find(~cellfun(@isempty, plotHandles));
    hArray    = [plotHandles{filledIdx}];
    lArray    = legendEntries(filledIdx);

    lgd = legend(ax, hArray, lArray, 'Location', 'northwest', 'FontSize', 11);
    set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);

    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    ylim(ax, [0 0.55]);
    set(ax, 'XTick', [5 10 20 30 50]);
end