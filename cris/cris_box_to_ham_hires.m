function [rad_ham,cal_ham] = cris_box_to_ham_hires(ichan, rad_box, cal_box, nguard);

%% see /asl/rtp_prod/cris/unapod/cris_box_to_ham.m      for OBS
%% see /asl/matlab2012/cris/unapod/cris888_box_to_ham.m for CAL

% function [rad_ham] = cris_box_to_ham_hires(ichan, rad_box, nguard);
%
% Convert the apodization of CrIS radiance from boxcar
% (ie unapodized) to Hamming.
%
% Input:
%    ichan   : [nchan x 1] channel IDs, typically includes guard chans, so 1x2235
%    rad_box : [nchan x nobs] unapodized (boxcar) radiance
%    cal_box     : [nchan x nobs] cal_boxcs
%    nguard  : OPTIONAL [1 x 1] number of guard channels per
%       band edge (default=4)
%
% Output:
%    rad_ham : [2211 x nobs] Hamming apodized rad obs
%    cal_ham : [2211 x nobs] Hamming apodized cal
%
% Created: 24 July 2011, Scott Hannon
% Update: 25 July 2011, S.Hannon - change arguments from head & prof to
%   the ichan and rad_box and check dimensions; set class of rad_ham to
%   match rad_box; report ID of any missing required channels.
% Update: 16 June 2016, S.HMachado - changed to hi res
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CrIS band edge (start & end) IDs
id_out = 1:2211;
id_band_start = [   1  714 1579];
id_band_end   = [ 713 1578 2211];

% Default number of guard channels per band edge
nguard_default = 4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin < 2 | nargin > 4)
   error('unexpected number of input arguments')
end
if (nargin == 3)
   nguard = nguard_default;
else
   % nguard is 4
   d = size(nguard);
   if (min(d) ~= 1 | max(d) ~= 1 | length(d) ~= 2)
      error('unexpected dimensions for argument nguard')
   end
   nguard = round(nguard); % exact integer
   if (nguard < 1)
      error('must have nguard >= 1')
   end
end
%
d = size(ichan);
if (min(d) ~= 1 | length(d) ~= 2)
   error('unexpected dimensions for argument ichan')
end
nchan = max(d);
%
d = size(rad_box);
if (length(d) ~= 2 | min(d) < 1)
   error('unexpected dimensions for argument rad_box')
end
if (d(1) ~= nchan)
   error('lead dimension of rad_box must match length of ichan')
end
nobs = d(2);


% Assign IDs of required guard channels
id_guard_lo = max(id_band_end) + [nguard, nguard*3, nguard*5];
id_guard_hi = id_guard_lo + 1;


% Check ichan contains all required channels
id_need = union(id_out,[id_guard_lo, id_guard_hi]);
[junk, ind, junk2] = intersect(ichan, id_need);
if (length(ind) < length(id_need))
   error(['missing required channel IDs: ' int2str(setdiff(id_need,ichan))])
end


% Declare output array
radclass = class(rad_box); 
rad_ham = zeros(length(id_out), nobs, radclass);


% Loop over the bands
for ib = 1:3
   % Current band IDs; also indices for output
   id_band = id_band_start(ib):id_band_end(ib);
   % Indices of current band in box_to_ham output
   indx = 2:(length(id_band) + 1);
   % Determine indices of current band and guard channels
   [junk, ipt1, junk2] = intersect(ichan, id_guard_lo(ib));
   [junk, ipt2, junk2] = intersect(ichan, id_band);
   [junk, ipt3, junk2] = intersect(ichan, id_guard_hi(ib));
   % Assemble indices of required channels in required order
   ind_need = [ipt1, ipt2', ipt3];

   % Convert robs1 apodization from boxcar to Hamming
   [junk] = box_to_ham(rad_box(ind_need,:));
   rad_ham(id_band,:) = junk(indx,:);

   % Convert calc apodization from boxcar to Hamming
   [junk] = box_to_ham(cal_box(ind_need,:));
   cal_ham(id_band,:) = junk(indx,:);
end

%%% end of program %%%
