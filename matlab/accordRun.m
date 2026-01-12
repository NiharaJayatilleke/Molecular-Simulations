function data = accordRun(filename)
% accordRun - Import and plot AcCoRD simulation results in one command
%   data = accordRun('accord_sample_communication_chemical_dif_coef')
%
%   This combines accordImport and accordQuickPlot into a single call.

    % Ensure matlab folder is on path
    [thisDir, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(thisDir);
    
    % Build file paths
    resultsPath = fullfile(thisDir, '..', 'bin', 'results', filename);
    outputFile = [filename '_out'];
    
    % Import data
    fprintf('Importing from: %s\n', resultsPath);
    data = accordImport(resultsPath, 1, true);
    
    % Plot results
    fprintf('Plotting: %s\n', outputFile);
    accordQuickPlot(outputFile);
end
