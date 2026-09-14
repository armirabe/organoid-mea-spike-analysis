%RUN_DEMO End-to-end demonstration on a synthetic recording.
%
%   Run this from the repository root:
%       >> addpath(genpath('src')); addpath('demo');
%       >> run_demo
%
%   It generates a surrogate 12-channel recording, runs the full pipeline,
%   draws the standard figures and writes results/demo_results.xlsx.
%   No real recordings are required.

clc; close all;

addpath(genpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src')));

% --- Parameters --------------------------------------------------------
p              = default_params();
p.n_channels   = 12;
p.filter.type  = 'bandpass';
p.output_file  = fullfile('results', 'demo_results.xlsx');
p.output_sheet = 'synthetic';

% --- Generate input ----------------------------------------------------
fprintf('Generating synthetic recording...\n');
[data, truth] = synthetic_recording(p, 'Duration', 20, 'Rate', 3, 'Seed', 42);

% --- Analyse -----------------------------------------------------------
fprintf('\nDetecting spikes...\n');
[T, S] = analyze_recording(data, p);

disp(' ');
disp(T);

% --- Detection check against ground truth ------------------------------
% Counts will not match exactly: detection misses spikes that overlap
% within the refractory window and adds occasional noise crossings.
true_counts = cellfun(@numel, truth);
found       = T.n_spikes;
fprintf('\nGround truth total: %d   Detected total: %d   Ratio: %.2f\n', ...
        sum(true_counts), sum(found), sum(found) / sum(true_counts));

% --- Firing rate density ----------------------------------------------
timestamps = arrayfun(@(s) s.spk.idx, S, 'UniformOutput', false);
[density, t_density] = firing_rate_density(timestamps, size(data, 2), p);

% --- Figures and export ------------------------------------------------
plot_results(S, density, t_density, p);
export_results(T, p);

fprintf('\nDemo complete.\n');
