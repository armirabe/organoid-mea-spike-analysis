function m = channel_metrics(spk, p, duration_s)
%CHANNEL_METRICS Summary statistics for one channel's detected spikes.
%
%   m = CHANNEL_METRICS(spk, p, duration_s) computes spike duration and
%   amplitude statistics, and two firing rate estimates:
%
%       firing_rate_hz  spike count divided by recording duration
%       isi_rate_hz     reciprocal of the mean inter-spike interval
%
%   The two differ when firing is bursty: the ISI-based rate weights active
%   periods more heavily, so reporting both is informative.
%
%   Rates are returned as NaN when fewer than two spikes were detected,
%   because a single spike yields no interval to average.
%
%   See also DETECT_SPIKES, ANALYZE_RECORDING.

m.n_spikes          = spk.n;
m.mean_duration_ms  = mean(spk.durations,  'omitnan');
m.std_duration_ms   = std(spk.durations,   'omitnan');
m.mean_amplitude_uv = mean(spk.amplitudes, 'omitnan');
m.std_amplitude_uv  = std(spk.amplitudes,  'omitnan');

if spk.n > 1
    m.firing_rate_hz    = spk.n / duration_s;
    isi                 = diff(spk.idx) / p.sf;
    m.isi_rate_hz       = 1 / mean(isi);
    m.active_spiking_s  = sum(spk.durations, 'omitnan') / 1000;
else
    m.firing_rate_hz    = NaN;
    m.isi_rate_hz       = NaN;
    m.active_spiking_s  = NaN;
    m.mean_amplitude_uv = NaN;
    m.std_amplitude_uv  = NaN;
end
end
