function [hFig, results] = accordPlotETDistances(etLabel)
% accordPlotETDistances - Plot received wave signals for distances 5–60 cm
%
%   [hFig, results] = accordPlotETDistances('et1')
%
% Plots 6 continuous wave curves (one per distance: 5,10,20,30,50,60 cm)
% showing the full molecule count time-series on a single graph.
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2', ..., 'et6'
%
% OUTPUTS
%   hFig    - figure handle
%   results - struct array from accordDecodeET (thresholds, BER, etc.)

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    dt = 2;   % global microscopic time step (seconds)

    % --- find & decode all distances ---
    results = accordDecodeET(etLabel);

    % --- keep only distances 5, 10, 20, 30, 50, 60 ---
    wantDist = [5 10 20 30 50];
    allDist  = [results.distance];
    keepIdx  = [];
    for w = wantDist
        idx = find(allDist == w, 1);
        if ~isempty(idx)
            keepIdx(end+1) = idx; %#ok
        end
    end
    results = results(keepIdx);

    % --- remove distances that failed to decode (empty rx_counts) ---
    valid = false(1, length(results));
    for k = 1:length(results)
        valid(k) = ~isempty(results(k).rx_counts) && ~isempty(results(k).threshold);
    end
    if any(~valid)
        skipped = [results(~valid).distance];
        fprintf('Skipping distances with no data: %s cm\n', num2str(skipped));
    end
    results = results(valid);
    numDist = length(results);

    if numDist == 0
        error('No matching distance files found for %s', etLabel);
    end

    % --- colours ---
    colours = [0.00 0.45 0.74;   % blue
               0.85 0.33 0.10;   % orange
               0.93 0.69 0.13;   % yellow-gold
               0.49 0.18 0.56;   % purple
               0.47 0.67 0.19;   % green
               0.30 0.75 0.93];  % cyan
    if numDist > size(colours,1)
        colours = lines(numDist);
    end

    % --- figure ---
    hFig = figure('Color','w', 'Name', ...
        sprintf('%s – Received Signal (5 to 50 cm)', upper(etLabel)), ...
        'Units','pixels', 'Position',[80 60 1100 500]);

    ax = axes('Parent', hFig); hold(ax, 'on');
    set(ax, 'Color', 'w');   % white axes background

    legendEntries = cell(1, numDist * 2);  % signal + threshold per distance
    plotHandles   = gobjects(1, numDist);  % only signal lines go in legend

    % --- find global time span (for threshold lines) ---
    tMax = 0;
    for k = 1:numDist
        tMax = max(tMax, (length(results(k).rx_counts)-1) * dt);
    end

    % --- plot wave curves ---
    for k = 1:numDist
        rx = results(k).rx_counts(:);         % force column vector
        t  = ((0:length(rx)-1) * dt)';         % force column vector

        h = plot(ax, t, rx, '-', 'Color', colours(k,:), 'LineWidth', 1.2);
        plotHandles(k) = h(1);                 % take first handle only
        legendEntries{k} = sprintf('%d cm', results(k).distance);
    end

    % --- plot threshold dotted lines ---
    thrHandles = gobjects(1, numDist);
    for k = 1:numDist
        thr = results(k).threshold;
        thrHandles(k) = plot(ax, [0 tMax], [thr thr], ':', ...
            'Color', colours(k,:), 'LineWidth', 1.5);
        legendEntries{numDist + k} = sprintf('%d cm Thr=%.1f', results(k).distance, thr);
    end

    hold(ax, 'off');

    % --- log scale ---
    set(ax, 'YScale', 'log');

    xlabel(ax, 'Time (s)',      'FontSize', 11);
    ylabel(ax, 'Molecule Count (log scale)', 'FontSize', 11);
    title(ax, sprintf('%s – Received Signal for Distances 5 to 50 cm (Log Scale)', upper(etLabel)), ...
          'FontSize', 13, 'FontWeight', 'bold');
    lgd = legend(ax, [plotHandles thrHandles], legendEntries, ...
        'Location', 'northeast', 'FontSize', 9, 'NumColumns', 2);
    set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    grid(ax, 'on');
    set(ax, 'FontSize', 10, 'Box', 'on', ...
        'XColor', [.2 .2 .2], 'YColor', [.2 .2 .2]);
end
