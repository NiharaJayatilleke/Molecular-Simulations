%% debugBER_detailed.m
% Detailed debug to see exactly what's being compared at each distance

% Parameters
resultFile = '/Users/nihara/Downloads/AcCoRD-1.4.2/et1_distance_5_10_20_out.mat';
load(resultFile, 'data');

txBits = [0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0];
symbolDuration = 300.0;
actionInterval = 2.0;
samplesPerSymbol = symbolDuration / actionInterval;

thresholds = [1557, 1151, 323];  % For 5cm, 10cm, 20cm
distances = [5, 10, 20];

fprintf('=== Detailed BER Debug for ET1 ===\n');
fprintf('Samples per symbol: %.0f\n\n', samplesPerSymbol);

for actorIdx = 1:3
    fprintf('========== Distance %d cm (Passive Actor %d) ==========\n', distances(actorIdx), actorIdx);
    fprintf('Threshold: %d\n\n', thresholds(actorIdx));
    
    % Extract data
    countData = data.passiveRecordCount{actorIdx};
    cumulativeCount = squeeze(countData(1, 1, :))';
    diffCount = [cumulativeCount(1), diff(cumulativeCount)];
    
    numPoints = length(diffCount);
    numBits = length(txBits);
    
    % Calculate sum per symbol
    rxSum = zeros(1, numBits);
    for i = 1:numBits
        startIdx = round((i-1) * samplesPerSymbol) + 1;
        endIdx = min(round(i * samplesPerSymbol), numPoints);
        if startIdx <= numPoints
            rxSum(i) = sum(diffCount(startIdx:endIdx));
        end
    end
    
    % Decode
    rxBits = rxSum > thresholds(actorIdx);
    
    % Show comparison
    fprintf('Bit | TX | RX_Sum    | Threshold | RX | Match?\n');
    fprintf('----|----|-----------|-----------|----|-------\n');
    errors = 0;
    for i = 1:numBits
        match = (txBits(i) == rxBits(i));
        if ~match
            errors = errors + 1;
        end
        matchStr = 'YES';
        if ~match
            matchStr = '** NO **';
        end
        fprintf('%3d | %d  | %9.1f | %9d | %d  | %s\n', ...
            i, txBits(i), rxSum(i), thresholds(actorIdx), rxBits(i), matchStr);
    end
    
    ber = errors / numBits;
    fprintf('\nTotal Errors: %d / %d = BER %.4f\n\n', errors, numBits, ber);
end
