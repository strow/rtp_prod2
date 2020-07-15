function [head, hattr, prof, pattr] = uwnc2rtp(nfile, opt)

% REQUIRES:
%          /asl/packages/time  :: airs2tai
%          /asl/packages/ccast/motmsc/rtp_sarta   :: ccast2rtp, cris_[iv]chan

nguard = 2; % set 2 guard channels
nsarta = 4;

% read in UW netcdf file 'nfile'
s = read_netcdf(nfile);

nfovs = 9;
nfors = 30;
nscans = 45;

nobs = nfovs*nfors*nscans;

% build user grid structures (These are packaged in Howard's ccast
% product but not in UW cris. Creating them here let's us use
% Howard's routines later)
if nargin < 2 | (nargin == 2 & strcmp(opt.resmode,'lowres'))
    userLW = struct('v1',650,'v2',1095,'opd',0.800,'vr',15,'dv', ...
                    0.6250,'band','LW');
    userMW = struct('v1',1210,'v2',1750,'opd',0.400,'vr',20, ...
                    'dv',1.2500,'band','MW');
    userSW = struct('v1',2155,'v2',2550,'opd',0.200,'vr', ...
                    22,'dv',2.500,'band','SW');
elseif nargin ==2 & strcmp(opt.resmode,'hires')
    userLW = struct('v1',650,'v2',1095,'opd',0.800,'vr',15,'dv', ...
                    0.6250,'band','LW');
    userMW = struct('v1',1210,'v2',1750,'opd',0.800,'vr',20, ...
                    'dv',0.6250,'band','MW');
    userSW = struct('v1',2155,'v2',2550,'opd',0.800,'vr', ...
                    20,'dv',0.6250,'band','SW');
else
    % Something's wrong: fail gently
    fprintf(1, ['** Problem setting parameters for resolution mode ' ...
                'Exiting\n'])
    head = NaN; hattr = NaN; prof = NaN; pattr = NaN;
    return
end

%--------------------------------------------------
% build prof structure
prof = struct;
prof.rlat = single(reshape(s.lat, 1, nobs));
prof.rlon = single(reshape(s.lon, 1, nobs));

% Obs times are TAI93 times (like AIRS) but need to be TAI58 for
% consistency wth other downstream processing
temp = reshape(airs2tai(s.obs_time_tai93), 1, nfors*nscans);
prof.rtime = reshape(ones(9,1)*temp, 1, nobs);
clear temp;

% $$$ prof.satzen = reshape(s.sat_zen, 1, nobs);
prof.satzen = reshape(s.sat_zen, 1, nobs);
prof.satazi = reshape(s.sat_azi, 1, nobs);
prof.solzen = reshape(s.sol_zen, 1, nobs);
prof.solazi = reshape(s.sol_azi, 1, nobs);
% SatelliteRange is zobs for nadir
temp = squeeze(s.sat_range(5,:,:));
temp = (nanmean(temp(15,:),2) + nanmean(temp(16,:),2))/2;
prof.zobs = ones(1,nobs)*temp;
clear temp;

iobs = 1:nobs;
prof.atrack = int32( 1 + floor((iobs-1)/270) );
prof.xtrack = int32( 1 + mod(floor((iobs-1)/9),30) );
prof.ifov = int32( 1 + mod(iobs-1,9) );

% reshape and concatenate radiance arrays
[vLW,~] = size(s.wnum_lw);
[vMW,~] = size(s.wnum_mw);
[vSW,~] = size(s.wnum_sw);

%--------------------
% copy radiance data 
%--------------------
sg = 2;       % number of src guard chans
dg = nguard;  % number of dst guard chans

% true channel set sizes
nLW = vLW - 2 * sg;  
nMW = vMW - 2 * sg;
nSW = vSW - 2 * sg;

% total number of output channels
nout = nLW + nMW + nSW + 6 * dg;

% initialize radiance output
prof.robs1 = ones(nout, nobs, 'single') * NaN;

[si, di] = guard_ind(sg, dg, nLW);
rtmp = reshape(s.rad_lw, vLW, nobs);
prof.robs1(di, :) = single(rtmp(si, :));

[si, di] = guard_ind(sg, dg, nMW);
di = nLW + 2 * dg + di;
rtmp = reshape(s.rad_mw, vMW, nobs);
prof.robs1(di, :) = single(rtmp(si, :));

[si, di] = guard_ind(sg, dg, nSW);
di = nLW + nMW + 4 * dg + di;
rtmp = reshape(s.rad_sw, vSW, nobs);
prof.robs1(di, :) = single(rtmp(si, :));

% set to 1, for now
prof.robsqual = zeros(1, nobs, 'single');

% observer pressure
prof.pobs = zeros(1,nobs,'single');

% upwelling radiances
prof.upwell = ones(1,nobs,'int32');

%**************************************************

%--------------------
% set the prof udefs
%--------------------
prof.udef = zeros(20, nobs, 'single');
prof.iudef = zeros(10, nobs, 'int32');

% iudef 3 is granule ID as an int32
prof.iudef(3,:) = NaN(nobs,1);  % no granule id info
                                       % available in UW format?
                                       % s.obs_id might work
                                       % here but, it is unpopulated

% iudef 4 is ascending/descending flag
t1 = double(s.asc_flag)';
t2 = int32(ones(270,1) * t1);
prof.iudef(4,:) = t2(:)';

% iudef 5 is orbit number 
prof.iudef(5,:) = NaN(nobs,1); % nothing in the UW
                                            % format that looks
                                            % like an orbit number
                                            % or similar designator

%**************************************************
% build head structure
head = struct;
head.nchan = nout;
head.ichan = cris_ichan(nguard, nsarta, nLW, nMW, nSW)';
head.vchan = cris_vchan(nguard, userLW, userMW, userSW)';
head.pfields = 4; % 4 = IR obs

% build header attribute structure
hattr = {{'header', 'instid', 'CrIS'}, ...
         {'header', 'reader', 'uwnc2rtp'}, ...
        };

% build profile attribute structure
pattr = {{'profiles' 'rtime' 'seconds since 0z 1 Jan 1993'}, ...
         {'profiles' 'iudef(3,:)' 'Granule ID {granid}'}, ...
         {'profiles' 'iudef(4,:)' 'Descending Indicator {descending_ind}'}, ...
         {'profiles' 'iudef(5,:)' 'Beginning Orbit Number {orbit_num}'}, ...
         {'profiles' 'udef(10,:)' 'spacecraft X coordinate {X}'}, ...
         {'profiles' 'udef(11,:)' 'spacecraft Y coordinate {Y}'}, ...
         {'profiles' 'udef(12,:)' 'spacecraft Z coordinate {Z}'}, ...
        };

