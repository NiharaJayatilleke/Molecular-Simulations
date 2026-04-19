function [hFig, allResults] = accordPlotBERvsSymbolDurationAllET()
% accordPlotBERvsSymbolDurationAllET - Plot BER vs Symbol Duration for ET1-ET5
%
%   [hFig, allResults] = accordPlotBERvsSymbolDurationAllET()
%
% Decodes all symbol-duration runs for ET1-ET5 using
% accordDecodeETSymbolDuration, then plots BER (y-axis) vs symbol duration
% (x-axis) with one curve per encoding technique.
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x5}, each cell is the struct array from
%                accordDecodeETSymbolDuration for that ET

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    etLabels = {'et1', 'et2', 'et3', 'et4', 'et5'};
    legendLabels = {'ET1 - ISI-mtg', 'ET2 - RLIM', 'ET3 - Mod. Huffman', 'ET4 - (4,2,1)', 'ET5 - SEC'};
    numET    = length(etLabels);

    % --- colours ---
    colours = [0.00 0.45 0.74;   % blue
               0.85 0.33 0.10;   % orange
               0.93 0.69 0.13;   % yellow-gold
               0.49 0.18 0.56;   % purple
               0.47 0.67 0.19];  % green
    markerStyles = {'o', 's', 'd', '^', 'v'};

    allResults = cell(1, numET);

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'BER vs Symbol Duration - All Encoding Techniques', ...
        'Units', 'pixels', 'Position', [80 80 920 560]);
    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    plotHandles   = gobjects(1, numET);
    legendEntries = cell(1, numET);

    for i = 1:numET
        fprintf('\n########## %s ##########\n', upper(etLabels{i}));

        try
            res = accordDecodeETSymbolDuration(etLabels{i});
        catch ME
            fprintf('Skipping %s: %s\n', upper(etLabels{i}), ME.message);
            allResults{i} = struct([]);
            continue;
        end

        allResults{i} = res;

        if isempty(res)
            fprintf('No decoded symbol duration data for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        % Keep only entries with valid BER and symbol duration
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).symbolDuration);
        end
        res = res(valid);

        if isempty(res)
            fprintf('No valid BER points for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        durations = [res.symbolDuration];
        bers      = [res.BER];

        % Sort by symbol duration
        [durations, si] = sort(durations);
        bers = bers(si);

        % Smooth curve if enough points
        if numel(durations) >= 3
            xFine = linspace(min(durations), max(durations), 200);
            yFine = interp1(durations, bers, xFine, 'pchip');
            markerIdx = unique([1, 1:20:numel(xFine), numel(xFine)]);
            h = plot(ax, xFine, yFine, ...
                'LineStyle', '-', ...
                'Marker', markerStyles{i}, ...
                'MarkerIndices', markerIdx, ...
                'Color', colours(i,:), 'LineWidth', 1.4, ...
                'MarkerSize', 8, ...
                'MarkerFaceColor', 'w', 'MarkerEdgeColor', colours(i,:));
        else
            h = plot(ax, durations, bers, ...
                'LineStyle', '-', ...
                'Marker', markerStyles{i}, ...
                'Color', colours(i,:), 'LineWidth', 1.4, ...
                'MarkerSize', 8, ...
                'MarkerFaceColor', 'w', 'MarkerEdgeColor', colours(i,:));
        end

        plotHandles(i) = h(1);
        legendEntries{i} = legendLabels{i};
    end

    hold(ax, 'off');

    xlabel(ax, 'Symbol Duration (s)', 'FontSize', 12);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 12);
    % title(ax, 'BER vs Symbol Duration for All Encoding Techniques', ...
        % 'FontSize', 14, 'FontWeight', 'bold');

    validH = plotHandles ~= 0 & isvalid(plotHandles);
    if any(validH)
        lgd = legend(ax, plotHandles(validH), legendEntries(validH), ...
            'Location', 'best', 'FontSize', 11);
        set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    end

    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % Prefer standard symbol-duration ticks if they exist in decoded data
    stdTicks = [100 200 300 400 500];
    allX = [];
    for i = 1:numET
        if ~isempty(allResults{i})
            x = [allResults{i}.symbolDuration];
            allX = [allX x(~isnan(x))]; %#ok<AGROW>
        end
    end
    if ~isempty(allX)
        xMin = min(allX);
        xMax = max(allX);
        ticks = stdTicks(stdTicks >= xMin & stdTicks <= xMax);
        if ~isempty(ticks)
            set(ax, 'XTick', ticks);
        end
    end

    % BER bounds
    ylim(ax, [0 0.55]);

    % --- console summary ---
    fprintf('\n\n========== BER vs SYMBOL DURATION SUMMARY ==========' );
    fprintf('\n%-6s  %-14s  %-10s\n', 'ET', 'SymbolDur(s)', 'BER');
    fprintf('%s\n', repmat('-', 1, 38));
    for i = 1:numET
        res = allResults{i};
        if isempty(res)
            continue;
        end

        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).symbolDuration);
        end
        res = res(valid);
        if isempty(res)
            continue;
        end

        [~, si] = sort([res.symbolDuration]);
        res = res(si);
        for k = 1:length(res)
            fprintf('%-6s  %-14d  %-10.4f\n', upper(etLabels{i}), res(k).symbolDuration, res(k).BER);
        end
    end
    fprintf('\n');
end