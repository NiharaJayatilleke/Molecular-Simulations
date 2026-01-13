function data = accordRun(filename)
% accordRun - Import and plot AcCoRD simulation results in one command
%   data = accordRun('accord_sample_communication_chemical_dif_coef')
%
%   This combines accordImport and accordQuickPlot into a single call.

    % Ensure matlab and JSONlab folders are on path
    [thisDir, ~, ~] = fileparts(mfilename('fullpath'));
    accordRoot = fullfile(thisDir, '..');
    addpath(thisDir);
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);
    
    fprintf('AcCoRD paths loaded. Use accordRun(filename) to import and plot.\n');
    fprintf('Example: data = accordRun(''accord_sample_communication_chemical_dif_coef'');\n');
    
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
