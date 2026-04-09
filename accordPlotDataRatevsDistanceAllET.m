function [hFig, allResults, rateData] = accordPlotDataRatevsDistanceAllET(symbolDuration, bitsPerSymbol, codeRates)
% accordPlotDataRatevsDistanceAllET - Plot data rate vs distance for ET1-ET5
%
%   [hFig, allResults, rateData] = accordPlotDataRatevsDistanceAllET()
%   [hFig, allResults, rateData] = accordPlotDataRatevsDistanceAllET(300, 1)
%   [hFig, allResults, rateData] = accordPlotDataRatevsDistanceAllET(300, 1, [0.5 0.33 0.818 0.5 0.375])
%
% Uses accordDecodeET to decode each ET distance run, then computes raw
% throughput directly from the number of received symbols and total time:
%   rawRate = (codeRate * bitsPerSymbol * numReceivedSymbols) / timeUsed
% where timeUsed = numReceivedSymbols * symbolDuration.
%
% BER is not used in this rate calculation.
%
% INPUTS
%   symbolDuration - symbol duration in seconds (default: 300)
%   bitsPerSymbol  - payload bits per symbol (default: 1)
%   codeRates      - coding rates for [ET1 ET2 ET3 ET4 ET5]
%                    (default: [0.5 0.33 0.818 0.5 0.375])
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x5}, each cell is struct array from accordDecodeET
%   rateData   - struct with fields per ET:
%                .distance, .numReceivedSymbols, .timeUsed, .rawRate

    if nargin < 1 || isempty(symbolDuration)
        symbolDuration = 300;
    end
    if nargin < 2 || isempty(bitsPerSymbol)
        bitsPerSymbol = 1;
    end
    if nargin < 3 || isempty(codeRates)
        codeRates = [0.5 0.33 0.818 0.5 0.375];
    end

    if symbolDuration <= 0
        error('symbolDuration must be > 0');
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
    numET    = length(etLabels);

    % --- colours ---
    colours = [0.00 0.45 0.74;   % blue
               0.85 0.33 0.10;   % orange
               0.93 0.69 0.13;   % yellow-gold
               0.49 0.18 0.56;   % purple
               0.47 0.67 0.19];  % green

    allResults = cell(1, numET);
    rateData   = struct();

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'Data Rate vs Distance - All Encoding Techniques', ...
        'Units', 'pixels', 'Position', [80 80 920 560]);
    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    plotHandles   = gobjects(1, numET);
    legendEntries = cell(1, numET);

    for i = 1:numET
        fprintf('\n########## %s ##########\n', upper(etLabels{i}));

        try
            res = accordDecodeET(etLabels{i});
        catch ME
            fprintf('Skipping %s: %s\n', upper(etLabels{i}), ME.message);
            allResults{i} = struct([]);
            continue;
        end

        allResults{i} = res;

        if isempty(res)
            fprintf('No decoded distance data for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).distance);
        end
        res = res(valid);

        if isempty(res)
            fprintf('No valid BER points for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        distances = [res.distance];
        numReceivedSymbols = zeros(1, numel(res));
        timeUsed = zeros(1, numel(res));
        rawRate = zeros(1, numel(res));

        for k = 1:numel(res)
            numReceivedSymbols(k) = numel(res(k).decoded_bits);
            timeUsed(k) = numReceivedSymbols(k) * symbolDuration;

            if timeUsed(k) > 0
                rawRate(k) = (codeRates(i) * bitsPerSymbol * numReceivedSymbols(k)) / timeUsed(k);
            else
                rawRate(k) = NaN;
            end
        end

        [distances, si] = sort(distances);
        numReceivedSymbols = numReceivedSymbols(si);
        timeUsed = timeUsed(si);
        rawRate = rawRate(si);

        validRate = ~isnan(rawRate);
        distances = distances(validRate);
        numReceivedSymbols = numReceivedSymbols(validRate);
        timeUsed = timeUsed(validRate);
        rawRate = rawRate(validRate);

        if isempty(rawRate)
            fprintf('No valid rate points for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        % Optional smoothing for nicer trend lines
        if numel(distances) >= 3
            dFine = linspace(min(distances), max(distances), 200);
            rFine = interp1(distances, rawRate, dFine, 'pchip');
            h = plot(ax, dFine, rFine, '-', 'Color', colours(i,:), 'LineWidth', 1.8);
        else
            h = plot(ax, distances, rawRate, '-', 'Color', colours(i,:), 'LineWidth', 1.8);
        end

        plot(ax, distances, rawRate, 'o', ...
            'Color', colours(i,:), 'MarkerSize', 7, ...
            'MarkerFaceColor', colours(i,:), 'MarkerEdgeColor', 'w', ...
            'HandleVisibility', 'off');

        plotHandles(i) = h(1);
        legendEntries{i} = upper(etLabels{i});

        rateData.(etLabels{i}).distance           = distances;
        rateData.(etLabels{i}).numReceivedSymbols = numReceivedSymbols;
        rateData.(etLabels{i}).timeUsed           = timeUsed;
        rateData.(etLabels{i}).rawRate            = rawRate;
        rateData.(etLabels{i}).codeRate           = codeRates(i);
    end

    hold(ax, 'off');

    xlabel(ax, 'Distance (cm)', 'FontSize', 12);
    ylabel(ax, 'Raw Data Rate (bits/s)', 'FontSize', 12);
    title(ax, 'Raw Data Rate vs Distance for All Encoding Techniques', ...
        'FontSize', 14, 'FontWeight', 'bold');

    validH = plotHandles ~= 0 & isvalid(plotHandles);
    if any(validH)
        lgd = legend(ax, plotHandles(validH), legendEntries(validH), ...
            'Location', 'southwest', 'FontSize', 11);
        set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    end

    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % Prefer standard distance ticks used in these experiments
    set(ax, 'XTick', [5 10 20 30 50]);

    % --- console summary ---
    fprintf('\n\n========== RAW DATA RATE vs DISTANCE SUMMARY ==========\n');
    fprintf('Assumed symbol duration: %.3f s, bits/symbol: %.3f\n', symbolDuration, bitsPerSymbol);
    fprintf('Code rates [ET1..ET5]: [%.4f %.4f %.4f %.4f %.4f]\n\n', codeRates);
    fprintf('%-6s  %-10s  %-10s  %-12s  %-14s\n', 'ET', 'Distance', 'RxSymbols', 'Time (s)', 'Raw Rate (b/s)');
    fprintf('%s\n', repmat('-', 1, 64));

    for i = 1:numET
        if ~isfield(rateData, etLabels{i})
            continue;
        end
        d = rateData.(etLabels{i}).distance;
        n = rateData.(etLabels{i}).numReceivedSymbols;
        t = rateData.(etLabels{i}).timeUsed;
        r = rateData.(etLabels{i}).rawRate;
        for k = 1:numel(d)
            fprintf('%-6s  %-10.0f  %-10d  %-12.2f  %-14.6f\n', upper(etLabels{i}), d(k), n(k), t(k), r(k));
        end
    end
    fprintf('\n');
end
