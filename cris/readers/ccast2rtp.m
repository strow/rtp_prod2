%
% NAME
%   ccast2rtp - take ccast SDR data to RTP structs
%
% SYNOPSIS
%   [head, hattr, prof, pattr] = ccast2rtp(sfile, nguard, nsarta);
%
% INPUTS
%   sfile  - ccast SDR mat file
%   nguard - number of output guard channels, default 2
%   nsarta - number of sarta guard channels, default 4
%
% OUTPUTS
%   head   - header data
%   hattr  - header attributes
%   prof   - profile data
%   pattr  - profile attributes
%
% DISCUSSION
%   see ccast/doc/ccast_sdr.txt for the ccast SDR spec
%
%   nguard and nsarta are optional parameters.  nguard is the number
%   of guard channels saved to the RTP output, and sguard the number
%   of guard channels sarta was built to recognize.  nguard should
%   be less than or equal to sguard.  The ccast SDR data has 2 guard
%   channels.  If you specify more in nguard, ichan and vchan fields
%   will be correct, and the missing radiances filled with NaNs
%
%   the output data is in frequency order.  head.vchan is the
%   frequency grid, including guard channels, and head.ichan an
%   informed guess at to what the sarta channel indices should
%   be for those frequencies
%
% AUTHOR
%  H. Motteler, 20 Oct 2014, from Scott's readsdr_rtp
%

function [head, hattr, prof, pattr] = ccast2rtp(sfile, nguard, nsarta);

% seconds between 1 Jan 1958 and 1 Jan 2000
tdif = 15340 * 24 * 3600;

% default is 2 output guard channels
if nargin < 2
  nguard = 2;
end

% default is 4 sarta guard channels
if nargin < 3
  nsarta = 4;
end

% sanity check for input file
if exist(sfile) ~= 2
  sfile
  error('ccast SDR file not found')
end

% load the ccast SDR data
load(sfile)

% sanity check for ccast QC 
if exist ('L1b_err') ~= 1
  sfile
  error('L1b_err flags missing in ccast SDR file')
end

% get total obs count
[m, nscan] = size(geo.FORTime);
nobs = 9 * 30 * nscan;

%---------------
% copy geo data 
%---------------
prof = struct;
prof.rlat = single(geo.Latitude(:)');
prof.rlon = single(geo.Longitude(:)');
prof.rtime = reshape(ones(9,1) * iet2tai(geo.FORTime(:))', 1, nobs);
prof.satzen = single(geo.SatelliteZenithAngle(:)');
prof.satazi = single(geo.SatelliteAzimuthAngle(:)');
prof.solzen = single(geo.SolarZenithAngle(:)');
prof.solazi = single(geo.SolarAzimuthAngle(:)');
prof.zobs = single(geo.Height(:)');

iobs = 1:nobs;
prof.atrack = int32(1 + floor((iobs-1)/270) );
prof.xtrack = int32(1 + mod(floor((iobs-1)/9),30) );
prof.ifov = int32(1 + mod(iobs-1,9) );

%--------------------
% copy radiance data 
%--------------------
sg = 2;       % number of src guard chans
dg = nguard;  % number of dst guard chans

% true channel set sizes
nLW = length(vLW) - 2 * sg;  
nMW = length(vMW) - 2 * sg;
nSW = length(vSW) - 2 * sg;

% total number of output channels
nout = nLW + nMW + nSW + 6 * dg;

% initialize radiance output
prof.robs1 = ones(nout, nobs, 'single') * NaN;

[si, di] = guard_ind(sg, dg, nLW);
rtmp = reshape(rLW, length(vLW), nobs);
prof.robs1(di, :) = single(rtmp(si, :));

[si, di] = guard_ind(sg, dg, nMW);
di = nLW + 2 * dg + di;
rtmp = reshape(rMW, length(vMW), nobs);
prof.robs1(di, :) = single(rtmp(si, :));

[si, di] = guard_ind(sg, dg, nSW);
di = nLW + nMW + 4 * dg + di;
rtmp = reshape(rSW, length(vSW), nobs);
prof.robs1(di, :) = single(rtmp(si, :));

% set to 1, for now
prof.robsqual = zeros(1, nobs, 'single');

% observer pressure
prof.pobs = zeros(1,nobs,'single');

% upwelling radiances
prof.upwell = ones(1,nobs,'int32');

%--------------------
% set the prof udefs
%--------------------
prof.udef = zeros(20, nobs, 'single');
prof.iudef = zeros(10, nobs, 'int32');

% $$$ iudef 3 is granule ID as an int32
% $$$ t1 = str2double(cellstr(geo.Granule_ID(:,4:16)))';
% $$$ t2 = int32(ones(270,1) * t1);
% $$$ prof.iudef(3,:) = t2(:)';

% iudef 4 is ascending/descending flag
t1 = geo.Asc_Desc_Flag';
t2 = int32(ones(270,1) * t1);
prof.iudef(4,:) = t2(:)';

% iudef 5 is orbit number 
t1 = geo.Orbit_Number';
t2 = int32(ones(270,1) * t1);
prof.iudef(5,:) = t2(:)';

% $$$ Interpolate X,Y,Z at MidTime to rtime
% $$$ xyz = geo.SCPosition; % [3 x 4*n]
% $$$ mtime = iet2tai(geo.MidTime); % [1 x 4*n]
% $$$ isub = prof.rtime > 0;
% $$$ msel = [logical(1); diff(mtime) > 0];
% $$$ prof.udef(10,isub) = interp1(mtime(msel),xyz(1,msel),prof.rtime(isub),'linear','extrap');
% $$$ prof.udef(11,isub) = interp1(mtime(msel),xyz(2,msel),prof.rtime(isub),'linear','extrap');
% $$$ prof.udef(12,isub) = interp1(mtime(msel),xyz(3,msel),prof.rtime(isub),'linear','extrap');

%-------------------------------
% trim output to a valid subset
%-------------------------------
% get good data index
% iok = find(~L1b_err(:)');
  [eLW, eMW, eSW] = fixmyQC(L1a_err, L1b_stat);
  etmp = eLW | eMW | eSW;
  iok = find(~etmp(:)');

prof.rlat   = prof.rlat(:, iok);
prof.rlon   = prof.rlon(:, iok);
prof.rtime  = prof.rtime(:, iok);
prof.satzen = prof.satzen(:, iok);
prof.satazi = prof.satazi(:, iok);
prof.solzen = prof.solzen(:, iok);
prof.solazi = prof.solazi(:, iok);
prof.zobs   = prof.zobs(:, iok);
prof.pobs   = prof.pobs(:, iok);
prof.upwell = prof.upwell(:, iok);
prof.atrack = prof.atrack(:, iok);
prof.xtrack = prof.xtrack(:, iok);
prof.ifov   = prof.ifov(:, iok);
prof.robs1  = prof.robs1(:, iok);
prof.robsqual = prof.robsqual(:, iok);
prof.udef   = prof.udef(:, iok);
prof.iudef  = prof.iudef(:, iok);

%------------------------
% set profile attributes
%------------------------
pattr = {{'profiles' 'rtime' 'seconds since 0z 1 Jan 2000'}, ...
         {'profiles' 'iudef(3,:)' 'Granule ID {granid}'}, ...
         {'profiles' 'iudef(4,:)' 'Descending Indicator {descending_ind}'}, ...
         {'profiles' 'iudef(5,:)' 'Beginning Orbit Number {orbit_num}'}, ...
         {'profiles' 'udef(10,:)' 'spacecraft X coordinate {X}'}, ...
         {'profiles' 'udef(11,:)' 'spacecraft Y coordinate {Y}'}, ...
         {'profiles' 'udef(12,:)' 'spacecraft Z coordinate {Z}'}, ...
        };

%-------------------
% set header values
%-------------------
head = struct;
head.nchan = nout;
head.ichan = cris_ichan(nguard, nsarta, nLW, nMW, nSW);
head.vchan = cris_vchan(nguard, userLW, userMW, userSW);
head.pfields = 4; % 4 = IR obs

%-----------------------
% set header attributes
%-----------------------
hattr = {{'header', 'instid', 'CrIS'}, ...
         {'header', 'reader', 'ccast2rtp'}, ...
        };

