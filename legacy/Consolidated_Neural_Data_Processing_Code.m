clc;
close all;
% delete 'spike_analysis_results.xlsx'; % deletes old file to clear old data

% Load dataset 
data = single(NS6.Data); % Change NS6.Data to the actual dataset

% Parameter Definition
sf = 30000; % Sample frequency
recording_duration = length(data) / sf; 
pre_time = 2; post_time = 2; % in ms, acquisition time before and after spike detection
thres = 6; % Define multiple of sigma (for threshold settings)
results = []; % Initialize results storage
num_channels = 12;
 gauss_w = 10; % Gaussian window width (s)
burst_d = 0.001; % Burst peak resolution (s)
spike_total = zeros(num_channels,1);
time_stamp = cell(num_channels,1); % Use cell array to handle different spike counts

% Process Each Channel
for channel = 1:num_channels

    % Highpass data
    test_data = highpass(data(channel, :), 500, sf) / 4;

    % Threshold Calculation
    sigma = median(abs(test_data) / 0.6745); % MAD estimate of standard deviation
    threshold = -thres * sigma; % Negative threshold for detecting negative spikes

    % Initialize Spike Detection Variables
    spikes = [];
    waveform = [];
    count = 0;
    spike_durations = []; % Store spike durations
    ii = pre_time * 30 + 1;

    % Spike Detection
    while ii < length(test_data) - post_time * 30
        if test_data(ii) < threshold
            count = count + 1;
            spikes(count) = ii;
            waveform(count, :) = test_data((ii - pre_time * sf/1000):(ii + post_time * sf/1000));

            % Estimate spike duration (full width at half maximum)
            peak_index = find(waveform(count, :) == min(waveform(count, :)), 1);
            half_max = min(waveform(count, :)) / 2;
            left = find(waveform(count, 1:peak_index) >= half_max, 1, 'last');
            right = find(waveform(count, peak_index:end) >= half_max, 1, 'first') + peak_index - 1;
            if ~isempty(left) && ~isempty(right)
                spike_durations(count) = (right - left) / sf * 1000; % Convert to ms
            end

            % Find spike amplitude
            spike_amplitudes(count) = min(waveform(count, :));

            ii = ii + post_time * 30; % Skip to avoid overlapping detections
        else
            ii = ii + 1;
        end
    end

    time_stamp{channel} = spikes;

    % Calculate mean spike duration
    [std_spike_duration, mean_spike_duration] = std(spike_durations, 'omitnan');

    % Calculate mean spike amplitude
    [std_spike_amplitude, mean_spike_amplitude] = std(spike_amplitudes, 'omitnan');

    % Calculate firing rate (all methods)
    if length(spikes) > 1
        firing_rate = count / recording_duration; % Standard firing rate (Hz)

        inter_spike_intervals = diff(spikes) / sf; % Convert to seconds
        mean_isi = mean(inter_spike_intervals);
        isi_rate = 1 / mean_isi; % Reciprocal of mean ISI

        active_spiking_duration = sum(spike_durations) / 1000; % Convert to seconds
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

    %% Subplot for Waveforms (3x4 Grid)
    if count == 0
        waveform = zeros(121);
    end

    figure (1)
    subplot(3, 4, channel);
    hold on
    t = (-pre_time * 30:post_time * 30) / 30; % Time axis in ms

    % Plot all waveforms in light gray
    plot(t, waveform', 'Color', "#dbd9e2", 'LineWidth', 0.5);

    % Overlay mean waveform in solid black
    plot(t, mean(waveform), 'Color', "#250e62", 'LineWidth', 2);

    title(['Ch ', num2str(channel), ' | Spikes: ', num2str(count)]);
    xlabel('Time (ms)');
    ylabel('Voltage (uV)');
    if count == 0
        ylim([-100, 100])
    else
        ylim([-max(abs(waveform(:))) max(abs(waveform(:)))]) % Adjust Y limits based on waveforms
    end
    hold off

    % Add to Stacked Filtered Data Plot
    figure(2); % Switch to filtered data figure
    hold on
    time_for_plot = (1:length(test_data)) / sf;
    plot(time_for_plot, test_data(:) * 0.4 / max(abs(test_data(:))) + channel); % Normalize and shift to channel number
    hold off

    if length(waveform) >= 1
        %% Add to Stacked Raster Plot
        figure(3); % Switch to raster plot figure
        hold on
        sunset_cmap = [...
            0.1 0 0.3;   % Deep Purple (Lowest Amplitude)
            0.5 0 0.5;   % Purple
            0.8 0 0.2;   % Red
            1 0.5 0;     % Orange
            1 0.8 0.2;   % Yellow-Orange
            1 1 0.6];    % Soft Yellow (Highest Amplitude)
        amp_min = 100;  % Lowest expected amplitude
        amp_max = 300; % Highest expected amplitude

        figure(3); % Switch to raster plot figure
        hold on
        if ~isempty(spike_amplitudes)
    norm_amplitudes = (abs(spike_amplitudes) - amp_min) / (amp_max - amp_min);
    norm_amplitudes = max(0, min(norm_amplitudes, 1)); % Clamp values between 0 and 1

    cmap = interp1(linspace(0,1,size(sunset_cmap,1)), sunset_cmap, norm_amplitudes);

    % Loop through each spike and plot with amplitude-based color
    for ii = 1:length(spikes)
        color = cmap(ii, :);
        plot([spikes(ii), spikes(ii)] / sf, [channel - 0.4, channel + 0.4], ...
            'Color', color, 'LineWidth', 1.5);
    end
        end
        hold off
        hold off

        %% Add to Spike Duration Plot
        figure (4) % Switch to spike duration figure
        hold on
        bar(channel, mean_spike_duration, 'b')
        errorbar(channel, mean_spike_duration, std_spike_duration, 'r')
        hold off

        %% Add to Spike Amplitude Plot
        figure (5) % Switch to spike amplitude figure
        hold on
        bar(channel, abs(mean_spike_amplitude), 'r')
        errorbar(channel, abs(mean_spike_amplitude), std_spike_amplitude, 'b')
        hold off
    end

end

%% Finalize Filtered Data Plot
figure(2);
title('Filtered Data - All Channels');
xlabel('Time (s)');
ylabel('Channel', "FontSize", 20);
ylim([0.5, 12.5]);
yticks(1:12);
xlim([0, length(test_data) / sf]);
hold off;

%% Finalize Raster Plot
figure(3);
title('Raster Plot - All Channels');
xlabel('Time (s)');
ylabel('Channel', "Fontsize", 20);
ylim([0.5, 12.5]); % Keep within range
yticks(1:12);

colormap(sunset_cmap);
c = colorbar;
c.Ticks = linspace(0, 1, 6); % Set tick marks at evenly spaced intervals
c.TickLabels = round(linspace(amp_min, amp_max, 6), 1); % µV labels from 0 to 200
c.Label.String = 'Voltage (µV)';
c.Label.FontSize = 20;
c.Label.FontWeight = 'bold';
hold off;

%% Finalize Spike Duration Plot
figure (4)
title('Mean Spike Durations')
xlabel('Channel')
ylabel('Spike Duration (ms)')
xticks(1:12)
hold off

%% Finalize Spike Amplitude Plot
figure (5)
title('Mean Spike Amplitudes')
xlabel('Channel')
ylabel('Spike Amplitude (uV)')
xticks(1:12)
hold off

%% Save to Excel
headers = {'Channel', 'Spike Count', 'Mean Spike Duration (ms)', ...
    'Spike Duration Standard Deviation (ms)', 'Mean Spike Amplitude (uV)', ...
    'Spike Amplitude Standard Deviation (uV)', 'Firing Rate - Standard (Hz)', ...
    'Firing Rate - ISI (Hz)', 'Active Spiking Duration (s)'};

totals = {'Totals', sum(sum(results(:,2))) NaN NaN NaN NaN...
    mean(mean(~isnan(results(:,7)))) NaN NaN};
subCell = [headers; num2cell(results); totals];
writecell(subCell,'AAV Spontaneous.xlsx', 'Sheet', '9007');

%% Gaussian Kernel Definition
width = gauss_w * sf; % Gaussian window size
t = linspace(-width/2, width/2, width);
gauss_kern = exp(-t.^2 / (0.1 * width^2));
gauss_kern = gauss_kern / sum(gauss_kern); % Normalize kernel

%% Compute Local Firing Rate Density
resolution = round(recording_duration); % Number of points in density plot
density = zeros(num_channels, resolution);

for channel = 1:num_channels
    tmp = zeros(1, length(data));

    if ~isempty(time_stamp{channel}) % Check if channel has spikes
        tmp(time_stamp{channel}) = 1; % Mark spikes in binary vector

        % Convolve with Gaussian kernel
        convolved_tmp = conv(tmp, gauss_kern, 'same') * sf; % Convert to Hz

        % Interpolation
        x = 1:length(convolved_tmp);
        interp_time = linspace(1, x(end), min(resolution, length(convolved_tmp)));
        density(channel, :) = interp1(x, convolved_tmp, interp_time, 'linear', 'extrap');
    end
end

%% Compute Thresholds for Visualization
all_density = density(:);
mi = min(all_density);
iqr_value = max(iqr(all_density), 0.01); % Ensure IQR is not zero
low = mi + iqr_value * 0.5;
high = min(mi + iqr_value * 0.001, max(all_density)); % Clamp to 3x IQR

% Ensure high value is greater than 0.1
high_clim = max(0.1, high * (length(gauss_kern) / 5));

% Plot Local Firing Rate Density
figure (6)
imagesc(density); % Use fixed high_clim
colormap(parula); % Use built-in colormap
colorbar;
caxis([0 max(sum(density)/num_channels)]); % Ensure the colormap spans density values from 0 to maximum
ylabel('Channel Index');
xlabel('Time [s]');
title('Local Firing Rate [Hz]');
axis tight;

figure (7)
plot(1:length(density), sum(density)/num_channels, "Color", "#250e62");
title("Firing rate over time for whole organoid")
ylabel("Spikes/s")
xlabel("Time (s)")
xlim([0, recording_duration])

% 
% %% Burst Detection
% % Define burst detection threshold (2x RMS of population rate)
% population_rate_vector = convolved_tmp;
% rms_value = rms(population_rate_vector);
% burst_threshold = 2 * rms_value;
% 
% % Find burst peaks using findpeaks function
% [burst_peaks, burst_locs] = findpeaks(population_rate_vector, 'MinPeakHeight', burst_threshold, 'MinPeakDistance', burst_d * sf);
% 
% % Define burst durations (90% attenuation of peak amplitude)
% burst_durations = zeros(1, length(burst_peaks));
% for i = 1:length(burst_peaks)
%     peak_amplitude = burst_peaks(i);
%     peak_loc = burst_locs(i);
% 
%     % Find start of burst (amplitude drops below 10% of peak)
%     start_idx = find(population_rate_vector(1:peak_loc) < 0.1 * peak_amplitude, 1, 'last');
%     if isempty(start_idx)
%         start_idx = 1;
%     end
% 
%     % Find end of burst (amplitude drops below 10% of peak)
%     end_idx = find(population_rate_vector(peak_loc:end) < 0.1 * peak_amplitude, 1, 'first') + peak_loc - 1;
%     if isempty(end_idx)
%         end_idx = length(population_rate_vector);
%     end
% 
%     burst_durations(i) = (end_idx - start_idx) / sf * 1000; % Convert to ms
% end
% 
% %% Burst Similarity Analysis
% % Define time windows for burst similarity analysis
% window_start_times = -200:10:0; % Start times in ms
% window_end_times = 0:10:500; % End times in ms
% 
% % Initialize burst similarity results
% burst_diffs = zeros(length(burst_peaks));
% 
% % Compute burst similarity for each pair of bursts
% for i = 1:length(burst_peaks)
%     for j = i+1:length(burst_peaks)
%         % Compute start and end indices (convert ms to samples)
%         start_idx1 = round(burst_locs(i) + window_start_times * sf / 1000);
%         end_idx1 = round(burst_locs(i) + window_end_times * sf / 1000);
% 
%         start_idx2 = round(burst_locs(j) + window_start_times * sf / 1000);
%         end_idx2 = round(burst_locs(j) + window_end_times * sf / 1000);
% 
%         % Ensure indices are within valid range (>= 1 and <= length of vector)
%         start_idx1 = max(start_idx1, 1);
%         end_idx1 = min(end_idx1, length(population_rate_vector));
% 
%         start_idx2 = max(start_idx2, 1);
%         end_idx2 = min(end_idx2, length(population_rate_vector));
% 
%         % Extract population rate vectors for the two bursts
%         burst1_rate = population_rate_vector(start_idx1:end_idx1);
%         burst2_rate = population_rate_vector(start_idx2:end_idx2);
% 
%         % Ensure vectors are same length before subtraction
%         min_length = min(length(burst1_rate), length(burst2_rate));
%         burst1_rate = burst1_rate(1:min_length);
%         burst2_rate = burst2_rate(1:min_length);
% 
%         % Compute absolute difference between the two burst rate vectors
%         rate_difference = mean(abs(burst1_rate - burst2_rate));
% 
%         % Store the difference in the similarity matrix
%         burst_diffs(i, j) = rate_difference;
%     end
% end
% 
% % Compute average burst similarity ratio
% average_burst_diff = mean(burst_diffs(:));
% 
% %% Save Burst Analysis Results
% burst_results = [burst_peaks', (burst_locs / sf)', burst_durations'];
% burst_headers = {'Burst Peak Amplitude', 'Burst Peak Time (s)', 'Burst Duration (ms)'};
% burst_cell = [burst_headers; num2cell(burst_results)];
% writecell(burst_cell, 'spike_analysis_results.xlsx', 'Sheet', 2);
% % diff_header_1 = {'Differences between bursts'};
% % diff_header_2 = {'Average burst difference'};
% % diff_cell = [diff_header_1; num2cell(burst_diffs); diff_header_2; average_burst_diff];
% % writecell(diff_cell, 'spike_analysis_results.xlsx', 'Sheet', 3);

%% Display Results
%disp(['Population-Averaged Firing Rate: ', num2str(mean(population_rate_vector)), num2str(std(population_rate_vector)), ' Hz']);
%disp(['Average Burst Difference: ', num2str(average_burst_diff)]);
