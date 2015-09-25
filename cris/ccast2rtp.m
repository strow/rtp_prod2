%
% NAME
%   ccast2rtp - read ccast SDR data as RTP structs
%
% SYNOPSIS
%   [head, hattr, prof, pattr] = ccast2rtp(sfile, nguard);
%
% INPUTS
%   sfile  - ccast SDR mat file
%   nguard - optional number of guard channels, default 0
%
% OUTPUTS
%   head   - header data
%   hattr  - header attributes
%   prof   - profile data
%   pattr  - profile attributes
%
% DISCUSSION
%   derived from Scott's readsdr_rtp
%
%   see ccast/doc/ccast_sdr.txt for the ccast SDR spec
%
%   common values for nguard are 0, 2, and 4.  The ccast SDR data
%   has 2 guard channels.  If you specify more than that, the ichan
%   and vchan values will be correct, and the missing radiances are
%   filled with NaNs
%
%   the output grid (in head.vchan) is in frequency order, while
%   head.ichan is an informed guess at to what the sarta channel
%   assignments would be
%
% AUTHOR
%  H. Motteler, 20 Oct 2014, 
%

function [head, hattr, prof, pattr] = ccast2rtp(sfile, nguard);

% seconds between 1 Jan 1958 and 1 Jan 2000
tdif = 15340 * 24 * 3600;

% Suggest changing tif to reference 1993, like AIRS, then 
% CrIS rtime == AIRS rtime.
% tdif = seconds( datetime(1993,1,1) - datetime(1958,1,1) );

% default is no output guard channels
if nargin < 2
  nguard = 0;
end

% sanity check for input file
if exist(sfile) ~= 2
  sfile
  error('ccast SDR file not found')
end

% load the ccast SDR data
load(sfile)

% sanity check for ccast QC 
if exist ('L1a_err') ~= 1
  sfile
  error('L1a_err flags missing in ccast SDR file')
end

% get total obs count
[m, nscan] = size(scTime);
nobs = 9 * 30 * nscan;

%---------------
% copy geo data 
%---------------
prof = struct;
prof.rlat = single(geo.Latitude(:)');
prof.rlon = single(geo.Longitude(:)');
%prof.rtime = reshape(ones(9,1) * (geo.FORTime(:)' * 1e-6 - tdif), 1, nobs);
prof.rtime = reshape(ones(9,1) * (geo.FORTime(:)' * 1e-6 ), 1, nobs);
prof.satzen = single(geo.SatelliteZenithAngle(:)');
prof.satazi = single(geo.SatelliteAzimuthAngle(:)');
prof.solzen = single(geo.SolarZenithAngle(:)');
prof.solazi = single(geo.SolarAzimuthAngle(:)');
% Incorrect
%prof.zobs = single(geo.Height(:)');
% SatelliteRange is zobs for nadir
temp = squeeze(geo.SatelliteRange(5,:,:));
temp = (nanmean(temp(15,:),2) + nanmean(temp(16,:),2))/2;
prof.zobs = ones(1,nobs)*temp;
clear temp;

iobs = 1:nobs;
prof.atrack = int32( 1 + floor((iobs-1)/270) );
prof.xtrack = int32( 1 + mod(floor((iobs-1)/9),30) );
prof.ifov = int32( 1 + mod(iobs-1,9) );

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

% iudef 3 is granule ID as an int32
t1 = str2double(cellstr(geo.Granule_ID(:,4:16)))';
t2 = int32(ones(270,1) * t1);
prof.iudef(3,:) = t2(:)';

% iudef 4 is ascending/descending flag
t1 = geo.Asc_Desc_Flag';
t2 = int32(ones(270,1) * t1);
prof.iudef(4,:) = t2(:)';

% iudef 5 is orbit number 
t1 = geo.Orbit_Number';
t2 = int32(ones(270,1) * t1);
prof.iudef(5,:) = t2(:)';

% Interpolate X,Y,Z at MidTime to rtime
xyz = geo.SCPosition; % [3 x 4*n]
mtime = double(geo.MidTime)*1E-6 - tdif; % [1 x 4*n]
isub = prof.rtime > 0;
msel = [logical(1); diff(mtime) > 0];
prof.udef(10,isub(2:end)) = interp1(mtime(msel(2:end)),xyz(1,msel(2:end)),prof.rtime(isub(2:end)),'linear','extrap');
prof.udef(11,isub(2:end)) = interp1(mtime(msel(2:end)),xyz(2,msel(2:end)),prof.rtime(isub(2:end)),'linear','extrap');
prof.udef(12,isub(2:end)) = interp1(mtime(msel(2:end)),xyz(3,msel(2:end)),prof.rtime(isub(2:end)),'linear','extrap');

%-------------------------------
% trim output to a valid subset
%-------------------------------
% get good data index
iok = find(reshape(ones(9,1) * ~L1a_err(:)', 1, nobs));

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
pattr = {{'profiles' 'rtime' 'seconds since 0z 1 Jan 1958'}, ...
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
head.ichan = cris_ichan(nguard, 4, nLW, nMW, nSW);
head.vchan = cris_vchan(nguard, userLW, userMW, userSW);
head.pfields = 4; % 4 = IR obs

%-----------------------
% set header attributes
%-----------------------
hattr = {{'header', 'instid', 'CrIS'}, ...
         {'header', 'reader', 'ccast2rtp'}, ...
        };

