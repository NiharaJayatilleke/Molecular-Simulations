function results = accordDecodeETSymbolDuration(etLabel)
% accordDecodeETSymbolDuration - Decode all symbol duration results for one ET
%
%   results = accordDecodeETSymbolDuration('et1')
%
% Automatically finds all et<N>_symbol_duration_<SD>_SEED1.txt files,
% decodes each one using the correct samples_per_symbol for that duration,
% computes threshold and BER, and returns a summary struct sorted by symbol duration.
%
% INPUTS
%   etLabel - encoding technique label, e.g. 'et1', 'et2'
%
% OUTPUTS
%   results - struct array (one element per symbol duration) with fields:
%       .symbolDuration   - symbol duration in seconds
%       .threshold        - computed threshold (mean-of-means)
%       .decoded_bits     - decoded bit vector
%       .tx_bits          - transmitted bit vector
%       .BER              - bit error rate
%       .num_errors       - number of bit errors
%       .num_bits         - number of transmitted bits
%       .peak_per_symbol  - peak molecule count per symbol period
%       .rx_counts        - full raw received molecule count time-series

    % --- paths ---
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    dt = 2;   % global microscopic time step (seconds)

    % --- find all symbol duration result files for this ET ---
    resultsDir = fullfile(accordRoot, 'bin', 'results');
    pattern = [etLabel '_symbol_duration_*_SEED1.txt'];
    listing = dir(fullfile(resultsDir, pattern));

    if isempty(listing)
        error('No symbol duration result files found for %s in %s', etLabel, resultsDir);
    end

    % Parse symbol duration from filenames
    %  e.g. et1_symbol_duration_300_SEED1.txt
    symDurations = zeros(length(listing), 1);
    keep         = true(length(listing), 1);

    for k = 1:length(listing)
        name = listing(k).name;
        name = strrep(name, '_SEED1.txt', '');                          % et1_symbol_duration_300
        name = strrep(name, [etLabel '_symbol_duration_'], '');         % 300
        val  = str2double(name);
        if isnan(val)
            keep(k) = false;   % skip non-numeric (e.g. "comparison")
        else
            symDurations(k) = val;
        end
    end

    listing      = listing(keep);
    symDurations = symDurations(keep);

    % Sort by symbol duration
    [symDurations, sortIdx] = sort(symDurations);
    listing = listing(sortIdx);

    numFiles = length(symDurations);
    fprintf('\n=== Decoding %s Symbol Durations – %d files found ===\n', upper(etLabel), numFiles);

    % Pre-allocate output struct
    results = struct('symbolDuration',  num2cell(symDurations'), ...
                     'threshold',       [], ...
                     'decoded_bits',    [], ...
                     'tx_bits',         [], ...
                     'BER',             [], ...
                     'num_errors',      [], ...
                     'num_bits',        [], ...
                     'peak_per_symbol', [], ...
                     'rx_counts',       []);

    % --- decode each file ---
    for k = 1:numFiles
        file = fullfile(resultsDir, listing(k).name);
        sd   = symDurations(k);
        samples_per_symbol = sd / dt;

        fprintf('\n--- %d s  (%s) ---\n', sd, listing(k).name);

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
        tx_text  = regexprep(tx_text, '^ActiveActor\s+0:\s*', '');
        tx_bits  = sscanf(tx_text, '%d');
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
        fprintf('Samples/symbol: %d\n', samples_per_symbol);
        fprintf('TX bits (%d): ', num_symbols);
        fprintf('%d', tx_bits); fprintf('\n');
        fprintf('RX bits (%d): ', num_symbols);
        fprintf('%d', decoded);  fprintf('\n');
        fprintf('Threshold : %.2f\n', threshold);
        fprintf('BER       : %.4f  (%d / %d errors)\n', BER, num_errors, num_symbols);
    end

    % ---- summary table ----
    fprintf('\n\n========== %s SYMBOL DURATION SUMMARY ==========\n', upper(etLabel));
    fprintf('%-15s  %-12s  %-10s  %-10s\n', 'Symbol Dur (s)', 'Threshold', 'BER', 'Errors');
    fprintf('%s\n', repmat('-', 1, 52));
    for k = 1:numFiles
        fprintf('%-15s  %-12.2f  %-10.4f  %d / %d\n', ...
            sprintf('%d s', results(k).symbolDuration), ...
            results(k).threshold, results(k).BER, ...
            results(k).num_errors, results(k).num_bits);
    end
    fprintf('\n');
end
