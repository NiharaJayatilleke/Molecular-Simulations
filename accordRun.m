function data = accordRun(filename)
% accordRun - Import and plot AcCoRD simulation results in one command
%   data = accordRun('accord_sample_communication_chemical_dif_coef')
%
%   This is a launcher script in the root folder that sets up paths
%   and calls the main accordRun function in the matlab folder.

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
    data = accordImport(resultsPath, 1, true);
    
    % Plot results
    fprintf('Plotting: %s\n', outputFile);
    accordQuickPlot(outputFile);
end
