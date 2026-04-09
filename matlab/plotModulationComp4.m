function [hFig, hAxes] = plotModulationComparison()
%
% plotModulationComparison.m - Plot multiple ET1 modulation strengths on one graph
%
% This function plots 1e2, 1e3, 1e5 and 1e6 modulation strength results for the
% ET1 encoding technique at 10cm distance on a single graph for comparison.
%
% USAGE:
%   [hFig, hAxes] = plotModulationComparison()
%
% OUTPUTS:
%   hFig  - handle to plotted figure
%   hAxes - handle to axes in plotted figure
%
% Created for AcCoRD modulation strength comparison

% Get the directory where this script is located and set up paths
scriptDir = fileparts(mfilename('fullpath'));
accordRoot = fileparts(scriptDir);  % Parent directory (AcCoRD root)

% Add required paths
addpath(scriptDir);  % matlab folder
addpath(fullfile(accordRoot, 'JSONlab'));  % JSONlab folder

% Change to AcCoRD root directory for relative file paths
cd(accordRoot);

% File paths - use base filename without _SEED suffix
file1e2 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e2_10');
file1e3 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e3_10');
file1e4 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e4_10');
file1e5 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e5_10');
file1e6 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e6_10');

% Import all datasets
[data1e2, config1e2] = accordImport(file1e2, 1, 1);
[data1e3, config1e3] = accordImport(file1e3, 1, 1);
[data1e4, config1e4] = accordImport(file1e4, 1, 1);
[data1e5, config1e5] = accordImport(file1e5, 1, 1);
[data1e6, config1e6] = accordImport(file1e6, 1, 1);

% Save imported data to mat files for accordPlotMaker (needs both data and config)
dataFileName1e2 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e2_10_out.mat');
dataFileName1e3 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e3_10_out.mat');
dataFileName1e4 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e4_10_out.mat');
dataFileName1e5 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e5_10_out.mat');
dataFileName1e6 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e6_10_out.mat');

data = data1e2; config = config1e2; save(dataFileName1e2, 'data', 'config');
data = data1e3; config = config1e3; save(dataFileName1e3, 'data', 'config');
data = data1e4; config = config1e4; save(dataFileName1e4, 'data', 'config');
data = data1e5; config = config1e5; save(dataFileName1e5, 'data', 'config');
data = data1e6; config = config1e6; save(dataFileName1e6, 'data', 'config');

% Setup figure properties
customFigProp = [];
customFigProp.Color = 'w';
customAxesProp.Visible = 'on';
customAxesProp.Projection = 'orthographic';
customAxesProp.Clipping = 'on';
customAxesProp.Color = 'w';
customObsProp = [];

hAxes = 0;

% Plot 1e2 dataset - green solid line
for i = 1:data1e2.numPassiveRecord
    for j = 1:data1e2.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e2';
        customCurveProp.Color = [0 0.6 0];  % dark green
        customCurveProp.LineStyle = '-';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName1e2,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 1e3 dataset - magenta dashed line
for i = 1:data1e3.numPassiveRecord
    for j = 1:data1e3.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e3';
        customCurveProp.Color = 'm';
        customCurveProp.LineStyle = '--';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName1e3,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 1e4 dataset - cyan dash-dot line
for i = 1:data1e4.numPassiveRecord
    for j = 1:data1e4.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e4';
        customCurveProp.Color = 'c';
        customCurveProp.LineStyle = '-.';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName1e4,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 1e5 dataset - blue solid line
for i = 1:data1e5.numPassiveRecord
    for j = 1:data1e5.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e5';
        customCurveProp.Color = 'b';
        customCurveProp.LineStyle = '-';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName1e5,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot 1e6 dataset - red dashed line
for i = 1:data1e6.numPassiveRecord
    for j = 1:data1e6.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e6';
        customCurveProp.Color = 'r';
        customCurveProp.LineStyle = '--';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName1e6,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Update legend and title
legend(hAxes, 'show', 'Location', 'best');
title(hAxes, 'ET1 Encoding: Modulation Strength Comparison (10 cm)');
xlabel(hAxes, 'Time (s)');
ylabel(hAxes, 'Molecule Count');
grid(hAxes, 'on');

% Set log scale for Y-axis
set(hAxes, 'YScale', 'log');

set(hAxes, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
hLeg = legend(hAxes);
set(hLeg, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');

end
