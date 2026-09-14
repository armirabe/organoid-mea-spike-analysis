function T = export_results(T, p)
%EXPORT_RESULTS Write the per-channel results table to an Excel workbook.
%
%   EXPORT_RESULTS(T, p) appends a totals row and writes T to
%   p.output_file, sheet p.output_sheet. The output directory is created
%   if it does not exist.
%
%   The totals row reports the summed spike count and the mean of the
%   per-channel firing rates, ignoring channels with no detected spikes.
%
%   See also ANALYZE_RECORDING.

out_dir = fileparts(p.output_file);
if ~isempty(out_dir) && ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

headers = T.Properties.VariableNames;
body    = table2cell(T);

totals              = repmat({NaN}, 1, numel(headers));
totals{1}           = 'Totals';
totals{2}           = sum(T.n_spikes);
rate_col            = find(strcmp(headers, 'firing_rate_hz'), 1);
if ~isempty(rate_col)
    totals{rate_col} = mean(T.firing_rate_hz, 'omitnan');
end

writecell([headers; body; totals], p.output_file, 'Sheet', p.output_sheet);
fprintf('Wrote %s (sheet "%s")\n', p.output_file, p.output_sheet);
end
