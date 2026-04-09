function [thresholds, decoded_bits, BERs] = accordDecode(filename)
% accordDecode - Decode AcCoRD simulation output and calculate BER for all passive actors
%   [thresholds, decoded_bits, BERs] = accordDecode('et1_distance_5_10_20')
%
% INPUTS
%   filename - name of the simulation result file (without path)
%
% OUTPUTS
%   thresholds   - threshold for each passive actor (array)
%   decoded_bits - decoded bit sequence for each passive actor (cell array)
%   BERs         - bit error rate for each passive actor (array)

    % Get the root directory (where this script lives)
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    
    % Add required paths
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    
    % Change to AcCoRD root directory
    cd(accordRoot);
    
    fprintf('AcCoRD paths loaded.\n');
    
    % Build file path (add _SEED1.txt suffix)
    file = fullfile(accordRoot, 'bin', 'results', [filename '_SEED1.txt']);
    
    fprintf('Decoding: %s\n\n', file);

    % Read file
    text = fileread(file);

    % Extract transmitted bits
    tx_start = strfind(text, 'ActiveActor 0:');
    tx_end   = strfind(text, 'PassiveActor 1:');

    tx_text = text(tx_start:tx_end);

    tx_bits = sscanf(tx_text, '%*[^0-1]%d');
    num_symbols = length(tx_bits);

    % Symbol duration (SET THIS from your simulation)
    % Action Interval = 300s, Global Microscopic Time Step = 2s
    % samples_per_symbol = 300 / 2 = 150
    samples_per_symbol = 150;

    % Find all passive actors
    passive_pattern = 'PassiveActor \d+:';
    [passive_starts, passive_ends] = regexp(text, passive_pattern);
    num_passive = length(passive_starts);
    
    % Initialize outputs
    thresholds = zeros(num_passive, 1);
    decoded_bits = cell(num_passive, 1);
    BERs = zeros(num_passive, 1);
    
    fprintf('=== Transmitted bits ===\n');
    fprintf('%d', tx_bits);
    fprintf('\n\n');

    for actor_idx = 1:num_passive
        % Find the start of this passive actor's data
        actor_start = passive_starts(actor_idx);
        
        % Find the end (either next PassiveActor or end of file)
        if actor_idx < num_passive
            actor_end = passive_starts(actor_idx + 1) - 1;
        else
            actor_end = length(text);
        end
        
        rx_text = text(actor_start:actor_end);
        
        % Find "Count:" and extract numbers after it
        count_start = strfind(rx_text, 'Count:');
        if isempty(count_start)
            fprintf('PassiveActor %d: No count data found\n', actor_idx);
            continue;
        end
        
        count_text = rx_text(count_start(1):end);
        rx_counts = sscanf(count_text, '%*[^0-9]%d');
        
        % Calculate symbol values (max within each symbol period)
        rx_symbol_values = zeros(num_symbols, 1);
        
        for i = 1:num_symbols
            start_idx = (i-1)*samples_per_symbol + 1;
            end_idx   = i*samples_per_symbol;
            
            if end_idx <= length(rx_counts)
                rx_symbol_values(i) = max(rx_counts(start_idx:end_idx));
            end
        end

        % Compute threshold
        zero_values = rx_symbol_values(tx_bits == 0);
        one_values  = rx_symbol_values(tx_bits == 1);

        threshold = (mean(zero_values) + mean(one_values)) / 2;
        thresholds(actor_idx) = threshold;

        % Decode bits
        decoded = double(rx_symbol_values >= threshold);
        decoded_bits{actor_idx} = decoded;

        % Compute BER
        BER = sum(decoded ~= tx_bits) / num_symbols;
        BERs(actor_idx) = BER;
        
        fprintf('=== PassiveActor %d ===\n', actor_idx);
        fprintf('Threshold: %.2f\n', threshold);
        fprintf('BER: %.4f\n', BER);
        fprintf('Decoded bits: ');
        fprintf('%d', decoded);
        fprintf('\n\n');
    end

end
