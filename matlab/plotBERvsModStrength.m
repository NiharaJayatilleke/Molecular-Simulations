function hFig = plotBERvsModStrength()
% plotBERvsModStrength - Plot BER vs Modulation Strength for ET1 and ET2
%
% Computes the BER for each modulation strength (1e2, 1e3, 1e4, 1e5, 1e6)
% using accordBER, then plots two curves comparing ET1 and ET2 encoding.
%
% USAGE:
%   hFig = plotBERvsModStrength()
%
% OUTPUTS:
%   hFig - handle to the plotted figure

    % Setup paths
    scriptDir = fileparts(mfilename('fullpath'));
    accordRoot = fileparts(scriptDir);
    addpath(accordRoot);       % for accordBER / accordDecode
    addpath(scriptDir);        % matlab folder
    addpath(fullfile(accordRoot, 'JSONlab'));
    cd(accordRoot);

    % Modulation strength labels and numeric values for x-axis
    modLabels = {'1e2', '1e3', '1e4', '1e5', '1e6'};
    modValues = [1e2, 1e3, 1e4, 1e5, 1e6];
    numMod = length(modLabels);

    % Preallocate BER arrays
    ber_et1 = zeros(1, numMod);
    ber_et2 = zeros(1, numMod);

    % --- Compute BER for each modulation strength ---
    for k = 1:numMod
        % ET1
        name_et1 = ['et1_modulation_strength_' modLabels{k} '_10'];
        fprintf('\n========== ET1  %s ==========\n', modLabels{k});
        BERs = accordBER(name_et1, name_et1);
        ber_et1(k) = BERs(1);   % take first passive actor

        % ET2
        name_et2 = ['et2_modulation_strength_' modLabels{k} '_10'];
        fprintf('\n========== ET2  %s ==========\n', modLabels{k});
        BERs = accordBER(name_et2, name_et2);
        ber_et2(k) = BERs(1);   % take first passive actor
    end

    % --- Print summary table ---
    fprintf('\n\n===== BER Summary =====\n');
    fprintf('%-18s  %-10s  %-10s\n', 'Mod Strength', 'ET1 BER', 'ET2 BER');
    fprintf('%-18s  %-10s  %-10s\n', '----------', '-------', '-------');
    for k = 1:numMod
        fprintf('%-18s  %-10.4f  %-10.4f\n', modLabels{k}, ber_et1(k), ber_et2(k));
    end
    fprintf('\n');

    % --- Plot ---
    hFig = figure('Color', 'w', 'Name', 'BER vs Modulation Strength');
    hold on;

    plot(modValues, ber_et1, '-o', ...
        'Color', 'b', 'LineWidth', 2, 'MarkerSize', 8, ...
        'MarkerFaceColor', 'b', 'DisplayName', 'ET1');

    plot(modValues, ber_et2, '--s', ...
        'Color', 'r', 'LineWidth', 2, 'MarkerSize', 8, ...
        'MarkerFaceColor', 'r', 'DisplayName', 'ET2');

    set(gca, 'XScale', 'log');          % log scale for modulation strength
    xlabel('Modulation Strength (molecules)', 'FontSize', 12);
    ylabel('Bit Error Rate (BER)', 'FontSize', 12);
    title('BER vs Modulation Strength — ET1 vs ET2', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

    % Set y-axis limits nicely (0 to max + margin, or at least 0-1)
    yMax = max([ber_et1, ber_et2]);
    if yMax > 0
        ylim([0, min(1, yMax * 1.2 + 0.02)]);
    else
        ylim([0 1]);
    end

    hold off;
end
