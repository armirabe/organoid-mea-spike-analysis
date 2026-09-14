function spk = detect_spikes(x, p)
%DETECT_SPIKES Threshold-crossing spike detection on a filtered channel.
%
%   spk = DETECT_SPIKES(x, p) detects negative-going threshold crossings in
%   the filtered signal x. The threshold is -p.thresh_mult * sigma, where
%   sigma is the median absolute deviation estimate of the noise standard
%   deviation (Quiroga et al., 2004):
%
%       sigma = median(|x|) / 0.6745
%
%   After each detection the search index advances by the post-spike window,
%   enforcing a refractory period of p.post_ms so a single spike is not
%   counted more than once.
%
%   Returned fields:
%       idx         sample indices of detected spikes
%       waveforms   nSpikes x nSamples matrix of aligned waveforms
%       amplitudes  trough amplitude of each spike (uV, negative)
%       durations   full width at half minimum of each spike (ms)
%       n           number of spikes detected
%       threshold   detection threshold used (uV)
%       sigma       noise estimate (uV)
%       t_ms        time axis for the waveform window (ms)
%
%   See also PREPROCESS_CHANNEL, CHANNEL_METRICS.

pre  = round(p.pre_ms  * p.sf / 1000);
post = round(p.post_ms * p.sf / 1000);
n    = numel(x);

sigma     = median(abs(x)) / 0.6745;
threshold = -p.thresh_mult * sigma;

% Preallocate generously, then trim. Growing these arrays inside the loop
% was the dominant cost in the original scripts on long recordings.
max_spikes = max(1, ceil(n / max(post, 1)));
idx        = zeros(1, max_spikes);
waveforms  = zeros(max_spikes, pre + post + 1);
amplitudes = zeros(1, max_spikes);
durations  = nan(1, max_spikes);

count = 0;
i     = pre + 1;

while i <= n - post
    if x(i) < threshold
        w = x(i - pre : i + post);
        [amp, k] = min(w);

        % Full width at half minimum.
        half  = amp / 2;
        left  = find(w(1:k)   >= half, 1, 'last');
        right = find(w(k:end) >= half, 1, 'first') + k - 1;
        if isempty(left) || isempty(right)
            dur = NaN;
        else
            dur = (right - left) / p.sf * 1000;
        end

        count              = count + 1;
        idx(count)         = i;
        waveforms(count,:) = w;
        amplitudes(count)  = amp;
        durations(count)   = dur;

        i = i + post;   % refractory skip
    else
        i = i + 1;
    end
end

spk.idx        = idx(1:count);
spk.waveforms  = waveforms(1:count, :);
spk.amplitudes = amplitudes(1:count);
spk.durations  = durations(1:count);
spk.n          = count;
spk.threshold  = threshold;
spk.sigma      = sigma;
spk.t_ms       = (-pre:post) / p.sf * 1000;
end
