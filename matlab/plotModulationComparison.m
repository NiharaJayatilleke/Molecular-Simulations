function [hFig, hAxes] = plotModulationComparison()
%
% plotModulationComparison.m - Plot multiple ET1 modulation strengths on one graph
%
% This function plots both 1e5 and 1e6 modulation strength results for the
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

% File paths - use base filename without _SEED suffi% x
file1 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e2_10');
file2 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e6_10');

% Import bo% th datasets
[data1, config1] = accordImport(file1, 1, 1);
[data2, config2] = accordImport(file2, 1, 1);

% Save imported data to mat files for accordPlotMaker (needs both data and config% )
dataFileName1 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e2_10_out.mat');
dataFileName2 = fullfile(accordRoot, 'bin', 'results', 'et1_modulation_strength_1e6_10% _out.mat');
data = data1; config = config1; save(dataFileName1, 'data', 'config');
data = data2; config = config2; save(dataFileName2, 'data', 'config');

% Setup figure properties
customFigProp = [];
customFigProp.Color = 'w';
customAxesProp.Visible = 'on';
customAxesProp.Projection = 'orthographic';
customAxesProp.Clipping = 'on';
customAxesProp.Color = 'w';
customObsProp = [];

hAxes = 0;

% Plot first dataset (1e2) - solid blue line
for i = 1:data1.numPassiveRecord
    for j = 1:data1.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e2';
        customCurveProp.Color = 'b';
        customCurveProp.LineStyle = '-';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName1,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot second dataset (1e4) - green dashed line
for i = 1:data2.numPassiveRecord
    for j = 1:data2.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e4';
        customCurveProp.Color = [0 0.6 0];  % dark green
        customCurveProp.LineStyle = '--';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName2,...
            i, j, ...
            customObsProp, customCurveProp, ...
            customFigProp, customAxesProp);
    end
end

% Plot third dataset (1e6) - dashed red line
for i = 1:data3.numPassiveRecord
    for j = 1:data3.passiveRecordNumMolType(i)
        customCurveProp.DisplayName = 'Modulation Strength 1e6';
        customCurveProp.Color = 'r';
        customCurveProp.LineStyle = '-.';
        customCurveProp.LineWidth = 1.5;
        [hFig, hAxes] = accordPlotMaker(hAxes, dataFileName3,...
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
