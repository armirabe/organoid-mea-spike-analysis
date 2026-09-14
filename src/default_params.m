function p = default_params()
%DEFAULT_PARAMS Parameter set for the spike detection and analysis pipeline.
%
%   p = DEFAULT_PARAMS() returns a struct of default parameters. Override
%   any field before passing it to ANALYZE_RECORDING:
%
%       p = default_params();
%       p.n_channels  = 14;
%       p.filter.type = 'bandpass';
%
%   See also ANALYZE_RECORDING, DETECT_SPIKES.

% --- Acquisition -------------------------------------------------------
p.sf         = 30000;   % sampling frequency (Hz)
p.n_channels = 12;      % number of channels to process
p.channels   = [];      % specific channels to process; [] means 1:n_channels

% Blackrock NSx files store samples in units of 1/4 uV, so raw counts are
% multiplied by 0.25 to obtain microvolts. Change this if your acquisition
% system uses different scaling.
p.scale_uv   = 0.25;

% --- Filtering ---------------------------------------------------------
% 'bandpass' applies a zero-phase Butterworth filter via filtfilt.
% 'highpass' uses MATLAB's highpass() and reproduces the behaviour of the
% original Consolidated_Neural_Data_Processing_Code.m.
p.filter.type   = 'bandpass';
p.filter.order  = 4;
p.filter.band   = [300 6000];  % Hz, used when type is 'bandpass'
p.filter.cutoff = 500;         % Hz, used when type is 'highpass'

% --- Spike detection ---------------------------------------------------
p.pre_ms      = 2;   % waveform window before threshold crossing (ms)
p.post_ms     = 2;   % waveform window after threshold crossing (ms)
p.thresh_mult = 6;   % threshold = -thresh_mult * sigma (MAD estimate)

% --- Firing rate density ----------------------------------------------
p.density_bin_s   = 0.01;  % bin width for the population rate (s)
p.density_sigma_s = 1.0;   % Gaussian smoothing standard deviation (s)

% --- Output ------------------------------------------------------------
p.output_file  = fullfile('results', 'spike_analysis_results.xlsx');
p.output_sheet = 'Sheet1';
end
