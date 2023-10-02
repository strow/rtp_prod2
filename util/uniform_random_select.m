function prof = uniform_random_select(p, cfg)
%
% NAME
%   uniform_random_select -- wrapper to select random with uniform
%   random selection
%
% INPUTS
%   p   : rtp profile struct to select from
%   cfg : configuration struct (OPTIONAL)
%
% OUTPUTS
%   prof : subset rtp profile struct containing random/nadir obs
%
func_name = 'uniform_random_select';

fudgefactor = 1.0;  % shouldn't need this, why don't we get right nobs?
scale = 0.01;       % keep 1% of obs

if nargin == 2
    if isfield(cfg, 'fudgefactor')
        fudgefactor = cfg.fudgefactor;
    end
    if isfield(cfg, 'scale')
        scale = cfg.scale;
    end
end

nobs = length(p.rtime);
nselect = ceil(nobs * scale * fudgefactor);

nrinds = randperm(nobs, nselect);

prof = rtp_sub_prof(p, nrinds);