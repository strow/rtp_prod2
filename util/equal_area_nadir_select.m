function prof = equal_area_nadir_select(p, cfg)
%
% NAME
%   equal_area_nadir_select -- wrapper to select random/nadir obs
%
% INPUTS
%   p   : rtp profile struct to select from
%   cfg : configuration struct (OPTIONAL)
%
% OUTPUTS
%   prof : subset rtp profile struct containing random/nadir obs
%
func_name = 'equal_area_nadir_select';

fovs = [43:48];  % [45 46] original, [43:48] current nadir,
                 % [1:90]  full swath
obslimit = 20000;  % number of obs to keep
fudgefactor = 1.6;  % shouldn't need this, why don't we get right nobs?
instparams = [135, 90, 1, 240]; % swaths, FORs, FOVS, ngrans (AIRS
                                % for default)
if nargin == 2
    if isfield(cfg, 'fovlist')
        fovs = cfg.fovlist;
    end
    if isfield(cfg, 'obslimit')
        obslimit = cfg.obslimit;
    end
    if isfield(cfg, 'fudgefactor')
        fudgefactor = cfg.fudgefactor;
    end
    if isfield(cfg, 'instparams')
        instparams = cfg.instparams;
    end
end

nSwaths = instparams(1);
nFORs = instparams(2);
nFOVs = instparams(3);
nGrans = instparams(4);

% filter out desired FOVs/scan angles 
nadir = ismember(p.xtrack,fovs);
% rtp has a 2GB limit so we have to scale number of kept FOVs
% to stay within that as an absolute limit. Further, we
% currently restrict obs count in random to ~20k to match
% historical AIRXBCAL processing
maxobs = nSwaths * nFORs * nFOVs * nGrans;
scale = (obslimit/maxobs)*fudgefactor; % preserves ~20k obs/day (without
                            % 1.6 multiplier, only getting
                            % ~12-13k counts ?? 
randoms = get_equal_area_sub_indices(p.rlat, scale);
nrinds = find(nadir & randoms);
prof = rtp_sub_prof(p, nrinds);

        