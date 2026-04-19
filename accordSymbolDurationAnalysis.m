function [figs, results] = accordSymbolDurationAnalysis(etLabel)
% accordSymbolDurationAnalysis - Publication-quality symbol duration comparison
%
%   [figs, results] = accordSymbolDurationAnalysis('et1')
%
% Generates 4 thesis-ready figures:
%   Figure 1 – Small Multiples: separate subplot per symbol duration (same axes)
%   Figure 2 – Single Symbol Window: overlay of first symbol period only
%   Figure 3 – Performance: BER vs Symbol Duration (smooth curve)
%   Figure 4 – Threshold: Optimal Threshold vs Symbol Duration
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2'
%
% OUTPUTS
%   figs    - struct with handles: .smallMultiples, .singleSymbol,
%             .berPlot, .thresholdPlot
%   results - struct array from accordDecodeETSymbolDuration

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    dt = 2;   % global microscopic time step (seconds)

    % --- decode ---
    results = accordDecodeETSymbolDuration(etLabel);

    % --- remove failed decodes ---
    valid = false(1, length(results));
    for k = 1:length(results)
        valid(k) = ~isempty(results(k).rx_counts) && ~isempty(results(k).threshold);
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

    smoothWindow = 15;

    % --- common axis limits across all subplots ---
    tMaxAll  = 0;
    yMaxAll  = 0;
    for k = 1:numSD
        rx = movmean(results(k).rx_counts(:), smoothWindow);
        tMaxAll = max(tMaxAll, (length(rx)-1) * dt);
        yMaxAll = max(yMaxAll, max(rx));
    end

    % =====================================================================
    %  FIGURE 1 – SMALL MULTIPLES
    % =====================================================================
    figs.smallMultiples = figure('Color','w', 'Name', ...
        sprintf('%s – Small Multiples (Symbol Durations)', upper(etLabel)), ...
        'Units','pixels', 'Position',[60 40 1000 numSD*180+60]);

    axHandles = gobjects(numSD, 1);

    for k = 1:numSD
        axHandles(k) = subplot(numSD, 1, k);
        hold(axHandles(k), 'on');
        set(axHandles(k), 'Color', 'w');

        rx = results(k).rx_counts(:);
        t  = ((0:length(rx)-1) * dt)';
        rx = movmean(rx, smoothWindow);

        % Signal
        plot(axHandles(k), t, rx, '-', 'Color', colours(k,:), 'LineWidth', 1.2);

        % Threshold
        thr = results(k).threshold;
        plot(axHandles(k), [0 tMaxAll], [thr thr], ':', ...
            'Color', [0.4 0.4 0.4], 'LineWidth', 1.3);

        hold(axHandles(k), 'off');

        % Same limits for all
        set(axHandles(k), 'YScale', 'log');
        xlim(axHandles(k), [0 tMaxAll]);
        ylim(axHandles(k), [0.5 yMaxAll * 1.3]);
        grid(axHandles(k), 'on');
        set(axHandles(k), 'FontSize', 9, 'Box', 'on', ...
            'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

        % Label on right side
        ylabel(axHandles(k), sprintf('%d s', results(k).symbolDuration), ...
            'FontSize', 11, 'FontWeight', 'bold', 'Color', colours(k,:));

        % Only show x-label on bottom subplot
        if k < numSD
            set(axHandles(k), 'XTickLabel', []);
        else
            xlabel(axHandles(k), 'Time (s)', 'FontSize', 11);
        end

        % Annotation: BER and threshold
        text(axHandles(k), tMaxAll * 0.98, yMaxAll * 0.8, ...
            sprintf('Thr=%.0f  BER=%.3f', thr, results(k).BER), ...
            'FontSize', 8, 'HorizontalAlignment', 'right', ...
            'Color', [0.3 0.3 0.3], 'BackgroundColor', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    end

    % Link axes for synchronized zoom/pan
    linkaxes(axHandles, 'x');

    % Super-title
    sgtitle(sprintf('%s – Received Signal per Symbol Duration (Log Scale)', upper(etLabel)), ...
        'FontSize', 14, 'FontWeight', 'bold');

    % =====================================================================
    %  FIGURE 2 – SINGLE SYMBOL WINDOW (First '1' symbol of each)
    % =====================================================================
    figs.singleSymbol = figure('Color','w', 'Name', ...
        sprintf('%s – Single Symbol Window Overlay', upper(etLabel)), ...
        'Units','pixels', 'Position',[100 100 900 500]);

    ax2 = axes('Parent', figs.singleSymbol); hold(ax2, 'on');
    set(ax2, 'Color', 'w');

    plotH2 = gobjects(1, numSD);
    leg2   = cell(1, numSD);

    for k = 1:numSD
        rx = results(k).rx_counts(:);
        sd = results(k).symbolDuration;
        samplesPerSymbol = sd / dt;
        tx = results(k).tx_bits;

        % Find first '1' symbol
        firstOne = find(tx == 1, 1);
        if isempty(firstOne)
            firstOne = 1;
        end

        si = (firstOne - 1) * samplesPerSymbol + 1;
        ei = min(firstOne * samplesPerSymbol, length(rx));

        if ei > length(rx), continue; end

        rxSym = rx(si:ei);
        rxSym = movmean(rxSym, smoothWindow);

        % Normalize to 0–1
        Npeak = max(rxSym);
        if Npeak > 0
            rxSym = rxSym / Npeak;
        end

        % Normalize time to 0–1 (fraction of symbol period)
        tNorm = linspace(0, 1, length(rxSym));

        h = plot(ax2, tNorm, rxSym, '-', 'Color', colours(k,:), 'LineWidth', 1.6);
        plotH2(k) = h(1);
        leg2{k} = sprintf('%d s', sd);
    end

    % Normalized threshold = 0.5 reference (midpoint of 0–1 for visual ref)
    plot(ax2, [0 1], [0.5 0.5], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, ...
        'HandleVisibility', 'off');
    text(ax2, 1.02, 0.5, '0.5', 'FontSize', 8, 'Color', [0.5 0.5 0.5]);

    hold(ax2, 'off');

    xlabel(ax2, 'Normalized Time (fraction of symbol period)', 'FontSize', 11);
    ylabel(ax2, 'Normalized Signal (N / N_{peak})', 'FontSize', 11);
    title(ax2, sprintf('%s – First "1" Symbol Window (Normalized)', upper(etLabel)), ...
        'FontSize', 13, 'FontWeight', 'bold');
    lgd2 = legend(ax2, plotH2(isvalid(plotH2)), leg2(isvalid(plotH2)), ...
        'Location', 'northeast', 'FontSize', 10);
    set(lgd2, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    grid(ax2, 'on');
    ylim(ax2, [0 1.05]);
    xlim(ax2, [0 1]);
    set(ax2, 'FontSize', 10, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % =====================================================================
    %  FIGURE 3 – BER vs SYMBOL DURATION
    % =====================================================================
    durations = [results.symbolDuration];
    bers      = [results.BER];
    [durations, si] = sort(durations);
    bers = bers(si);

    figs.berPlot = figure('Color','w', 'Name', ...
        sprintf('%s – BER vs Symbol Duration', upper(etLabel)), ...
        'Units','pixels', 'Position',[140 140 750 450]);
    ax3 = axes('Parent', figs.berPlot); hold(ax3, 'on');
    set(ax3, 'Color', 'w');

    % Smooth curve
    if length(durations) >= 3
        dFine = linspace(min(durations), max(durations), 200);
        bFine = interp1(durations, bers, dFine, 'pchip');
    else
        dFine = durations;
        bFine = bers;
    end

    fill(ax3, [dFine fliplr(dFine)], [bFine zeros(size(bFine))], ...
        [0.00 0.45 0.74], 'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(ax3, dFine, bFine, '-', 'Color', [0.00 0.45 0.74], 'LineWidth', 2);
    plot(ax3, durations, bers, 'o', 'Color', [0.00 0.45 0.74], ...
        'MarkerSize', 8, 'MarkerFaceColor', [0.00 0.45 0.74], ...
        'MarkerEdgeColor', 'w', 'LineWidth', 1.2, 'HandleVisibility', 'off');

    % Label each point
    for k = 1:length(durations)
        text(ax3, durations(k), bers(k) + 0.015, sprintf('%.3f', bers(k)), ...
            'FontSize', 9, 'HorizontalAlignment', 'center', ...
            'Color', [0.2 0.2 0.2]);
    end

    hold(ax3, 'off');
    xlabel(ax3, 'Symbol Duration (s)', 'FontSize', 12);
    ylabel(ax3, 'Bit Error Rate (BER)', 'FontSize', 12);
    title(ax3, sprintf('%s – BER vs Symbol Duration', upper(etLabel)), ...
        'FontSize', 14, 'FontWeight', 'bold');
    grid(ax3, 'on');
    ylim(ax3, [0 max(bers)*1.3 + 0.02]);
    set(ax3, 'XTick', durations);
    set(ax3, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % =====================================================================
    %  FIGURE 4 – OPTIMAL THRESHOLD vs SYMBOL DURATION
    % =====================================================================
    thresholds = [results.threshold];
    thresholds = thresholds(si);

    figs.thresholdPlot = figure('Color','w', 'Name', ...
        sprintf('%s – Threshold vs Symbol Duration', upper(etLabel)), ...
        'Units','pixels', 'Position',[180 180 750 450]);
    ax4 = axes('Parent', figs.thresholdPlot); hold(ax4, 'on');
    set(ax4, 'Color', 'w');

    % Smooth curve
    if length(durations) >= 3
        tFine = interp1(durations, thresholds, dFine, 'pchip');
    else
        tFine = thresholds;
    end

    fill(ax4, [dFine fliplr(dFine)], [tFine zeros(size(tFine))], ...
        [0.85 0.33 0.10], 'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(ax4, dFine, tFine, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 2);
    plot(ax4, durations, thresholds, 's', 'Color', [0.85 0.33 0.10], ...
        'MarkerSize', 9, 'MarkerFaceColor', [0.85 0.33 0.10], ...
        'MarkerEdgeColor', 'w', 'LineWidth', 1.2, 'HandleVisibility', 'off');

    % Label each point
    for k = 1:length(durations)
        text(ax4, durations(k), thresholds(k) * 1.08, sprintf('%.0f', thresholds(k)), ...
            'FontSize', 9, 'HorizontalAlignment', 'center', ...
            'Color', [0.2 0.2 0.2]);
    end

    hold(ax4, 'off');
    xlabel(ax4, 'Symbol Duration (s)', 'FontSize', 12);
    ylabel(ax4, 'Optimal Threshold (molecule count)', 'FontSize', 12);
    title(ax4, sprintf('%s – Detection Threshold vs Symbol Duration', upper(etLabel)), ...
        'FontSize', 14, 'FontWeight', 'bold');
    grid(ax4, 'on');
    ylim(ax4, [0 max(thresholds)*1.3]);
    set(ax4, 'XTick', durations);
    set(ax4, 'FontSize', 11, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);

    % --- Print summary ---
    fprintf('\n\n========== %s SYMBOL DURATION ANALYSIS ==========\n', upper(etLabel));
    fprintf('%-15s  %-15s  %-12s  %-10s\n', 'Duration (s)', 'Peak Molecules', 'Threshold', 'BER');
    fprintf('%s\n', repmat('-', 1, 56));
    for k = 1:length(durations)
        idx = si(k);
        peakMol = max(results(idx).rx_counts);
        fprintf('%-15d  %-15.0f  %-12.0f  %-10.4f\n', ...
            durations(k), peakMol, thresholds(k), bers(k));
    end
    fprintf('\n');
end
