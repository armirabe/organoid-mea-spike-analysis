# Porting notes

`src/` is a refactor of the two scripts preserved in `legacy/`. This file
records every difference in behaviour, so results from this code can be
compared against the published analysis honestly.

## Unchanged

The parts that determine the reported numbers are mathematically identical:

- MAD noise estimate, `sigma = median(|x|) / 0.6745`
- Threshold at `-thresh_mult * sigma`, negative-going crossings only
- Refractory skip of `post_ms` after each detection
- Waveform window of `±2 ms`, trough amplitude as the window minimum
- Spike duration as full width at half minimum
- Both firing rate definitions, and the rule returning `NaN` below two spikes
- The 300–6000 Hz 4th-order Butterworth applied with `filtfilt`

## Bugs fixed

**Stray line of non-code.** Line 117 of the consolidated script reads
`Add to Stacked Filtered Data Plot` with no comment marker. MATLAB parses
this as an expression and throws an error, so the script as committed could
not run to completion.

**`spike_amplitudes` never cleared between channels.** `spikes`, `waveform`,
`count` and `spike_durations` were reset at the top of each channel
iteration, but `spike_amplitudes` was not. A channel detecting fewer spikes
than its predecessor inherited stale amplitudes from the previous channel,
contaminating `mean_spike_amplitude`, `std_spike_amplitude` and the raster
colouring. Channel 1 was unaffected; later channels with declining spike
counts were affected most.

**`waveform = zeros(121)` on empty channels.** This allocates a 121×121
matrix rather than a single 1×121 row. The subsequent `length(waveform) >= 1`
guard therefore passed on silent channels, and the plotting block ran on a
square matrix of zeros.

**Totals row computed the wrong quantity.** The consolidated script wrote
`mean(mean(~isnan(results(:,7))))` into the firing rate totals cell — the
fraction of channels with a non-NaN rate, not the mean firing rate. The
Butterworth script had this right; the correct form is used here.

**Sample-per-millisecond conversion hard-coded as 30.** The consolidated
script mixed `pre_time * 30` with `pre_time * sf/1000`. These agree only at
30 kHz and diverge silently at any other sampling rate. All conversions now
derive from `p.sf`.

**No bounds check at recording edges.** The consolidated script could index
outside the signal near the start or end. The Butterworth script added a
check but counted those events as `skipped`. The loop bounds here make
out-of-range access impossible.

**Channel loop started at 3.** `Butterworth_Filter.m` looped
`for channel = 3:num_channels`, silently dropping channels 1 and 2. Channel
selection is now explicit via `p.channels`.

## Changed behaviour

**Firing rate density reimplemented.** The original built a full-resolution
binary vector over the entire recording and convolved it with a kernel
defined as `exp(-t.^2 / (0.1 * width^2))` where `width = gauss_w * sf`. That
couples the kernel's standard deviation to its truncation width in a
nonstandard way, so the effective smoothing was not `gauss_w` seconds. It was
also slow: a 300,000-sample kernel convolved against every channel.

The replacement bins spikes at `density_bin_s` and convolves with a proper
normalised Gaussian of standard deviation `density_sigma_s`, truncated at
±3σ. The shape of the rate over time is preserved; **absolute values differ
from the published figures.** If you need to reproduce those exactly, use
`legacy/Consolidated_Neural_Data_Processing_Code.m`.

**Dead threshold code removed.** The variables `low`, `high` and `high_clim`
were computed from the IQR of the density and never used — `caxis` was set
from a different expression. The comment claimed a clamp to 3×IQR while the
code multiplied by 0.001. All of it is gone.

**Output paths are parameters.** Filenames and sheet names were hard-coded
(`'Class I gsk.xlsx'` / `'cluster 2 glut001'`, `'AAV Spontaneous.xlsx'` /
`'9007'`). These now come from `p.output_file` and `p.output_sheet`. Beyond
being a usability issue, those strings encoded experimental conditions and
sample identifiers.

**Unit scaling made explicit.** The unexplained `/ 4` is now
`p.scale_uv = 0.25`, documented as the Blackrock NSx unit of 1/4 µV per
count.

**Arrays preallocated.** Growing `spikes`, `waveform` and friends one element
at a time dominated runtime on long recordings.

**Commented-out burst detection dropped.** Roughly 90 lines of commented
burst detection and burst similarity analysis were not carried over. If that
analysis is needed, it should be restored deliberately and tested.

**`caxis` replaced.** Deprecated in favour of default colour limits; use
`clim` if you need explicit control on R2022a or newer.

## Untested

This refactor has not been executed — it was written without a MATLAB
license available. The logic is a direct translation, but run `run_demo`
before trusting it, and compare against `legacy/` output on a recording with
known results.
