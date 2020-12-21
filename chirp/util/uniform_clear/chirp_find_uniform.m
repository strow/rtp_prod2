function  [clear_ind, amax_keep, amax] = chirp_find_uniform(head, prof, cfg);
%
% chirp_uniform_clear
%
% inputs
%     head: rtp header struct
%     prof: rtp prof struct (needs robs1 field, does not require
%     klayers or sarta to have been run)
%     cfg: struct of configuration cfgions for channel and
%     threshold (cfgional)
%
% Mfile testing code
% see chirp_l1c_to_rtp_calcs.m in this repo

wn = 961;  % 961 cm^-1 default
threshold = 0.4;  % 0.4K FOV to FOV BT difference threshold
cscanlines = 45; % default number of CrIS scanlines per granule
ascanlines = 135; % default number of AIRS scanlines per granule

if isfield(cfg, 'uniform_test_channel')
    wn = cfg.uniform_test_channel;
end
if isfield(cfg, 'uniform_bt_threshold')
    threshold = cfg.uniform_bt_threshold;
end
if isfield(cfg, 'cscanlines')
    cscanlines = cfg.cscanlines;
end
if isfield(cfg, 'ascanlines')
    ascanlines = cfg.ascanlines;
end
if ~isfield(cfg, 'source_instrument')
    error('*** ERROR: Missing source instrument in configuration')
end


ch = find(head.vchan > wn, 1);
bt_rtp = rad2bt(head.vchan(ch), prof.robs1(ch,:));

switch cfg.source_instrument
  case 'airs'
    % create AIRS-like scanlines by reshaping chirp scanlines (which
    % are, essentially, concatenated FOV xtracks for a CrIS FOR scanline)
    bt = reshape(bt_rtp, 90, ascanlines )';
  case 'cris'
    % create AIRS-like scanlines by rearranging FOR/FOV indices
    % into 90xscanline array
    bt_tmp = reshape(bt_rtp, 9,30,cscanlines);
    bt = create_airs_scan_from_cris(bt_tmp, cscanlines)';
    clear bt_tmp
  otherwise
    error('*** ERROR: invalid source instrument specified')
end

% Do the xtrack and atrack diffs
d1 = diff(bt,1,1);
d2 = diff(bt,1,2);

% a will hold the diffs for each of the four neighbors
a = NaN(4,ascanlines,90);

% Indices to save, cannot use first/last rows or columns since neighbors missing
i1 = 2:ascanlines-1;
j1 = 2:89;

% Tricky part, assign the four diffs into a
a(1,i1,j1) = d1(1:ascanlines-2,j1);
a(2,i1,j1) = d1(i1,j1);
a(3,i1,j1) = d2(i1,1:88);
a(4,i1,j1) = d2(i1,j1);

% Find the max of the absolute difference in the four diffs
amax = squeeze(max(abs(a),[],1));

% Final output is amax, but with NaNs for scenes that are not clear
% $$$ amax_keep = amax(2:3:134,2:3:89);
amax_keep = amax;
amax_keep(amax_keep > threshold) = NaN;

% Get amax_keep indices for uniform FOVs
k = ~isnan(amax_keep);

% need to map k back into the rtp linear index space (depends on
% source instrument format
switch cfg.source_instrument
  case 'airs'
    ind = reshape(1:(90*ascanlines),90,ascanlines);
  case 'cris'
    ind1 = reshape(1:(9*30*cscanlines),9,30,cscanlines);
    ind = create_airs_scan_from_cris(ind1, cscanlines)';
end

clear_ind = ind(k);
