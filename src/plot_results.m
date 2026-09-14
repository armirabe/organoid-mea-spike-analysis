function plot_results(S, density, t_density, p)
%PLOT_RESULTS Standard figure set for an analysed recording.
%
%   PLOT_RESULTS(S, density, t_density, p) draws:
%       Figure 1  per-channel spike waveforms with the mean overlaid
%       Figure 2  stacked filtered traces
%       Figure 3  raster, coloured by spike amplitude
%       Figure 4  mean spike duration per channel with error bars
%       Figure 5  mean spike amplitude per channel with error bars
%       Figure 6  firing rate density heat map
%       Figure 7  population firing rate over time
%
%   See also ANALYZE_RECORDING, FIRING_RATE_DENSITY.

n_ch     = numel(S);
channels = [S.channel];
n_cols   = ceil(sqrt(n_ch));
n_rows   = ceil(n_ch / n_cols);

AMP_MIN = 100;   % uV, low end of the raster colour scale
AMP_MAX = 300;   % uV, high end of the raster colour scale
sunset  = [0.1 0 0.3; 0.5 0 0.5; 0.8 0 0.2; 1 0.5 0; 1 0.8 0.2; 1 1 0.6];

% --- Figure 1: waveforms ----------------------------------------------
figure(1); clf
for k = 1:n_ch
    subplot(n_rows, n_cols, k); hold on
    spk = S(k).spk;
    if spk.n > 0
        plot(spk.t_ms, spk.waveforms', 'Color', '#dbd9e2', 'LineWidth', 0.5);
        plot(spk.t_ms, mean(spk.waveforms, 1), 'Color', '#250e62', 'LineWidth', 2);
        lim = max(abs(spk.waveforms(:)));
        ylim([-lim lim]);
    else
        ylim([-100 100]);
    end
    title(sprintf('Ch %d | %d spikes', channels(k), spk.n));
    xlabel('Time (ms)'); ylabel('Voltage (uV)');
    hold off
end

% --- Figure 2: stacked filtered traces --------------------------------
figure(2); clf; hold on
for k = 1:n_ch
    x = S(k).filtered;
    tt = (1:numel(x)) / p.sf;
    plot(tt, x * 0.4 / max(abs(x)) + k);
end
title('Filtered data - all channels');
xlabel('Time (s)'); ylabel('Channel');
ylim([0.5, n_ch + 0.5]); yticks(1:n_ch); yticklabels(string(channels));
hold off

% --- Figure 3: amplitude-coloured raster -------------------------------
figure(3); clf; hold on
for k = 1:n_ch
    spk = S(k).spk;
    if spk.n == 0, continue; end
    norm_amp = (abs(spk.amplitudes) - AMP_MIN) / (AMP_MAX - AMP_MIN);
    norm_amp = max(0, min(norm_amp, 1));
    cmap     = interp1(linspace(0, 1, size(sunset, 1)), sunset, norm_amp);
    if spk.n == 1, cmap = reshape(cmap, 1, 3); end
    for s = 1:spk.n
        plot([spk.idx(s), spk.idx(s)] / p.sf, [k - 0.4, k + 0.4], ...
             'Color', cmap(s, :), 'LineWidth', 1.5);
    end
end
title('Raster - all channels');
xlabel('Time (s)'); ylabel('Channel');
ylim([0.5, n_ch + 0.5]); yticks(1:n_ch); yticklabels(string(channels));
colormap(gca, sunset);
c = colorbar;
c.Ticks        = linspace(0, 1, 6);
c.TickLabels   = round(linspace(AMP_MIN, AMP_MAX, 6), 1);
c.Label.String = 'Spike amplitude (uV)';
hold off

% --- Figures 4 and 5: per-channel bar summaries ------------------------
dur_mean = arrayfun(@(s) s.metrics.mean_duration_ms,  S);
dur_std  = arrayfun(@(s) s.metrics.std_duration_ms,   S);
amp_mean = abs(arrayfun(@(s) s.metrics.mean_amplitude_uv, S));
amp_std  = arrayfun(@(s) s.metrics.std_amplitude_uv,  S);

figure(4); clf; hold on
bar(1:n_ch, dur_mean, 'FaceColor', '#250e62');
errorbar(1:n_ch, dur_mean, dur_std, 'LineStyle', 'none', 'Color', 'r');
title('Mean spike duration'); xlabel('Channel'); ylabel('Duration (ms)');
xticks(1:n_ch); xticklabels(string(channels)); hold off

figure(5); clf; hold on
bar(1:n_ch, amp_mean, 'FaceColor', '#8b0000');
errorbar(1:n_ch, amp_mean, amp_std, 'LineStyle', 'none', 'Color', 'b');
title('Mean spike amplitude'); xlabel('Channel'); ylabel('|Amplitude| (uV)');
xticks(1:n_ch); xticklabels(string(channels)); hold off

% --- Figures 6 and 7: firing rate density ------------------------------
if nargin >= 3 && ~isempty(density)
    figure(6); clf
    imagesc(t_density, 1:n_ch, density);
    colormap(gca, parula); colorbar;
    ylabel('Channel'); xlabel('Time (s)');
    yticks(1:n_ch); yticklabels(string(channels));
    title('Local firing rate (Hz)');
    axis tight

    figure(7); clf
    plot(t_density, mean(density, 1), 'Color', '#250e62', 'LineWidth', 1.5);
    title('Population firing rate');
    xlabel('Time (s)'); ylabel('Spikes/s per channel');
    xlim([t_density(1), t_density(end)]);
end
end
