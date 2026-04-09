function [hFig, results] = accordPlotETSymbolDurations(etLabel)
% accordPlotETSymbolDurations - Plot normalized received signals for all symbol durations
%
%   [hFig, results] = accordPlotETSymbolDurations('et1')
%
% Plots continuous wave curves (one per symbol duration) normalized to 0–1
% scale (N(t)/Npeak) so that shape and ISI can be compared without magnitude
% differences causing overlap. Includes normalized threshold lines.
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2'
%
% OUTPUTS
%   hFig    - figure handle
%   results - struct array from accordDecodeETSymbolDuration

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    dt = 2;   % global microscopic time step (seconds)

    % --- find & decode all symbol durations ---
    results = accordDecodeETSymbolDuration(etLabel);

    % --- remove entries that failed to decode (empty rx_counts) ---
    valid = false(1, length(results));
    for k = 1:length(results)
        valid(k) = ~isempty(results(k).rx_counts) && ~isempty(results(k).threshold);
    end
    if any(~valid)
        skipped = [results(~valid).symbolDuration];
        fprintf('Skipping symbol durations with no data: %s s\n', num2str(skipped));
    end
    results = results(valid);
    numSD   = length(results);

    if numSD == 0
        error('No valid symbol duration data found for %s', etLabel);
    end

    % --- colours ---
    colours = [0.00 0.45 0.74;   % blue
               0.85 0.33 0.10;   % orange
               0.93 0.69 0.13;   % yellow-gold
               0.49 0.18 0.56;   % purple
               0.47 0.67 0.19;   % green
               0.30 0.75 0.93];  % cyan
    if numSD > size(colours,1)
        colours = lines(numSD);
    end

    % --- figure ---
    hFig = figure('Color','w', 'Name', ...
        sprintf('%s – Symbol Duration Comparison (Normalized)', upper(etLabel)), ...
        'Units','pixels', 'Position',[80 60 1100 500]);

    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');

    legendEntries = cell(1, numSD * 2);
    plotHandles   = gobjects(1, numSD);

    % --- find global time span (for threshold lines) ---
    tMax = 0;
    for k = 1:numSD
        tMax = max(tMax, (length(results(k).rx_counts)-1) * dt);
    end

    % --- plot wave curves (normalized to 0–1) ---
    smoothWindow = 25;  % moving average window to reduce noise
    for k = 1:numSD
        rx = results(k).rx_counts(:);
        t  = ((0:length(rx)-1) * dt)';

        % --- smoothing ---
        rx = movmean(rx, smoothWindow);

        % --- normalize: N(t) / Npeak → [0, 1] ---
        Npeak = max(rx);
        if Npeak > 0
            rx = rx / Npeak;
        end

        h = plot(ax, t, rx, '-', 'Color', colours(k,:), 'LineWidth', 1.2);
        plotHandles(k) = h(1);
        legendEntries{k} = sprintf('%d s (BER=%.3f)', results(k).symbolDuration, results(k).BER);
    end

    % --- plot normalized threshold dotted lines ---
    thrHandles = gobjects(1, numSD);
    for k = 1:numSD
        thr  = results(k).threshold;
        Npeak = max(results(k).rx_counts);
        if Npeak > 0
            thrNorm = thr / Npeak;
        else
            thrNorm = 0;
        end
        thrHandles(k) = plot(ax, [0 tMax], [thrNorm thrNorm], ':', ...
            'Color', colours(k,:), 'LineWidth', 1.5);
        legendEntries{numSD + k} = sprintf('%d s Thr=%.2f', results(k).symbolDuration, thrNorm);
    end

    hold(ax, 'off');

    xlabel(ax, 'Time (s)',           'FontSize', 11);
    ylabel(ax, 'Normalized Signal (N/N_{peak})', 'FontSize', 11);
    title(ax, sprintf('%s – Normalized Received Signal for Different Symbol Durations', upper(etLabel)), ...
          'FontSize', 13, 'FontWeight', 'bold');
    lgd = legend(ax, [plotHandles thrHandles], legendEntries, ...
        'Location', 'northeast', 'FontSize', 9, 'NumColumns', 2);
    set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    grid(ax, 'on');
    ylim(ax, [0 1.05]);
    set(ax, 'FontSize', 10, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);
end
