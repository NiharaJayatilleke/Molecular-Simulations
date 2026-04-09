function [hFig, hAxes] = accordRunLog(filename)
% accordRunLog - Import and plot AcCoRD simulation results with log scale
%   [hFig, hAxes] = accordRunLog('et1_distance_5_10_20')
%
%   This is a launcher script in the root folder that sets up paths
%   and plots with log scale on y-axis.

    % Get the root directory (where this script lives)
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    
    % Add required paths
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    
    % Change to AcCoRD root directory
    cd(accordRoot);
    
    fprintf('AcCoRD paths loaded.\n');
    
    % Build file paths
    resultsPath = fullfile(accordRoot, 'bin', 'results', filename);
    outputFile = [filename '_out'];
    
    % Import data
    fprintf('Importing from: %s\n', resultsPath);
    accordImport(resultsPath, 1, true);
    
    % Plot results with log scale
    fprintf('Plotting (log scale): %s\n', outputFile);
    [hFig, hAxes] = accordQuickPlot(outputFile);
    set(hAxes, 'YScale', 'log');
end
