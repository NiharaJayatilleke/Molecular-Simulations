function plotET1ModThresholds()
% plotET1ModThresholds - Visualise received signal & threshold for all ET1
%                        modulation strengths (1e2 … 1e6) in one figure.
%
% Each subplot shows:
%   - peak molecule count per symbol period (blue stems)
%   - threshold (red dashed line)
%   - transmitted bits (green step)
%   - decoded bits (markers: correct = blue circle, error = red x)
%
% USAGE:
%   plotET1ModThresholds()

    % --- paths ---
    scriptDir  = fileparts(mfilename('fullpath'));
    accordRoot = fileparts(scriptDir);
    addpath(accordRoot);
    addpath(scriptDir);
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    modLabels  = {'1e2','1e3','1e4','1e5','1e6'};
    modValues  = [1e2, 1e3, 1e4, 1e5, 1e6];
    numMod     = length(modLabels);

    samples_per_symbol = 150;   % 300 s / 2 s

    hFig = figure('Color','w','Name','ET1 Modulation Strength – Thresholds',...
                  'Units','normalized','Position',[0.05 0.05 0.9 0.85]);

    for k = 1:numMod
        name = ['et1_modulation_strength_' modLabels{k} '_10'];

        % --- read result file ---
        file = fullfile(accordRoot,'bin','results',[name '_SEED1.txt']);
        text = fileread(file);

        % transmitted bits
        tx_start = strfind(text,'ActiveActor 0:');
        tx_end   = strfind(text,'PassiveActor 1:');
        tx_text  = text(tx_start:tx_end);
        tx_bits  = sscanf(tx_text,'%*[^0-1]%d');
        num_symbols = length(tx_bits);

        % received counts (first passive actor)
        passive_pattern = 'PassiveActor \d+:';
        [pStarts, ~] = regexp(text, passive_pattern);
        if length(pStarts) >= 2
            rx_text = text(pStarts(1):pStarts(2)-1);
        else
            rx_text = text(pStarts(1):end);
        end
        cIdx = strfind(rx_text,'Count:');
        count_text = rx_text(cIdx(1):end);
        rx_counts  = sscanf(count_text,'%*[^0-9]%d');

        % peak per symbol
        peakPerSymbol = zeros(num_symbols,1);
        for s = 1:num_symbols
            si = (s-1)*samples_per_symbol + 1;
            ei = s*samples_per_symbol;
            if ei <= length(rx_counts)
                peakPerSymbol(s) = max(rx_counts(si:ei));
            end
        end

        % threshold & decoded bits
        zeroVals  = peakPerSymbol(tx_bits == 0);
        oneVals   = peakPerSymbol(tx_bits == 1);
        threshold = (mean(zeroVals) + mean(oneVals)) / 2;
        decoded   = double(peakPerSymbol >= threshold);

        errors   = (decoded ~= tx_bits);
        BER      = sum(errors) / num_symbols;

        % --- subplot ---
        subplot(numMod, 1, k);
        hold on;

        % stem of peak counts
        stem(1:num_symbols, peakPerSymbol, 'filled', ...
             'Color',[0.2 0.4 0.8],'MarkerSize',4,'LineWidth',1.2);

        % threshold line
        yline(threshold, 'r--', 'LineWidth', 1.5);

        % mark correct / error symbols
        correctIdx = find(~errors);
        errorIdx   = find(errors);
        plot(correctIdx, peakPerSymbol(correctIdx), 'bo', 'MarkerSize', 6);
        plot(errorIdx,   peakPerSymbol(errorIdx),   'rx', 'MarkerSize', 9, 'LineWidth', 2);

        % transmitted bit labels along x-axis
        for s = 1:num_symbols
            txColor = [0 0.5 0];
            text(s, -0.08 * max(peakPerSymbol+1), num2str(tx_bits(s)), ...
                 'HorizontalAlignment','center','FontSize',7,'Color',txColor);
        end

        hold off;
        xlim([0 num_symbols+1]);
        ylabel('Peak count');
        title(sprintf('Mod Strength %s  |  Threshold = %.1f  |  BER = %.4f  (%d errors / %d bits)', ...
              modLabels{k}, threshold, BER, sum(errors), num_symbols), 'FontSize', 10);
        set(gca,'FontSize',9);
        grid on;

        if k == numMod
            xlabel('Symbol index');
        end
    end

    sgtitle('ET1 Encoding – All Modulation Strengths with Thresholds', 'FontSize', 13, 'FontWeight', 'bold');
end
