%
% NAME
%   inst_params - set sensor and user-grid parameters
%
% SYNOPSIS
%   [inst, user] = inst_params(band, wlaser, opts)
%
% INPUTS
%   band    - 'LW', 'MW', or 'SW'
%   wlaser  - metrology laser wavelength
%   opts    - optional parameters
% 
% OPTS FIELDS
%   inst_res - 'lowres' (default), 'hires1-4', 'hi3to2'
%   user_res - 'lowres' (default), 'hires'
%   pL, pH   - processing filter passband start and end freqs
%   rL, rH   - processing filter out-of-band LHS and RHS rolloff
%
% OUTPUTS
%   inst  - sensor grid parameters
%   user  - user grid parameters
%
% DISCUSSION
%   Sets user and sensor grid parameters.  Options include CrIS
%   version, sensor and user grid resolution modes, and processing
%   filter specs.  user.vr is used for bandpass filtering by some
%   non-ccast app's
%
% AUTHOR
%   H. Motteler, 4 Oct 2013
%

function [inst, user] = inst_params(band, wlaser, opts)

% keep "band" upper-case locally
band = upper(band);

%----------
% defaults
%----------
inst_res = 'lowres';
user_res = 'lowres';

% e5-e6 cal algo filters
switch band
  case 'LW', pL =  650; pH = 1100; rL = 15; rH = 20; vr = 15;
  case 'MW', pL = 1200; pH = 1760; rL = 30; rH = 30; vr = 20;
  case 'SW', pL = 2145; pH = 2560; rL = 30; rH = 30; vr = 20;
end

% allow some old "resmode" style options
if nargin == 3 && isfield(opts, 'resmode') 
  switch opts.resmode
    case 'hires3', inst_res = 'hires3'; user_res = 'hires';
    case 'hires2', inst_res = 'hires2'; user_res = 'hires';
    case 'lowres', inst_res = 'lowres'; user_res = 'lowres';
    otherwise, error(['bad resmode param ', opts.resmode]);
  end
end

% apply recognized input options
if nargin == 3
  if isfield(opts, 'inst_res'), inst_res = opts.inst_res; end
  if isfield(opts, 'user_res'), user_res = opts.user_res; end
  if isfield(opts, 'pL'), pL = opts.pL; end
  if isfield(opts, 'pH'), pH = opts.pH; end
  if isfield(opts, 'rL'), rL = opts.rL; end
  if isfield(opts, 'rH'), rH = opts.rH; end
end

%-----------
% user grid
%-----------
switch band
  case 'LW'
    user.v1 = 650;    % first channel
    user.v2 = 1095;   % last channel
    user.opd = 0.8;   % user grid OPD

  case 'MW'  
    user.v1 = 1210;
    user.v2 = 1750;
    user.opd = 0.4;

  case 'SW'  
    user.v1 = 2155;
    user.v2 = 2550;
    user.opd = 0.2;
end

% user OPD is 0.8 for high res
switch user_res
  case 'lowres'
  case 'hires', user.opd = 0.8;
  otherwise, error(['bad user res value ', user_res])
end

% derived parameters
user.dv = 1 / (2*user.opd);
user.band = band;
user.vr = vr;

%-------------
% sensor grid
%-------------
switch band
  case 'LW'
    df = 24;          % decimation factor
    vbase = 1;        % alias offset
    switch inst_res   % interferogram size
      case {'lowres', 'hires1', 'hires2', 'hi3to2'}, npts = 866;
      case 'hi3odd', npts = 873;
      case 'hires3', npts = 874;
      case 'hires4', npts = 876;
    end

  case 'MW'
    df = 20;
    vbase = 1;
    switch inst_res
      case 'lowres', npts = 530;
      case 'hires1', npts = 1039;
      case 'hi3odd', npts = 1051;
      case {'hires2', 'hires3', 'hires4', 'hi3to2'}, npts = 1052;
    end

  case 'SW'
    df = 26;
    vbase = 4;
    switch inst_res
      case 'lowres', npts = 202;
      case {'hires1', 'hires2'}, npts = 799;
      case 'hi3to2', npts = 800;
      case 'hi3odd', npts = 807;
      case {'hires3', 'hires4'}, npts = 808;
    end
end

% derived parameters
vlaser = 1e7 / wlaser;  % laser frequency
dx  = df / vlaser;      % distance step
opd = dx * npts / 2;    % max OPD
dv  = 1 / (2*opd);      % frequency step
awidth = vlaser / df;   % alias width
vmid = (user.v1 + user.v2) / 2;     % desired band center (d37)
vdfc = vmid - awidth / 2;           % desired 1st chan cent (d38)
cutpt = mod(round(vdfc/dv), npts);  % cut point (d9)

% get the channel index permutation
cind = [(cutpt+1:npts)' ; (1:cutpt)'];
freq = dv * (cutpt:cutpt+npts-1)' + awidth * vbase;

% instrument params
inst.band    = band;
inst.wlaser  = wlaser;
inst.df      = df;
inst.npts    = npts;
inst.vlaser  = vlaser;
inst.dx      = dx;
inst.opd     = opd;
inst.dv      = dv;
inst.cind    = cind;
inst.freq    = freq;
inst.inst_res = inst_res;
inst.user_res = user_res;
inst.pL      = pL;
inst.pH      = pH;
inst.rL      = rL;
inst.rH      = rH;

% mainly for tests
inst.awidth = awidth;
inst.cutpt  = cutpt;
inst.vdfc   = vdfc;
inst.vbase  = vbase;


