%
% NAME
%   iasi2rtp - read IASI M02 L1C data as RTP structs
%
% SYNOPSIS
%   [head, hattr, prof, pattr] = iasi2rtp(sfile);
%
% INPUTS
%   sfile  - IASI binary file, with full absolute path
%
% OUTPUTS
%   head   - header data
%   hattr  - header attributes
%   prof   - profile data
%   pattr  - profile attributes
%
% DISCUSSION
%   derived 
%
% DEPENDENCIES
%   a. local files:
%      readl1c_epsflip_all.m, read_eps_grh.m, read_eps_mphr102.m, declare_mdr.m
%      load_mdr.m, read_eps_giadr512.m, read_eps_mdr824.m, read_eps_mdr825.m
%   b. remote files:
%      /asl/matlib/aslutil/ {mktemp.m, unlink.m}

function [head, hattr, prof, pattr] = iasi2rtp(sfile);

% establish dependency paths
addpath /asl/matlib/aslutil/                    % mktemp.m unlink.m


% Initializations/defaults
% IASI channel info
fchan  = (645:0.25:2760)'; %' [8461 x 1]
indpt1 = (1:4231)';
indpt2 = (4232:8461)';
id_offset = 0;             % offset for index to fast model ID conversion (not used)

% Expected/required data dimensions
maxfov  = 690;             % max number of atrack*xtrack per granule (can be 660).
nxtrack = 30;              % number of cross track (xtrack)
npixfov = 4;               % number of IASI "pixels" per FOV (ie 2x2 = 4)
nimager = 4096;            % number of IASI Imager pixels (64 x 64)
nchan   = 8461;            % number of IASI channels


% sanity check for input file
if exist(sfile) ~= 2
  sfile
  error('IASI L1C file not found\n');
end

% Clear all used variables
clear qualflag randomflag coastflag  siteflag  imageunflag  hicloudflag;

% load the granule
data = readl1c_epsflip_all(sfile);

% get number of observations
[nax,nif] = size(data.Latitude);
% warn if not [690 x 4] or [660 x 4]
if( nax ~= 690 && nax ~= 660 || nif ~= 4) 
  warning('unexpected granule size ', nax,nif);
end
nobs = single(round(nax*nif));

% convert IASI time to TAI-58 (needed for fill_ecmwf.m)
ntime = data.Time2000 + 15340 * 24 * 3600;

% trap bad data: defined by GQisFlagQual == 7, with in valid time -> 2001/01/01
% and reset time so that fill_era.m will work.
% get granule mean time
badObs    = find(reshape(data.GQisFlagQual,[],nobs) == 7);
junk      = reshape(ntime,[],nobs);
junk(badObs) = NaN;
gtimemn   = nanmean(junk);
junk(badObs) = gtimemn;
rtime     = junk;   clear junk;

% Reshape lat/lon to 1D for use with ECMWF reader
prof.rlat     = single(reshape(data.Latitude, 1,nobs));
prof.rlon     = single(reshape(data.Longitude, 1,nobs));
%prof.rtime    = double(reshape(ntime,1,nobs));
prof.rtime    = double(rtime);
prof.robsqual = single(reshape(data.GQisFlagQual,1,nobs));
prof.satzen   = single(reshape(data.Satellite_Zenith,1,nobs));
prof.satazi   = single(reshape(data.Satellite_Azimuth,1,nobs));
prof.solzen   = single(reshape(data.Solar_Zenith,1,nobs));
prof.solazi   = single(reshape(data.Solar_Azimuth,1,nobs));
prof.zobs     = single(reshape(data.Satellite_Height,1,nobs));
prof.atrack   = single(reshape(data.Scan_Line,1,nobs));
prof.xtrack   = single(reshape(data.AMSU_FOV,1,nobs));
      % Note: IASI has no granule number (findex)
prof.ifov     = single(reshape(data.IASI_FOV,1,nobs)); % pixel number
prof.robs1    = single(reshape(data.IASI_Radiances,nobs,nchan)'); %'

% observer pressures
prof.pobs = zeros(1,nobs,'single');

% upwelling radiances
prof.upwell = ones(1,nobs,'int32');

% set the prof udefs
% ------------------
prof.udef  = zeros(20, nobs,'single');
prof.iudef = zeros(10, nobs, 'int32');

prof.iudef(3,:)  = reshape(data.Scan_Direction,1,nobs);

prof.udef(6,:)   = data.state_vector_time - prof.rtime;


% set header attributes
% ---------------------
hattr = {{'header', 'instid', 'IASI'},...
         {'header', 'pltfid', 'MetOp-A'},...
         {'header', 'reader', 'iasi2rtp'},...
	 {'header', 'number FORs', nax},...
        };

% set header values
% -----------------
head         = struct;
head.pfields = 4;                     % 4: IR Obs, 
head.vchan   = fchan;                 % column vectors [8641 x 1] etc
head.nchan   = nchan;
head.ichan   = [indpt1; indpt2];                % [indpt1; indpt2];

% set profile attributes
% ----------------------
pattr = {{'profiles' 'rtime'      'seconds since 0z, 1 Jan 1958'},...
	 {'profiles' 'robsqual'   'GQisFlagQual [0=OK,1=band1bad,2=band2bad,4=band3bad]'},...
         {'profiles' 'iudef(3,:)' 'scan direction {scandir}'}, ...
	 {'profiles' 'iudef(6,:)' 'state_vector_time-rtime {orbittime}'},...
	};	 

end   % of function
