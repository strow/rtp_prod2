function  [clear_ind, amax_keep, amax] = chirp_find_uniform(head, prof, opt);
%
% chirp_uniform_clear
%
% inputs
%     head: rtp header struct
%     prof: rtp prof struct (needs robs1 field, does not require
%     klayers or sarta to have been run)
%     opt: struct of configuration options for channel and
%     threshold (optional)
%
% Mfile testing code
% see chirp_l1c_to_rtp_calcs.m in this repo

wn = 961;  % 961 cm^-1 default
threshold = 0.4;  % 0.4K FOV to FOV BT difference threshold
scanlines = 135; % default number of CrIS scanlines per granule
if nargin == 3 
    if isfield(opt, 'uniform_test_channel')
        wn = opt.uniform_test_channel;
    end
    if isfield(opt, 'uniform_bt_threshold')
        threshold = opt.uniform_bt_threshold;
    end
    if isfield(opt, 'scanlines')
        scanlines = opt.scanlines;
    end
end

ch = find(head.vchan > wn, 1);
bt_rtp = rad2bt(head.vchan(ch), prof.robs1(ch,:));

% create AIRS-like scanlines by reshaping chirp scanlines (which
% are, essentially, concatenated FOV xtracks for a CrIS FOR scanline)
bt = reshape(bt_rtp, 90, scanlines )';

% Do the xtrack and atrack diffs
d1 = diff(bt,1,1);
d2 = diff(bt,1,2);

% a will hold the diffs for each of the four neighbors
a = NaN(4,scanlines,90);

% Indices to save, cannot use first/last rows or columns since neighbors missing
i1 = 2:scanlines-1;
j1 = 2:89;

% Tricky part, assign the four diffs into a
a(1,i1,j1) = d1(1:scanlines-2,j1);
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

% need to map k back into the rtp linear index space
ind = reshape(1:(90*scanlines),90,scanlines);
clear_ind = ind(k);
%tmp=reshape(amax_keep',1,[]);simplemap(prof.rlat(clear_ind), prof.rlon(clear_ind),tmp(clear_ind));
% scatter_coast(prof.rlon(clear_ind), prof.rlat(clear_ind), 10, ones(size(clear_ind)))