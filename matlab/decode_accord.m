function [threshold, decoded_bits, BER] = decode_accord(file)
% decode_accord - Decode AcCoRD simulation output and calculate BER
%   [threshold, decoded_bits, BER] = decode_accord('et1_distance_5_10_20_SEED1.txt')
%
% INPUTS
%   file - path to the simulation result file
%
% OUTPUTS
%   threshold    - optimal threshold for decoding
%   decoded_bits - decoded bit sequence
%   BER          - bit error rate

    % Read file
    text = fileread(file);

    % Extract transmitted bits
    tx_start = strfind(text, 'ActiveActor 0:');
    tx_end   = strfind(text, 'PassiveActor 1:');

    tx_text = text(tx_start:tx_end);

    tx_bits = sscanf(tx_text, '%*[^0-1]%d');

    % Extract received counts
    rx_start = strfind(text, 'PassiveActor 1:');
    rx_text = text(rx_start:end);

    rx_counts = sscanf(rx_text, '%*[^0-9]%d');

    % Symbol duration (SET THIS from your simulation)
    samples_per_symbol = 300;

    num_symbols = length(tx_bits);

    rx_symbol_values = zeros(num_symbols,1);

    for i = 1:num_symbols

        start_idx = (i-1)*samples_per_symbol + 1;
        end_idx   = i*samples_per_symbol;

        rx_symbol_values(i) = max(rx_counts(start_idx:end_idx));

    end

    % Compute threshold
    zero_values = rx_symbol_values(tx_bits==0);
    one_values  = rx_symbol_values(tx_bits==1);

    threshold = (mean(zero_values) + mean(one_values)) / 2;

    % Decode bits
    decoded_bits = rx_symbol_values >= threshold;

    % Compute BER
    BER = sum(decoded_bits ~= tx_bits) / length(tx_bits);

end

BERs = accordBER('et1_distance_5_10_20', 'et1_distance_5_10_20')
