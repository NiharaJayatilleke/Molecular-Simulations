function [hFig, results] = accordPlotETModStrengths(etLabel)
% accordPlotETModStrengths - Plot received wave signals for all modulation strengths
%
%   [hFig, results] = accordPlotETModStrengths('et1')
%
% Plots continuous wave curves (one per modulation strength) showing the full
% molecule count time-series on a single graph with log-scale Y-axis and
% threshold dotted lines.
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2'
%
% OUTPUTS
%   hFig    - figure handle
%   results - struct array from accordDecodeETModStrength

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    dt = 2;   % global microscopic time step (seconds)

    % --- find & decode all modulation strengths ---
    results = accordDecodeETModStrength(etLabel);

    % --- remove entries that failed to decode (empty rx_counts) ---
    valid = false(1, length(results));
    for k = 1:length(results)
        valid(k) = ~isempty(results(k).rx_counts) && ~isempty(results(k).threshold);
    end
    if any(~valid)
        skipped = {results(~valid).modStrengthStr};
        fprintf('Skipping modulation strengths with no data: %s\n', strjoin(skipped, ', '));
    end
    results = results(valid);
    numMod  = length(results);

    if numMod == 0
        error('No valid modulation strength data found for %s', etLabel);
    end

    % --- colours ---
    colours = [0.00 0.45 0.74;   % blue
               0.85 0.33 0.10;   % orange
               0.93 0.69 0.13;   % yellow-gold
               0.49 0.18 0.56;   % purple
               0.47 0.67 0.19;   % green
               0.30 0.75 0.93];  % cyan
    if numMod > size(colours,1)
        colours = lines(numMod);
    end

    % --- figure ---
    hFig = figure('Color','w', 'Name', ...
        sprintf('%s – Modulation Strength Comparison', upper(etLabel)), ...
        'Units','pixels', 'Position',[80 60 1100 500]);

    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    legendEntries = cell(1, numMod * 2);
    plotHandles   = gobjects(1, numMod);

    % --- find global time span (for threshold lines) ---
    tMax = 0;
    for k = 1:numMod
        tMax = max(tMax, (length(results(k).rx_counts)-1) * dt);
    end

    % --- plot wave curves ---
    smoothWindow = 25;  % moving average window to reduce noise
    for k = 1:numMod
        rx = results(k).rx_counts(:);
        t  = ((0:length(rx)-1) * dt)';

        % --- smoothing ---
        rx = movmean(rx, smoothWindow);

        h = plot(ax, t, rx, '-', 'Color', colours(k,:), 'LineWidth', 1.2);
        plotHandles(k) = h(1);
        legendEntries{k} = sprintf('%s (d=%d cm)', results(k).modStrengthStr, results(k).distance);
    end

    % --- plot threshold dotted lines ---
    thrHandles = gobjects(1, numMod);
    for k = 1:numMod
        thr = results(k).threshold;
        thrHandles(k) = plot(ax, [0 tMax], [thr thr], ':', ...
            'Color', colours(k,:), 'LineWidth', 1.5);
        legendEntries{numMod + k} = sprintf('%s Thr=%.1f', results(k).modStrengthStr, thr);
    end

    hold(ax, 'off');

    % --- log scale ---
    set(ax, 'YScale', 'log');

    xlabel(ax, 'Time (s)',      'FontSize', 11);
    ylabel(ax, 'Molecule Count (log scale)', 'FontSize', 11);
    title(ax, sprintf('%s – Received Signal for Different Modulation Strengths (Log Scale)', upper(etLabel)), ...
          'FontSize', 13, 'FontWeight', 'bold');
    lgd = legend(ax, [plotHandles thrHandles], legendEntries, ...
        'Location', 'northeast', 'FontSize', 9, 'NumColumns', 2);
    set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    grid(ax, 'on');
    set(ax, 'FontSize', 10, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);
end
