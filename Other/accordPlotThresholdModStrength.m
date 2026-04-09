function [hFig, hAxes, thresholds] = accordPlotThresholdModStrength(etLabel)
% accordPlotThresholdModStrength - Plot ET modulation strengths with thresholds
%   [hFig, hAxes, thresholds] = accordPlotThresholdModStrength('et1')
%   [hFig, hAxes, thresholds] = accordPlotThresholdModStrength('et2')
%
% Overlays all modulation strengths (1e2–1e6) on one graph with threshold
% lines, similar to accordPlotThreshold but for modulation strength sweeps.
%
% INPUTS
%   etLabel - encoding technique label: 'et1' or 'et2'
%
% OUTPUTS
%   hFig       - handle to plotted figure
%   hAxes      - handle to axes in plotted figure
%   thresholds - threshold for each modulation strength [5x1]

    if nargin < 1
        etLabel = 'et1';
    end

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    modLabels = {'1e2','1e3','1e4','1e5','1e6'};
    numMod    = length(modLabels);
    thresholds = zeros(numMod, 1);

    % Line styles & colours for each modulation strength
    lineColors = {[0 0.6 0], 'm', 'c', 'b', 'r'};
    lineStyles = {'-', '--', '-.', '-', '--'};

    % --- import first dataset to create the figure ---
    firstName = [etLabel '_modulation_strength_' modLabels{1} '_10'];
    resultsPath = fullfile(accordRoot, 'bin', 'results', firstName);
    [data, config] = accordImport(resultsPath, 1, 1);
    outFile = fullfile(accordRoot, 'bin', 'results', [firstName '_out.mat']);
    save(outFile, 'data', 'config');

    % Setup figure
    customFigProp = [];
    customFigProp.Color = 'w';
    customAxesProp.Visible = 'on';
    customAxesProp.Projection = 'orthographic';
    customAxesProp.Clipping = 'on';
    customAxesProp.Color = 'w';
    customObsProp = [];

    hAxes = 0;

    % --- loop over modulation strengths ---
    for k = 1:numMod
        name = [etLabel '_modulation_strength_' modLabels{k} '_10'];
        resultsPath = fullfile(accordRoot, 'bin', 'results', name);
        outMat = fullfile(accordRoot, 'bin', 'results', [name '_out.mat']);

        % import & save
        [datK, cfgK] = accordImport(resultsPath, 1, 1);
        data = datK; config = cfgK;
        save(outMat, 'data', 'config');

        % plot curve (first passive actor, first mol type)
        customCurveProp.DisplayName = ['Mod ' modLabels{k}];
        customCurveProp.Color       = lineColors{k};
        customCurveProp.LineStyle   = lineStyles{k};
        customCurveProp.LineWidth   = 1.5;

        [hFig, hAxes] = accordPlotMaker(hAxes, outMat, ...
            1, 1, customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);

        % compute threshold via accordDecode
        [thr, ~, ~] = accordDecode(name);
        thresholds(k) = thr(1);   % first passive actor
    end

    % --- draw threshold lines ---
    hold(hAxes, 'on');
    xlims = xlim(hAxes);
    for k = 1:numMod
        hLine = plot(hAxes, xlims, [thresholds(k) thresholds(k)], ...
            ':', 'Color', lineColors{k}, 'LineWidth', 1.2, ...
            'HandleVisibility', 'off');

        text(hAxes, xlims(2), thresholds(k), ...
            sprintf('  Thr %s: %.1f', modLabels{k}, thresholds(k)), ...
            'Color', lineColors{k}, 'FontSize', 8, ...
            'VerticalAlignment', 'bottom');
    end
    hold(hAxes, 'off');

    % --- formatting ---
    set(hAxes, 'YScale', 'log');
    legend(hAxes, 'show', 'Location', 'best');
    title(hAxes, sprintf('%s Encoding – Modulation Strength Comparison with Thresholds', upper(etLabel)));
    xlabel(hAxes, 'Time (s)');
    ylabel(hAxes, 'Molecule Count');
    grid(hAxes, 'on');
    set(hAxes, 'XColor', 'k', 'YColor', 'k');
    hLeg = legend(hAxes);
    set(hLeg, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');

    % --- print summary ---
    fprintf('\n=== %s Thresholds ===\n', upper(etLabel));
    for k = 1:numMod
        fprintf('  Mod Strength %s : Threshold = %.2f\n', modLabels{k}, thresholds(k));
    end
    fprintf('\n');
end
