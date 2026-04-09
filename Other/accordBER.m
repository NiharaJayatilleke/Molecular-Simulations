function BERs = accordBER(config_filename, result_filename)
% accordBER - Calculate BER by comparing config bit pattern with decoded bits
%   BERs = accordBER('et1_distance_5_10_20', 'et1_distance_5_10_20')
%
% INPUTS
%   config_filename - name of the config file (without path, without .txt)
%   result_filename - name of the result file (without path, without _SEED1.txt)
%
% OUTPUTS
%   BERs - bit error rate for each passive actor (array)

    % Get the root directory (where this script lives)
    [accordRoot, ~, ~] = fileparts(mfilename('fullpath'));
    
    % Add required paths
    addpath(fullfile(accordRoot, 'matlab'));
    addpath(fullfile(accordRoot, 'JSONlab'));
    
    % Change to AcCoRD root directory
    cd(accordRoot);
    
    fprintf('AcCoRD paths loaded.\n');
    
    % Read config file to get transmitted bit sequence
    config_file = fullfile(accordRoot, 'config', [config_filename '.txt']);
    fprintf('Reading config: %s\n', config_file);
    
    config_text = fileread(config_file);
    
    % Extract bit sequence from config using regex
    bit_pattern = regexp(config_text, '"Bit Sequence":\s*\[([\d,\s]+)\]', 'tokens');
    if isempty(bit_pattern)
        error('Could not find Bit Sequence in config file');
    end
    
    % Parse the bit sequence
    bit_str = bit_pattern{1}{1};
    tx_bits = sscanf(bit_str, '%d,')';
    tx_bits = tx_bits(:);  % Make column vector
    
    fprintf('\n=== Transmitted bits (from config) ===\n');
    fprintf('%d', tx_bits);
    fprintf('\n\n');
    
    % Get decoded bits from accordDecode
    [~, decoded_bits, ~] = accordDecode(result_filename);
    
    % Calculate BER for each passive actor
    num_passive = length(decoded_bits);
    BERs = zeros(num_passive, 1);
    num_bits = length(tx_bits);
    
    fprintf('\n=== BER Results ===\n');
    for actor_idx = 1:num_passive
        decoded = decoded_bits{actor_idx};
        
        % Trim decoded bits to match config length (remove extra bits at end)
        if length(decoded) > num_bits
            fprintf('PassiveActor %d: Trimming decoded from %d to %d bits\n', ...
                actor_idx, length(decoded), num_bits);
            decoded = decoded(1:num_bits);
        elseif length(decoded) < num_bits
            fprintf('PassiveActor %d: Warning - decoded has fewer bits (%d vs %d)\n', ...
                actor_idx, length(decoded), num_bits);
            continue;
        end
        
        % Calculate BER
        errors = sum(decoded ~= tx_bits);
        BER = errors / num_bits;
        BERs(actor_idx) = BER;
        
        fprintf('PassiveActor %d: %d errors / %d bits = BER %.4f\n', ...
            actor_idx, errors, num_bits, BER);
    end
    
    fprintf('\n');

end
