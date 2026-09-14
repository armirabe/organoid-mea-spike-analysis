function [T, S] = analyze_recording(data, p)
%ANALYZE_RECORDING Run the full spike analysis pipeline on a recording.
%
%   [T, S] = ANALYZE_RECORDING(data, p) processes every channel in data,
%   a nChannels x nSamples matrix of raw integer samples, using the
%   parameters in p (see DEFAULT_PARAMS).
%
%   Returns:
%       T   table of per-channel summary metrics
%       S   struct array with the full per-channel results, including
%           filtered traces, waveforms and spike times
%
%   Example:
%       p = default_params();
%       p.n_channels = 12;
%       [T, S] = analyze_recording(data, p);
%
%   See also DEFAULT_PARAMS, DETECT_SPIKES, CHANNEL_METRICS.

if ~ismatrix(data)
    error('analyze_recording:badInput', 'data must be a 2-D matrix.');
end

% Orient the matrix as channels x samples. Recordings always have far more
% samples than channels, so the longer dimension is time.
if size(data, 1) > size(data, 2)
    warning('analyze_recording:transposed', ...
            'data looks like samples x channels; transposing.');
    data = data.';
end

n_samples   = size(data, 2);
duration_s  = n_samples / p.sf;

if isempty(p.channels)
    channels = 1:min(p.n_channels, size(data, 1));
else
    channels = p.channels;
end

n_ch = numel(channels);
S    = struct('channel', cell(1, n_ch), 'filtered', [], 'spk', [], 'metrics', []);
rows = cell(n_ch, 1);

for k = 1:n_ch
    ch = channels(k);

    x   = preprocess_channel(data(ch, :), p);
    spk = detect_spikes(x, p);
    m   = channel_metrics(spk, p, duration_s);

    S(k).channel  = ch;
    S(k).filtered = x;
    S(k).spk      = spk;
    S(k).metrics  = m;

    rows{k} = [ch, m.n_spikes, m.mean_duration_ms, m.std_duration_ms, ...
               m.mean_amplitude_uv, m.std_amplitude_uv, ...
               m.firing_rate_hz, m.isi_rate_hz, m.active_spiking_s];

    fprintf('Channel %2d: %5d spikes, threshold %.1f uV\n', ...
            ch, spk.n, spk.threshold);
end

T = array2table(vertcat(rows{:}), 'VariableNames', { ...
    'channel', 'n_spikes', 'mean_duration_ms', 'std_duration_ms', ...
    'mean_amplitude_uv', 'std_amplitude_uv', ...
    'firing_rate_hz', 'isi_rate_hz', 'active_spiking_s'});
end
