clc;
close all;

% Load data and define parameters
data = single(NS6.Data);         % Replace with your actual dataset
sf = 30000;                      % Sampling frequency in Hz
num_channels = 14;              % Define number of channels explicitly
pre_time = 2; post_time = 2;    % Pre/post spike window in ms
thres = 6;                      % Threshold multiplier
recording_duration = length(data) / sf;      % Duration of recording in seconds
results = [];                  % Initialize results table
time_stamp = cell(num_channels, 1);
spike_total = zeros(num_channels, 1);

% Design Butterworth bandpass filter (300–6000 Hz)
[b, a] = butter(4, [300 6000] / (sf/2), 'bandpass');

% Loop through channels
for channel = 3:num_channels
    % Filter the signal (zero-phase)
    test_data = filtfilt(b, a, double(data(channel, :))) / 4;

    % Threshold using MAD
    sigma = median(abs(test_data) / 0.6745);
    threshold = -thres * sigma;

    % Spike detection setup
    spikes = [];
    waveform = [];
    spike_amplitudes = [];
    spike_durations = [];
    count = 0;
    ii = pre_time * sf / 1000;
    skipped = 0;

    % Spike detection loop
    while ii < length(test_data) - post_time * sf / 1000
        if test_data(ii) < threshold
            start_idx = ii - pre_time * sf / 1000;
            end_idx = ii + post_time * sf / 1000;

            % Bounds check
            if start_idx >= 1 && end_idx <= length(test_data)
                count = count + 1;
                spikes(count) = ii;
                waveform(count, :) = test_data(start_idx:end_idx);
                spike_amplitudes(count) = min(waveform(count, :));

                % FWHM spike duration
                peak_index = find(waveform(count, :) == min(waveform(count, :)), 1);
                half_max = min(waveform(count, :)) / 2;
                left = find(waveform(count, 1:peak_index) >= half_max, 1, 'last');
                right = find(waveform(count, peak_index:end) >= half_max, 1, 'first') + peak_index - 1;
                if ~isempty(left) && ~isempty(right)
                    spike_durations(count) = (right - left) / sf * 1000; % in ms
                end

                ii = ii + post_time * sf / 1000; % skip ahead
            else
                skipped = skipped + 1;
                ii = ii + 1;
            end
        else
            ii = ii + 1;
        end
    end

    % Save timestamps
    time_stamp{channel} = spikes;

    % Metrics
    [std_spike_duration, mean_spike_duration] = std(spike_durations, 'omitnan');
    [std_spike_amplitude, mean_spike_amplitude] = std(spike_amplitudes, 'omitnan');

    if length(spikes) > 1
        firing_rate = count / recording_duration;
        isi = diff(spikes) / sf;
        isi_rate = 1 / mean(isi);
        active_spiking_duration = sum(spike_durations) / 1000; % in s
    else
        firing_rate = NaN;
        isi_rate = NaN;
        active_spiking_duration = NaN;
        mean_spike_amplitude = NaN;
        std_spike_amplitude = NaN;
    end

    % Store results
    results = [results; channel, count, mean_spike_duration, std_spike_duration, ...
        mean_spike_amplitude, std_spike_amplitude, firing_rate, isi_rate, active_spiking_duration];

    fprintf("Channel %d: %d spikes detected, %d skipped near edges\n", channel, count, skipped);
end

% Save results to Excel
headers = {'Channel', 'Spike Count', 'Mean Spike Duration (ms)', ...
    'Spike Duration Standard Deviation (ms)', 'Mean Spike Amplitude (uV)', ...
    'Spike Amplitude Standard Deviation (uV)', 'Firing Rate - Standard (Hz)', ...
    'Firing Rate - ISI (Hz)', 'Active Spiking Duration (s)'};
totals = {'Totals', sum(results(:,2)), NaN, NaN, NaN, NaN, ...
    mean(results(:,7), 'omitnan'), NaN, NaN};
subCell = [headers; num2cell(results); totals];
writecell(subCell, 'Class I gsk.xlsx', 'Sheet', 'cluster 2 glut001');