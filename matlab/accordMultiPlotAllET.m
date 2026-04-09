function [hFig, hAxesArray] = accordMultiPlotAllET()
% accordMultiPlotAllET - Plot distance comparison for each encoding technique
%
% Creates a figure with one subplot per encoding technique (ET1–ET5).
% Within each subplot, all distances (5, 10, 20, 30, 50 cm) are overlaid.
%
% USAGE:
%   [hFig, hAxesArray] = accordMultiPlotAllET()
%
% OUTPUTS:
%   hFig       - handle to the figure
%   hAxesArray - array of axes handles (one per subplot)

    % --- paths ---
    scriptDir  = fileparts(mfilename('fullpath'));
    accordRoot = fileparts(scriptDir);
    addpath(scriptDir);
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    % --- settings ---
    etLabels   = {'et1','et2','et3','et4','et5'};
    distances  = [5, 10, 20, 30, 50];
    numET      = length(etLabels);
    numDist    = length(distances);

    % Colours & line styles per distance
    distColors = {[0.00 0.45 0.74], ...   % blue
                  [0.47 0.67 0.19], ...   % green
                  [0.85 0.33 0.10], ...   % orange-red
                  [0.49 0.18 0.56], ...   % purple
                  [0.93 0.69 0.13]};      % gold
    distStyles = {'-', '--', '-.', '-', '--'};

    % --- figure (16:11 aspect, white background) ---
    figW = 900;  figH = 620;              % pixels – roughly 16:11
    screenSz = get(0, 'ScreenSize');
    posX = round((screenSz(3) - figW) / 2);
    posY = round((screenSz(4) - figH) / 2);
    hFig = figure('Color','w', 'Name','All ET – Distance Comparison', ...
                  'Units','pixels', 'Position',[posX posY figW figH]);

    hAxesArray = gobjects(numET, 1);

    % Spacing for subplots (tighter, less stretched)
    margins = struct('left',0.08, 'right',0.03, 'top',0.06, 'bottom',0.07, ...
                     'hgap',0, 'vgap',0.06);
    plotW = 1 - margins.left - margins.right;
    plotH = (1 - margins.top - margins.bottom - (numET-1)*margins.vgap) / numET;

    for e = 1:numET

        % Manual subplot position for even spacing
        yPos = margins.bottom + (numET - e) * (plotH + margins.vgap);
        hAx = axes('Parent', hFig, 'Position', [margins.left, yPos, plotW, plotH]);
        hold(hAx, 'on');

        for d = 1:numDist
            name = sprintf('%s_distance_%d', etLabels{e}, distances(d));
            resultsPath = fullfile(accordRoot, 'bin', 'results', name);
            outMat = fullfile(accordRoot, 'bin', 'results', [name '_out.mat']);

            % import & save
            try
                [datK, cfgK] = accordImport(resultsPath, 1, 1);
                data = datK; config = cfgK; %#ok<NASGU>
                save(outMat, 'data', 'config');
            catch ME
                fprintf('Warning: could not import %s (%s)\n', name, ME.message);
                continue;
            end

            % Build time axis from config
            actorID = 1;
            while config.actor{actorID}.passiveID ~= 1
                actorID = actorID + 1;
            end
            numObs = size(datK.passiveRecordCount{1}, 3);
            tArray = config.actor{actorID}.startTime + ...
                     (0:(numObs-1)) * config.actor{actorID}.actionInterval;

            % Average molecule count across realisations (passive 1, mol 1)
            yData = squeeze(mean(datK.passiveRecordCount{1}(:,1,:), 1));

            % Plot
            plot(hAx, tArray, yData, ...
                 'Color', distColors{d}, 'LineStyle', distStyles{d}, ...
                 'LineWidth', 1.4, 'DisplayName', sprintf('%d cm', distances(d)));
        end

        hold(hAx, 'off');

        % --- formatting ---
        set(hAx, 'YScale', 'log', 'Color', 'w', ...
            'XColor', [0.25 0.25 0.25], 'YColor', [0.25 0.25 0.25], ...
            'FontSize', 9, 'Box', 'on', 'TickDir', 'out');
        ylabel(hAx, 'Mol. Count', 'FontSize', 9);
        title(hAx, upper(etLabels{e}), 'FontSize', 10, 'FontWeight', 'bold');
        grid(hAx, 'on');
        set(hAx, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.5);

        % Only show x-label on bottom subplot; hide tick labels on others
        if e == numET
            xlabel(hAx, 'Time (s)', 'FontSize', 10);
        else
            set(hAx, 'XTickLabel', []);
        end

        % Legend only on first subplot (shared for all)
        if e == 1
            hLeg = legend(hAx, 'show', 'Location', 'northeast', ...
                          'FontSize', 8, 'NumColumns', numDist);
            set(hLeg, 'Color', 'w', 'EdgeColor', [0.7 0.7 0.7], 'TextColor', 'k');
        end

        hAxesArray(e) = hAx;
    end

    % Super-title
    annotation(hFig, 'textbox', [0 0.95 1 0.05], ...
        'String', 'Encoding Techniques – Distance Comparison (5, 10, 20, 30, 50 cm)', ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
        'FontSize', 13, 'FontWeight', 'bold', 'FitBoxToText', 'off');
end
