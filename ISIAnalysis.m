% =========================================================================
% ISI Level Analysis — All Encoding Techniques
% Generates 3 figures matching the Python analysis output
%
% USAGE:
%   1. Place this file in the same folder as your AcCoRD output .txt files
%   2. Update the file names in the "File Configuration" section if needed
%   3. Run the script
%
% REQUIREMENTS: MATLAB R2019b or later (uses tiledlayout, boxchart)
% =========================================================================

clear; clc; close all;

%% ── File Configuration ───────────────────────────────────────────────────
% Update these paths if your files are in a different folder
this_dir = fileparts(mfilename('fullpath'));
file_dir = fullfile(this_dir, 'bin', 'results');   % default AcCoRD results folder

files = {
    'ET1 (ISI-mtg)',      'et1_distance_10_SEED1.txt';
    'ET2 (RLIM)',         'et2_distance_10_SEED1.txt';
    'ET3 (Mod. Huffman)', 'et3_distance_10_SEED1.txt';
    'ET4 (4,2,1)',        'et4_distance_10_SEED1.txt';
    'ET5 (SEC)',          'et5_distance_10_SEED1.txt';
};

n_ET   = size(files, 1);
Ns     = 150;    % samples per symbol (Tsym=300s / Tsample=2s)

%% ── Colours & Markers (consistent with thesis BER plots) ─────────────────
clrs = [
    0.122, 0.467, 0.706;   % ET1 blue
    1.000, 0.498, 0.055;   % ET2 orange
    0.173, 0.627, 0.173;   % ET3 green
    0.839, 0.153, 0.157;   % ET4 red
    0.580, 0.404, 0.741;   % ET5 purple
];
mrks = {'o','s','^','d','v'};

%% ── Parse AcCoRD Files ───────────────────────────────────────────────────
ET = struct();
for k = 1:n_ET
    fpath = resolve_result_file(file_dir, files{k,2}, this_dir);
    [bits, counts] = parse_accord(fpath);
    n_bits         = numel(bits);
    peaks          = compute_peaks(counts, n_bits, Ns);
    isi            = compute_isi(counts, n_bits, Ns);
    ET(k).label    = files{k,1};
    ET(k).bits     = bits;
    ET(k).counts   = counts;
    ET(k).peaks    = peaks;
    ET(k).isi      = isi;
    ET(k).n_bits   = n_bits;
end

%% ── Summary Statistics ───────────────────────────────────────────────────
fprintf('\n%-25s %6s %10s %10s %12s %12s\n', ...
    'Encoding','N_bits','Mean ISI','Max ISI','ISI@1-bits','ISI@0-bits');
fprintf('%s\n', repmat('-',1,80));

summary_mean  = zeros(1, n_ET);
summary_mean1 = zeros(1, n_ET);
summary_mean0 = zeros(1, n_ET);
summary_max   = zeros(1, n_ET);

for k = 1:n_ET
    isi_valid  = ET(k).isi(2:end);          % skip window 0
    bits_valid = ET(k).bits(2:end);
    mean_isi   = mean(isi_valid);
    max_isi    = max(isi_valid);
    idx1       = bits_valid == 1;
    idx0       = bits_valid == 0;
    mean_isi1  = mean(isi_valid(idx1));
    mean_isi0  = mean(isi_valid(idx0));
    summary_mean(k)  = mean_isi;
    summary_mean1(k) = mean_isi1;
    summary_mean0(k) = mean_isi0;
    summary_max(k)   = max_isi;
    fprintf('%-25s %6d %10.4f %10.4f %12.4f %12.4f\n', ...
        ET(k).label, ET(k).n_bits, mean_isi, max_isi, mean_isi1, mean_isi0);
end

%% ═════════════════════════════════════════════════════════════════════════
%  FIGURE 1 — ISI Level per Symbol Window (stacked subplots)
%% ═════════════════════════════════════════════════════════════════════════
fig1 = figure('Name','ISI per Symbol Window', ...
              'Color','w', ...
              'Position',[100 50 1100 950]);

t = tiledlayout(n_ET, 1, 'TileSpacing','compact', 'Padding','compact');
title(t, {'ISI Level per Symbol Window — All Encoding Techniques', ...
          '(10 cm, 10^6 molecules, 300 s symbol duration)'}, ...
    'FontSize',13, 'FontWeight','bold');

for k = 1:n_ET
    ax = nexttile;
    set(ax, 'Color', 'w');
    bits = ET(k).bits;
    isi  = ET(k).isi;
    x    = 0:(numel(isi)-1);

    % Grey shading for bit-1 windows
    hold on;
    for i = 1:numel(bits)
        if bits(i) == 1
            patch([i-1.5 i-0.5 i-0.5 i-1.5], [0 0 1.05 1.05], ...
                  [0.82 0.82 0.82], 'EdgeColor','none', 'FaceAlpha',0.5);
        end
    end

    % ISI line
    plot(x, isi, '-', 'Color', clrs(k,:), 'Marker', mrks{k}, ...
         'MarkerSize',5, 'LineWidth',1.8, 'DisplayName', ET(k).label);

    % Mean dashed line
    mean_val = mean(isi(2:end));
    yline(mean_val, '--k', 'LineWidth',1.0, ...
          'Label', sprintf('Mean = %.3f', mean_val), ...
          'LabelHorizontalAlignment','right', 'FontSize',8);

    % X tick labels: b1(0), b2(1), ...
    xtick_labels = arrayfun(@(i,b) sprintf('b%d\n(%d)',i,b), ...
        (1:numel(bits))', bits', 'UniformOutput', false);
    set(ax, 'XTick', x, 'XTickLabel', xtick_labels, 'FontSize', 7);
    xlim([-0.5, numel(isi)-0.5]);
    ylim([-0.02, 1.05]);
    ylabel('ISI Level', 'FontSize',9);
    grid on; grid minor;
    lgd1 = legend(ax, ET(k).label, 'Location','northeast', 'FontSize',9);
    set(lgd1, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
    hold off;
end
xlabel(t, 'Symbol Window (bit value in parentheses)', 'FontSize',11);

%% ═════════════════════════════════════════════════════════════════════════
%  FIGURE 2 — Mean ISI Comparison Bar Chart
%% ═════════════════════════════════════════════════════════════════════════
fig2 = figure('Name','Mean ISI Comparison', 'Color','w', 'Position',[200 200 850 520]);

labels_short = {'ET1 (ISI-mtg)','ET2 (RLIM)','ET3 (Mod. Huffman)', ...
                'ET4 (4,2,1)','ET5 (SEC)'};
x  = 1:n_ET;
w  = 0.26;

ax2 = axes(fig2);
set(ax2, 'Color', 'w');
hold on;

% Bar group 1 — Overall mean ISI
b1 = bar(x - w, summary_mean,  w, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',0.8);
% Bar group 2 — Mean ISI after 1-bit (hatch-like: use FaceAlpha)
b2 = bar(x,     summary_mean1, w, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',0.8, 'FaceAlpha',0.55);
% Bar group 3 — Mean ISI after 0-bit
b3 = bar(x + w, summary_mean0, w, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',0.8, 'FaceAlpha',0.30);

% Apply colours
for k = 1:n_ET
    b1.CData(k,:) = clrs(k,:);
    b2.CData(k,:) = clrs(k,:);
    b3.CData(k,:) = clrs(k,:);
end

% Value labels on bars
all_bars  = {b1, b2, b3};
all_vals  = {summary_mean, summary_mean1, summary_mean0};
for g = 1:3
    for k = 1:n_ET
        xpos = all_bars{g}.XData(k) + all_bars{g}.XOffset;
        yval = all_vals{g}(k);
        text(xpos, yval + 0.008, sprintf('%.3f', yval), ...
             'HorizontalAlignment','center', 'FontSize',7.5);
    end
end

set(ax2, 'XTick', x, 'XTickLabel', labels_short, 'FontSize',11);
ylabel('ISI Level (residual / peak)', 'FontSize',12);
title({'Mean ISI Level Comparison Across Encoding Schemes', ...
       '(10 cm, 10^6 molecules, 300 s symbol duration)'}, ...
      'FontSize',13, 'FontWeight','bold');
ylim([0, max([summary_mean, summary_mean1]) * 1.25]);
lgd2 = legend({'Overall Mean ISI','Mean ISI (after 1-bit)','Mean ISI (after 0-bit)'}, ...
        'FontSize',10, 'Location','northeast');
set(lgd2, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.7 0.7 0.7]);
grid on;
hold off;

%% ═════════════════════════════════════════════════════════════════════════
%  FIGURE 3 — ISI Level Box Plot
%% ═════════════════════════════════════════════════════════════════════════
fig3 = figure('Name','ISI Level Box Plot', 'Color','w', 'Position',[300 200 850 520]);
ax3  = axes(fig3);
set(ax3, 'Color', 'w');
hold on;

% Build combined data vector + group labels for boxchart
all_isi    = [];
all_groups = [];
for k = 1:n_ET
    isi_k      = ET(k).isi(2:end);   % skip window 0
    all_isi    = [all_isi;    isi_k(:)];
    all_groups = [all_groups; repmat(k, numel(isi_k), 1)];
end

bc = boxchart(all_groups, all_isi, 'BoxFaceAlpha',0.7, ...
              'MarkerStyle','+', 'LineWidth',1.2);

% Apply per-group colour
for k = 1:n_ET
    bc(1).BoxFaceColor = clrs(k,:);   % boxchart is a single object; colour via loop below
end

% boxchart doesn't support per-group colours natively in a single call,
% so we overlay individual boxcharts per group
delete(bc);
for k = 1:n_ET
    isi_k = ET(k).isi(2:end);
    boxchart(repmat(k, numel(isi_k), 1), isi_k(:), ...
             'BoxFaceColor', clrs(k,:), 'BoxFaceAlpha', 0.7, ...
             'MarkerStyle', '+', 'LineWidth', 1.2);
end

set(ax3, 'XTick', 1:n_ET, 'XTickLabel', labels_short, 'FontSize',11);
ylabel('ISI Level (residual / peak)', 'FontSize',12);
title({'ISI Level Distribution per Encoding Scheme', ...
       '(10 cm, 10^6 molecules, 300 s symbol duration)'}, ...
      'FontSize',13, 'FontWeight','bold');
ylim([0, 1.1]);
grid on;
hold off;

fprintf('\nAll 3 figures generated successfully.\n');

%% ═════════════════════════════════════════════════════════════════════════
%  LOCAL FUNCTIONS
%% ═════════════════════════════════════════════════════════════════════════

function [bits, counts] = parse_accord(fpath)
% Reads an AcCoRD output file and extracts the transmitted bit sequence
% and the PassiveActor molecule count time-series.
    txt = fileread(fpath);

    % --- transmitted bits (ActiveActor 0 line) ---
    tok_bits = regexp(txt, 'ActiveActor 0:\s*([\d\s]+)', 'tokens', 'once');
    if isempty(tok_bits)
        error('Could not find ActiveActor 0 in %s', fpath);
    end
    bits = str2double(strsplit(strtrim(tok_bits{1})));
    bits = bits(~isnan(bits));

    % --- receiver counts (Count: block) ---
    tok_cnt = regexp(txt, 'Count:\s*([\d\s]+)', 'tokens', 'once');
    if isempty(tok_cnt)
        error('Could not find Count block in %s', fpath);
    end
    counts = str2double(strsplit(strtrim(tok_cnt{1})));
    counts = counts(~isnan(counts));
end

function peaks = compute_peaks(counts, n_bits, Ns)
% Returns the peak molecule count within each symbol window.
    peaks = zeros(1, n_bits);
    for i = 1:n_bits
        idx_start = (i-1)*Ns + 1;
        idx_end   = min(i*Ns, numel(counts));
        if idx_start > numel(counts); break; end
        peaks(i) = max(counts(idx_start:idx_end));
    end
end

function isi = compute_isi(counts, n_bits, Ns)
% ISI_level_i = counts(first sample of window i) / peak(window i)
% Window 0 (i=1) has no prior symbol, so ISI = 0.
    isi = zeros(1, n_bits);
    for i = 2:n_bits
        idx_start = (i-1)*Ns + 1;
        idx_end   = min(i*Ns, numel(counts));
        if idx_start > numel(counts); break; end
        peak_i = max(counts(idx_start:idx_end));
        if peak_i == 0; continue; end
        residual  = counts(idx_start);   % tail of previous symbol
        isi(i)    = residual / peak_i;
    end
end

function fpath = resolve_result_file(file_dir, file_name, this_dir)
% Resolve result file across common AcCoRD locations.
    candidates = {
        fullfile(file_dir, file_name), ...
        fullfile(this_dir, 'bin', 'results', file_name), ...
        fullfile(this_dir, file_name), ...
        fullfile('.', 'bin', 'results', file_name), ...
        fullfile('.', file_name)
    };

    for i = 1:numel(candidates)
        if exist(candidates{i}, 'file') == 2
            fpath = candidates{i};
            return;
        end
    end

    error(['Could not find result file: %s\n', ...
           'Checked paths:\n  - %s\n  - %s\n  - %s\n  - %s\n  - %s'], ...
          file_name, candidates{1}, candidates{2}, candidates{3}, candidates{4}, candidates{5});
end