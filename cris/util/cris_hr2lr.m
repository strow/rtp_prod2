function [head, prof] = cris_hr2lr(head, prof, cfg)

% Interpolate hires spectrual profiles down to lowres

% information on guard channels is brought in via cfg.nguard and
% cfg.nsarta

opt1 = struct;
opt1.user_res = 'lowres';
opt1.inst_res =  'hires3';
wlaser = 773.1301;

%% Sort out radiance interpolation
% this function has prof.robs1(2223, nobs). I assume that I can
% take the existing spectrum (with any guard channels already
% embedded) and interpolate, then pull out the lowres spectral
% channels including whatever guard channels are needed

% LW band requires no interpolation, it is unchaged between hires
% and lowres
v1LW =
r1LW = prof.robs1([..]:);

% MW
v1MW =
r1MW = prof.robs1(..):);
[instMW, userMW = inst_params('MW', wlaser, opt1);
[r2MW, v2MW] = finterp(r1MW(:,:), v1MW, userMW.dv);
ix = find(xo
% SW 
v1SW =
r1SW = prof.robs1(..),:);
[instSW, userSW = inst_params('SW', wlaser, opt1);
[r2SW, v2SW] = finterp(r1SW(:,:), v1SW, userSW.dv);


%% sort out making new head vchan/ichan


%% what do I really have here? I am starting further down the
%% processing chain than ccast2rtp so we are not reading
%% information at the granule level but, rather, information that
%% has already been massaged into/onto a user grid. In particular,
%% onto a hires user grid and into a linear array of live and guard
%% channels. I need to pull out the existing spectral information,
%% interpolate down to the lowres user grid and include proper
%% guard channels. Since we are going to a coarser grid, the guard
%% channels will not, necessarily, be interpolatd and have any real
%% relevance. In that, they will be much like guard channels added
%% at the ccast2rtp level. So, maybe the thing to do is:
%% - extract each band
%% - remove the hires guard channels
%% - interpolate down to lowres
%% - add new guard channels including NaNs in the spectra?
%% - recombine the bands into a single liear array with guard
%% channels included
 