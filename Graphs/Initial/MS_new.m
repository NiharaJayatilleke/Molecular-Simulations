function results = accordDecodeETModStrength(etLabel)
% accordDecodeETModStrength - Decode all modulation strength results for one ET
%
%   results = accordDecodeETModStrength('et1')
%
% Automatically finds all et<N>_modulation_strength_<S>_<D>_SEED1.txt files,
% decodes each one, computes threshold and BER, and returns a summary struct
% sorted by modulation strength.
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2'
%
% OUTPUTS
%   results - struct array (one element per modulation strength) with fields:
%       .modStrength     - modulation strength value (e.g. 100, 1000, ...)
%       .modStrengthStr  - original string label (e.g. '1e2', '1e3', ...)
%       .distance        - distance in cm
%       .threshold       - computed threshold (mean-of-means)
%       .decoded_bits    - decoded bit vector
%       .tx_bits         - transmitted bit vector
%       .BER             - bit error rate
%       .num_errors      - number of bit errors
%       .num_bits        - number of transmitted bits
%       .peak_per_symbol - peak molecule count per symbol period
%       .rx_counts       - full raw received molecule count time-series

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    % Fixed timing: 300 s symbol period / 2 s time step = 150 samples per symbol.
    % The simulation may run beyond the transmission window; only the first
    % (num_symbols * samples_per_symbol) samples are used for decoding.
    samples_per_symbol = 150;

    % --- find all modulation strength result files for this ET ---
    resultsDir = fullfile(accordRoot, 'bin', 'results');
    pattern = [etLabel '_modulation_strength_*_SEED1.txt'];
    listing = dir(fullfile(resultsDir, pattern));

    if isempty(listing)
        error('No modulation strength result files found for %s in %s', etLabel, resultsDir);
    end

    % Parse modulation strength and distance from filenames
    %  e.g. et1_modulation_strength_1e3_10_SEED1.txt
    modStrengths    = zeros(length(listing), 1);
    modStrengthStrs = cell(length(listing), 1);
    distances       = zeros(length(listing), 1);
    keep            = true(length(listing), 1);

    for k = 1:length(listing)
        name = listing(k).name;
        name = strrep(name, '_SEED1.txt', '');              % et1_modulation_strength_1e3_10
        name = strrep(name, [etLabel '_modulation_strength_'], '');  % 1e3_10
        parts = strsplit(name, '_');
        if length(parts) >= 2
            modStrengthStrs{k} = parts{1};                  % '1e3'
            modStrengths(k)    = str2double(parts{1});      % 1000
            distances(k)       = str2double(parts{2});      % 10
        else
            keep(k) = false;
        end
    end

    listing         = listing(keep);
    modStrengths    = modStrengths(keep);
    modStrengthStrs = modStrengthStrs(keep);
    distances       = distances(keep);

    % Sort by modulation strength
    [modStrengths, sortIdx] = sort(modStrengths);
    listing         = listing(sortIdx);
    modStrengthStrs = modStrengthStrs(sortIdx);
    distances       = distances(sortIdx);

    numFiles = length(modStrengths);
    fprintf('\n=== Decoding %s Modulation Strengths – %d files found ===\n', upper(etLabel), numFiles);

    % Pre-allocate output struct
    results = struct('modStrength',    num2cell(modStrengths'), ...
                     'modStrengthStr', modStrengthStrs', ...
                     'distance',       num2cell(distances'), ...
                     'samples_per_symbol', [], ...
                     'num_rx_samples', [], ...
                     'threshold',      [], ...
                     'decoded_bits',   [], ...
                     'tx_bits',        [], ...
                     'BER',            [], ...
                     'num_errors',     [], ...
                     'num_bits',       [], ...
                     'peak_per_symbol',[], ...
                     'rx_counts',      []);

    % --- decode each file ---
    for k = 1:numFiles
        file = fullfile(resultsDir, listing(k).name);
        fprintf('\n--- %s (d=%d cm)  (%s) ---\n', modStrengthStrs{k}, distances(k), listing(k).name);

        text = fileread(file);
        if isempty(strtrim(text))
            warning('File is empty: %s', listing(k).name);
            continue;
        end

        % ---- transmitted bits ----
        tx_start = strfind(text, 'ActiveActor 0:');
        pa_start = strfind(text, 'PassiveActor ');
        if isempty(tx_start) || isempty(pa_start)
            warning('Could not find ActiveActor/PassiveActor in %s', listing(k).name);
            continue;
        end
        tx_text  = text(tx_start(1):pa_start(1)-1);
        tx_bits  = sscanf(tx_text, '%*[^0-1]%d');
        num_symbols = length(tx_bits);

        % ---- received counts (single passive actor) ----
        if length(pa_start) >= 2
            rx_text = text(pa_start(1):pa_start(2)-1);
        else
            rx_text = text(pa_start(1):end);
        end
        cIdx = strfind(rx_text, 'Count:');
        if isempty(cIdx)
            warning('No Count data found in %s', listing(k).name);
            continue;
        end
        count_text = rx_text(cIdx(1):end);
        rx_counts  = sscanf(count_text, '%*[^0-9]%d');

        if num_symbols <= 0
            warning('No transmitted symbols found in %s', listing(k).name);
            continue;
        end

        % Trim RX signal to exactly the transmission window.
        % Any samples beyond num_symbols * samples_per_symbol are post-transmission
        % tail from the simulation running past the last bit and are discarded.
        num_rx_needed = num_symbols * samples_per_symbol;
        if length(rx_counts) < num_rx_needed
            warning('RX signal too short in %s: need %d samples, got %d.', ...
                listing(k).name, num_rx_needed, length(rx_counts));
            continue;
        end
        rx_counts = rx_counts(1:num_rx_needed);

        % ---- peak per symbol period ----
        peak = zeros(num_symbols, 1);
        for s = 1:num_symbols
            si = (s-1)*samples_per_symbol + 1;
            ei = s*samples_per_symbol;
            peak(s) = max(rx_counts(si:ei));
        end

        % ---- threshold (mean of 0-symbol peaks + mean of 1-symbol peaks) / 2 ----
        zeroVals  = peak(tx_bits == 0);
        oneVals   = peak(tx_bits == 1);
        threshold = (mean(zeroVals) + mean(oneVals)) / 2;

        % ---- decode ----
        decoded = double(peak >= threshold);

        % ---- BER ----
        num_errors = sum(decoded ~= tx_bits);
        BER = num_errors / num_symbols;

        % ---- store ----
        results(k).threshold       = threshold;
        results(k).samples_per_symbol = samples_per_symbol;
        results(k).num_rx_samples  = length(rx_counts);
        results(k).decoded_bits    = decoded;
        results(k).tx_bits         = tx_bits;
        results(k).BER             = BER;
        results(k).num_errors      = num_errors;
        results(k).num_bits        = num_symbols;
        results(k).peak_per_symbol = peak;
        results(k).rx_counts       = rx_counts;

        % ---- print ----
        fprintf('TX bits (%d): ', num_symbols);
        fprintf('%d', tx_bits); fprintf('\n');
        fprintf('RX bits (%d): ', num_symbols);
        fprintf('%d', decoded);  fprintf('\n');
        fprintf('Samples/symbol : %d\n', samples_per_symbol);
        fprintf('Threshold : %.2f\n', threshold);
        fprintf('BER       : %.4f  (%d / %d errors)\n', BER, num_errors, num_symbols);
    end

    % ---- summary table ----
    fprintf('\n\n========== %s MODULATION STRENGTH SUMMARY ==========\n', upper(etLabel));
    fprintf('%-12s  %-10s  %-12s  %-10s  %-10s\n', 'Mod Strength', 'Distance', 'Threshold', 'BER', 'Errors');
    fprintf('%s\n', repmat('-', 1, 60));
    for k = 1:numFiles
        fprintf('%-12s  %-10s  %-12.2f  %-10.4f  %d / %d\n', ...
            results(k).modStrengthStr, ...
            sprintf('%d cm', results(k).distance), ...
            results(k).threshold, results(k).BER, ...
            results(k).num_errors, results(k).num_bits);
    end
    fprintf('\n');
end
