function ber = computeBER(resultFile, txBits, symbolDuration, threshold, passiveActorIdx, molIdx)
%
% computeBER - Compute Bit Error Rate from AcCoRD simulation results
%
% USAGE:
%   ber = computeBER(resultFile, txBits, symbolDuration, threshold)
%   ber = computeBER(resultFile, txBits, symbolDuration, threshold, passiveActorIdx, molIdx)
%
% INPUTS:
%   resultFile      - Path to result file (with or without _out.mat extension)
%   txBits          - Vector of transmitted bits (0s and 1s)
%   symbolDuration  - Duration of each symbol/bit in seconds
%   threshold       - Molecule count threshold for deciding bit 1 vs 0
%   passiveActorIdx - (Optional) Index of passive actor to use. Default: 1
%   molIdx          - (Optional) Index of molecule type to use. Default: 1
%
% OUTPUT:
%   ber - Bit Error Rate (0 to 1)
%
% EXAMPLE:
%   txBits = [1 0 1 1 0 0 1 0];
%   ber = computeBER('et1_distance_5_10_20_out', txBits, 0.2, 40);

% Set defaults
if nargin < 5
    passiveActorIdx = 1;
end
if nargin < 6
    molIdx = 1;
end

% Ensure file has proper extension
if ~endsWith(resultFile, '.mat')
    if ~endsWith(resultFile, '_out')
        resultFile = strcat(resultFile, '_out');
    end
    resultFile = strcat(resultFile, '.mat');
end

% Check if file exists
if ~exist(resultFile, 'file')
    error('Result file not found: %s', resultFile);
end

% Load the data
loadedData = load(resultFile, 'data');
data = loadedData.data;

% Extract time and count data from passive actor
% Data structure from accordImport:
%   data.passiveRecordTime{actorIdx}(realization, timePoints)
%   data.passiveRecordCount{actorIdx}(realization, molType, timePoints)

% Get molecule counts - average across all realizations
% Shape: (numRealizations, numMolTypes, numTimePoints)
countData = data.passiveRecordCount{passiveActorIdx};
if ndims(countData) == 3
    % Average across realizations (dim 1), select molType (dim 2)
    cumulativeCount = squeeze(mean(countData(:, molIdx, :), 1));
else
    % Already 2D
    cumulativeCount = squeeze(mean(countData, 1));
end

% Ensure count is a row vector
cumulativeCount = cumulativeCount(:)';

% IMPORTANT: Counts are CUMULATIVE - convert to per-interval counts
count = [cumulativeCount(1), diff(cumulativeCount)];

% Generate time based on action interval (2.0s from receiver config)
actionInterval = 2.0;  % From receiver Action Interval in config
numPoints = length(count);
time = (0:numPoints-1) * actionInterval;

% Sample once per symbol period by SUMMING molecules in each period
% This is more robust than sampling at a single point
numSymbols = length(txBits);
samplesPerSymbol = symbolDuration / actionInterval;  % e.g., 300/2 = 150

% Calculate sum of molecules received during each bit period
rxSum = zeros(1, numSymbols);
for i = 1:numSymbols
    startIdx = round((i-1) * samplesPerSymbol) + 1;
    endIdx = min(round(i * samplesPerSymbol), length(count));
    
    if startIdx <= length(count)
        rxSum(i) = sum(count(startIdx:endIdx));
    end
end

% Ensure we don't exceed available data
maxValidBits = floor(length(count) / samplesPerSymbol);
numValidSymbols = min(numSymbols, maxValidBits);

if numValidSymbols < numSymbols
    warning('Only %d of %d symbols fit within simulation data', ...
        numValidSymbols, numSymbols);
end

% Decode received bits using threshold
rxBits = zeros(1, numValidSymbols);
for i = 1:numValidSymbols
    if rxSum(i) > threshold
        rxBits(i) = 1;
    else
        rxBits(i) = 0;
    end
end

% Compute BER
txBitsValid = txBits(1:numValidSymbols);
errors = sum(rxBits ~= txBitsValid);
ber = errors / numValidSymbols;

% Display results
fprintf('TX: %s\n', num2str(txBitsValid));
fprintf('RX: %s\n', num2str(rxBits));
fprintf('Errors: %d / %d, BER = %.4f\n', errors, numValidSymbols, ber);

end
