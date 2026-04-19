function results = accordDecodeET(etLabel)
% accordDecodeET - Decode all single-distance results for one encoding technique
%
%   results = accordDecodeET('et1')
%   results = accordDecodeET('et2')
%
% Automatically finds all et<N>_distance_<D>_SEED1.txt files (single-
% receiver experiments), decodes each one, computes threshold and BER,
% and returns a summary struct sorted by distance.
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2', ..., 'et5'
%
% OUTPUTS
%   results - struct array (one element per distance) with fields:
%       .distance       - distance in cm
%       .threshold      - computed threshold (mean-of-means)
%       .decoded_bits   - decoded bit vector
%       .tx_bits        - transmitted bit vector
%       .BER            - bit error rate
%       .num_errors     - number of bit errors
%       .num_bits       - number of transmitted bits
%       .peak_per_symbol - peak molecule count per symbol period
%       .rx_counts      - received count time-series used for decoding

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    % Timing (common to all experiments)
    samples_per_symbol = 150;   % 300 s symbol / 2 s time step

    % --- find all single-distance result files for this ET ---
    resultsDir = fullfile(accordRoot, 'bin', 'results');
    pattern = [etLabel '_distance_*_SEED1.txt'];
    listing = dir(fullfile(resultsDir, pattern));

    % Filter out the multi-distance combo files (e.g. et1_distance_5_10_20)
    keep = true(length(listing), 1);
    distances = zeros(length(listing), 1);
    for k = 1:length(listing)
        name = listing(k).name;                         % et1_distance_30_SEED1.txt
        name = strrep(name, '_SEED1.txt', '');           % et1_distance_30
        parts = strsplit(name, '_');                      % {'et1','distance','30'}
        % If there are more than 3 parts the file is a multi-distance combo
        if length(parts) ~= 3
            keep(k) = false;
        else
            distances(k) = str2double(parts{3});
        end
    end
    listing   = listing(keep);
    distances = distances(keep);

    if isempty(listing)
        error('No single-distance result files found for %s in %s', etLabel, resultsDir);
    end

    % Sort by distance
    [distances, sortIdx] = sort(distances);
    listing = listing(sortIdx);

    numDist = length(distances);
    fprintf('\n=== Decoding %s – %d distances found ===\n', upper(etLabel), numDist);

    % Pre-allocate output struct
    results = struct('distance',    num2cell(distances'), ...
                     'threshold',   [], ...
                     'decoded_bits',[], ...
                     'tx_bits',     [], ...
                     'BER',         [], ...
                     'num_errors',  [], ...
                     'num_bits',    [], ...
                     'peak_per_symbol', [], ...
                     'rx_counts',   []);

    % --- decode each file ---
    for k = 1:numDist
        file = fullfile(resultsDir, listing(k).name);
        fprintf('\n--- %d cm  (%s) ---\n', distances(k), listing(k).name);

        text = fileread(file);

        % ---- transmitted bits ----
        tx_start = strfind(text, 'ActiveActor 0:');
        pa_start = strfind(text, 'PassiveActor ');
        if isempty(tx_start) || isempty(pa_start)
            warning('Could not find ActiveActor/PassiveActor in %s', listing(k).name);
            continue;
        end
        tx_text  = text(tx_start(1):pa_start(1)-1);
        tx_text  = regexprep(tx_text, '^ActiveActor\s+0:\s*', '');
        tx_bits  = sscanf(tx_text, '%d');
        num_symbols = length(tx_bits);
        if num_symbols <= 0
            warning('No transmitted symbols found in %s', listing(k).name);
            continue;
        end

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

        % Trim everything beyond the transmission window first.
        rx_trimmed = rx_counts(1:min(num_symbols * samples_per_symbol, length(rx_counts)));

        % Pad with zeros if simulation ended before transmission window completed.
        if length(rx_trimmed) < num_symbols * samples_per_symbol
            fprintf('Note: RX signal shorter than transmission window in %s. Zero-padding %d missing samples.\n', ...
                listing(k).name, num_symbols * samples_per_symbol - length(rx_trimmed));
            rx_trimmed(end+1 : num_symbols * samples_per_symbol) = 0;
        end

        % ---- peak per symbol period ----
        peak = zeros(num_symbols, 1);
        for s = 1:num_symbols
            si = (s-1)*samples_per_symbol + 1;
            ei = s*samples_per_symbol;
            peak(s) = max(rx_trimmed(si:ei));
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
        results(k).decoded_bits    = decoded;
        results(k).tx_bits         = tx_bits;
        results(k).BER             = BER;
        results(k).num_errors      = num_errors;
        results(k).num_bits        = num_symbols;
        results(k).peak_per_symbol = peak;
        results(k).rx_counts       = rx_trimmed;

        % ---- print ----
        fprintf('TX bits (%d): ', num_symbols);
        fprintf('%d', tx_bits); fprintf('\n');
        fprintf('RX bits (%d): ', num_symbols);
        fprintf('%d', decoded);  fprintf('\n');
        fprintf('Threshold : %.2f\n', threshold);
        fprintf('BER       : %.4f  (%d / %d errors)\n', BER, num_errors, num_symbols);
    end

    % ---- summary table ----
    fprintf('\n\n========== %s SUMMARY ==========\n', upper(etLabel));
    fprintf('%-10s  %-12s  %-10s  %-10s\n', 'Distance', 'Threshold', 'BER', 'Errors');
    fprintf('%s\n', repmat('-', 1, 46));
    for k = 1:numDist
        fprintf('%-10s  %-12.2f  %-10.4f  %d / %d\n', ...
            sprintf('%d cm', results(k).distance), ...
            results(k).threshold, results(k).BER, ...
            results(k).num_errors, results(k).num_bits);
    end
    fprintf('\n');
end
