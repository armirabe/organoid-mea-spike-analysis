function x = preprocess_channel(raw, p)
%PREPROCESS_CHANNEL Scale raw samples to microvolts and filter.
%
%   x = PREPROCESS_CHANNEL(raw, p) converts one channel of raw integer
%   samples to microvolts and applies the filter specified in p.filter.
%
%   See also DEFAULT_PARAMS, DETECT_SPIKES.

x = double(raw(:)') * p.scale_uv;

switch lower(p.filter.type)
    case 'bandpass'
        [b, a] = butter(p.filter.order, p.filter.band / (p.sf / 2), 'bandpass');
        x = filtfilt(b, a, x);
    case 'highpass'
        x = highpass(x, p.filter.cutoff, p.sf);
    case 'none'
        % leave unfiltered
    otherwise
        error('preprocess_channel:badFilter', ...
              'Unknown filter type "%s".', p.filter.type);
end
end
