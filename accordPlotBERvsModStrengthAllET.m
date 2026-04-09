function [hFig, allResults] = accordPlotBERvsModStrengthAllET()
% accordPlotBERvsModStrengthAllET - Plot BER vs Modulation Strength for ET1-ET5
%
%   [hFig, allResults] = accordPlotBERvsModStrengthAllET()
%
% Decodes all modulation-strength runs for ET1-ET5 using
% accordDecodeETModStrength, then plots BER (y-axis) vs modulation strength
% (x-axis, log-scale) with one curve per encoding technique.
%
% OUTPUTS
%   hFig       - figure handle
%   allResults - cell array {1x5}, each cell is the struct array from
%                accordDecodeETModStrength for that ET

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

    % --- figure ---
    hFig = figure('Color', 'w', 'Name', 'BER vs Modulation Strength - All Encoding Techniques', ...
        'Units', 'pixels', 'Position', [80 80 920 560]);
    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    plotHandles   = gobjects(1, numET);
    legendEntries = cell(1, numET);

    for i = 1:numET
        fprintf('\n########## %s ##########\n', upper(etLabels{i}));

        try
            res = accordDecodeETModStrength(etLabels{i});
        catch ME
            fprintf('Skipping %s: %s\n', upper(etLabels{i}), ME.message);
            allResults{i} = struct([]);
            continue;
        end

        allResults{i} = res;

        if isempty(res)
            fprintf('No decoded modulation data for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        % Keep only entries with valid BER and modulation strength
        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).modStrength);
        end
        res = res(valid);

        if isempty(res)
            fprintf('No valid BER points for %s, skipping.\n', upper(etLabels{i}));
            continue;
        end

        modVals = [res.modStrength];
        bers    = [res.BER];

        % Sort by modulation strength
        [modVals, si] = sort(modVals);
        bers = bers(si);

        % Plot raw points
        plot(ax, modVals, bers, 'o', ...
            'Color', colours(i,:), 'MarkerSize', 7, ...
            'MarkerFaceColor', colours(i,:), 'MarkerEdgeColor', 'w', ...
            'HandleVisibility', 'off');

        % Smooth curve if enough points
        if numel(modVals) >= 3
            xFine = logspace(log10(min(modVals)), log10(max(modVals)), 200);
            yFine = interp1(modVals, bers, xFine, 'pchip');
            h = plot(ax, xFine, yFine, '-', 'Color', colours(i,:), 'LineWidth', 1.8);
        else
            h = plot(ax, modVals, bers, '-', 'Color', colours(i,:), 'LineWidth', 1.8);
        end

        plotHandles(i) = h(1);
        legendEntries{i} = upper(etLabels{i});
    end

    hold(ax, 'off');

    set(ax, 'XScale', 'log');
    xlabel(ax, 'Modulation Strength (molecules)', 'FontSize', 12);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 12);
    title(ax, 'BER vs Modulation Strength for All Encoding Techniques', ...
        'FontSize', 14, 'FontWeight', 'bold');

    validH = isgraphics(plotHandles);
    if any(validH)
        validHandles = plotHandles(validH);
        validEntries = legendEntries(validH);

        % Guard against empty legend labels in older MATLAB versions.
        keep = ~cellfun(@isempty, validEntries);
        validHandles = validHandles(keep);
        validEntries = validEntries(keep);

        axes(ax);
        lgd = legend(validHandles, validEntries, ...
            'Location', 'northeast', 'FontSize', 11);
        set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    end

    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % Prefer standard modulation ticks if they exist in decoded data
    stdTicks = [1e2 1e3 1e4 1e5 1e6];
    allX = [];
    for i = 1:numET
        if ~isempty(allResults{i})
            x = [allResults{i}.modStrength];
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

    % BER bounds (dynamic so high-BER ETs are not clipped out)
    allBER = [];
    for i = 1:numET
        if ~isempty(allResults{i})
            b = [allResults{i}.BER];
            allBER = [allBER b(~isnan(b))]; %#ok<AGROW>
        end
    end
    if isempty(allBER)
        ylim(ax, [0 0.55]);
    else
        yMax = max(0.55, min(1.0, max(allBER) + 0.05));
        ylim(ax, [0 yMax]);
    end

    % --- console summary ---
    fprintf('\n\n========== BER vs MODULATION STRENGTH SUMMARY ==========' );
    fprintf('\n%-6s  %-12s  %-10s\n', 'ET', 'ModStrength', 'BER');
    fprintf('%s\n', repmat('-', 1, 36));
    for i = 1:numET
        res = allResults{i};
        if isempty(res)
            continue;
        end

        valid = false(1, length(res));
        for k = 1:length(res)
            valid(k) = ~isempty(res(k).BER) && ~isempty(res(k).modStrengthStr);
        end
        res = res(valid);
        if isempty(res)
            continue;
        end

        [~, si] = sort([res.modStrength]);
        res = res(si);
        for k = 1:length(res)
            fprintf('%-6s  %-12s  %-10.4f\n', upper(etLabels{i}), res(k).modStrengthStr, res(k).BER);
        end
    end
    fprintf('\n');
end
