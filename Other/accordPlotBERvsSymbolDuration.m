function [hFig, allResults] = accordPlotBERvsSymbolDuration()
% accordPlotBERvsSymbolDuration - Plot BER vs Symbol Duration for all ETs that have data
%
%   [hFig, allResults] = accordPlotBERvsSymbolDuration()
%
% Decodes all symbol-duration results for each ET using accordDecodeETSymbolDuration,
% then plots BER (y-axis) vs Symbol Duration (x-axis) with smooth curves.
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - struct with fields .et1, .et2, etc. (each is the decoded struct array)

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

    % --- try decoding each ET ---
    allResults  = struct();
    etWithData  = {};
    etColours   = [];
    decodedData = {};

    for i = 1:numET
        % Check if result files exist before attempting decode
        resultsDir = fullfile(accordRoot, 'bin', 'results');
        pattern = [etLabels{i} '_symbol_duration_*_SEED1.txt'];
        listing = dir(fullfile(resultsDir, pattern));

        % Filter out non-numeric names (e.g. "comparison")
        validFiles = false(length(listing), 1);
        for j = 1:length(listing)
            name = strrep(listing(j).name, '_SEED1.txt', '');
            name = strrep(name, [etLabels{i} '_symbol_duration_'], '');
            validFiles(j) = ~isnan(str2double(name));
        end
        listing = listing(validFiles);

        % Skip if no valid files or all empty
        hasData = false;
        for j = 1:length(listing)
            if listing(j).bytes > 0
                hasData = true;
                break;
            end
        end

        if ~hasData
            fprintf('No symbol duration data for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        fprintf('\n########## %s ##########\n', upper(etLabels{i}));
        res = accordDecodeETSymbolDuration(etLabels{i});

        % Filter out failed decodes
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).threshold);
        end
        res = res(valid);

        if ~isempty(res)
            allResults.(etLabels{i}) = res;
            etWithData{end+1}  = etLabels{i};    %#ok
            etColours(end+1,:) = colours(i,:);    %#ok
            decodedData{end+1} = res;             %#ok
        end
    end

    numPlot = length(etWithData);
    if numPlot == 0
        error('No symbol duration data found for any encoding technique.');
    end

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'BER vs Symbol Duration', ...
        'Units', 'pixels', 'Position', [80 80 900 550]);
    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    plotHandles   = gobjects(1, numPlot);
    legendEntries = cell(1, numPlot);

    for i = 1:numPlot
        res = decodedData{i};

        durations = [res.symbolDuration];
        bers      = [res.BER];

        % Sort by symbol duration
        [durations, si] = sort(durations);
        bers = bers(si);

        % Smooth curve via interpolation (only if >= 3 points)
        if length(durations) >= 3
            dFine = linspace(min(durations), max(durations), 200);
            bFine = interp1(durations, bers, dFine, 'pchip');
        else
            dFine = durations;
            bFine = bers;
        end

        % Plot smooth curve
        h = plot(ax, dFine, bFine, '-', ...
            'Color', etColours(i,:), 'LineWidth', 1.8);
        % Plot data points on top
        plot(ax, durations, bers, 'o', ...
            'Color', etColours(i,:), 'MarkerSize', 7, ...
            'MarkerFaceColor', etColours(i,:), 'MarkerEdgeColor', 'w', ...
            'HandleVisibility', 'off');

        plotHandles(i) = h(1);
        legendEntries{i} = upper(etWithData{i});
    end

    hold(ax, 'off');

    xlabel(ax, 'Symbol Duration (s)', 'FontSize', 12);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 12);
    title(ax, 'BER vs Symbol Duration for All Encoding Techniques', ...
        'FontSize', 14, 'FontWeight', 'bold');

    lgd = legend(ax, plotHandles, legendEntries, ...
        'Location', 'best', 'FontSize', 11);
    set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);

    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);
    ylim(ax, [0 0.55]);
end
