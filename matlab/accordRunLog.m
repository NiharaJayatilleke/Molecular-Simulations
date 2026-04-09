function [hFig, hAxes] = accordRunLog(inputFile)
%
% accordRunLog.m - Wrapper for accordQuickPlot that sets log scale
%
% INPUTS
% inputFile - full filename (including directory) of data to plot
%
% OUTPUTS
% hFig - handle to plotted figure
% hAxes - handle to axes in plotted figure
%

% Ensure matlab and JSONlab folders are on path
[thisDir, ~, ~] = fileparts(mfilename('fullpath'));
accordRoot = fullfile(thisDir, '..');
addpath(thisDir);
addpath(fullfile(accordRoot, 'JSONlab'));
cd(accordRoot);

fprintf('AcCoRD paths loaded.\n');

[hFig, hAxes] = accordQuickPlot(inputFile);
set(hAxes, 'YScale', 'log');

end
