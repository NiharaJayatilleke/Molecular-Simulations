function [hFig, allResults, rateData] = accordPlotDataRatevsSymbolDurationAllET(symbolDurations, bitsPerSymbol, codeRates)
% accordPlotDataRatevsSymbolDurationAllET - Plot data rate vs symbol duration for ET1-ET5
%
%   [hFig, allResults, rateData] = accordPlotDataRatevsSymbolDurationAllET()
%   [hFig, allResults, rateData] = accordPlotDataRatevsSymbolDurationAllET([100, 200, 300, 400, 500])
%   [hFig, allResults, rateData] = accordPlotDataRatevsSymbolDurationAllET([100, 200, 300, 400, 500], 1)
%   [hFig, allResults, rateData] = accordPlotDataRatevsSymbolDurationAllET([100, 200, 300, 400, 500], 1, [0.5 0.33 0.818 0.5 0.375])
%
% Decodes all symbol-duration runs for ET1-ET5 using
% accordDecodeETSymbolDuration, then calculates data rate for each
% symbol duration using:
%   rawRate = (codeRate * bitsPerSymbol * numReceivedSymbols) / timeUsed
% where timeUsed = numReceivedSymbols * symbolDuration.
%
% Plots data rate (y-axis) vs symbol duration (x-axis / transmission time)
% with one curve per encoding technique.
%
% INPUTS
%   symbolDurations - vector of symbol durations to include (default: all available)
%   bitsPerSymbol   - payload bits per symbol (default: 1)
%   codeRates       - coding rates for [ET1 ET2 ET3 ET4 ET5]
%                    (default: [0.5 0.33 0.818 0.5 0.375])
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x5}, each cell is struct array from
%                accordDecodeETSymbolDuration for that ET
%   rateData   - struct with fields per ET:
%                .symbolDuration, .numReceivedSymbols, .timeUsed, .rawRate

    if nargin < 1 || isempty(symbolDurations)
        symbolDurations = [];  % Use all available
    end
    if nargin < 2 || isempty(bitsPerSymbol)
        bitsPerSymbol = 1;
    end
    if nargin < 3 || isempty(codeRates)
        codeRates = [0.5 0.33 0.818 0.5 0.375];
    end

    if bitsPerSymbol <= 0
        error('bitsPerSymbol must be > 0');
    end
    if numel(codeRates) ~= 5 || any(codeRates <= 0)
        error('codeRates must be a 1x5 vector of positive values for [ET1 ET2 ET3 ET4 ET5].');
    end

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
    rateData   = struct();

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'Data Rate vs Symbol Duration - All Encoding Techniques', ...
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

        % Filter to requested symbol durations if specified
        if ~isempty(symbolDurations)
            symbolDurations = sort(symbolDurations);
            keep = false(1, length(res));
            for k = 1:length(res)
                if ~isempty(res(k).symbolDuration) && ...
                   any(abs(res(k).symbolDuration - symbolDurations) < 1e-6)
                    keep(k) = true;
                end
            end
            res = res(keep);
        end

        % Keep only entries with valid data
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).symbolDuration) && ...
                       ~isempty(res(k).num_bits) && ...
                       ~isempty(res(k).decoded_bits);
        end
        res = res(valid);

        if isempty(res)
            fprintf('No valid symbol duration points for %s after filtering, skipping.\n', upper(etLabels{i}));
            continue;
        end

        % Extract symbol durations and compute data rates
        symDurations       = zeros(1, length(res));
        numReceivedSymbols = zeros(1, length(res));
        timeUsed           = zeros(1, length(res));
        rawRate            = zeros(1, length(res));

        for k = 1:length(res)
            symDurations(k)       = res(k).symbolDuration;
            numReceivedSymbols(k) = numel(res(k).decoded_bits);
            timeUsed(k)           = numReceivedSymbols(k) * symDurations(k);

            if timeUsed(k) > 0
                rawRate(k) = (codeRates(i) * bitsPerSymbol * numReceivedSymbols(k)) / timeUsed(k);
            else
                rawRate(k) = NaN;
            end
        end

        % Sort by symbol duration
        [symDurations, si] = sort(symDurations);
        numReceivedSymbols = numReceivedSymbols(si);
        timeUsed           = timeUsed(si);
        rawRate            = rawRate(si);

        % Remove NaN rates
        validRate = ~isnan(rawRate);
        symDurations       = symDurations(validRate);
        numReceivedSymbols = numReceivedSymbols(validRate);
        timeUsed           = timeUsed(validRate);
        rawRate            = rawRate(validRate);

        if isempty(rawRate)
            fprintf('No valid rate points for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        % Smooth line plus original data-point markers for a cleaner look.
        if numel(symDurations) >= 3
            xFine = linspace(min(symDurations), max(symDurations), 200);
            yFine = interp1(symDurations, rawRate, xFine, 'pchip');
            h = plot(ax, xFine, yFine, '-', ...
                'Color', colours(i,:), 'LineWidth', 2.0);
        else
            h = plot(ax, symDurations, rawRate, '-', ...
                'Color', colours(i,:), 'LineWidth', 2.0);
        end

        plot(ax, symDurations, rawRate, ...
            'LineStyle', 'none', ...
            'Marker', markerStyles{i}, ...
            'Color', colours(i,:), ...
            'MarkerSize', 8, ...
            'LineWidth', 1.2, ...
            'MarkerFaceColor', 'w', ...
            'MarkerEdgeColor', colours(i,:), ...
            'HandleVisibility', 'off');

        plotHandles(i) = h(1);
        legendEntries{i} = legendLabels{i};

        rateData.(etLabels{i}).symbolDuration     = symDurations;
        rateData.(etLabels{i}).numReceivedSymbols = numReceivedSymbols;
        rateData.(etLabels{i}).timeUsed           = timeUsed;
        rateData.(etLabels{i}).rawRate            = rawRate;
        rateData.(etLabels{i}).codeRate           = codeRates(i);

        % Print summary
        fprintf('ET%d Data Rates:\n', i);
        for k = 1:length(symDurations)
            fprintf('  SD=%4d s: Rate=%8.4f bits/s (Time=%8.1f s, NumRxSymbols=%6d)\n', ...
                symDurations(k), rawRate(k), timeUsed(k), numReceivedSymbols(k));
        end
    end

    hold(ax, 'off');

    xlabel(ax, 'Symbol Duration (s)', 'FontSize', 12);
    ylabel(ax, 'Raw Data Rate (bits/s)', 'FontSize', 12);
    % title(ax, 'Raw Data Rate vs Symbol Duration / Transmission Time for All Encoding Techniques', ...
        % 'FontSize', 14, 'FontWeight', 'bold');

    validH = plotHandles ~= 0 & isvalid(plotHandles);
    if any(validH)
        lgd = legend(ax, plotHandles(validH), legendEntries(validH), ...
            'Location', 'best', 'FontSize', 11);
        set(lgd, 'Box', 'on', 'EdgeColor', 'k', 'Color', 'w', 'TextColor', 'k');
    end

    set(ax, 'XScale', 'log');
    set(ax, 'YScale', 'log');
    grid(ax, 'on');
    ax.XMinorGrid = 'on';
    ax.YMinorGrid = 'on';
    ax.GridAlpha = 0.2;
    ax.MinorGridAlpha = 0.12;
    set(ax, 'FontSize', 10, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

end
