function [density, t] = firing_rate_density(timestamps, n_samples, p)
%FIRING_RATE_DENSITY Smoothed per-channel firing rate over time.
%
%   [density, t] = FIRING_RATE_DENSITY(timestamps, n_samples, p) bins each
%   channel's spike times at p.density_bin_s resolution and convolves the
%   binned counts with a Gaussian kernel of standard deviation
%   p.density_sigma_s. density is nChannels x nBins in Hz; t is the bin
%   centre time in seconds.
%
%   NOTE ON REPRODUCIBILITY: this is a reimplementation. The original script
%   convolved a full-resolution binary spike vector with a kernel whose width
%   and standard deviation were coupled in a nonstandard way, so absolute
%   values here will not match the original figures even though the shape of
%   the rate over time is preserved. See PORTING_NOTES.md.
%
%   See also ANALYZE_RECORDING.

bin_s   = p.density_bin_s;
edges   = 0 : bin_s : (n_samples / p.sf);
if numel(edges) < 2
    error('firing_rate_density:shortRecording', ...
          'Recording is shorter than one density bin.');
end
t       = edges(1:end-1) + bin_s / 2;

n_ch    = numel(timestamps);
density = zeros(n_ch, numel(t));

% Gaussian kernel truncated at +/- 3 standard deviations.
sigma_bins = max(p.density_sigma_s / bin_s, eps);
half       = ceil(3 * sigma_bins);
tt         = -half:half;
kernel     = exp(-tt.^2 / (2 * sigma_bins^2));
kernel     = kernel / sum(kernel);

for c = 1:n_ch
    if isempty(timestamps{c})
        continue
    end
    counts       = histcounts(timestamps{c} / p.sf, edges);
    density(c,:) = conv(counts / bin_s, kernel, 'same');
end
end
