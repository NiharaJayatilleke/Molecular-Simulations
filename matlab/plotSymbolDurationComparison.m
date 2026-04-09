function [hFig, hAxes] = plotSymbolDurationComparison()
%
% plotSymbolDurationComparison.m - Plot multiple ET1 symbol durations on one graph
%
% This function plots different symbol duration results for the
% ET1 encoding technique on a single graph for comparison.
%
% USAGE:
%   [hFig, hAxes] = plotSymbolDurationComparison()
%
% OUTPUTS:
%   hFig  - handle to plotted figure
%   hAxes - handle to axes in plotted figure
%
% Created for AcCoRD symbol duration comparison

% Get the directory where this script is located and set up paths
scriptDir = fileparts(mfilename('fullpath'));
accordRoot = fileparts(scriptDir);  % Parent directory (AcCoRD root)

% Add required paths
addpath(scriptDir);  % matlab folder
addpath(fullfile(accordRoot, 'JSONlab'));  % JSONlab folder

% Change to AcCoRD root directory for relative file paths
cd(accordRoot);

% File paths - use base filename without _SEED suffix
file100 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_100');
file200 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_200');
file300 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_300');
file400 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_400');
file500 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_500');

% Import all datasets
[data100, config100] = accordImport(file100, 1, 1);
[data200, config200] = accordImport(file200, 1, 1);
[data300, config300] = accordImport(file300, 1, 1);
[data400, config400] = accordImport(file400, 1, 1);
[data500, config500] = accordImport(file500, 1, 1);

% Save imported data to mat files for accordPlotMaker (needs both data and config)
dataFileName100 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_100_out.mat');
dataFileName200 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_200_out.mat');
dataFileName300 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_300_out.mat');
dataFileName400 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_400_out.mat');
dataFileName500 = fullfile(accordRoot, 'bin', 'results', 'et1_symbol_duration_500_out.mat');

data = data100; config = config100; save(dataFileName100, 'data', 'config');
data = data200; config = config200; save(dataFileName200, 'data', 'config');
data = data300; config = config300; save(dataFileName300, 'data', 'config');
data = data400; config = config400; save(dataFileName400, 'data', 'config');
data = data500; config = config500; save(dataFileName500, 'data', 'config');

% Setup figure properties
customFigProp = [];
customFigProp.Color = 'w';
customAxesProp.Visible = 'on';
customAxesProp.Projection = 'orthographic';
customAxesProp.Clipping = 'on';
customAxesProp.Color = 'w';
customObsProp = [];

hAxes = 0;

% Plot 100s symbol duration - cyan solid line
for i = 1:data100.numPassiveRecord
    for j = 1:data100.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Symbol Duration 100s';
        customCurveProp.Color = 'c';  % cyan
        customCurveProp.LineStyle = '-';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName100,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 200s symbol duration - green dashed line
for i = 1:data200.numPassiveRecord
    for j = 1:data200.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Symbol Duration 200s';
        customCurveProp.Color = [0 0.6 0];  % dark green
        customCurveProp.LineStyle = '--';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName200,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 300s symbol duration - blue dash-dot line
for i = 1:data300.numPassiveRecord
    for j = 1:data300.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Symbol Duration 300s';
        customCurveProp.Color = 'b';
        customCurveProp.LineStyle = '-.';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName300,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 400s symbol duration - red dotted line
for i = 1:data400.numPassiveRecord
    for j = 1:data400.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Symbol Duration 400s';
        customCurveProp.Color = 'r';
        customCurveProp.LineStyle = ':';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName400,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 500s symbol duration - magenta solid thick line
for i = 1:data500.numPassiveRecord
    for j = 1:data500.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Symbol Duration 500s';
        customCurveProp.Color = 'm';
        customCurveProp.LineStyle = '-';
        customCurveProp.LineWidth = 2.0;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName500,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Update legend and title
legend(hAxes, 'show', 'Location', 'best');
title(hAxes, 'ET1 Encoding: Symbol Duration Comparison');
xlabel(hAxes, 'Time (s)');
ylabel(hAxes, 'Molecule Count');
grid(hAxes, 'on');

% Set log scale for Y-axis
set(hAxes, 'YScale', 'log');

set(hAxes, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
hLeg = legend(hAxes);
set(hLeg, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');

end
