function [data, truth] = synthetic_recording(p, varargin)
%SYNTHETIC_RECORDING Generate a surrogate extracellular recording.
%
%   [data, truth] = SYNTHETIC_RECORDING(p) returns a nChannels x nSamples
%   matrix of raw integer-scaled samples, in the same units the pipeline
%   expects (counts of p.scale_uv microvolts), so the demo exercises the
%   identical code path as a real file.
%
%   Name-value options:
%       'Duration'   recording length in seconds           (default 20)
%       'Rate'       mean firing rate per channel in Hz    (default 2)
%       'Amplitude'  mean spike trough amplitude in uV     (default 180)
%       'NoiseUv'    background noise standard deviation   (default 15)
%       'Seed'       random seed for reproducibility       (default 0)
%
%   truth returns the ground-truth spike sample indices per channel, which
%   makes this usable as a rough detection check as well as a demo input.
%
%   This generator exists so the repository is runnable without any real
%   recordings. It is not a biophysical model and should not be used to
%   make claims about detection performance.

ip = inputParser;
ip.addParameter('Duration',  20);
ip.addParameter('Rate',       2);
ip.addParameter('Amplitude',180);
ip.addParameter('NoiseUv',   15);
ip.addParameter('Seed',        0);
ip.parse(varargin{:});
o = ip.Results;

rng(o.Seed);

n_samples = round(o.Duration * p.sf);
n_ch      = p.n_channels;

% Biphasic spike template: fast negative trough, slower positive rebound.
t_ms     = (-1.0 : 1/p.sf*1000 : 1.5);
template = -exp(-((t_ms - 0).^2) / (2 * 0.18^2)) ...
           + 0.35 * exp(-((t_ms - 0.55).^2) / (2 * 0.35^2));
template = template / max(abs(template));
n_tmpl   = numel(template);

data  = zeros(n_ch, n_samples);
truth = cell(n_ch, 1);

for ch = 1:n_ch
    % Background noise, lightly low-pass correlated so it is not pure white.
    noise = o.NoiseUv * randn(1, n_samples);
    noise = filter(ones(1, 4) / 4, 1, noise);

    % Poisson spike times with a 3 ms refractory period enforced by
    % rejection, plus a slow rate modulation so the density plot has shape.
    lambda   = o.Rate * (1 + 0.6 * sin(2 * pi * (0:n_samples-1) / n_samples * 3));
    draws    = rand(1, n_samples) < lambda / p.sf;
    idx      = find(draws);
    idx      = idx(idx > n_tmpl & idx < n_samples - n_tmpl);
    if ~isempty(idx)
        keep = [true, diff(idx) > 0.003 * p.sf];
        idx  = idx(keep);
    end

    trace = noise;
    for s = idx
        amp   = o.Amplitude * (0.8 + 0.4 * rand);
        range = s : s + n_tmpl - 1;
        trace(range) = trace(range) + amp * template;
    end

    data(ch, :) = trace;
    truth{ch}   = idx;
end

% Convert microvolts back to raw acquisition counts and quantise, matching
% what an NSx file would contain.
data = round(data / p.scale_uv);
end
